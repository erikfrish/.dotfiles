# Dotfiles Dependencies

Packages required for these dotfiles to work. Arch Linux / CachyOS package names.

## Compositor

| Package | Purpose |
|---|---|
| `niri` | Scrollable-tiling Wayland compositor |

## Core Wayland

| Package | Purpose |
|---|---|
| `xwayland-satellite` | XWayland for Niri |
| `waybar` | Status bar |
| `polkit-kde-agent` | Authentication dialog (`/usr/lib/polkit-kde-authentication-agent-1`) |
| `xdg-desktop-portal-gtk` | File picker portal (Niri fallback) |
| `dbus-update-activation-environment` | DBus env sync (part of `dbus`) |

## Display Manager & Lock

| Package | Purpose |
|---|---|
| `ly` | TTY display manager |
| `hyprlock` | Screen locker |
| `swayidle` | Idle daemon for lock and monitor power management |

## App Launchers & Menus

| Package | Purpose |
|---|---|
| `rofi` | App launcher, clipboard menu, wallpaper picker |
| `rofi-emoji` | Emoji picker (rofi plugin) |
| `rofi-calc` | Calculator (rofi plugin) |
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
| `brightnessctl` | Screen brightness control (backlight + ddcci) |
| `ddcutil` | DDC/CI monitor control (fallback when no ddcci driver) |
| `ddcci-driver-linux-dkms` | Kernel driver for DDC/CI as `/sys/class/backlight/ddcci*` |
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
| `imagemagick` | Generate thumbnails for image clipboard entries |

## Screenshots

| Package | Purpose |
|---|---|
| `grim` | Screenshot capture |
| `slurp` | Area selection |

## Wallpaper

| Package | Purpose |
|---|---|
| `awww` | Wallpaper backend (`awww`, `awww-daemon`) |
| `mpvpaper` | Optional video wallpaper backend for `.mp4`, `.webm`, `.mkv` |
| `ffmpeg` | Generate video thumbnails for the wallpaper picker |

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
| `jq` | JSON parsing for desktop scripts |
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

## Install Everything (Arch/CachyOS)

```bash
sudo pacman -S --needed \
  niri xwayland-satellite waybar polkit-kde-agent \
  xdg-desktop-portal-gtk \
  ly hyprlock swayidle \
  rofi rofi-emoji rofi-calc wlogout \
  pipewire wireplumber pipewire-pulse pavucontrol \
  brightnessctl ddcutil wob swayosd \
  swaync libnotify \
  wl-clipboard cliphist wl-clip-persist imagemagick \
  grim slurp \
  awww ffmpeg \
  networkmanager nm-connection-editor network-manager-applet bluez blueman \
  fprintd libfprint fcitx5 \
  gammastep hyprpicker playerctl \
  zsh alacritty \
  jq gsimplecal btop paru curl \
  ttf-jetbrains-mono-nerd \
  xkeyboard-config xkbcli \
  code nautilus zen-browser forkgram-desktop

paru -S --needed arch-update-tray sshpass ddcci-driver-linux-dkms-git mpvpaper
```

## Post-Install Setup (requires sudo)

```bash
# DDC/CI backlight driver for external monitors
# Run: sudo ~/.dotfiles/scripts/setup-ddcci
#
# Or manually:
#   sudo modprobe ddcci ddcci-backlight
#   sudo sh -c 'echo ddcci 0x37 > /sys/bus/i2c/devices/i2c-10/new_device'
#   ls /sys/class/backlight/   # should show ddcciN

# SSH agent (user service)
# Run: ~/.dotfiles/scripts/setup-ssh-agent
#
# Or manually:
#   systemctl --user disable ssh-agent.socket
#   systemctl --user enable --now ssh-agent.service

# YubiKey pool
# Run: ~/.dotfiles/.local/bin/yubikey-pool-setup
