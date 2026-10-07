# Dotfiles

Personal Linux desktop configuration for Niri and Hyprland, with Waybar, Rofi, swaync, hyprlock, ly, systemd user services, and shared shell scripts. Both compositors live on `main`; select the session at login, not by switching Git branches. GNU Stow manages the files, with generated files kept out of Git.

Both sessions share one launcher stack, one theme switcher, one volume path, one wallpaper path, and the same session services.

## Desktop

- **Compositors:** Niri in `cfg/*.kdl`, or Hyprland 0.55+ in `hyprland.lua`.
- **Bar:** Waybar selects the compositor's workspace config automatically, with shared VPN, Wakatime, audio, brightness, battery, language, and notification modules.
- **Popups:** Niri uses Quickshell panels; Hyprland keeps native menu, pavucontrol, and wlogout actions.
- **Launcher:** Rofi for apps, clipboard, wallpapers, and theme selection.
- **Locking:** hyprlock with PAM fingerprint support and password fallback.
- **Idle:** swayidle, calling `hyprlock` and the current compositor's monitor power actions.
- **Display manager:** ly on `tty1`.
- **Wallpaper:** `awww` for images and `mpvpaper` for videos.
- **Themes:** one preset system applies Waybar, Rofi, GTK/libadwaita, Qt/KDE, swaync, hyprlock, and wlogout together.

## Layout

```
.config/niri/          Niri session, outputs, input, rules, keybinds, autostart
.config/waybar/        Bar config, active theme layers, Wakatime/status scripts
.config/quickshell/   Native Wayland panels for audio, network, power,
                      display, media, and calendar.
.config/themes/        Unified theme presets and generator
.config/rofi/          Launcher, clipboard, wallpaper, and theme menus
.config/swaync/        Notification center config, CSS template, focus helper
.config/desktop/       Shared scripts for menu, volume, brightness, wallpaper
.config/dotfiles/      Shared helper library and machine-local profile example
.config/hypr/          Hyprland Lua session, app autostart, shared hyprlock config
.config/ly/            TTY display manager config and deploy helper
.config/systemd/user/  Session services started by dotfiles-session.target
.config/xkb/           Custom Russian shortcut-friendly XKB layout
etc/pam.d/hyprlock     PAM config for fingerprint unlock with password fallback
etc/systemd/system/     Root systemd units for hardware/session integration
etc/udev/rules.d/       Udev rules for power-source automation
scripts/               Package lists, setup helpers, doctor, PAM, SSH, DDC/CI
notes/                 Hardware and operational notes
```

## Install

Install packages first:

```sh
~/.dotfiles/scripts/setup
```

The package sets live in `scripts/packages.pacman` and `scripts/packages.aur`.

Stow the files:

```sh
cd ~/.dotfiles
stow --restow --target="$HOME" .
```

Apply privileged pieces when needed:

```sh
sudo ~/.dotfiles/scripts/setup-pam
sudo ~/.dotfiles/scripts/setup-power
sudo ~/.dotfiles/scripts/setup-ddcci
~/.dotfiles/scripts/setup-ssh-agent
~/.dotfiles/scripts/setup-home-dns
~/.dotfiles/scripts/setup-stt
```

Deploy ly config explicitly:

```sh
sudo ~/.config/ly/apply.sh
```

`scripts/setup` also creates editable repo-local files from every `*.example`
template when the matching file without `.example` does not already exist, then
stows them into `$HOME`.

After setup, edit optional per-machine overrides as needed:

```sh
$EDITOR ~/.dotfiles/.config/dotfiles/machine.conf
```

Configure home split DNS after setting the local NetworkManager connection name
in `machine.conf` if it is not `eth`:

```sh
~/.dotfiles/scripts/setup-home-dns
```

This routes `*.home` to the local OPNsense DNS while VPN default DNS (`~.`)
continues to handle public names. It also adds a persistent `10.69.0.0/16`
route through the local gateway so home VLANs bypass full-tunnel VPNs.

Validate a machine after install:

```sh
~/.dotfiles/scripts/doctor
```

Run repository-level tests without touching the real home directory:

```sh
~/.dotfiles/scripts/test
```

## Machine-Local Files

These files are intentionally ignored and should stay outside Git:

```text
~/.gitconfig.local
~/.ssh/config.local
~/.ssh/yubikeys.tsv
~/.config/dotfiles/machine.conf
~/.config/Code/User/settings.json
~/.zshrc.local
```

On a machine that already has local Git or SSH config, move it into the local override files before stowing:

```sh
mv ~/.gitconfig ~/.gitconfig.local
mv ~/.ssh/config ~/.ssh/config.local
cd ~/.dotfiles
stow --restow --target="$HOME" .
```

## Niri

Niri is configured as small, readable files:

```text
.config/niri/config.kdl
.config/niri/cfg/input.kdl
.config/niri/cfg/display.kdl
.config/niri/cfg/layout.kdl
.config/niri/cfg/environment.kdl
.config/niri/cfg/autostart.kdl
.config/niri/cfg/rules.kdl
.config/niri/cfg/keybinds.kdl
```

Useful commands:

```sh
niri validate -c ~/.config/niri/config.kdl
niri msg outputs
niri msg windows
niri msg action load-config-file
```

The laptop panel is fixed at `3072x1920@120.000` with VRR disabled for stable frame pacing. External DP output can keep VRR in `display.kdl`.

## Hyprland

The settings from the former `hypr` branch live in `.config/hypr/hyprland.lua` on `main`, without reverting current Niri settings, shared services, themes, or Herdr integration. The disabled hyprexpo experiment is not included.

Select **Hyprland (uwsm-managed)** in ly so `graphical-session.target` owns the session lifecycle. The startup hook imports the Wayland environment, finalizes UWSM, and starts the same `dotfiles-session.target`, Gammastep, and swaync as Niri.

```sh
Hyprland --verify-config --config ~/.config/hypr/hyprland.lua
hyprctl configerrors
hyprctl monitors
```

Waybar selects `.config/waybar/config.hyprland` when `XDG_CURRENT_DESKTOP` contains `Hyprland`; Niri keeps its existing generated/theme config. Hyprland workspace buttons use the Lua dispatch API. Language OSD, notification-source focus, power-menu layout restoration, and idle DPMS actions select the current compositor too.

The former branch's complete history is retained under the `archive/hypr` tag; `main` is the only working branch.

## Themes

Themes are flat presets in `.config/themes/*.conf`. Applying a theme generates runtime files for the rest of the desktop. Each preset has `theme_mode=dark` or `theme_mode=light`; this drives GTK/libadwaita `color-scheme`, shell exports, and portal-aware apps such as browsers.

```sh
~/.config/themes/theme-switch list
~/.config/themes/theme-switch current
~/.config/themes/theme-switch apply tokyo-night
~/.config/themes/theme-switch menu
```

Theme previews are captured on an empty Niri workspace with each preset's `bg` color applied as a solid wallpaper.

GTK3 uses the configured `gtk_theme` plus generated `gtk.css`. GTK4/libadwaita apps read the generated `gtk-4.0/gtk.css` and `org.gnome.desktop.interface color-scheme`. GTK surfaces get a subtle automatic tint by blending each theme's `bg`, `muted`, and `accent`; presets can override this with `gtk_surface`, `gtk_sidebar`, and `gtk_header`. Already-running GTK apps may need to be restarted manually to reload generated CSS. Qt apps are themed globally through `QT_QPA_PLATFORMTHEME=qt6ct`, generated `qt5ct`/`qt6ct` palettes, and a small `dotfiles.qss` for menus and popups. Dolphin is the exception: it is launched through `~/.local/bin/dolphin` with the KDE platform theme so it uses KDE's native dark palette instead of Qt stylesheet file-view hacks.

Toolkit styling expects `adw-gtk-theme`, `qt5ct`, `qt6ct`, and `breeze` to be installed. `adw-gtk-theme` provides the GTK theme presets use, `qt5ct`/`qt6ct` load generated Qt palettes, and `breeze` provides KDE/Qt styling for Dolphin.

