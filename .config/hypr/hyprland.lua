-- Hyprland compositor config, ported from the Niri setup.
-- Target: Hyprland 0.55+ Lua config API.

local terminal = "alacritty"
local mod = "SUPER"
local hyprexpo_enabled = false
local hyprexpo_plugin = "/home/erikfrish/.local/share/hyprland/plugins/hyprexpo/hyprexpo.so"

local function bind(keys, dispatcher, flags)
    hl.bind(keys, dispatcher, flags or {})
end

local function exec(cmd)
    return hl.dsp.exec_cmd(cmd)
end

-- Environment -----------------------------------------------------------------

if hyprexpo_enabled then
    hl.plugin.load(hyprexpo_plugin)
end

hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")
hl.env("SSH_AUTH_SOCK", "/run/user/1000/ssh-agent.socket")
hl.env("SDL_VIDEODRIVER", "wayland,x11")
hl.env("GTK_THEME", "adw-gtk3-dark")
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
hl.env("XKB_DEFAULT_LAYOUT", "us,dotfiles")
hl.env("XKB_DEFAULT_VARIANT", ",ru_ctrl_shortcuts")
hl.env("XKB_DEFAULT_OPTIONS", "grp:alt_shift_toggle")
hl.env("EGL_PLATFORM", "wayland")

-- Outputs ---------------------------------------------------------------------

hl.monitor({ output = "eDP-1", mode = "3072x1920@120.000", position = "0x0", scale = 1.75 })
hl.monitor({ output = "DP-4", mode = "2560x1440@164.833", position = "0x0", scale = 1 })
hl.monitor({ output = "DP-3", mode = "2560x1440@164.833", position = "0x0", scale = 1 })
hl.monitor({ output = "HDMI-A-2", disabled = true })

-- Core options ----------------------------------------------------------------

hl.config({
    input = {
        kb_layout = "us,dotfiles",
        kb_variant = ",ru_ctrl_shortcuts",
        kb_options = "grp:alt_shift_toggle",
        numlock_by_default = true,
        follow_mouse = 0,
        touchpad = {
            natural_scroll = true,
            clickfinger_behavior = true,
        },
    },

    general = {
        gaps_in = 8,
        gaps_out = 8,
        border_size = 3,
        ["col.active_border"] = "rgb(cba6f7)",
        ["col.inactive_border"] = "rgb(6E6A86)",
        layout = "dwindle",
    },

    decoration = {
        rounding = 0,
        shadow = {
            enabled = true,
            range = 30,
            render_power = 3,
            color = "rgba(00000077)",
        },
    },

    misc = {
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
        focus_on_activate = true,
        vrr = 1,
    },

    render = {
        direct_scanout = true,
    },

})

-- Window rules ----------------------------------------------------------------

hl.window_rule({ match = { class = "^zen$" }, workspace = "1 silent" })
hl.window_rule({ match = { class = "^code$" }, workspace = "2 silent" })
hl.window_rule({ match = { class = "^(forkgram|tdesktop|Band)$" }, workspace = "3 silent" })

hl.window_rule({ match = { class = "^org\\.pulseaudio\\.pavucontrol$" }, float = true, size = { 800, 600 }, center = true })
hl.window_rule({ match = { class = "^blueman-manager$" }, float = true, size = { 800, 600 }, center = true })
hl.window_rule({ match = { class = "^nm-connection-editor$" }, float = true, size = { 800, 600 }, center = true })
hl.window_rule({ match = { class = "^rofi$" }, float = true, center = true })
hl.window_rule({
    match = { title = "(?i)(^|[^[:alnum:]_])(pip|picture[-[:space:]]*in[-[:space:]]*picture)([^[:alnum:]_]|$)" },
    float = true,
    pin = true,
    size = { 480, 270 },
})

-- Autostart -------------------------------------------------------------------

