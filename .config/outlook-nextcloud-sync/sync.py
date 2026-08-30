#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.12"
# dependencies = [
#   "caldav>=1.3,<2",
#   "exchangelib>=5.6,<6",
# ]
# ///

from __future__ import annotations

import argparse
import hashlib
import json
import os
import sys
import tomllib
import subprocess
import traceback
from html.parser import HTMLParser
from urllib.parse import urljoin, urlparse
from datetime import date, datetime, timedelta, timezone
from pathlib import Path
from types import SimpleNamespace

from caldav import DAVClient
from caldav.lib.error import NotFoundError
from exchangelib import Account, Attendee, BASIC, DELEGATE, NTLM, Configuration, Credentials, EWSDateTime, EWSTimeZone, FailFast, FileAttachment, Mailbox
from exchangelib.protocol import BaseProtocol
from icalendar import Alarm, Calendar, Event, vBinary, vCalAddress, vText

DEFAULT_CONFIG = Path.home() / ".config/outlook-nextcloud-sync/config.toml"
DEFAULT_CREDENTIALS = Path.home() / ".config/outlook-nextcloud-sync/credentials.toml"
SYNC_MARKER = "X-OUTLOOK-NEXTCLOUD-SYNC"


def load_config(path: Path) -> dict:
    with path.open("rb") as handle:
        return tomllib.load(handle)

def load_credentials(path: Path) -> dict:
    if path.stat().st_mode & 0o077:
        raise RuntimeError(f"{path} must have mode 0600")
    exchange = load_config(path)["exchange"]
    if not exchange.get("username") or not exchange.get("password"):
        raise RuntimeError(f"Fill username and password in {path}")
    exchange.setdefault("mailbox", exchange["username"])
    return exchange


def credential(name: str) -> str:
    directory = os.environ.get("CREDENTIALS_DIRECTORY")
    if not directory:
        raise RuntimeError("Run through outlook-nextcloud-sync.service so systemd can decrypt credentials")
    path = Path(directory) / name
    return path.read_text().rstrip("\n")


def event_uid(source_uid: str, start: datetime | date) -> str:
    raw = f"{source_uid}\0{start.isoformat()}".encode()
    return f"{hashlib.sha256(raw).hexdigest()}@ews-work-mirror"


def to_utc(value: datetime) -> datetime:
    return datetime.fromtimestamp(value.timestamp(), timezone.utc)

class MeetingBodyParser(HTMLParser):
    def __init__(self) -> None:
        super().__init__(convert_charrefs=True)
        self.text: list[str] = []
        self.links: list[str] = []
        self.skip = 0

    def handle_starttag(self, tag: str, attrs) -> None:
        if tag in {"script", "style"}:
            self.skip += 1
        if not self.skip and tag in {"br", "div", "li", "p", "tr"}:
            self.text.append("\n")
        if not self.skip and tag == "a":
            href = dict(attrs).get("href", "")
            if urlparse(href).scheme in {"http", "https"} and href not in self.links:
                self.links.append(href)

    def handle_endtag(self, tag: str) -> None:
        if tag in {"script", "style"} and self.skip:
            self.skip -= 1
        elif not self.skip and tag in {"div", "li", "p", "tr"}:
            self.text.append("\n")

    def handle_data(self, data: str) -> None:
        if not self.skip:
            self.text.append(data)

    def plain_text(self) -> str:
        return "\n".join(line.strip() for line in "".join(self.text).splitlines() if line.strip())


