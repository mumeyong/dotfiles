-- Hyprland + Ambxst
-- Ambxst (https://axeni.de/ambxst) provides the bar, notch (dynamic island),
-- launcher, dashboard, notifications, wallpaper, lock screen, OSD and clipboard.
-- Ambxst settings: SUPER+SHIFT+C, or ~/.config/ambxst/
-- Previous Noctalia setup: ~/.config/hypr/hyprland.lua.pre-ambxst

local terminal = "kitty"
local file_manager = "thunar"
local ambxst = "ambxst "

----------------------------------------------------------------------
-- Environment
----------------------------------------------------------------------
hl.env("EDITOR", "nvim")
hl.env("VISUAL", "nvim")
hl.env("XCURSOR_THEME", "Bibata-Modern-Ice")
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_THEME", "Bibata-Modern-Ice")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("GDK_BACKEND", "wayland,x11,*")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
hl.env("QT_AUTO_SCREEN_SCALE_FACTOR", "1")
hl.env("CLUTTER_BACKEND", "wayland")
hl.env("MOZ_ENABLE_WAYLAND", "1")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")

----------------------------------------------------------------------
-- Monitors & workspaces
----------------------------------------------------------------------
hl.monitor({ output = "eDP-1", mode = "1920x1200@60", position = "1920x0", scale = "1" })
hl.monitor({ output = "HDMI-A-1", mode = "1920x1080@74.97", position = "0x0", scale = "1" })

for ws = 1, 10 do
  hl.workspace_rule({
    workspace = tostring(ws),
    monitor = ws <= 5 and "HDMI-A-1" or "eDP-1",
    default = (ws == 1 or ws == 6) or nil,
    persistent = true,
  })
end

----------------------------------------------------------------------
-- Autostart
----------------------------------------------------------------------
hl.on("hyprland.start", function()
  hl.exec_cmd("dbus-update-activation-environment --systemd --all")
  hl.exec_cmd("hyprctl setcursor Bibata-Modern-Ice 24")
  -- ambxst itself is started by its generated config (see end of file)
end)

----------------------------------------------------------------------
-- Look & feel
----------------------------------------------------------------------
hl.config({
  general = {
    layout = "dwindle",
    border_size = 1,
    gaps_in = 4,
    gaps_out = 6,
    resize_on_border = true,
    col = {
      active_border = "rgba(8db4ffff)",
      inactive_border = "rgba(5f6578ff)",
    },
  },
  decoration = {
    rounding = 10,
    active_opacity = 1.0,
    inactive_opacity = 0.95,
    fullscreen_opacity = 1.0,
    dim_inactive = true,
    dim_strength = 0.1,
    dim_special = 0.8,
    shadow = {
      enabled = true,
      range = 2,
      render_power = 1,
      color = "rgba(8db4ffff)",
      color_inactive = "rgba(5f6578ff)",
    },
    blur = {
      enabled = true,
      size = 6,
      passes = 2,
      new_optimizations = true,
      xray = false,
      ignore_opacity = true,
      special = true,
      popups = true,
    },
  },
  dwindle = {
    preserve_split = true,
    smart_resizing = true,
    special_scale_factor = 0.8,
  },
  input = {
    kb_layout = "us",
    kb_model = "pc105",
    repeat_rate = 50,
    repeat_delay = 300,
    numlock_by_default = true,
    follow_mouse = 1,
    float_switch_override_focus = false,
    touchpad = {
      disable_while_typing = true,
      natural_scroll = true,
      tap_to_click = true,
    },
  },
  misc = {
    force_default_wallpaper = 0,
    disable_hyprland_logo = true,
    disable_splash_rendering = true,
    vrr = 0,
    mouse_move_enables_dpms = true,
    focus_on_activate = false,
  },
  binds = {
    workspace_back_and_forth = true,
    allow_workspace_cycles = true,
  },
  xwayland = {
    force_zero_scaling = true,
  },
  cursor = {
    sync_gsettings_theme = true,
    enable_hyprcursor = true,
  },
  animations = {
    enabled = true,
  },
})

hl.curve("wind", { type = "bezier", points = { { 0.05, 0.9 }, { 0.1, 1.00 } } })
hl.curve("winOut", { type = "bezier", points = { { 0.3, 0.0 }, { 0, 1 } } })
hl.curve("linear", { type = "bezier", points = { { 0.0, 0.0 }, { 1.0, 1.0 } } })
hl.curve("slow", { type = "bezier", points = { { 0, 0.85 }, { 0.3, 1 } } })
hl.curve("overshot", { type = "bezier", points = { { 0.7, 0.6 }, { 0.1, 1.0 } } })
hl.curve("bounce", { type = "bezier", points = { { 1.0, 1.0 }, { 0.1, 0.85 } } })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 5, bezier = "slow", style = "popin" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 5, bezier = "winOut", style = "popin" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 5, bezier = "wind", style = "slide" })
hl.animation({ leaf = "border", enabled = true, speed = 10, bezier = "linear" })
hl.animation({ leaf = "fade", enabled = true, speed = 5, bezier = "overshot" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 5, bezier = "wind" })
hl.animation({ leaf = "windows", enabled = true, speed = 5, bezier = "bounce", style = "popin" })

