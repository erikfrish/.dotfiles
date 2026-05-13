# Desktop Setup Notes

These dotfiles are shared between `laptopchik` and `compik`. Keep common behavior in tracked files and machine-specific settings in local override files.

## Dotfiles Layout

- Main repo: `~/.dotfiles`
- Symlink manager: GNU Stow
- Apply configs: `cd ~/.dotfiles && stow .`

Machine-specific files are intentionally ignored:

```text
~/.gitconfig.local
~/.ssh/config.local
~/.ssh/yubikeys.tsv
```

Comment convention: shared configs should explain the reason for non-obvious settings, especially compatibility helpers, cross-compositor behavior, and machine-independent defaults. Avoid comments that only restate the option name.

## SSH And Git

Common config is tracked:

- `.gitconfig`
- `.ssh/config`
- `.ssh/scripts/current_yubikey`
- `.ssh/scripts/start_ssh_agent`
- `.local/bin/yubikey-pool-add`
- `.local/bin/yubikey-pool-setup`

Local user/company settings go into:

```text
~/.gitconfig.local
~/.ssh/config.local
```

The shared SSH config enables multiplexing:

```sshconfig
ControlMaster auto
ControlPath ~/.ssh/ssh-conn-%C
ControlPersist 30m
```

GitHub uses a longer persist window via common Git/SSH settings to avoid repeated YubiKey touches and VSCode askpass popups.

## Audio

Current audio approach is intentionally simple and portable:

- No EasyEffects autostart.
- No hardcoded `laptopchik` sink names.
- No `audio_output` profile switcher.
- Volume keys and Waybar call `~/.config/desktop/scripts/volume`.
- Primary backend is `wpctl`; fallback is `pactl`.

The volume script supports:

```sh
volume --get
volume --inc
volume --dec
volume --toggle
volume --toggle-mic
volume --mic-inc
volume --mic-dec
```

If the default sink is still `easyeffects_sink`, the script switches to the first real PipeWire sink before changing volume. This prevents old EasyEffects routing from breaking `compik`.

Waybar uses the `custom/audio-volume` module, backed by the same script.

## Hyprland

Relevant files:

- `.config/hypr/config/autostart.conf`
- `.config/hypr/config/keybinds.conf`
- `.config/desktop/scripts/volume`
- `.config/waybar/config`

Volume keybinds:

```ini
bindel = ,XF86AudioRaiseVolume, exec, ~/.config/desktop/scripts/volume --inc
bindel = ,XF86AudioLowerVolume, exec, ~/.config/desktop/scripts/volume --dec
bindel = ,XF86AudioMute, exec, ~/.config/desktop/scripts/volume --toggle
bind = , XF86AudioMicMute, exec, ~/.config/desktop/scripts/volume --toggle-mic
```

## Keyboard Layout

Russian layout uses a tracked user XKB symbols file:

```text
.config/xkb/symbols/dotfiles
```

Hyprland and Niri use `us,dotfiles` with the `,ru_ctrl_shortcuts` variant. Regular typing stays Russian, but `Ctrl`/`Ctrl+Shift` on Russian letters resolves to the matching Latin keysyms, so common application shortcuts keep working without switching to `us`.

Waybar power button launches:

```text
.config/desktop/scripts/power_menu
```

That wrapper temporarily switches to `us` before opening `wlogout` and restores the previous layout afterward, because `wlogout` single-letter hotkeys are not `Ctrl` shortcuts and are not covered by the XKB shortcut layer.

## Niri Autostart Apps

Niri app placement is handled by:

```text
.config/niri/scripts/niri_autostart_apps
```

Startup placement:

- Workspace 1: `zen-browser`.
- Workspace 2: `code`.
- Workspace 3: Band and Forkgram/Telegram.

The script moves windows by Niri window id after they appear and ensures Telegram is to the right of Band on the chat workspace.

## Shell

Preferred login shell is `zsh`. CachyOS zsh config enables Oh My Zsh correction internally, so the tracked `.zshrc` disables it again immediately after sourcing `/usr/share/cachyos-zsh-config/cachyos-config.zsh` with `unsetopt correct correct_all` and then unsets `ENABLE_CORRECTION`.

If the login shell is still different on a machine, change it locally:

```sh
chsh -s /bin/zsh
```

## VSCode

User-level VSCode config is tracked in the correct Stow path:

```text
.config/Code/User/settings.json
.config/Code/User/keybindings.json
```

There is no repository-local `.vscode/settings.json` for these shared settings.

## Terminal

Alacritty config is tracked at:

```text
.config/alacritty/alacritty.toml
```

Alacritty keeps only terminal-specific bindings. Russian-layout shortcut handling is intentionally centralized in the shared XKB layout instead of duplicated per app.

## Remote Machines

Do not sync files manually unless explicitly requested. Normal propagation path is Git:

```sh
git pull
stow .
```

Before applying on a machine with existing configs, preserve machine-specific files as local overrides:

```sh
mv ~/.gitconfig ~/.gitconfig.local
mv ~/.ssh/config ~/.ssh/config.local
cd ~/.dotfiles
stow .
```