def event_details(item, owa_url: str) -> tuple[str, str | None, str | None]:
    parser = MeetingBodyParser()
    parser.feed(str(item.body or ""))
    description = str(item.text_body or "").strip() or parser.plain_text()

    links = list(parser.links)
    for attr in ("meeting_workspace_url", "net_show_url"):
        link = str(getattr(item, attr, "") or "").strip()
        if urlparse(link).scheme in {"http", "https"} and link not in links:
            links.append(link)
    missing_links = [link for link in links if link not in description]
    if missing_links:
        description = "\n\n".join(filter(None, [description, "Ссылки:\n" + "\n".join(missing_links)]))

    attachment_lines = []
    for attachment in getattr(item, "attachments", None) or []:
        name = str(attachment.name or "без имени")
        content_type = str(attachment.content_type or "application/octet-stream")
        size = int(attachment.size or 0)
        attachment_lines.append(f"- {name} ({content_type}, {size} байт)")
    if attachment_lines:
        description = "\n\n".join(
            filter(None, [description, "Вложения:\n" + "\n".join(attachment_lines)])
        )

    def owa_link(query) -> str | None:
        query = str(query or "").strip()
        return urljoin(owa_url.rstrip("/") + "/", query) if query else None

    read_url = owa_link(getattr(item, "web_client_read_form_query_string", None))
    edit_url = owa_link(getattr(item, "web_client_edit_form_query_string", None))
    if read_url:
        description = "\n\n".join(filter(None, [description, f"Открыть в Outlook: {read_url}"]))
    if edit_url and edit_url != read_url:
        description = "\n".join(filter(None, [description, f"Редактировать в Outlook: {edit_url}"]))
    return description, read_url, edit_url


def add_x_property(event: Event, name: str, value) -> None:
    if value is not None and str(value) != "":
        event.add(f"X-EWS-{name}", str(value))


def mailbox_address(mailbox, role: str | None = None, partstat: str | None = None):
    if not mailbox or not mailbox.email_address:
        return None
    address = vCalAddress(f"MAILTO:{mailbox.email_address}")
    if mailbox.name:
        address.params["CN"] = vText(mailbox.name)
    if role:
        address.params["ROLE"] = role
    if partstat:
        address.params["PARTSTAT"] = partstat
    return address


def attendee_partstat(response_type) -> str:
    return {
        "Accept": "ACCEPTED",
        "Decline": "DECLINED",
        "Tentative": "TENTATIVE",
        "NoResponseReceived": "NEEDS-ACTION",
        "Unknown": "NEEDS-ACTION",
        "Organizer": "ACCEPTED",
    }.get(str(response_type), "NEEDS-ACTION")


def add_attendees(event: Event, attendees, role: str) -> None:
    for attendee in attendees or []:
        address = mailbox_address(
            attendee.mailbox,
            role=role,
            partstat=attendee_partstat(attendee.response_type),
        )
        if address:
            event.add("attendee", address, encode=0)


def add_attachments(event: Event, item, config: dict) -> None:
    max_each = int(config["sync"].get("max_attachment_bytes", 10 * 1024 * 1024))
    max_total = int(config["sync"].get("max_total_attachment_bytes", 20 * 1024 * 1024))
    total = 0
    for attachment in getattr(item, "attachments", None) or []:
        if not isinstance(attachment, FileAttachment):
            continue
        size = int(attachment.size or 0)
        # ponytail: inline payloads are bounded; the Outlook URL remains the fallback for larger files.
        if size > max_each or total + size > max_total:
            continue
        content = attachment.content
        binary = vBinary(content)
        binary.params["FMTTYPE"] = attachment.content_type or "application/octet-stream"
        binary.params["FILENAME"] = attachment.name or "attachment"
        if attachment.content_id:
            binary.params["X-CONTENT-ID"] = attachment.content_id
        if attachment.is_inline:
            binary.params["X-INLINE"] = "TRUE"
        event.add("attach", binary, encode=0)
        total += len(content)


