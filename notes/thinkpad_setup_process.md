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

## Niri

Relevant files:

- `.config/niri/cfg/autostart.kdl`
- `.config/niri/cfg/keybinds.kdl`
- `.config/desktop/scripts/volume`
- `.config/waybar/config`

Volume keybinds:

```kdl
XF86AudioRaiseVolume allow-when-locked=true { spawn-sh "~/.config/desktop/scripts/volume --inc"; }
XF86AudioLowerVolume allow-when-locked=true { spawn-sh "~/.config/desktop/scripts/volume --dec"; }
XF86AudioMute allow-when-locked=true { spawn-sh "~/.config/desktop/scripts/volume --toggle"; }
XF86AudioMicMute allow-when-locked=true { spawn-sh "~/.config/desktop/scripts/volume --toggle-mic"; }
```

### Laptop panel: VRR off for PSR

`eDP-1` (Tianma 3072x1920, 120 Hz) has no `variable-refresh-rate` in
`.config/niri/cfg/display.kdl`, and `vrr = 0` in `.config/hypr/hyprland.lua`.
Measured 2026-10-30 on battery: with VRR on, i915 reported `PSR mode: disabled`;
with VRR off it reported `PSR2 enabled`. Without PSR the panel needs continuous
scanout and the package rarely leaves PC2/PC6. Check with root:
`cat /sys/kernel/debug/dri/*/eDP-1/i915_psr_status`.

Other measured blockers of deep package C-states (PC8/PC10): an open browser
audio stream (even paused YouTube keeps the sink RUNNING), and many idle OMP
agents under Herdr (~2.8k wakeups/s from one 40-pane Herdr server).

## Keyboard Layout

Russian layout uses a tracked user XKB symbols file:

```text
.config/xkb/symbols/dotfiles
```

Niri uses `us,dotfiles` with the `,ru_ctrl_shortcuts` variant. Regular typing stays Russian, but `Ctrl`/`Ctrl+Shift` on Russian letters resolves to the matching Latin keysyms, so common application shortcuts keep working without switching to `us`.

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

On `laptopchik`, workspace 2 uses a full-width windowed Alacritty with Herdr instead
of VS Code. Keep this override in `~/.config/dotfiles/machine.conf`:

```sh
DOTFILES_IDE_CMD="alacritty --class herdr -o 'window.startup_mode=\"Windowed\"' -e zsh -lic 'exec herdr'"
DOTFILES_IDE_APP_ID=herdr
```

The laptop's Niri rule for app-id `herdr` sets `default-column-width` to
`proportion 1.0` and `open-fullscreen false`, keeping Waybar visible.

Herdr 0.9.5 is installed at `~/.local/bin/herdr` using the official user installer;
update it with `herdr update`. The laptop's `~/.config/autostart/autoclaw.desktop`
has `Hidden=true` and `X-GNOME-Autostart-enabled=false` to disable AutoClaw's
Electron launcher. This does not stop applications already running.

Laptop software refresh (2026-10-25): Bun 1.4.4 restores OMP 18.12.6;
OpenCode 2.0.32 lives in `~/.opencode/bin`, Claude Code 2.1.310 and GWS 0.22.5
are user installations. Prism CLI is installed with
`go install github.com/deLiseLINO/prism/cmd/prism@v0.1.0-rc.17` into `~/go/bin`;
`~/.local/bin/prism` links to it. The separate Prism GUI AppImage rc.17 uses
that Go daemon through `PRISMD_PATH`. Astra/Dia run local independent pools.
Shared MCP code is in `~/.agents/mcp`.

Nekobox was explicitly replaced with packaged sing-box and kvn. The kvn user
daemon is enabled but disconnected. Profiles and routing are synced from the PC.
AmneziaVPN was not toggled. STT now runs locally on port 8001; the existing `Super+D`
binding is unchanged and recording requires an unmuted microphone.

Only kvn 0.35.1 and the already-installed Happ 4.6.0 are retained as VLESS
clients. Throne, Hiddify, Prizrak Box, Koala Clash, v2rayN, and the newly
installed portable INCY were removed at the user's request. The update tray
already comes from `cachy-update`, not a separate `arch-update-tray` package.

