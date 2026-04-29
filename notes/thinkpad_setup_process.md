# ThinkPad T14p Gen 3 Setup Process

**Date Started:** April 29, 2026  
**Machine:** ThinkPad T14p Gen 3 (Intel Arrow Lake cAVS, Realtek ALC257)  
**OS:** Arch/CachyOS  
**WM:** Hyprland (primary), Niri (configured but unused)

---

## System Overview

### Hardware
- **CPU:** Intel Arrow Lake  
- **Audio Codec:** Realtek ALC257  
- **Audio Driver:** sof-audio-pci-intel-mtl → sof-hda-dsp ALSA card  
- **Audio System:** PipeWire + WirePlumber  
- **Display:** Hyprland + Wayland

### Dotfiles Structure
- Located: `~/.dotfiles`
- Config symlinks: `~/.config → ~/.dotfiles/.config`
- All configs are version-controlled and sync automatically

---

## Setup History

### Phase 1: Base Configuration
**Status:** ✅ DONE

1. **Natural Scroll**: Fixed in `~/.dotfiles/.config/hypr/config/input.conf`
   ```ini
   natural_scroll = true
   ```

2. **Systemd Services Migration**: Moved from direct autostart to user services
   - `gammastep.service` (color temperature)
   - `swaync.service` (notification daemon)
   - `arch-update-tray.service` (system updates)

3. **Hyprlock Configuration**: Fixed broken config
   - Replaced missing theme paths with existing `mocha.conf`
   - Set screenshot as background
   - File: `~/.dotfiles/.config/hypr/hyprlock.conf`

4. **VS Code Weak Encryption Fix**: Added `password-store: gnome-libsecret`
   - File: `~/.vscode/argv.json`

5. **GNOME Keyring Reset**: Backed up old keyrings, created fresh login keyring
   - Backup: `~/.local/share/keyrings.bak`

### Phase 2: Display Manager (ly) Setup
**Status:** ✅ DONE

Created custom ly login screen configuration with Kanagawa Dragon theme:
- **File:** `~/.dotfiles/.config/ly/config.ini`
- **Animation:** colormix
- **Colors:**
  - Accent: `0x006A5FA8` (mauve-blue)
  - Foreground: `0x00FF1F2D` (ThinkPad red)
  - Background: `0x00181820` (dark)

Created deployment script: `~/.dotfiles/.config/ly/apply.sh`
- Requires sudo: `sudo ~/.config/ly/apply.sh`
- Deploys config to `/etc/ly`
- Creates backup before replacing

**Current Status:**
- `ly@tty1` enabled (inactive)
- `ly@tty2` enabled (active) — **will switch to tty1 after reboot**
- `sddm` disabled (will stop at next reboot)

### Phase 3: Audio Configuration
**Status:** ✅ WORKING, ENHANCED PROFILE AVAILABLE

#### What Was Wrong (Part 1: Routing)
Initially tried complex audio routing:
- EasyEffects service-mode enabled
- `easyeffects_sink` set as default
- **Problem:** Virtual sink not connected to physical Speaker sink = **no audio**
- **Symptom:** Can't select output device; sound appears to work but outputs nowhere

#### Solution Applied (Part 1)
1. **Set** physical Speaker sink as safe fallback
2. **Started** EasyEffects in service mode
3. **Loaded** `thinkpad-speakers` convolver preset
4. **Set** `easyeffects_sink` as default only after EasyEffects is available
5. **Added** a dynamic audio profile switcher; no more hardcoded PipeWire node IDs

**Current autostart.conf:**
```bash
exec-once = sh -c 'easyeffects --service-mode --hide-window & sleep 2; easyeffects --load-preset thinkpad-speakers >/dev/null 2>&1 || true; pactl set-default-sink easyeffects_sink 2>/dev/null || pactl set-default-sink alsa_output.pci-0000_00_1f.3-platform-skl_hda_dsp_generic.HiFi__Speaker__sink'
```

#### What's Wrong (Part 2: Audio Quality Issues - NOW DISCOVERED)
Sound quality is poor due to **multiple hardware/firmware limitations**:

1. **Speaker Volume Was Too Low**: Speaker mixer was 72% (-18dB)
   - Fixed with `amixer -c 0 sset Speaker 87`
   - Current state: 100% (0dB)