def make_ical(item, config: dict) -> tuple[str, bytes]:
    start = item.start.date() if item.is_all_day else to_utc(item.start)
    end = item.end.date() if item.is_all_day else to_utc(item.end)
    source_uid = item.uid or item.id
    uid = event_uid(source_uid, start)

    calendar = Calendar()
    calendar.add("prodid", "-//outlook-nextcloud-sync//full-mirror//EN")
    calendar.add("version", "2.0")

    event = Event()
    event.add("uid", uid)
    event.add("dtstamp", datetime.now(timezone.utc))
    event.add("dtstart", start)
    event.add("dtend", end)
    event.add("summary", item.subject or "Работа")

    description, read_url, edit_url = event_details(item, config["exchange"]["owa_url"])
    if description:
        event.add("description", description)
    if item.body:
        event.add(
            "X-ALT-DESC",
            vText(str(item.body), params={"FMTTYPE": "text/html"}),
            encode=0,
        )
    if read_url:
        event.add("url", read_url)
    add_x_property(event, "EDIT-URL", edit_url)

    location = str(getattr(item, "location", "") or "").strip()
    if location:
        event.add("location", location)

    organizer = mailbox_address(getattr(item, "organizer", None))
    if organizer:
        event.add("organizer", organizer, encode=0)
    add_attendees(event, getattr(item, "required_attendees", None), "REQ-PARTICIPANT")
    add_attendees(event, getattr(item, "optional_attendees", None), "OPT-PARTICIPANT")
    add_attendees(event, getattr(item, "resources", None), "NON-PARTICIPANT")

    categories = list(getattr(item, "categories", None) or [])
    if categories:
        event.add("categories", categories)
    event.add(
        "priority",
        {"High": 1, "Normal": 5, "Low": 9}.get(
            str(getattr(item, "importance", "Normal")), 5
        ),
    )
    event.add(
        "class",
        {
            "Confidential": "CONFIDENTIAL",
            "Private": "PRIVATE",
            "Personal": "PRIVATE",
            "Normal": "PUBLIC",
        }.get(str(getattr(item, "sensitivity", "Normal")), "PUBLIC"),
    )

    free_busy = str(getattr(item, "legacy_free_busy_status", "Busy"))
    event.add("transp", "TRANSPARENT" if free_busy == "Free" else "OPAQUE")
    event.add(
        "status",
        "CANCELLED"
        if getattr(item, "is_cancelled", False)
        else "TENTATIVE"
        if free_busy == "Tentative"
        else "CONFIRMED",
    )

    if getattr(item, "datetime_created", None):
        event.add("created", to_utc(item.datetime_created))
    if getattr(item, "last_modified_time", None):
        event.add("last-modified", to_utc(item.last_modified_time))
    if getattr(item, "appointment_sequence_number", None) is not None:
        event.add("sequence", int(item.appointment_sequence_number))

    if (
        getattr(item, "reminder_is_set", False)
        and getattr(item, "reminder_minutes_before_start", None) is not None
    ):
        alarm = Alarm()
        alarm.add("action", "DISPLAY")
        alarm.add("description", item.subject or "Рабочая встреча")
        alarm.add("trigger", timedelta(minutes=-int(item.reminder_minutes_before_start)))
        event.add_component(alarm)

    metadata = {
        "SOURCE-UID": getattr(item, "uid", None),
        "ITEM-CLASS": getattr(item, "item_class", None),
        "CONVERSATION-ID": getattr(item, "conversation_id", None),
        "FREE-BUSY": free_busy,
        "MY-RESPONSE": getattr(item, "my_response_type", None),
        "APPOINTMENT-TYPE": getattr(item, "type", None),
        "APPOINTMENT-STATE": getattr(item, "appointment_state", None),
        "APPOINTMENT-REPLY-TIME": getattr(item, "appointment_reply_time", None),
        "RECURRENCE-ID": getattr(item, "recurrence_id", None),
        "ORIGINAL-START": getattr(item, "original_start", None),
        "IS-MEETING": getattr(item, "is_meeting", None),
        "IS-RECURRING": getattr(item, "is_recurring", None),
        "IS-ONLINE-MEETING": getattr(item, "is_online_meeting", None),
        "MEETING-REQUEST-SENT": getattr(item, "meeting_request_was_sent", None),
        "RESPONSE-REQUESTED": getattr(item, "is_response_requested", None),
        "ALLOW-NEW-TIME-PROPOSAL": getattr(item, "allow_new_time_proposal", None),
        "CONFERENCE-TYPE": getattr(item, "conference_type", None),
        "DURATION": getattr(item, "duration", None),
        "CONFLICTING-COUNT": getattr(item, "conflicting_meeting_count", None),
        "ADJACENT-COUNT": getattr(item, "adjacent_meeting_count", None),
        "REMINDER-DUE-BY": getattr(item, "reminder_due_by", None),
        "LAST-MODIFIED-BY": getattr(item, "last_modified_name", None),
    }
    for name, value in metadata.items():
        add_x_property(event, name, value)

    add_attachments(event, item, config)
    event.add(SYNC_MARKER, "1")
    calendar.add_component(event)
    return uid, calendar.to_ical()