| Theme | Preview |
| --- | --- |
| `amber-forge` | ![amber-forge](docs/theme-previews/amber-forge.png) |
| `blood-moon` | ![blood-moon](docs/theme-previews/blood-moon.png) |
| `catppuccin-mocha` | ![catppuccin-mocha](docs/theme-previews/catppuccin-mocha.png) |
| `cyberpunk` | ![cyberpunk](docs/theme-previews/cyberpunk.png) |
| `dracula` | ![dracula](docs/theme-previews/dracula.png) |
| `everforest` | ![everforest](docs/theme-previews/everforest.png) |
| `gruvbox-dark` | ![gruvbox-dark](docs/theme-previews/gruvbox-dark.png) |
| `kanagawa-thin` | ![kanagawa-thin](docs/theme-previews/kanagawa-thin.png) |
| `kanagawa-wave` | ![kanagawa-wave](docs/theme-previews/kanagawa-wave.png) |
| `matte-black` | ![matte-black](docs/theme-previews/matte-black.png) |
| `miasma` | ![miasma](docs/theme-previews/miasma.png) |
| `mono` | ![mono](docs/theme-previews/mono.png) |
| `nord-frost` | ![nord-frost](docs/theme-previews/nord-frost.png) |
| `one-dark` | ![one-dark](docs/theme-previews/one-dark.png) |
| `rose-pine` | ![rose-pine](docs/theme-previews/rose-pine.png) |
| `tokyo-night` | ![tokyo-night](docs/theme-previews/tokyo-night.png) |
| `vantablack` | ![vantablack](docs/theme-previews/vantablack.png) |
| `violet-dusk` | ![violet-dusk](docs/theme-previews/violet-dusk.png) |

Generated files are ignored by Git:

```text
~/.cache/waybar/theme.css
~/.config/rofi/theme.rasi
~/.config/rofi/wallpaper-theme.rasi
~/.config/rofi/clipboard-theme.rasi
~/.config/gtk-3.0/gtk.css
~/.config/gtk-4.0/gtk.css
~/.config/swaync/style.css
~/.config/hypr/hyprlock-theme.conf
~/.config/wlogout/style.css
~/.config/wob/wob.ini
~/.config/swayosd/style.css
~/.config/alacritty/theme.toml
~/.config/kdeglobals
~/.local/share/color-schemes/Dotfiles.colors
~/.config/Code/User/dotfiles-theme.generated.json
~/.config/qt5ct/colors/dotfiles.conf
~/.config/qt6ct/colors/dotfiles.conf
~/.config/qt5ct/qt5ct.conf
~/.config/qt6ct/qt6ct.conf
~/.config/qt6ct/dotfiles.qss
~/.config/ly/theme.ini
~/.config/shell/theme.sh
```

The Waybar wallpaper button is the main theme entrypoint:

- Left click: wallpaper picker.
- Right click: theme picker.
- Middle click: random wallpaper.

## Keyboard

The XKB layout is `us,dotfiles` with the `,ru_ctrl_shortcuts` variant. Russian typing stays normal, but common `Ctrl` and `Ctrl+Shift` shortcuts resolve to the matching Latin physical keys.

Both compositors use the same layouts:

- `Alt+Shift` switches layout at XKB level.
- `Mod+Space` calls `lang_indicator next`, which dispatches through Niri or Hyprland and refreshes Waybar.

The source files live in:

```text
.config/xkb/symbols/dotfiles
.config/xkb/rules/evdev.extras.xml
```

## Audio And Brightness

Volume and microphone controls go through one script:

```sh
~/.config/desktop/scripts/volume --get
~/.config/desktop/scripts/volume --inc
~/.config/desktop/scripts/volume --dec
~/.config/desktop/scripts/volume --toggle
~/.config/desktop/scripts/volume --toggle-mic
```

Brightness uses backlight first and DDC/CI fallback for external monitors:

```sh
~/.config/desktop/scripts/brightness --json
~/.config/desktop/scripts/brightness --inc
~/.config/desktop/scripts/brightness --dec
~/.config/desktop/scripts/brightness --cycle
```