The DDC/CI DKMS package builds on the installed LTS kernel 6.18.55, but fails
on kernel 7.3.0 because its source calls the removed `strncpy` kernel API.
`brightnessctl` works with the laptop's native `intel_backlight`; do not claim
the external-monitor DDC/CI module works on the current kernel.

Configuration sync (2026-10-25): kvn has 12 profiles and one subscription,
Cloudflare DoH, `ru`/`bypass_ru` geo routing with updates every seven days, and
the PC's geo rule sets. The laptop's hwid is preserved, auto-connect and kill
switch are disabled. Waybar's current theme was reapplied to refresh its cached
config; `custom/kvn` is visible and its profile selector lists all 12 profiles.

OMP config/models/roles/MCP and the Herdr extension match the PC, with required
key files and provider credentials imported through OMP's supported auth merge.
The synced default is `prism/astra-proxy/glm-5.3`; plan uses GPT-6.1 Sol, task
uses CoreLLM Coder, and smol uses Gemini 3.8 Flash. Histories stay machine-local.

`omp-pc-forwards.service` now forwards only laptop loopback 7070 to the PC's
llama.cpp endpoint (currently stopped). Prism runs locally on 10200 with
`daemon --register`; Astra/Dia own local 6447/8085. The forwarding identity
has no shell access, uses no SSH agent/YubiKey, and disables multiplexing.

Backups live in laptop `~/backup/sync-kvn-omp-20261025-041053/` (OMP) and
`~/backup/sync-kvn-omp-20261025-041137/` (kvn/Waybar). Browser extension pairing
is separate machine-local setup. MCP connection profiles were subsequently
copied opaquely; no database connections were exercised. `kvn doctor` still reports missing
passwordless Polkit authorization for resolved DNS changes; no extra root
prompt was requested during this sync.

An explicitly authorized opaque transfer copied 708 configuration/auth/hook/
skill files plus four helper configs from the PC, without inspecting their
contents. Destination backups are in `~/backup/opaque-config-sync-20261025-043021/`
and its `-helpers` sibling. All 708 initial files matched SHA-256 after transfer.
Claude, Codex, OpenCode, Pi, Hermes, CLI/MCP profiles, local shell, and SSH/Git
configs were included. Existing dotfiles symlinks were followed rather than
replaced. Editor settings, private SSH keys, known_hosts, runtime histories,
session databases, caches, and service/timer activation were excluded. The
dedicated laptop OMP forwarding key and service remain machine-local.

Google Workspace authentication was not verified: its PC config directory had
no portable credential files outside cache. Protected keyring state was not
copied. Custom PC services/timers were inventoried only, pending a separate
decision about duplicate background jobs.

Tern was removed on 2026-10-25 at the user's request: the PC's
`tern-remote.service` was stopped, disabled, and deleted, along with the
standalone binary, old binary, desktop launchers, icons, and active Tern data.
No Tern installation or service was found on the laptop. The PC's prior Tern
state is archived at `~/backup/tern-before-removal-20261025.tar.gz` (mode 600).
Shared SSH authorized keys, OMP, and Herdr were not removed.

Laptop service refresh: no alternate idle daemon was found. The missing
`~/.config/swayidle` link was restored to the dotfiles config, and swayidle was
enabled/started. It turns monitors off after 330 seconds, locks after 1800
seconds and before sleep, and does not automatically suspend.

`minimax-fleet-serve.service` and `minimax-fleet-register.service` are stopped
and disabled. Local Astra/Dia proxy and autoreg services are enabled with
independent laptop account/pool state, not cloned PC sessions. Astra thresholds
are min-alive 25/refill-to 50; Dia thresholds are 4/7 (half PC 9/15 rounded down).
Both listen only on loopback. First registration succeeded in each pool, and
Dia returned a real HTTP 200 streaming response through the new account.
Prism is local and configured with the local Astra/Dia client keys, so default
OMP routes use laptop pools. GUI readiness and a real OMP reply were exercised.

Installed proxy binaries are byte-identical to the PC, including running
`/proc/PID/exe` hashes. Astra proxy build records `f4e8b5b509e9` (modified
worktree); its watcher records `d08f5a68f501` (modified). The source workspace
is `master`, with uncommitted autoreg changes, so rebuilding just a branch
would not reproduce these installed artifacts. Dia proxy records
`3ccd2cb90ab8` (modified) and watcher `517692041c1d` (clean); the current source
workspace is `autoreg-native-signup`, a later squashed revision. Installed
artifacts, not branch names alone, are the source of truth for laptop parity.

