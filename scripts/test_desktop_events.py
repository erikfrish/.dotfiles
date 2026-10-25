#!/usr/bin/env python3
"""Protocol transitions and real file/process lifecycle regression checks."""
import ctypes
import ctypes.util
import json
import os
from pathlib import Path
import select
import subprocess
import sys
import tempfile
import unittest

SCRIPTS = Path(__file__).resolve().parents[1] / '.config/desktop/scripts'
sys.path.insert(0, str(SCRIPTS))
from layout_events import NiriLayout, hyprland_keyboard, short_layout


class LayoutTransitions(unittest.TestCase):
    def test_niri_snapshot_switch_and_reconfigured_names(self):
        state = NiriLayout()
        self.assertIsNone(state.feed({'KeyboardLayoutSwitched': {'idx': 1}}))
        self.assertEqual(state.feed({'KeyboardLayoutsChanged': {'keyboard_layouts': {
            'names': ['English (US)', 'Russian'], 'current_idx': 0}}}), 'English (US)')
        self.assertEqual(state.feed({'KeyboardLayoutSwitched': {'idx': 1}}), 'Russian')
        self.assertIsNone(state.feed({'WorkspaceActivated': {'id': 3}}))
        self.assertEqual(state.feed({'KeyboardLayoutsChanged': {'keyboard_layouts': {
            'names': ['German', 'English (US)'], 'current_idx': 0}}}), 'German')
        self.assertIsNone(state.feed({'KeyboardLayoutSwitched': {'idx': 5}}))
        self.assertEqual(short_layout('English (US)'), 'en')
        self.assertEqual(short_layout('Russian'), 'ru')

    def test_hyprland_uses_main_keyboard_not_first_device(self):
        selected = hyprland_keyboard({'keyboards': [
            {'name': 'virtual', 'active_keymap': 'English (US)'},
            {'name': 'physical', 'main': True, 'active_keymap': 'Russian'}]})
        self.assertEqual(selected['name'], 'physical')
        self.assertEqual(selected['active_keymap'], 'Russian')
        self.assertEqual(hyprland_keyboard({'keyboards': []}), {})

    def test_custom_xkb_group_is_resolvable_by_native_waybar_registry(self):
        def bind(library, name, result, *arguments):
            function = getattr(library, name)
            function.restype, function.argtypes = result, list(arguments)
            return function

        pointer, string = ctypes.c_void_p, ctypes.c_char_p
        xkb = ctypes.CDLL(ctypes.util.find_library('xkbcommon'))
        registry = ctypes.CDLL(ctypes.util.find_library('xkbregistry'))
        new_context = bind(xkb, 'xkb_context_new', pointer, ctypes.c_int)
        append = bind(xkb, 'xkb_context_include_path_append', ctypes.c_int, pointer, string)
        free_context = bind(xkb, 'xkb_context_unref', None, pointer)

        class Rules(ctypes.Structure):
            _fields_ = [(name, string) for name in ('rules', 'model', 'layout', 'variant', 'options')]

        new_keymap = bind(xkb, 'xkb_keymap_new_from_names', pointer, pointer, ctypes.POINTER(Rules), ctypes.c_int)
        group_name = bind(xkb, 'xkb_keymap_layout_get_name', string, pointer, ctypes.c_uint)
        free_keymap = bind(xkb, 'xkb_keymap_unref', None, pointer)
        new_registry = bind(registry, 'rxkb_context_new', pointer, ctypes.c_int)
        append_registry = bind(registry, 'rxkb_context_include_path_append', ctypes.c_bool, pointer, string)
        parse_registry = bind(registry, 'rxkb_context_parse_default_ruleset', ctypes.c_bool, pointer)
        first = bind(registry, 'rxkb_layout_first', pointer, pointer)
        next_layout = bind(registry, 'rxkb_layout_next', pointer, pointer)
        description = bind(registry, 'rxkb_layout_get_description', string, pointer)
        brief = bind(registry, 'rxkb_layout_get_brief', string, pointer)
        free_registry = bind(registry, 'rxkb_context_unref', None, pointer)
        include = os.fsencode(SCRIPTS.parents[1] / 'xkb')
        context = new_context(0)
        registered = new_registry(2)  # RXKB_CONTEXT_LOAD_EXOTIC_RULES
        keymap = None
        try:
            self.assertTrue(append(context, include))
            names = Rules(b'evdev', None, b'us,dotfiles', b',ru_ctrl_shortcuts', b'')
            keymap = new_keymap(context, ctypes.byref(names), 0)
            self.assertTrue(keymap)
            active_name = group_name(keymap, 1)
            self.assertTrue(append_registry(registered, include))
            self.assertTrue(parse_registry(registered))
            item = first(registered)
            visible = []
            while item:
                if description(item) == active_name:
                    visible.append(brief(item))
                item = next_layout(item)
            self.assertIn(b'ru', visible, 'Native Waybar would hide the custom Russian layout')
        finally:
            if keymap:
                free_keymap(keymap)
            free_context(context)
            free_registry(registered)


class KvnLifecycle(unittest.TestCase):
    def record(self, watcher, timeout=5):
        ready, _, _ = select.select([watcher.stdout], [], [], timeout)
        self.assertTrue(ready, 'No state event before deadline')
        line = watcher.stdout.readline()
        if not line:
            self.fail('Watcher exited: ' + watcher.stderr.read().decode())
        return json.loads(line)

    def stop(self, process):
        if process.poll() is None:
            process.terminate()
        try:
            process.communicate(timeout=3)
        except subprocess.TimeoutExpired:
            process.kill()
            process.communicate()

    def test_missing_directory_atomic_replacement_partial_write_and_process_death(self):
        with tempfile.TemporaryDirectory(prefix='dotfiles-events-') as directory:
            runtime = Path(directory)
            env = dict(os.environ, XDG_RUNTIME_DIR=directory, PYTHONDONTWRITEBYTECODE='1')
            watcher = subprocess.Popen([str(SCRIPTS / 'kvn_status'), '--watch'],
                                       env=env, stdout=subprocess.PIPE, stderr=subprocess.PIPE, bufsize=0)
            self.addCleanup(self.stop, watcher)
            self.assertEqual(self.record(watcher)['class'], 'inactive')
            child = subprocess.Popen(['sleep', '60'])
            self.addCleanup(self.stop, child)
            state = runtime / 'kvn/state.json'
            state.parent.mkdir()
            pending = state.with_suffix('.new')
            document = {'connected': True, 'profile_name': 'test profile', 'singbox_pid': child.pid}
            pending.write_text(json.dumps(document))
            pending.replace(state)
            first = self.record(watcher)
            self.assertEqual(first['class'], 'active')
            self.assertIn('test profile', first['tooltip'])
            state.write_text('{"connected":')
            self.assertFalse(select.select([watcher.stdout], [], [], 0.25)[0], 'Partial JSON changed the displayed state')
            document['profile_name'] = 'renamed profile'
            pending.write_text(json.dumps(document))
            pending.replace(state)
            self.assertIn('renamed profile', self.record(watcher)['tooltip'])
            # Do not reap yet: /proc/PID can remain present as a zombie. pidfd must
            # still report exit, rather than leaving a stale connected indicator.
            child.terminate()
            self.assertEqual(self.record(watcher)['class'], 'inactive')
            child.wait(timeout=3)
            state.unlink()
            self.assertFalse(select.select([watcher.stdout], [], [], 0.25)[0], 'Duplicate inactive event was emitted')
            watcher.terminate()
            watcher.communicate(timeout=3)
            self.assertEqual(watcher.returncode, 0)


if __name__ == '__main__':
    unittest.main()