def fetch_exchange(config: dict, auth: dict):
    exchange = config["exchange"]
    BaseProtocol.TIMEOUT = exchange.get("timeout_seconds", 20)
    credentials = Credentials(auth["username"], auth["password"])
    service = Configuration(
        service_endpoint=exchange["service_endpoint"],
        credentials=credentials,
        auth_type={"basic": BASIC, "ntlm": NTLM}[exchange.get("auth_type", "ntlm").lower()],
        retry_policy=FailFast(),
        max_connections=2,
    )
    account = Account(
        primary_smtp_address=auth["mailbox"],
        config=service,
        autodiscover=False,
        access_type=DELEGATE,
        default_timezone=EWSTimeZone("UTC"),
    )
    now = EWSDateTime.now(EWSTimeZone("UTC"))
    start = now - timedelta(days=config["sync"].get("lookback_days", 7))
    end = now + timedelta(days=config["sync"].get("lookahead_days", 60))
    fields = (
        "uid", "item_class", "subject", "sensitivity", "body", "text_body", "attachments",
        "datetime_created", "categories", "importance", "reminder_due_by", "reminder_is_set",
        "reminder_minutes_before_start", "last_modified_name", "last_modified_time",
        "web_client_read_form_query_string", "web_client_edit_form_query_string", "conversation_id",
        "start", "end", "original_start", "is_all_day", "legacy_free_busy_status", "location",
        "is_meeting", "is_cancelled", "is_recurring", "meeting_request_was_sent",
        "is_response_requested", "type", "my_response_type", "organizer", "required_attendees",
        "optional_attendees", "resources", "conflicting_meeting_count", "adjacent_meeting_count",
        "duration", "appointment_reply_time", "appointment_sequence_number", "appointment_state",
        "recurrence_id", "conference_type", "allow_new_time_proposal", "is_online_meeting",
        "meeting_workspace_url", "net_show_url",
    )
    return list(account.calendar.view(start=start, end=end).only(*fields))


def load_state(path: Path) -> set[str]:
    if not path.exists():
        return set()
    return set(json.loads(path.read_text()).get("uids", []))


