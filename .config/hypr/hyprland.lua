-- Hyprland + Noctalia
-- Noctalia (https://noctalia.dev) provides the bar, launcher, notifications,
-- wallpaper, lock screen, idle, OSD, clipboard and night light.
-- Noctalia settings: SUPER+SHIFT+N > settings, or ~/.config/noctalia/

local terminal = "kitty"
local file_manager = "thunar"
local noctalia = "noctalia msg "

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
  hl.exec_cmd("noctalia")
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

local function bind(keys, action, desc, opts)
  opts = opts or {}
  opts.description = desc
  hl.bind(keys, action, opts)
end

local function sh(cmd)
  return dsp.exec_cmd(cmd)
end

local function ipc(cmd)
  return dsp.exec_cmd(noctalia .. cmd)
end

local held = { locked = true, repeating = true }
local locked = { locked = true }

-- Apps
bind("SUPER + Return", sh(terminal), "terminal")
bind("SUPER + E", sh(file_manager), "file manager")
bind("SUPER + B", sh('xdg-open "https://"'), "browser")

-- Noctalia
bind("SUPER + D", ipc("panel-toggle launcher"), "app launcher")
bind("SUPER + ALT + E", ipc("panel-toggle launcher /emo"), "emoji picker")
bind("SUPER + SHIFT + N", ipc("panel-toggle control-center"), "control center")
bind("SUPER + SHIFT + E", ipc("panel-toggle control-center"), "control center")
bind("SUPER + W", ipc("panel-toggle wallpaper"), "wallpaper picker")
bind("CTRL + ALT + W", ipc("wallpaper-random"), "random wallpaper")
bind("SUPER + ALT + V", ipc("panel-toggle clipboard"), "clipboard history")
bind("CTRL + ALT + P", ipc("panel-toggle session"), "power menu")
bind("CTRL + ALT + L", ipc("session lock"), "lock screen")
bind("CTRL + ALT + Delete", ipc("session logout"), "exit Hyprland")
bind("CTRL + ALT + D", ipc("dock-toggle"), "toggle dock")
bind("SUPER + CTRL + ALT + B", ipc("bar-toggle"), "toggle bar")
bind("SUPER + N", ipc("nightlight-force-toggle"), "night light")
bind("ALT + Tab", ipc("window-switcher hold"), "window switcher")
bind("SUPER + CTRL + S", ipc("window-switcher"), "window switcher")

-- Screenshots
bind("SUPER + Print", ipc("screenshot-fullscreen"), "screenshot")
bind("SUPER + SHIFT + Print", ipc("screenshot-region"), "screenshot (area)")
bind("ALT + SHIFT + S", ipc("screenshot-region"), "screenshot (area)")
bind("SUPER + SHIFT + S", ipc("screenshot-annotate"), "screenshot (annotate)")
bind("SUPER + F6", ipc("screenshot-fullscreen"), "screenshot")
bind("SUPER + SHIFT + F6", ipc("screenshot-region"), "screenshot (area)")

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
bind("XF86AudioRaiseVolume", ipc("volume-up"), "volume up", held)
bind("XF86AudioLowerVolume", ipc("volume-down"), "volume down", held)
bind("ALT + XF86AudioRaiseVolume", ipc("volume-up 1"), "volume up precise", held)
bind("ALT + XF86AudioLowerVolume", ipc("volume-down 1"), "volume down precise", held)
bind("XF86AudioMute", ipc("volume-mute"), "toggle mute", locked)
bind("XF86AudioMicMute", ipc("mic-mute"), "toggle mic mute", locked)
bind("XF86AudioPlay", ipc("media toggle"), "play/pause", locked)
bind("XF86AudioPause", ipc("media toggle"), "play/pause", locked)
bind("XF86AudioNext", ipc("media next"), "next track", locked)
bind("XF86AudioPrev", ipc("media previous"), "previous track", locked)
bind("XF86AudioStop", ipc("media stop"), "stop", locked)
bind("XF86MonBrightnessUp", ipc("brightness-up"), "brightness up", held)
bind("XF86MonBrightnessDown", ipc("brightness-down"), "brightness down", held)
bind("CTRL + ALT + equal", ipc("brightness-up"), "brightness up", held)
bind("CTRL + ALT + minus", ipc("brightness-down"), "brightness down", held)
bind("XF86KbdBrightnessUp", ipc("keyboard-backlight-up"), "keyboard backlight up", held)
bind("XF86KbdBrightnessDown", ipc("keyboard-backlight-down"), "keyboard backlight down", held)
bind("XF86Sleep", ipc("session suspend"), "suspend", locked)