-- 3-finger horizontal swipe switches workspace
pcall(hl.gesture, { fingers = 3, direction = "horizontal", action = "workspace" })

----------------------------------------------------------------------
-- Layer & window rules
----------------------------------------------------------------------
hl.layer_rule({
  name = "noctalia",
  match = { namespace = "^noctalia-(bar-.+|notification|dock|panel|attached-panel|osd|window-switcher)$" },
  no_anim = true,
  ignore_alpha = 0.5,
  blur = true,
  blur_popups = true,
})

hl.window_rule({
  name = "noctalia-settings",
  match = { class = "dev.noctalia.Noctalia" },
  float = true,
  size = { 1080, 920 },
})
hl.window_rule({
  name = "idle-inhibit-fullscreen",
  match = { fullscreen = true },
  idle_inhibit = "fullscreen",
})
hl.window_rule({
  name = "picture-in-picture",
  match = { title = "^[Pp]icture-in-[Pp]icture$" },
  float = true,
  pin = true,
  keep_aspect_ratio = true,
  move = "72% 7%",
  size = "(monitor_w*0.3) (monitor_h*0.3)",
})
hl.window_rule({
  name = "float-dialogs",
  match = { title = "^(Authentication Required|Save As|Open File|Open Files)$" },
  float = true,
  center = true,
})
hl.window_rule({
  name = "float-utilities",
  match = { class = "^(pavucontrol|org.pulseaudio.pavucontrol|nm-connection-editor|blueman-manager|qalculate-gtk|mpv|yad)$" },
  float = true,
  center = true,
})

----------------------------------------------------------------------
-- Keybinds
----------------------------------------------------------------------
local dsp = hl.dsp
local win = hl.dsp.window

-- Normalized "MODS|KEY" for every combo bound here, so Ambxst's generated
-- binds can skip keys we already use (see end of file).
local user_combos = {}