def save_state(path: Path, uids: set[str]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_suffix(".tmp")
    temporary.write_text(json.dumps({"uids": sorted(uids)}, indent=2) + "\n")
    temporary.replace(path)


def sync_nextcloud(config: dict, password: str, items) -> tuple[int, int]:
    nextcloud = config["nextcloud"]
    state_path = Path(config["sync"]["state_file"]).expanduser()
    previous = load_state(state_path)
    current: set[str] = set()
    updated = 0

    with DAVClient(
        url=nextcloud["url"],
        username=nextcloud["username"],
        password=password,
        timeout=20,
    ) as client:
        target = client.calendar(url=nextcloud["calendar_url"])
        for item in items:
            uid, data = make_ical(item, config)
            current.add(uid)
            try:
                remote = target.event_by_uid(uid)
                remote.data = data
                remote.save()
            except NotFoundError:
                target.save_event(data)
            updated += 1

        deleted = 0
        for uid in previous - current:
            try:
                target.event_by_uid(uid).delete()
                deleted += 1
            except NotFoundError:
                pass

    save_state(state_path, current)
    return updated, deleted




def self_test() -> None:
    start = datetime(2026, 8, 30, 10, 0, tzinfo=timezone.utc)
    organizer = Mailbox(name="Alice", email_address="alice@example.com")
    attendee = Attendee(mailbox=Mailbox(name="Bob", email_address="bob@example.com"), response_type="Accept")
    attachment = FileAttachment(name="agenda.txt", content_type="text/plain", content=b"agenda")
    fake = SimpleNamespace(
        start=start,
        end=start + timedelta(minutes=90),
        is_all_day=False,
        uid="exchange-source-uid",
        id="fallback-id",
        subject="Совещание по проекту",
        body='<p>Повестка</p><a href="https://meet.example/join">Подключиться</a>',
        text_body="Повестка",
        web_client_read_form_query_string="?ItemID=abc&viewmodel=ReadMessageItem",
        web_client_edit_form_query_string="?ItemID=abc&viewmodel=EditItem",
        meeting_workspace_url=None,
        net_show_url=None,
        attachments=[attachment],
        location="Переговорная 1",
        organizer=organizer,
        required_attendees=[attendee],
        optional_attendees=[],
        resources=[],
        categories=["Проект"],
        importance="High",
        sensitivity="Confidential",
        legacy_free_busy_status="Tentative",
        is_cancelled=False,
        datetime_created=start - timedelta(days=1),
        last_modified_time=start,
        appointment_sequence_number=2,
        reminder_is_set=True,
        reminder_minutes_before_start=15,
    )
    config = {
        "exchange": {"owa_url": "https://mail.rwb.ru/owa/"},
        "sync": {"max_attachment_bytes": 1024, "max_total_attachment_bytes": 2048},
    }
    uid1, data1 = make_ical(fake, config)
    uid2, _ = make_ical(fake, config)
    text = data1.decode()
    assert uid1 == uid2
    for expected in (
        "SUMMARY:", "DESCRIPTION:", "meet.example/join", "URL:", "mail.rwb.ru/owa/",
        "CLASS:CONFIDENTIAL", "STATUS:TENTATIVE", "LOCATION:", "ORGANIZER", "ATTENDEE",
        "CATEGORIES:", "PRIORITY:1", "BEGIN:VALARM", "ATTACH;", "agenda.txt",
        "X-ALT-DESC;", "X-EWS-SOURCE-UID:exchange-source-uid", SYNC_MARKER,
    ):
        assert expected in text, expected
    print("self-test: ok")


def main() -> int:
    parser = argparse.ArgumentParser(description="One-way full Exchange EWS to Nextcloud mirror")
    parser.add_argument("--config", type=Path, default=DEFAULT_CONFIG)
    parser.add_argument("--credentials", type=Path, default=DEFAULT_CREDENTIALS)
    parser.add_argument("--self-test", action="store_true")
    args = parser.parse_args()

    if args.self_test:
        self_test()
        return 0

    if not os.environ.get("CREDENTIALS_DIRECTORY"):
        subprocess.run(
            ["systemctl", "--user", "start", "outlook-nextcloud-sync.service"],
            check=True,
        )
        subprocess.run(
            [
                "journalctl", "--user", "-u", "outlook-nextcloud-sync.service",
                "-n", "5", "--no-pager",
            ],
            check=True,
        )
        return 0

    config = load_config(args.config)
    auth = load_credentials(args.credentials)
    items = fetch_exchange(config, auth)
    updated, deleted = sync_nextcloud(config, credential("nextcloud_password"), items)
    print(f"sync complete: {updated} upserted, {deleted} deleted")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception as exc:
        traceback.print_exc()
        print(f"sync failed: {exc!r}", file=sys.stderr)
        raise SystemExit(1)