The backlight path requires the `ddcci` DKMS module built for the running kernel and bound to the monitor's current I2C bus. `scripts/setup-ddcci` reads `DOTFILES_DDCCI_BUS` from `~/.config/dotfiles/machine.conf`; use `ddcutil detect --brief` if bus numbering changes. Without `/sys/class/backlight/ddcci*`, brightness falls back to `ddcutil`, which can take several seconds per VCP query. After a kernel update, verify `dkms status` includes `uname -r`. The installed ddcci 0.4.5 source needs `<linux/string.h>` and `strncpy(..., PAGE_SIZE)` replaced with `strscpy(...)` in its five attribute readers to build against Linux 7.2.

Both scripts write to `/tmp/niri.wob` for the on-screen value display.

## Wallpaper

The wallpaper picker supports images and videos:

```text
jpg jpeg png webp gif mp4 webm mkv
```

Relevant scripts:

```text
.config/desktop/scripts/wallpaper_switcher
.config/desktop/scripts/change_wallpaper
```

Video thumbnails are generated with `ffmpeg`. Video wallpapers use `mpvpaper`; image wallpapers use `awww`.
`DOTFILES_WALLPAPER_DIR` and `DOTFILES_MPV_HWDEC` can be overridden in `~/.config/dotfiles/machine.conf`; hardware decoding is disabled by default for stability on mixed-GPU Wayland sessions.

## Lock And Idle

`hyprlock` is the screen locker for both Niri and Hyprland.

Session services are grouped under `dotfiles-session.target`:

```text
waybar.service
wob.service
swayosd.service
swayidle.service
clipboard-history.service
herdr.service
wallpaper.service
stt-server.service
```

Both compositors import the Wayland environment before starting this target, Gammastep,
and swaync. The dotfiles session services are tied to `graphical-session.target`
and stop when the graphical session ends; Herdr remains persistent by design.

The Herdr user service is started from this target only after the compositor imports the Wayland environment. Its drop-in skips the earlier `default.target` start, which otherwise leaves Herdr-spawned agents without `WAYLAND_DISPLAY` and breaks image paste.

The update tray applet belongs to XDG autostart, not the shared service start
command. The local `~/.config/autostart/arch-update-tray.desktop` override waits
for `org.kde.StatusNotifierWatcher` before launching `arch-update --tray`.

Idle flow:

- `swayidle` starts from the shared session target.
- 5.5 minutes: monitors turn off through Niri power actions or Hyprland Lua DPMS dispatch; input turns them back on.
- 30 minutes: lock through `hyprlock`.
- Before sleep: lock through `hyprlock`.

Fingerprint unlock is enabled in `~/.config/hypr/hyprlock.conf` through `auth.fingerprint`. `/etc/pam.d/hyprlock` intentionally stays password-only so hyprlock does not run a second `pam_fprintd` flow in parallel with its built-in fingerprint auth. ly intentionally does not use fingerprint PAM because TTY display managers can hang or behave poorly with fingerprint prompts.

## Power

Power source changes are handled by `/etc/udev/rules.d/90-dotfiles-power-profile.rules`, which starts `dotfiles-power-profile.service`.

The service runs `/usr/local/libexec/dotfiles-power-profile`:

- On battery: `powerprofilesctl set power-saver`, PCIe ASPM `powersave`, Wi-Fi power saving on.
- On AC: `powerprofilesctl set balanced`, PCIe ASPM `default`, Wi-Fi power saving stays on.

Install the privileged pieces with:

```sh
sudo ~/.dotfiles/scripts/setup-power
```

Check the active state:

```sh
powerprofilesctl get
cat /sys/module/pcie_aspm/parameters/policy
iw dev wlan0 get power_save
```

## Notes

- `DEPENDENCIES.md` lists the package set and post-install commands.
- `notes/yubikey_pool.md` documents the dynamic YubiKey/SSH signing pool.
- `notes/thinkpad_setup_process.md` keeps hardware and migration notes.
- Niri and Hyprland are maintained together on `main`. Wofi, Swaylock, legacy Waybar styles, and unused Waybar modules remain removed.
- Machine-specific knobs live in `~/.config/dotfiles/machine.conf`; keep host quirks there instead of hardcoding them into shared scripts.