local function combo(keys)
  local parts = {}
  for p in keys:gmatch("[^+]+") do
    parts[#parts + 1] = p:match("^%s*(.-)%s*$"):upper()
  end
  local key = table.remove(parts)
  table.sort(parts)
  return table.concat(parts, "+") .. "|" .. key
end

local function bind(keys, action, desc, opts)
  opts = opts or {}
  opts.description = desc
  user_combos[combo(keys)] = true
  hl.bind(keys, action, opts)
end

local function sh(cmd)
  return dsp.exec_cmd(cmd)
end

local function ipc(cmd)
  return dsp.exec_cmd(ambxst .. cmd)
end

local held = { locked = true, repeating = true }
local locked = { locked = true }

-- Apps
bind("SUPER + Return", sh(terminal), "terminal")
bind("SUPER + E", sh(file_manager), "file manager")
bind("SUPER + B", sh('xdg-open "https://"'), "browser")

-- Ambxst (same keys as the old Noctalia setup)
bind("SUPER + D", ipc("run launcher"), "app launcher")
bind("SUPER + ALT + E", ipc("run emoji"), "emoji picker")
bind("SUPER + SHIFT + N", ipc("run dashboard"), "dashboard")
bind("SUPER + SHIFT + E", ipc("run dashboard-controls"), "quick controls")
bind("SUPER + W", ipc("run wallpapers"), "wallpaper picker")
bind("SUPER + ALT + V", ipc("run clipboard"), "clipboard history")
bind("CTRL + ALT + P", ipc("run powermenu"), "power menu")
bind("CTRL + ALT + L", ipc("lock"), "lock screen")
bind("CTRL + ALT + Delete", ipc("run powermenu"), "power menu")
bind("SUPER + CTRL + ALT + B", ipc("toggle bar"), "toggle bar")
bind("ALT + Tab", ipc("run overview"), "overview")
bind("SUPER + CTRL + S", ipc("run overview"), "overview")

-- Screenshots (Ambxst's screenshot tool lets you pick region/window/screen)
bind("SUPER + Print", ipc("run screenshot"), "screenshot")
bind("SUPER + SHIFT + Print", ipc("run screenshot"), "screenshot")
bind("ALT + SHIFT + S", ipc("run screenshot"), "screenshot")
bind("SUPER + SHIFT + S", ipc("run screenshot"), "screenshot")
bind("SUPER + F6", ipc("run screenshot"), "screenshot")
bind("SUPER + SHIFT + F6", ipc("run screenshot"), "screenshot")

-- Windows
bind("SUPER + Q", win.close(), "close window")
bind("SUPER + SHIFT + Q", win.kill(), "kill window")
bind("SUPER + F", win.fullscreen({ mode = "maximized" }), "maximize")
bind("SUPER + SHIFT + F", win.fullscreen({ mode = "fullscreen" }), "fullscreen")
bind("SUPER + SPACE", win.float({ action = "toggle" }), "toggle floating")
bind("SUPER + P", win.pseudo(), "pseudotile")
bind("SUPER + SHIFT + I", dsp.layout("togglesplit"), "toggle split")
bind("SUPER + G", dsp.group.toggle(), "toggle group")
bind("SUPER + mouse:272", win.drag(), "move window")
bind("SUPER + mouse:273", win.resize(), "resize window")

local directions = { left = "left", right = "right", up = "up", down = "down" }
local resize_steps = { left = { -50, 0 }, right = { 50, 0 }, up = { 0, -50 }, down = { 0, 50 } }
for key, dir in pairs(directions) do
  bind("SUPER + " .. key, dsp.focus({ direction = dir }), "focus " .. dir)
  bind("SUPER + CTRL + " .. key, win.move({ direction = dir }), "move window " .. dir)
  bind("SUPER + ALT + " .. key, win.swap({ direction = dir }), "swap window " .. dir)
  local step = resize_steps[key]
  bind("SUPER + SHIFT + " .. key, win.resize({ x = step[1], y = step[2], relative = true }), "resize " .. dir, { repeating = true })
end

-- Workspaces
local shifted = { "exclam", "at", "numbersign", "dollar", "percent", "asciicircum", "ampersand", "asterisk", "parenleft", "parenright" }
for ws = 1, 10 do
  local key = tostring(ws % 10)
  bind("SUPER + " .. key, dsp.focus({ workspace = ws }), "workspace " .. ws)
  bind("SUPER + SHIFT + " .. key, win.move({ workspace = ws }), "move to workspace " .. ws)
  bind("SUPER + SHIFT + " .. shifted[ws], win.move({ workspace = ws }), "move to workspace " .. ws)
  bind("SUPER + CTRL + " .. key, win.move({ workspace = ws, follow = false }), "move silently to workspace " .. ws)
end
bind("SUPER + Tab", dsp.focus({ workspace = "m+1" }), "next workspace")
bind("SUPER + SHIFT + Tab", dsp.focus({ workspace = "m-1" }), "previous workspace")
bind("SUPER + period", dsp.focus({ workspace = "e+1" }), "next workspace")
bind("SUPER + comma", dsp.focus({ workspace = "e-1" }), "previous workspace")
bind("SUPER + mouse_down", dsp.focus({ workspace = "e+1" }), "next workspace")
bind("SUPER + mouse_up", dsp.focus({ workspace = "e-1" }), "previous workspace")
bind("SUPER + SHIFT + bracketleft", win.move({ workspace = "-1" }), "move to previous workspace")
bind("SUPER + SHIFT + bracketright", win.move({ workspace = "+1" }), "move to next workspace")
bind("SUPER + U", dsp.workspace.toggle_special(), "toggle special workspace")
bind("SUPER + SHIFT + U", win.move({ workspace = "special" }), "move to special workspace")
bind("SUPER + CTRL + F9", dsp.exec_raw("movecurrentworkspacetomonitor l"), "workspace to left monitor")
bind("SUPER + CTRL + F10", dsp.exec_raw("movecurrentworkspacetomonitor r"), "workspace to right monitor")

-- Media & hardware keys
-- Volume, play/pause/next/prev/stop and screen brightness keys come from
-- Ambxst's generated binds (so its OSD shows). Extras it doesn't cover:
bind("ALT + XF86AudioRaiseVolume", sh("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 1%+"), "volume up precise", held)
bind("ALT + XF86AudioLowerVolume", sh("wpctl set-volume @DEFAULT_AUDIO_SINK@ 1%-"), "volume down precise", held)
bind("XF86AudioMicMute", sh("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), "toggle mic mute", locked)
bind("XF86AudioPause", sh("playerctl play-pause"), "play/pause", locked)
bind("CTRL + ALT + equal", ipc("brightness +5"), "brightness up", held)
bind("CTRL + ALT + minus", ipc("brightness -5"), "brightness down", held)
bind("XF86KbdBrightnessUp", sh("brightnessctl -d '*::kbd_backlight' set +10%"), "keyboard backlight up", held)
bind("XF86KbdBrightnessDown", sh("brightnessctl -d '*::kbd_backlight' set 10%-"), "keyboard backlight down", held)
bind("XF86Sleep", ipc("suspend"), "suspend", locked)

----------------------------------------------------------------------
-- Ambxst
----------------------------------------------------------------------
-- Ambxst regenerates this file whenever its settings change (theme colors,
-- gaps, borders, its own keybinds) and it also autostarts ambxst. Loaded
-- last so its theming applies; any key already bound above is skipped so
-- your binds always win.
local ambxst_config = loadfile(os.getenv("HOME") .. "/.local/share/ambxst/hyprland.lua")
if ambxst_config then
  local real_bind = hl.bind
  hl.bind = function(keys, ...)
    if user_combos[combo(keys)] then return end
    return real_bind(keys, ...)
  end
  local ok, err = pcall(ambxst_config)
  hl.bind = real_bind
  if not ok then print("ambxst config error: " .. tostring(err)) end
else
  -- Generated file missing (first run): still start the shell
  hl.on("hyprland.start", function() hl.exec_cmd("ambxst") end)
end
