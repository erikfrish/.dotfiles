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
| `stow` | Dotfile symlink management |
| `shellcheck` | Optional script lint used by `scripts/doctor` |

`scripts/test` runs portable checks in a temporary home: Bash syntax, Niri validation, Stow simulation, theme generation, and local override behavior.

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
| `amneziawg-dkms` | AmneziaWG kernel module (required for NM plugin) |
| `amneziawg-tools` | `awg`, `awg-quick` CLI utilities |
| `network-manager-amneziawg` | NM VPN plugin (built from [vovochka404/network-manager-amneziawg](https://github.com/vovochka404/network-manager-amneziawg)) |

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
| `libxkbcommon` | Provides `xkbcli` for custom layout validation |

The custom layout lives in `~/.config/xkb/symbols/dotfiles` and is activated by:
- **Niri**: `layout "us,dotfiles"` + `variant ",ru_ctrl_shortcuts"` + `xkb_options "grp:alt_shift_toggle"` in `cfg/input.kdl`

## Install Everything (Arch/CachyOS)

```bash
~/.dotfiles/scripts/setup
```

The concrete package lists are the source of truth:

```text
scripts/packages.pacman
scripts/packages.aur
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

# AmneziaWG (NM plugin)
# The NM plugin needs both the kernel module AND a correctly compiled service binary.
# Run: sudo modprobe amneziawg
#
# Build the NM plugin from source (must match host CPU ISA level):
#   cd ~/Developer/GitHub/network-manager-amneziawg
#   mkdir build && cd build
#   cmake .. -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_INSTALL_LIBDIR=lib \
#     -DCMAKE_C_FLAGS="-march=x86-64-v3" -DCMAKE_CXX_FLAGS="-march=x86-64-v3"
#   cmake --build . -j$(nproc)
#   sudo cmake --install .
#
# IMPORTANT: Building on a different host (e.g. compik.home with AVX-512) produces
# a binary requiring x86-64-v4. Intel Arrow Lake (Core Ultra 200H) dropped AVX-512
# and only supports x86-64-v3. The service will fail with:
#   "CPU ISA level is lower than required"
# Always build on the target host, or set -march=x86-64-v3 for portability.
#
# The AmneziaVPN GUI client works without the kernel module because it uses
# wireguard-go (userspace). The NM plugin cannot — it creates kernel interfaces
# via netlink and requires the amneziawg kernel module.
