# Dotfiles Dependencies

Packages required for these dotfiles to work. Arch Linux / CachyOS package names.

## Compositors (pick one or both)

| Package | Purpose |
|---|---|
| `hyprland` | Wayland compositor |
| `niri` | Scrollable-tiling Wayland compositor |

## Core Wayland

| Package | Purpose |
|---|---|
| `xwayland-satellite` | XWayland for Niri |
| `waybar` | Status bar |
| `polkit-kde-agent` | Authentication dialog (`/usr/lib/polkit-kde-authentication-agent-1`) |
| `xdg-desktop-portal-hyprland` | Screen share / screenshot portal (Hyprland) |
| `xdg-desktop-portal-gtk` | File picker portal (Niri fallback) |
| `dbus-update-activation-environment` | DBus env sync (part of `dbus`) |

## Display Manager & Lock

| Package | Purpose |
|---|---|
| `ly` | TTY display manager |
| `hyprlock` | Screen locker |
| `hypridle` | Idle daemon (auto-lock, suspend) |

## App Launchers & Menus

| Package | Purpose |
|---|---|
| `wofi` | App launcher, clipboard menu, wallpaper picker |
| `wlogout` | Power menu |

## Audio

| Package | Purpose |
|---|---|
| `pipewire` | Audio server |
| `wireplumber` | PipeWire session manager |
| `pipewire-pulse` | PulseAudio compatibility |
| `pavucontrol` | Volume mixer (floating window rule) |
| `wpctl` | WirePlumber CLI (part of `wireplumber`) |
| `pactl` | PulseAudio CLI (part of `libpulse`) |

## Brightness & Volume OSD

| Package | Purpose |
|---|---|
| `brightnessctl` | Screen brightness control |
| `wob` | Volume/brightness overlay bar |
| `swayosd` | Layout/CapsLock/volume OSD |

## Notifications

| Package | Purpose |
|---|---|
| `swaync` | Notification center |
| `libnotify` | `notify-send` CLI |

## Clipboard

| Package | Purpose |
|---|---|
| `wl-clipboard` | `wl-copy`, `wl-paste` |
| `cliphist` | Clipboard history store |
| `wl-clip-persist` | Keep clipboard after source closes |

## Screenshots

| Package | Purpose |
|---|---|
| `grim` | Screenshot capture |
| `slurp` | Area selection |
| `grimblast` | Screenshot wrapper (part of `hyprland-contrib`) |

## Wallpaper

| Package | Purpose |
|---|---|
| `hyprpaper` | Wallpaper for Hyprland |
| `awww` | Wallpaper for Niri (`awww`, `awww-daemon`) |

## Bluetooth & Network

| Package | Purpose |
|---|---|
| `networkmanager` | Network management |
| `nm-connection-editor` | Network GUI |
| `nm-applet` | Network tray icon (part of `network-manager-applet`) |
| `bluez` | Bluetooth stack |
| `blueman` | Bluetooth GUI + tray applet |

## Input & Fingerprint

| Package | Purpose |
|---|---|
| `fprintd` | Fingerprint management |
| `libfprint` | Fingerprint driver library |
| `fcitx5` | Input method framework |

## Color & Display

| Package | Purpose |
|---|---|
| `gammastep` | Blue light filter |
| `hyprpicker` | Color picker |

## Media

| Package | Purpose |
|---|---|
| `playerctl` | Media key control (play/pause/next/prev) |

## Shell & Terminal

| Package | Purpose |
|---|---|
| `zsh` | Default shell |
| `alacritty` | Terminal emulator |

## Bar Modules Dependencies

| Package | Purpose |
|---|---|
| `jq` | JSON parsing (Niri/Hyprland IPC in scripts) |
| `socat` | Hyprland socket2 listener (layout OSD) |
| `gsimplecal` | Calendar popup |
| `btop` | System monitor |
| `paru` | AUR helper (update check module) |
| `curl` | Weather module |
| `arch-update-tray` | Arch update tray icon |

## Fonts

| Package | Purpose |
|---|---|
| `ttf-jetbrains-mono-nerd` | Bar/lock screen font (JetBrainsMono Nerd Font) |

## Apps (referenced in keybinds/autostart)

| Package | Purpose |
|---|---|
| `code` / `visual-studio-code-bin` | IDE (`Mod+I`) |
| `nautilus` | File manager (`Mod+E`) |
| `zen-browser` | Browser (autostart WS1) |
| `forkgram-desktop` | Telegram client (autostart WS3) |
| `band-desktop` (AppImage) | Work messenger (autostart WS3) |

## XKB Custom Layout

| Package | Purpose |
|---|---|
| `xkeyboard-config` | Base XKB data (provides `ru(winkeys)`, `EIGHT_LEVEL_BY_CTRL` type) |
| `xkbcli` | Validate custom layout (`xkbcli compile-keymap --test`) |

The custom layout lives in `~/.config/xkb/symbols/dotfiles` and is activated by:
- **Niri**: `layout "us,dotfiles"` + `variant ",ru_ctrl_shortcuts"` + `xkb_options "grp:alt_shift_toggle"` in `cfg/input.kdl`
- **Hyprland**: `kb_layout = us,dotfiles` + `kb_variant = ,ru_ctrl_shortcuts` + `kb_options = grp:win_space_toggle` in `config/input.conf`

## Install Everything (Arch/CachyOS)

```bash
sudo pacman -S --needed \
  hyprland niri xwayland-satellite waybar polkit-kde-agent \
  xdg-desktop-portal-hyprland xdg-desktop-portal-gtk \
  ly hyprlock hypridle \
  wofi wlogout \
  pipewire wireplumber pipewire-pulse pavucontrol \
  brightnessctl wob swayosd \
  swaync libnotify \
  wl-clipboard cliphist wl-clip-persist \
  grim slurp hyprland-contrib \
  hyprpaper awww \
  networkmanager nm-connection-editor network-manager-applet bluez blueman \
  fprintd libfprint fcitx5 \
  gammastep hyprpicker playerctl \
  zsh alacritty \
  jq socat gsimplecal btop paru curl \
  ttf-jetbrains-mono-nerd \
  xkeyboard-config xkbcli \
  code nautilus zen-browser forkgram-desktop

paru -S --needed arch-update-tray sshpass
```