2. **Known ThinkPad T14P Issues** (from ArchWiki research):
   - TLP audio power saving causes pops/crackles if enabled (`SOUND_POWER_SAVE_ON_BAT=0` fixes it)
   - Current system: TLP not installed (good)
   - PipeWire/WirePlumber power management can cause audio dropouts
   - Speaker codec firmware may need tuning

3. **Realtek ALC257 Codec Limitations**:
   - Integrated codec with limited speaker amp capabilities
   - Pre-mixer analog set to 100% (OK)
   - Post-mixer DRC not available in current firmware
   - No advanced EQ or voice/speaker optimization channels

#### Current Audio Mixer State
```
Master: 100% [0.00dB] ✓
Pre-Mixer Analog: 100% [0.00dB] ✓
Speaker: 100% [0.00dB] ✓
Digital Mic (Dmic0): 100% [0.00dB] ✓
```

**Audio profile switcher:** `~/.local/bin/audio_output`
```bash
audio_output enhanced  # EasyEffects convolver -> Speaker
audio_output speaker   # Raw physical speakers
audio_output hdmi1
audio_output hdmi2
audio_output hdmi3
audio_output status
```

### Phase 4: Wallpaper Management
**Status:** ✅ DONE

Updated `~/.dotfiles/.config/hypr/scripts/change_wallpaper`:
- Changed from `swww` → `awww` (modern Wayland wallpaper daemon)
- File: `~/.dotfiles/.config/hypr/scripts/change_wallpaper`

**Wallpaper directory:** `~/Pictures/Wallpapers` (created)

---

## Current System State

### ✅ Working
- Natural scroll
- Hyprlock with correct theme
- VS Code password storage
- GNOME keyring
- Ly display manager (ready to deploy)
- Wallpaper switching (awww daemon)
- Audio playback to Speaker
- Audio device selection
- **Audio Quality IMPROVED:**
  - Speaker volume increased to 100% (max: 87/87)
  - EasyEffects preset `thinkpad-speakers` loaded
  - Confirmed PipeWire graph: app → `easyeffects_sink` → convolver → physical `Speaker`
  - Removed experimental `~/.asoundrc` direct-hardware override because it bypassed PipeWire and could break mixing
  - Fixed volume controls after EasyEffects: Hypr/Waybar volume script now uses `wpctl @DEFAULT_AUDIO_SINK@`

### ⚠️ Partially Working
- EasyEffects preset (convolver with speaker optimization) now active when `easyeffects_sink` is selected
- Waybar may reference missing scripts (needs verification)

### 📋 Needs Attention
1. Apply ly config: `sudo ~/.config/ly/apply.sh`
2. Verify Waybar script references
3. Add wallpapers to `~/Pictures/Wallpapers`
4. Test full reboot cycle with audio improvements
5. Monitor audio quality for pops/crackles

### 🔧 Known Issues & Decisions

**Audio Architecture Decision:**
- Originally attempted: EasyEffects convolver (currently working!)
- Discovered: Speaker volume was capped at 72%, increased to 100%
- Discovered: TLP audio power saving issue (not present, TLP not installed)
- Removed: ALSA config for direct hardware routing (`~/.asoundrc`) because it was risky and not needed under PipeWire
- Applied: EasyEffects convolver + PipeWire routing
- **Reasoning:** Keep PipeWire/WirePlumber in charge of device selection; use EasyEffects only as an optional/enhanced sink.

**Arrow Lake (MTL) Audio Hardware Limitations:**
- Intel cAVS DSP supports modern SOF drivers (2025.12.2)
- Realtek ALC257 speaker amp is limited on ThinkPad (integrated codec)
- No advanced beam-forming or multi-speaker array support
- Maximum achievable: speaker quality optimization via EQ + convolver

**EasyEffects Preset (NOW ACTIVE):**
```
Runtime config: ~/.config/easyeffects/db/easyeffectsrc
Preset: thinkpad-speakers
Contains: Convolver filter + speaker optimization kernel
Kernel: ~/.local/share/easyeffects/irs/T14S_G3_Music_Movies.irs
Status: Loaded via --service-mode; active when default sink is easyeffects_sink
```

---

## Key Files Modified

