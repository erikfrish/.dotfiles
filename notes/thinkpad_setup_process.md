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
- Volume keys and Waybar call `~/.config/hypr/scripts/volume`.
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
- `.config/hypr/scripts/volume`
- `.config/waybar/config`

Volume keybinds:

```ini
bindel = ,XF86AudioRaiseVolume, exec, ~/.config/hypr/scripts/volume --inc
bindel = ,XF86AudioLowerVolume, exec, ~/.config/hypr/scripts/volume --dec
bindel = ,XF86AudioMute, exec, ~/.config/hypr/scripts/volume --toggle
bind = , XF86AudioMicMute, exec, ~/.config/hypr/scripts/volume --toggle-mic
```

## VSCode

User-level VSCode config is tracked in the correct Stow path:

```text
.config/Code/User/settings.json
.config/Code/User/keybindings.json
```

There is no repository-local `.vscode/settings.json` for these shared settings.

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
