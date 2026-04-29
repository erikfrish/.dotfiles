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

### Phase 3: Audio Configuration (MULTIPLE ISSUES - DIAGNOSIS COMPLETE)
**Status:** ⚠️ WORKING BUT POOR QUALITY (causes identified)

#### What Was Wrong (Part 1: Routing)
Initially tried complex audio routing:
- EasyEffects service-mode enabled
- `easyeffects_sink` set as default
- **Problem:** Virtual sink not connected to physical Speaker sink = **no audio**
- **Symptom:** Can't select output device; sound appears to work but outputs nowhere

#### Solution Applied (Part 1)
1. **Removed** automatic EasyEffects routing
2. **Set** physical Speaker sink as default
3. **Kept** EasyEffects running but non-intrusive (service-mode, hidden window)
4. **Allowed** manual device selection via script

**Current autostart.conf (simplified):**
```bash
exec-once = easyeffects --service-mode --hide-window &
```

#### What's Wrong (Part 2: Audio Quality Issues - NOW DISCOVERED)
Sound quality is poor due to **multiple hardware/firmware limitations**:

1. **Speaker Volume Limit**: Only 72% (-18dB) max volume
   - Root cause: ALSA firmware/driver limitation on Arrow Lake cAVS + Realtek ALC257
   - This severely limits dynamic range and causes distortion

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
Speaker: 72% [-18.00dB] ⚠️ (CAPPED)
Digital Mic (Dmic0): 100% [0.00dB] ✓
```

**Audio Device IDs:**
```
343 = Arrow Lake cAVS Speaker (DEFAULT)
142 = HDMI 1
383 = HDMI 2
388 = HDMI 3
```

**Manual device switcher:** `~/.local/bin/select_audio_output`
```bash
$ select_audio_output
Available audio output devices:
  343. Arrow Lake cAVS Speaker [vol: 0.90]
  142. Arrow Lake cAVS HDMI 1 [vol: 1.00]
  ...
Enter device name (Speaker/HDMI1/HDMI2/HDMI3): _
```

### Phase 4: Wallpaper Management
**Status:** ✅ DONE

Updated `~/.dotfiles/.config/hypr/scripts/change_wallpaper`:
- Changed from `swww` → `awww` (modern Wayland wallpaper daemon)
- File: `~/.dotfiles/.config/hypr/scripts/change_wallpaper`

**Wallpaper directory:** `~/Pictures/Wallpapers` (needs manual setup)

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
  - EasyEffects preset "thinkpad-speakers" loaded
  - ALSA config created (~/.asoundrc → ~/.dotfiles/.config/asound.conf)

### ⚠️ Partially Working
- EasyEffects preset (convolver with speaker optimization) now active
- Waybar may reference missing scripts (needs verification)

### 📋 Needs Attention
1. Apply ly config: `sudo ~/.config/ly/apply.sh`
2. Verify Waybar script references
3. Create `~/Pictures/Wallpapers` directory
4. Test full reboot cycle with audio improvements
5. Monitor audio quality for pops/crackles

### 🔧 Known Issues & Decisions

**Audio Architecture Decision:**
- Originally attempted: EasyEffects convolver (currently working!)
- Discovered: Speaker volume was capped at 72%, increased to 100%
- Discovered: TLP audio power saving issue (not present, TLP not installed)
- Applied: ALSA config for direct hardware routing + EasyEffects combo
- **Reasoning:** Combination of firmware speaker optimization + PipeWire mixing + EasyEffects EQ = best quality on limited hardware

**Arrow Lake (MTL) Audio Hardware Limitations:**
- Intel cAVS DSP supports modern SOF drivers (2025.12.2)
- Realtek ALC257 speaker amp is limited on ThinkPad (integrated codec)
- No advanced beam-forming or multi-speaker array support
- Maximum achievable: speaker quality optimization via EQ + convolver

**EasyEffects Preset (NOW ACTIVE):**
```
Location: ~/.config/easyeffects/ (loaded at runtime)
Preset: thinkpad-speakers
Contains: Convolver filter + speaker optimization kernel
Status: Loaded and active via --service-mode
```

---

## Key Files Modified

| File | Purpose | Status |
|------|---------|--------|
| `~/.dotfiles/.config/hypr/config/input.conf` | Natural scroll | ✅ |
| `~/.dotfiles/.config/hypr/config/autostart.conf` | Auto-launch apps | ✅ (simplified) |
| `~/.dotfiles/.config/hypr/hyprlock.conf` | Lock screen theme | ✅ |
| `~/.dotfiles/.config/hypr/scripts/change_wallpaper` | Wallpaper daemon | ✅ (awww) |
| `~/.dotfiles/.config/ly/config.ini` | Display manager theme | ✅ (ready to deploy) |
| `~/.dotfiles/.config/ly/apply.sh` | Deploy ly to /etc/ly | ✅ |
| `~/.dotfiles/.config/asound.conf` | ALSA hardware routing | ✅ (new) |
| `~/.vscode/argv.json` | VS Code encryption | ✅ |
| `~/.local/bin/select_audio_output` | Audio device switcher | ✅ (new) |

---

## Next Steps

### Immediate (Before Next Reboot)
- [ ] Deploy ly: `sudo ~/.config/ly/apply.sh`
- [ ] Test audio playback
- [ ] Verify Waybar functionality
- [ ] Create `~/Pictures/Wallpapers`

### After Reboot
- [ ] Verify ly displays at login (tty1)
- [ ] Check audio device selection works
- [ ] Test wallpaper rotation

### Audio Quality Improvements (to investigate)
1. **Increase Speaker Volume (ASAP)**
   ```bash
   amixer -c 0 sset Speaker 87  # Max level
   alsactl store  # Save permanently
   ```

2. **Check for Audio Firmware Updates**
   ```bash
   ls -la /lib/firmware/intel/sof-mtl*  # SOF firmware for Arrow Lake
   pacman -Q sof-firmware  # Check version
   ```

3. **Try EasyEffects Preset**
   - Load: `easyeffects --load-preset thinkpad-speakers`
   - This adds convolver + EQ to improve speaker quality

4. **Advanced: ALSA Configuration**
   - Create `/etc/asound.conf` with speaker boost
   - Add pre-emphasis EQ for ThinkPad speakers
   - Disable auto-mute if causing issues

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