CoreLLM model metadata was checked against its live catalog and requests:
`coder-medium` accepts images, so OMP/OpenCode both declare text/image input.
The `reviewer` output limit is 24576. With the current credentials,
`llm-medium-prod`, `llm-small-prod`, and `reviewer` returned 403
`model_access_denied`; updating model metadata does not grant access.

Faillock policy on both PC and laptop: `/etc/security/faillock.conf` uses
`deny = 5` and `unlock_time = 120`. The failure-count window remains the PAM
default of 900 seconds. No PAM module arguments override these settings.
The temporary faillock backups were removed at the user's request.
Policy verification did not generate failed login attempts or reset counters.

OMP/Herdr migration to laptop (2026-10-25): all 155 PC session journals,
their artifact trees, and image blobs were copied without deleting the four
existing laptop journals. PC layout was merged into one `from-pc` workspace in
the separate named Herdr session `from-pc`: 53 tabs, 54 panes, names prefixed
`home:`, `wb:`, `tal:`, `dot:`, `nm:`, `astra:`, and `dia:`. Manual tab names
were preserved; unnamed tabs use their session title or original tab number.

Launch/attach with `herdr --session from-pc`. Default laptop Herdr is untouched.
Native restore started 18 OMP processes. Thirty-two panes retain unavailable
cwd values (external disk plus Astra/Dia source directories); no substitute
directories were created. After those original paths are available, restarting
only the named session retries restore; first stop its agents if they are busy.
`home: workCal` referenced a journal already missing on the PC, so its empty
tab remains but the absent conversation could not be copied.

Migration backup: `~/backup/omp-herdr-from-pc-20261025-141426/` on laptop,
containing original PC layout, previous laptop layout, and any overwritten
files. Source sessions remain active on PC and were not marked moved: this is
a snapshot copy, not a final cutover. The ongoing migration conversation keeps
changing on PC and needs a final handoff before retiring that process. Avoid
continuing the same conversation on both machines; histories can diverge.
Visual verification was limited by the laptop's lock screen; saved topology,
named socket, restored process count, and transferred file hashes were checked.

Second session refresh: the latest active laptop conversation (battery power
optimization, id `01a17092-8b08-7570-a2b3-6b5bdeb42634`) was copied with artifacts
and blobs to the PC and opened in default Herdr, current workspace tab
`laptop: battery`. The laptop process was not stopped, so this is a snapshot
and the two copies must not be continued concurrently.

PC sessions were staged at laptop `~/backup/pc-session-refresh-20261025/`.
Identical files were retained, prefix-only updates applied with backups, and
divergent histories protected. OMP's official unpack imported the current PC
migration conversation as a fork (`01a173c8-80f3-77da-b140-0e6d65bf60a9`), and
updated one compatible old history. The active laptop battery session was not
overwritten: official unpack refused because a live OMP owns it; the PC
snapshot remains safely staged.

Third refresh (laptop had no live OMP): substantive journal deltas were
compared ignoring `session_exit`/title markers. PC-ahead histories (astra-proxy
main, dia-proxy, an old `/tmp` session, the battery session continued on PC,
and the migration conversation snapshot) were copied with artifacts and blobs;
prior laptop copies are in `~/backup/session-delta-20261025-225430/`.

Zen pinned tabs: profile on PC is `~/.zen/3jn0gaa8.Default (release)-1`, on
laptop `~/.config/zen/kcbz5qbn.Default (release)`. Pins live in
`zen-sessions.jsonlz4` (mozlz4). With laptop Zen stopped, PC pins and their
folders replaced laptop pins by `zenSyncId`, laptop-only pins and all unpinned
tabs were kept. Container ids differ between profiles (same names, different
numbers): existing pins keep laptop containers, new pins are mapped by
container name. Backup: laptop `~/backup/zen-pins-20261025-225911/`.

External SSD on laptop is LUKS2 (FIDO2 unlock) + btrfs, mounted manually at
`/mnt/extssd`; there is no fstab/crypttab entry. Sleep is
suspend-then-hibernate (6 h), USB persist is enabled for the RTL9210 bridge,
so the mapping and mount survive resume as long as the drive stays plugged.

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