hl.on("hyprland.start", function()
    hl.exec_cmd("fcitx5 -d")
    hl.exec_cmd("nm-applet --indicator")
    hl.exec_cmd("blueman-applet")
    hl.exec_cmd("~/.config/desktop/scripts/fix-xkb-wayland")
    hl.exec_cmd("pgrep -f /usr/lib/polkit-kde-authentication-agent-1 >/dev/null || /usr/lib/polkit-kde-authentication-agent-1")
    hl.exec_cmd("dbus-update-activation-environment --systemd SSH_AUTH_SOCK XDG_RUNTIME_DIR WAYLAND_DISPLAY DISPLAY XDG_CURRENT_DESKTOP")
    hl.exec_cmd("systemctl --user daemon-reload; systemctl --user start gammastep.service swaync.service arch-update-tray.service dotfiles-session.target")
    hl.exec_cmd("~/.config/desktop/scripts/lang_switch_osd")
    hl.exec_cmd("~/.config/hypr/scripts/hyprland_autostart_apps")
end)

-- Keybindings -----------------------------------------------------------------

bind(mod .. " + SHIFT + SLASH", exec("hyprctl binds"), { description = "Show keybinds" })
bind(mod .. " + SPACE", exec("hyprctl switchxkblayout all next; ~/.config/desktop/scripts/lang_indicator next; pkill -RTMIN+1 waybar"))

bind(mod .. " + I", exec("code"), { description = "Open VSCode" })
bind(mod .. " + Z", exec("rofi -show window"), { description = "Open window switcher" })
if hyprexpo_enabled then
    bind(mod .. " + TAB", function()
        hl.plugin.hyprexpo.expo("toggle")
    end, { description = "Toggle workspace overview" })
else
    bind(mod .. " + TAB", exec("rofi -show window"), { description = "Open window switcher" })
end
bind(mod .. " + T", exec(terminal), { description = "Open terminal" })
bind(mod .. " + E", exec("nautilus"), { description = "Open files" })
bind(mod .. " + R", exec("~/.config/desktop/scripts/menu"), { description = "Open menu" })