| File | Purpose | Status |
|------|---------|--------|
| `~/.dotfiles/.config/hypr/config/input.conf` | Natural scroll | ✅ |
| `~/.dotfiles/.config/hypr/config/autostart.conf` | Auto-launch apps | ✅ (simplified) |
| `~/.dotfiles/.config/hypr/scripts/volume` | Volume/mic controls via WirePlumber | ✅ |
| `~/.dotfiles/.config/waybar/config` | Waybar volume module follows EasyEffects sink | ✅ |
| `~/.dotfiles/.config/hypr/hyprlock.conf` | Lock screen theme | ✅ |
| `~/.dotfiles/.config/hypr/scripts/change_wallpaper` | Wallpaper daemon | ✅ (awww) |
| `~/.dotfiles/.config/ly/config.ini` | Display manager theme | ✅ (ready to deploy) |
| `~/.dotfiles/.config/ly/apply.sh` | Deploy ly to /etc/ly | ✅ |
| `~/.dotfiles/.local/bin/audio_output` | Dynamic audio profile switcher | ✅ |
| `~/.vscode/argv.json` | VS Code encryption | ✅ |
| `~/.local/bin/select_audio_output` | Symlink to `audio_output` | ✅ |

---

## Next Steps

### Immediate (Before Next Reboot)
- [ ] Deploy ly: `sudo ~/.config/ly/apply.sh`
- [ ] Test audio playback
- [ ] Verify Waybar functionality
- [x] Create `~/Pictures/Wallpapers`

### After Reboot
- [ ] Verify ly displays at login (tty1)
- [ ] Check audio device selection works
- [ ] Test wallpaper rotation

### Audio Quality Notes
1. **Speaker Volume**
   ```bash
   amixer -c 0 sset Speaker 87  # Max level, already applied
   ```

2. **Check for Audio Firmware Updates**
   ```bash
   ls -la /lib/firmware/intel/sof-mtl*  # SOF firmware for Arrow Lake
   pacman -Q sof-firmware  # Check version
   ```

3. **Use EasyEffects Preset**
   - Load enhanced profile: `audio_output enhanced`
   - Bypass processing: `audio_output speaker`
   - This adds the ThinkPad convolver to improve speaker quality

4. **Avoid ALSA Direct-Hardware Overrides**
   - Do not set `pcm.!default` to `hw:0,0` under PipeWire
   - It bypasses PipeWire mixing and can cause app/device selection problems

5. **Check Kernel Messages**
   ```bash
   sudo journalctl -f -k | grep -i "audio\|sof\|alc"
   ```

6. **Research Needed**
   - Arrow Lake (MTL) SOF driver maturity (2024-2025)
   - Realtek ALC257 speaker amp capabilities
   - WirePlumber routing optimization for ThinkPad hardware

---

## Troubleshooting

### No Sound Output
1. Check default sink: `pactl get-default-sink`
2. Check connected sinks: `wpctl status | grep -A 10 "Sinks:"`
3. Switch to Speaker: `wpctl set-default 343`
4. Test: `paplay /usr/share/sounds/freedesktop/stereo/complete.oga`

### Can't Select Audio Device
1. Ensure Speaker sink exists: `pactl list sinks short`
2. Use switcher: `~/.local/bin/select_audio_output`
3. Direct command: `wpctl set-default [device-id]`

### Hyprland Config Errors
1. Validate: `Hyprland --verify-config`
2. Check: `~/.dotfiles/.config/hypr/hyprland.conf`
3. Missing scripts: `ls -l ~/.config/hypr/scripts/`

---

## Audio Hardware Reference

**ALSA Card:** sof-hda-dsp  
**Card ID:** 0  
**Devices:**
- hw:sofhdadsp (Speaker, device 0)
- hw:sofhdadsp,3 (HDMI 1)
- hw:sofhdadsp,4 (HDMI 2)
- hw:sofhdadsp,5 (HDMI 3)
- hw:sofhdadsp,6 (Digital Mic)

**PipeWire Components:**
- Sink input: `easyeffects_source` (for EasyEffects input)
- Sink output: `easyeffects_sink` (for EasyEffects processing)
- Speaker output: `alsa_output.pci-0000_00_1f.3-platform-skl_hda_dsp_generic.HiFi__Speaker__sink`

---

**Last Updated:** April 29, 2026 (Audio routing fix)
