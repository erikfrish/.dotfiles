# Dotfiles

Personal Linux desktop configuration built around Niri, Waybar, Rofi, swaync, hyprlock, ly, and a small set of shell scripts. The repository is managed with GNU Stow and keeps generated files out of Git, so the checked-in files remain the source of truth.

The setup is intentionally boring in the places that should be reliable: one compositor, one launcher stack, one theme switcher, one volume path, one wallpaper path.

## Desktop

- **Compositor:** Niri, split into small `cfg/*.kdl` files.
- **Bar:** Waybar with Niri workspaces, VPN state, Wakatime, audio, brightness, battery, language, and notification state.
- **Launcher:** Rofi for apps, clipboard, wallpapers, and theme selection.
- **Notifications:** swaync with compact controls, MPRIS, and click-to-focus for source apps through Niri IPC.
- **Locking:** hyprlock with PAM fingerprint support and password fallback.
- **Idle:** swayidle, calling `hyprlock` and Niri monitor power actions.
- **Display manager:** ly on `tty1`.
- **Wallpaper:** `awww` for images and `mpvpaper` for videos.
- **Themes:** one preset system applies Waybar, Rofi, GTK, swaync, hyprlock, and wlogout together.

## Layout

```text
.config/niri/          Niri session, outputs, input, rules, keybinds, autostart
.config/waybar/        Bar config, active theme layers, Wakatime/status scripts
.config/themes/        Unified theme presets and generator
.config/rofi/          Launcher, clipboard, wallpaper, and theme menus
.config/swaync/        Notification center config, CSS template, focus helper
.config/desktop/       Shared scripts for menu, volume, brightness, wallpaper
.config/hypr/          hyprlock only; Hyprland compositor configs are removed
.config/ly/            TTY display manager config and deploy helper
.config/xkb/           Custom Russian shortcut-friendly XKB layout
etc/pam.d/hyprlock     PAM config for fingerprint unlock with password fallback
scripts/               Setup helpers for packages, PAM, SSH agent, DDC/CI
notes/                 Hardware and operational notes
```

## Install

Install packages first:

```sh
~/.dotfiles/scripts/setup
```

Stow the files:

```sh
cd ~/.dotfiles
stow --restow --target="$HOME" .
```

Apply privileged pieces when needed:

```sh
sudo ~/.dotfiles/scripts/setup-pam
sudo ~/.dotfiles/scripts/setup-ddcci
~/.dotfiles/scripts/setup-ssh-agent
```

Deploy ly config explicitly:

```sh
sudo ~/.config/ly/apply.sh
```

## Machine-Local Files

These files are intentionally ignored and should stay outside Git:

```text
~/.gitconfig.local
~/.ssh/config.local
~/.ssh/yubikeys.tsv
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

## Themes

Themes are flat presets in `.config/themes/*.conf`. Applying a theme generates runtime files for the rest of the desktop.

```sh
~/.config/themes/theme-switch list
~/.config/themes/theme-switch current
~/.config/themes/theme-switch apply tokyo-night
~/.config/themes/theme-switch menu
```

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
```

The Waybar wallpaper button is the main theme entrypoint:

- Left click: wallpaper picker.
- Right click: theme picker.
- Middle click: random wallpaper.

## Keyboard

The XKB layout is `us,dotfiles` with the `,ru_ctrl_shortcuts` variant. Russian typing stays normal, but common `Ctrl` and `Ctrl+Shift` shortcuts resolve to the matching Latin physical keys.

Niri uses both layers:

- `Alt+Shift` switches layout at XKB level for XWayland apps.
- `Mod+Space` calls Niri `switch-layout` for Wayland-native apps.

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

## Lock And Idle

`hyprlock` is kept only as the screen locker. The compositor is Niri.

Idle flow:

- `swayidle` starts from Niri autostart.
- 5.5 minutes: monitors turn off through `niri msg action power-off-monitors`.
- 30 minutes: lock through `hyprlock`.
- Before sleep: lock through `hyprlock`.

Fingerprint unlock is handled by `/etc/pam.d/hyprlock`. ly intentionally does not use fingerprint PAM because TTY display managers can hang or behave poorly with fingerprint prompts.

## Notes

- `DEPENDENCIES.md` lists the package set and post-install commands.
- `notes/yubikey_pool.md` documents the dynamic YubiKey/SSH signing pool.
- `notes/thinkpad_setup_process.md` keeps hardware and migration notes.
- Hyprland compositor configs, Wofi, Swaylock, legacy Waybar styles, and unused Waybar modules were removed to keep the tree focused on the active Niri desktop.