bind(mod .. " + Q", hl.dsp.window.close())
bind(mod .. " + V", hl.dsp.window.float({ action = "toggle" }))
bind(mod .. " + SHIFT + V", hl.dsp.focus({ last = true }))
bind(mod .. " + F", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))
bind(mod .. " + CTRL + F", hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" }))
bind(mod .. " + BRACKETRIGHT", hl.dsp.group.toggle())
bind(mod .. " + BRACKETLEFT", hl.dsp.group.toggle())

bind(mod .. " + P", exec("hyprpicker -a"))
bind(mod .. " + W", exec("~/.config/themes/theme-switch menu"))
bind(mod .. " + B", exec("systemctl --user restart waybar.service || ~/.config/waybar/scripts/statusbar"))
bind(mod .. " + C", exec("~/.config/desktop/scripts/clipboard_history"))

bind("XF86AudioRaiseVolume", exec("~/.config/desktop/scripts/volume --inc"), { locked = true, repeating = true })
bind("XF86AudioLowerVolume", exec("~/.config/desktop/scripts/volume --dec"), { locked = true, repeating = true })
bind("XF86AudioMute", exec("~/.config/desktop/scripts/volume --toggle"), { locked = true })
bind("XF86AudioMicMute", exec("~/.config/desktop/scripts/volume --toggle-mic"), { locked = true })
bind("XF86MonBrightnessUp", exec("~/.config/desktop/scripts/brightness --inc"), { locked = true, repeating = true })
bind("XF86MonBrightnessDown", exec("~/.config/desktop/scripts/brightness --dec"), { locked = true, repeating = true })
bind("XF86AudioPlay", exec("playerctl play-pause"), { locked = true })
bind("XF86AudioPause", exec("playerctl play-pause"), { locked = true })
bind("XF86AudioNext", exec("playerctl next"), { locked = true })
bind("XF86AudioPrev", exec("playerctl previous"), { locked = true })

for _, key in ipairs({ "LEFT", "H" }) do
    bind(mod .. " + " .. key, hl.dsp.focus({ direction = "left" }))
    bind(mod .. " + CTRL + " .. key, hl.dsp.window.move({ direction = "left" }))
    bind(mod .. " + SHIFT + " .. key, hl.dsp.window.move({ direction = "left" }))
end

for _, key in ipairs({ "RIGHT", "L" }) do
    bind(mod .. " + " .. key, hl.dsp.focus({ direction = "right" }))
    bind(mod .. " + CTRL + " .. key, hl.dsp.window.move({ direction = "right" }))
    bind(mod .. " + SHIFT + " .. key, hl.dsp.window.move({ direction = "right" }))
end

for _, key in ipairs({ "UP", "K" }) do
    bind(mod .. " + " .. key, hl.dsp.focus({ workspace = "e-1" }))
    bind(mod .. " + CTRL + " .. key, hl.dsp.window.move({ workspace = "e-1", follow = true }))
    bind(mod .. " + SHIFT + " .. key, hl.dsp.window.move({ direction = "up" }))
end

for _, key in ipairs({ "DOWN", "J" }) do
    bind(mod .. " + " .. key, hl.dsp.focus({ workspace = "e+1" }))
    bind(mod .. " + CTRL + " .. key, hl.dsp.window.move({ workspace = "e+1", follow = true }))
    bind(mod .. " + SHIFT + " .. key, hl.dsp.window.move({ direction = "down" }))
end

bind(mod .. " + MINUS", hl.dsp.window.resize({ x = -80, y = 0, relative = true }), { repeating = true })
bind(mod .. " + EQUAL", hl.dsp.window.resize({ x = 80, y = 0, relative = true }), { repeating = true })
bind(mod .. " + SHIFT + MINUS", hl.dsp.window.resize({ x = 0, y = -80, relative = true }), { repeating = true })
bind(mod .. " + SHIFT + EQUAL", hl.dsp.window.resize({ x = 0, y = 80, relative = true }), { repeating = true })

for i = 1, 10 do
    local key = i == 10 and "0" or tostring(i)
    bind(mod .. " + " .. key, hl.dsp.focus({ workspace = i }))
    bind(mod .. " + CTRL + " .. key, hl.dsp.window.move({ workspace = i }))
    bind(mod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

bind(mod .. " + PERIOD", hl.dsp.focus({ workspace = "e+1" }))
bind(mod .. " + COMMA", hl.dsp.focus({ workspace = "e-1" }))
bind(mod .. " + mouse_down", exec("hyprctl dispatch 'hl.dsp.focus({ workspace = \"e+1\" })'"))
bind(mod .. " + mouse_up", exec("hyprctl dispatch 'hl.dsp.focus({ workspace = \"e-1\" })'"))
bind(mod .. " + SHIFT + mouse_down", hl.dsp.focus({ direction = "right" }))
bind(mod .. " + SHIFT + mouse_up", hl.dsp.focus({ direction = "left" }))
bind(mod .. " + CTRL + mouse_down", hl.dsp.window.move({ workspace = "e+1", follow = true }))
bind(mod .. " + CTRL + mouse_up", hl.dsp.window.move({ workspace = "e-1", follow = true }))

bind(mod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

bind("PRINT", exec("~/.config/desktop/scripts/screenshot"))
bind("SHIFT + PRINT", exec("~/.config/desktop/scripts/screenshot_save_full"))
bind("CTRL + PRINT", exec("~/.config/desktop/scripts/screenshot_save"))
bind("CTRL + SHIFT + PRINT", exec("~/.config/desktop/scripts/screenshot_full"))

bind(mod .. " + CTRL + M", hl.dsp.exit())
bind(mod .. " + SHIFT + M", exec("loginctl terminate-user ''"))
