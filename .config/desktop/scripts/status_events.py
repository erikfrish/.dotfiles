#!/usr/bin/env python3
"""Event-driven Waybar JSON streams; no periodic state polling."""
import argparse
import json
import os
from pathlib import Path
import select
import signal
import subprocess
import sys

import gi
gi.require_version('Gio', '2.0')
gi.require_version('GLibUnix', '2.0')
from gi.repository import Gio, GLib, GLibUnix

SCRIPTS = Path(__file__).resolve().parent


class StatusWatcher:
    def __init__(self, kind, slot=None):
        self.kind, self.slot = kind, slot
        self.runtime = Path(os.environ.get('XDG_RUNTIME_DIR', f'/run/user/{os.getuid()}'))
        self.config = Path(os.environ.get('XDG_CONFIG_HOME', Path.home() / '.config'))
        self.state = Path(os.environ.get('XDG_STATE_HOME', Path.home() / '.local/state'))
        self.last = None
        self.pending = 0
        self.monitors = {}
        self.bus = None
        self.subscriptions = []
        self.pid = None
        self.pidfd = None
        self.pid_source = 0
        self.dead_pid = None
        self.kvn_document = None
        self.loop = GLib.MainLoop()
        if kind == 'vpn':
            self.files = [self.config / 'dotfiles/machine.conf',
                          self.state / f'waybar/{slot}-connection']
        elif kind == 'kvn':
            self.files = [self.runtime / 'kvn/state.json']
        else:
            self.files = [self.runtime / 'desktop-state/gammastep']

    def emit(self, value):
        if value != self.last:
            print(json.dumps(value, ensure_ascii=False, separators=(',', ':')), flush=True)
            self.last = value

    def schedule(self, *_):
        if not self.pending:
            self.pending = GLib.idle_add(self.refresh)

    def file_changed(self, monitor, file, other, event):
        paths = [Path(f.get_path()) for f in (file, other) if f is not None and f.get_path()]
        if any(p == target or p in target.parents for p in paths for target in self.files):
            self.schedule()

    def monitor_files(self):
        # Follow the nearest existing ancestor until missing state directories appear.
        # Watching directories, not the target inode, survives atomic os.replace().
        directories = set()
        for target in self.files:
            parent = target.parent
            while not parent.is_dir() and parent != parent.parent:
                parent = parent.parent
            directories.add(parent)
        for old in self.monitors.keys() - directories:
            self.monitors.pop(old).cancel()
        for directory in directories - self.monitors.keys():
            monitor = Gio.File.new_for_path(str(directory)).monitor_directory(Gio.FileMonitorFlags.WATCH_MOVES, None)
            monitor.connect('changed', self.file_changed)
            self.monitors[directory] = monitor

    def subscribe(self, sender, interface, member, path=None, arg0=None):
        self.subscriptions.append(self.bus.signal_subscribe(
            sender, interface, member, path, arg0, Gio.DBusSignalFlags.NONE,
            lambda *_: self.schedule()))

    def connect_bus(self):
        if self.kind == 'kvn':
            return
        bus_type = Gio.BusType.SYSTEM if self.kind == 'vpn' else Gio.BusType.SESSION
        self.bus = Gio.bus_get_sync(bus_type, None)
        if self.kind == 'vpn':
            self.subscribe('org.freedesktop.NetworkManager', 'org.freedesktop.DBus.Properties',
                           'PropertiesChanged', '/org/freedesktop/NetworkManager')
            self.subscribe('org.freedesktop.DBus', 'org.freedesktop.DBus', 'NameOwnerChanged',
                           '/org/freedesktop/DBus', 'org.freedesktop.NetworkManager')
        else:
            self.bus.call_sync('org.freedesktop.systemd1', '/org/freedesktop/systemd1',
                               'org.freedesktop.systemd1.Manager', 'Subscribe', None, None,
                               Gio.DBusCallFlags.NONE, 5000, None)
            self.subscribe('org.freedesktop.systemd1', 'org.freedesktop.DBus.Properties',
                           'PropertiesChanged', '/org/freedesktop/systemd1/unit/gammastep_2eservice')
            self.subscribe('org.freedesktop.systemd1', 'org.freedesktop.systemd1.Manager',
                           'UnitNew', '/org/freedesktop/systemd1', 'gammastep.service')

    def clear_pid(self):
        if self.pid_source:
            GLib.source_remove(self.pid_source)
            self.pid_source = 0
        if self.pidfd is not None:
            os.close(self.pidfd)
            self.pidfd = None
        self.pid = None

    def pid_exited(self, *_):
        self.dead_pid = self.pid
        self.pid_source = 0
        self.clear_pid()
        self.schedule()
        return GLib.SOURCE_REMOVE

    def watch_pid(self, pid):
        if pid == self.dead_pid:
            return False
        if pid == self.pid and self.pidfd is not None:
            return not bool(select.select([self.pidfd], [], [], 0)[0])
        self.clear_pid()
        try:
            fd = os.pidfd_open(pid)
        except ProcessLookupError:
            self.dead_pid = pid
            return False
        if select.select([fd], [], [], 0)[0]:
            os.close(fd)
            self.dead_pid = pid
            return False
        self.pid, self.pidfd = pid, fd
        self.pid_source = GLib.io_add_watch(fd, GLib.IO_IN | GLib.IO_HUP | GLib.IO_ERR, self.pid_exited)
        return True

    def kvn(self):
        try:
            document = json.loads(self.files[0].read_text())
            if not isinstance(document, dict):
                return None
        except FileNotFoundError:
            document = {}
        except (json.JSONDecodeError, UnicodeError):
            return None  # Wait for the final write, rather than flashing stale/partial JSON.
        if document != self.kvn_document:
            self.dead_pid = None
            self.kvn_document = document
        pid = document.get('singbox_pid')
        connected = document.get('connected') is True
        if connected and isinstance(pid, int) and not isinstance(pid, bool) and 0 < pid < 2**31:
            connected = self.watch_pid(pid)
        else:
            connected = False
            self.clear_pid()
        if connected:
            profile = str(document.get('profile_name') or '')
            return {'text': '󰒘', 'class': 'active',
                    'tooltip': f'kvn VPN\n{profile}: включен\nЛКМ: выключить · ПКМ: выбрать'}
        return {'text': '󰒙', 'class': 'inactive',
                'tooltip': 'kvn VPN: выключен\nЛКМ: включить · ПКМ: выбрать'}

    def gammastep(self):
        result = subprocess.run(['systemctl', '--user', 'show', 'gammastep.service',
                                 '-p', 'ActiveState', '-p', 'MainPID'],
                                capture_output=True, text=True, check=True)
        properties = dict(line.split('=', 1) for line in result.stdout.splitlines() if '=' in line)
        state = properties.get('ActiveState', 'inactive')
        status = state
        if state == 'active':
            try:
                pid, old, period = self.files[0].read_text().split()
                if pid == properties.get('MainPID'):
                    labels = {'daytime': 'Daytime', 'night': 'Nighttime', 'transition': 'Transition'}
                    label = labels.get(period)
                    if label:
                        status = f'active ({label})'
            except (FileNotFoundError, ValueError):
                pass
        return {'alt': status, 'tooltip': f'Gammastep is {status}'}

    def refresh(self):
        self.pending = 0
        try:
            self.monitor_files()
            if self.kind == 'vpn':
                result = subprocess.run([str(SCRIPTS / 'vpn_status'), self.slot],
                                        check=True, capture_output=True, text=True)
                value = json.loads(result.stdout)
            elif self.kind == 'kvn':
                value = self.kvn()
            else:
                value = self.gammastep()
            if value is not None:
                self.emit(value)
        except (OSError, ValueError, GLib.Error, subprocess.CalledProcessError) as error:
            # Fail loudly so Waybar's restart-interval restores a broken subscription.
            print(f'{self.kind} status: {error}', file=sys.stderr, flush=True)
            self.loop.quit()
            self.failure = True
        return GLib.SOURCE_REMOVE

    def run(self):
        self.failure = False
        self.monitor_files()
        self.connect_bus()
        self.refresh()
        if not self.failure:
            for sig in (signal.SIGTERM, signal.SIGINT):
                GLibUnix.signal_add(GLib.PRIORITY_DEFAULT, sig, lambda: self.loop.quit() or GLib.SOURCE_REMOVE)
            self.loop.run()
        self.clear_pid()
        for monitor in self.monitors.values():
            monitor.cancel()
        if self.bus is not None:
            for sub in self.subscriptions:
                self.bus.signal_unsubscribe(sub)
        return int(self.failure)


def main():
    os.umask(0o077)
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('kind', choices=('vpn', 'kvn', 'gammastep'))
    parser.add_argument('slot', nargs='?', choices=('vpn1', 'vpn2'))
    parser.add_argument('--once', action='store_true')
    args = parser.parse_args()
    if args.kind == 'vpn' and args.slot is None:
        parser.error('vpn requires a slot')
    watcher = StatusWatcher(args.kind, args.slot)
    if args.once:
        watcher.failure = False
        watcher.refresh()
        watcher.clear_pid()
        return int(watcher.failure)
    return watcher.run()


if __name__ == '__main__':
    sys.exit(main())
