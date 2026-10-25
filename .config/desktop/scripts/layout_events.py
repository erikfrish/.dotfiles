#!/usr/bin/env python3
"""Compositor events -> cached layout, layout OSD and Hyprlock refresh."""
import fcntl
import json
import os
from pathlib import Path
import selectors
import signal
import socket
import subprocess
import sys
import time


def short_layout(name):
    value = name.strip().lower()
    if 'russian' in value or value == 'ru':
        return 'ru'
    if 'english' in value or value == 'us':
        return 'en'
    return value[:2]


class NiriLayout:
    def __init__(self):
        self.names = []

    def feed(self, event):
        if 'KeyboardLayoutsChanged' in event:
            state = event['KeyboardLayoutsChanged']['keyboard_layouts']
            self.names = state['names']
            index = state['current_idx']
        elif 'KeyboardLayoutSwitched' in event:
            index = event['KeyboardLayoutSwitched']['idx']
        else:
            return None
        return self.names[index] if isinstance(index, int) and 0 <= index < len(self.names) else None


def hyprland_keyboard(devices):
    keyboards = devices.get('keyboards', [])
    return next((k for k in keyboards if k.get('main')), keyboards[0] if keyboards else {})


def command(*args):
    return subprocess.run(args, check=True, capture_output=True, text=True).stdout


def notify(*args):
    subprocess.run(args, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=False)


class LayoutWatcher:
    def __init__(self):
        self.runtime = Path(os.environ.get('XDG_RUNTIME_DIR', f'/tmp/desktop-{os.getuid()}'))
        self.directory = self.runtime / 'desktop-state'
        self.directory.mkdir(parents=True, exist_ok=True, mode=0o700)
        self.last = None
        self.niri = NiriLayout()
        self.hyprland = 'Hyprland' in os.environ.get('XDG_CURRENT_DESKTOP', '').split(':')
        self.keyboard = None
        self.running = True
        self.selector = selectors.DefaultSelector()
        self.source = None
        self.process = None
        self.buffer = b''
        self.caps = next(iter(Path('/sys/class/leds').glob('*::capslock/brightness')), None)
        self.caps_last = self.caps.read_text() if self.caps else None

    def publish(self, name):
        label = short_layout(name)
        if not label or label == self.last:
            return
        pending = self.directory / f'layout.{os.getpid()}'
        pending.write_text(label + '\n')
        pending.replace(self.directory / 'layout')
        notify('pkill', '-USR2', '-x', 'hyprlock')
        if self.last is not None:
            notify('swayosd-client', '--custom-message', label.upper())
        self.last = label

    def refresh_hyprland(self):
        keyboard = hyprland_keyboard(json.loads(command('hyprctl', '-j', 'devices')))
        self.keyboard = keyboard.get('name')
        if keyboard.get('active_keymap'):
            self.publish(keyboard['active_keymap'])

    def connect(self):
        self.buffer = b''
        if self.hyprland:
            signature = os.environ['HYPRLAND_INSTANCE_SIGNATURE']
            self.source = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
            # On failure the caller's disconnect() closes the partially opened source.
            self.source.connect(str(self.runtime / 'hypr' / signature / '.socket2.sock'))
            self.selector.register(self.source, selectors.EVENT_READ)
            # Subscribe before querying: changes during the snapshot remain queued.
            self.refresh_hyprland()
        else:
            self.process = subprocess.Popen(['niri', 'msg', '-j', 'event-stream'], stdout=subprocess.PIPE)
            self.source = self.process.stdout
            self.selector.register(self.source, selectors.EVENT_READ)
            # Niri's initial KeyboardLayoutsChanged event is the authoritative snapshot.

    def disconnect(self):
        if self.source is not None:
            try:
                self.selector.unregister(self.source)
            except KeyError:
                pass
            self.source.close()
            self.source = None
        if self.process is not None:
            self.process.terminate()
            try:
                self.process.wait(timeout=2)
            except subprocess.TimeoutExpired:
                self.process.kill()
                self.process.wait()
            self.process = None

    def consume(self, line):
        if self.hyprland:
            if line.startswith('activelayout>>'):
                keyboard, _, name = line[len('activelayout>>'):].partition(',')
                if keyboard == self.keyboard:
                    self.publish(name)
                else:
                    self.refresh_hyprland()
            elif line.startswith('configreloaded>>'):
                self.refresh_hyprland()
        else:
            name = self.niri.feed(json.loads(line))
            if name is not None:
                self.publish(name)

    def check_caps(self):
        if self.caps is None:
            return
        try:
            current = self.caps.read_text()
        except OSError:
            self.caps = next(iter(Path('/sys/class/leds').glob('*::capslock/brightness')), None)
            return
        if current != self.caps_last:
            self.caps_last = current
            notify('swayosd-client', '--caps-lock-led', self.caps.parent.name)

    def run(self):
        retry_at = 0
        try:
            while self.running:
                if self.source is None and time.monotonic() >= retry_at:
                    try:
                        self.connect()
                    except (OSError, KeyError, subprocess.CalledProcessError, ValueError) as error:
                        self.disconnect()
                        print(f'Layout event subscription: {error}', file=sys.stderr, flush=True)
                        retry_at = time.monotonic() + 2
                # Caps Lock sysfs does not reliably emit inotify events. Preserve the
                # existing 0.5s fallback, but without spawning a sleep process per tick.
                for key, _ in self.selector.select(timeout=0.5):
                    data = os.read(key.fd, 65536)
                    if not data:
                        self.disconnect()
                        retry_at = time.monotonic() + 2
                        break
                    self.buffer += data
                    while b'\n' in self.buffer:
                        line, self.buffer = self.buffer.split(b'\n', 1)
                        try:
                            self.consume(line.decode())
                        except (ValueError, KeyError, TypeError, subprocess.CalledProcessError) as error:
                            print(f'Layout event ignored: {error}', file=sys.stderr, flush=True)
                self.check_caps()
        finally:
            self.disconnect()
            self.selector.close()


def main():
    os.umask(0o077)
    watcher = LayoutWatcher()
    with (watcher.runtime / 'lang_switch_osd.lock').open('w') as lock:
        try:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            return
        for sig in (signal.SIGTERM, signal.SIGINT):
            signal.signal(sig, lambda *_: setattr(watcher, 'running', False))
        watcher.run()


if __name__ == '__main__':
    main()
