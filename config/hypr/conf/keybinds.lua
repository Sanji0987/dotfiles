local apps = require("conf.programs")
local mainMod = "SUPER"

hl.bind(mainMod .. " + return",    hl.dsp.exec_cmd(apps.terminal))
-- edited by claude opus 5
-- floating scratch terminal, to layer over tiled windows the way a macOS
-- window does. The --class is what the float rule in conf/rules.lua matches;
-- without it the rule would float every terminal.
hl.bind(mainMod .. " + SHIFT + return", hl.dsp.exec_cmd(apps.terminal .. " --class kitty-float"))
hl.bind(mainMod .. " + E",         hl.dsp.exec_cmd(apps.fileManager))
-- edited by claude opus 5
-- rofi toggles rather than stacking: pressing SUPER+Space with the launcher
-- already open closes it, which is what the Quickshell menu did
hl.bind(mainMod .. " + space",     hl.dsp.exec_cmd("pkill -x rofi || " .. apps.menu))
hl.bind(mainMod .. " + W",         hl.dsp.window.close())
hl.bind(mainMod .. " + F",         hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + P",         hl.dsp.window.pseudo())
hl.bind(mainMod .. " + J",         hl.dsp.layout("togglesplit"))
hl.bind(mainMod .. " + SHIFT + M", hl.dsp.exit())

hl.bind(mainMod .. " + SHIFT + L", hl.dsp.exec_cmd("pidof " .. apps.lock .. " || " .. apps.lock))

-- edited by claude opus 5
-- the three toggles ported from the gnome branch, on the same chords where
-- they were free, so one set of muscle memory covers both machines
--
--   SUPER+SHIFT+P   refresh rate, 60 <-> 180 Hz   (same chord as gnome)
--   SUPER+SHIFT+K   idle inhibit, a caffeine switch (same chord as gnome)
--   SUPER+SHIFT+A   animations on/off
--
-- The gnome branch puts animations on SUPER+SHIFT+M. That chord is taken here
-- by hl.dsp.exit(), which quits the session -- rebinding it to a cosmetic
-- toggle would silently remove the only way out. A is the divergence.
--
-- Each script also takes -s/--status, -q, -p and -h; see the headers in bin/.
hl.bind(mainMod .. " + SHIFT + P", hl.dsp.exec_cmd("toggle-refresh-rate"))
hl.bind(mainMod .. " + SHIFT + K", hl.dsp.exec_cmd("toggle-sleep"))
hl.bind(mainMod .. " + SHIFT + A", hl.dsp.exec_cmd("toggle-animations"))

-- edited by claude opus 5
-- theme picker; the menu itself is rofi, see bin/theme-menu --gtk for zenity
hl.bind(mainMod .. " + SHIFT + T", hl.dsp.exec_cmd("theme-menu"))

-- edited by claude opus 5
-- screenshots move to SUPER+SHIFT+S (region) and SUPER+SHIFT+PgUp (screen);
-- the old SUPER+SHIFT+P region bind is retired
--
-- Both write a timestamped PNG to ~/Pictures/Screenshots AND put it on the
-- clipboard, via tee, so it can be pasted straight away or found later.
local shot = "mkdir -p " .. apps.shotDir .. " && grim "
local shot_out = " - | tee " .. apps.shotDir .. "/$(date +%Y-%m-%d_%H-%M-%S).png | wl-copy"

hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd(shot .. "-g \"$(slurp)\"" .. shot_out))

-- Page_Up is `Prior` to xkbcommon, which is what Hyprland parses.
hl.bind(mainMod .. " + SHIFT + Prior", hl.dsp.exec_cmd(shot .. shot_out))
hl.bind("PRINT",                       hl.dsp.exec_cmd(shot .. shot_out))

-- edited by claude opus 5
-- hyprlauncher was never the launcher here, so this bind has been dead; rofi's
-- dmenu mode is the working equivalent
hl.bind(mainMod .. " + V", hl.dsp.exec_cmd(
    "cliphist list | rofi -dmenu -p Clipboard | cliphist decode | wl-copy"))

hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))

for i = 1, 10 do
    local key = i % 10
    hl.bind(mainMod .. " + " .. key,         hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- edited by claude opus 5
-- workspace overview on SUPER+G, the chord KDE uses for the same thing
--
-- Wrapped in a closure rather than passed directly, and that matters: the
-- plugin's dispatchers live at hl.plugin.hyprtasking.* and only exist once
-- hyprpm has loaded it, which happens in conf/autostart.lua — after this file
-- runs. Inside a function the lookup is deferred to keypress, so the bind
-- registers at config load whether or not the plugin is up yet, and starts
-- working the moment it is. Referencing it directly here would be nil at load.
--
-- "cursor" toggles the overview on the monitor under the pointer.
hl.bind(mainMod .. " + G", function() hl.plugin.hyprtasking.toggle("cursor") end)

hl.bind(mainMod .. " + S",         hl.dsp.workspace.toggle_special("magic"))
-- edited by claude opus 5
-- moved off SHIFT+S, which is the region screenshot now; SUPER+S is untouched
hl.bind(mainMod .. " + ALT + S",   hl.dsp.window.move({ workspace = "special:magic" }))

hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- edited by claude opus 5
-- swayosd-client replaces the raw wpctl calls: it makes the same change AND
-- draws the on-screen pill the Quickshell OSD used to, in one command
hl.bind("XF86AudioRaiseVolume",  hl.dsp.exec_cmd("swayosd-client --output-volume raise --max-volume 100"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume",  hl.dsp.exec_cmd("swayosd-client --output-volume lower"),                  { locked = true, repeating = true })
hl.bind("XF86AudioMute",         hl.dsp.exec_cmd("swayosd-client --output-volume mute-toggle"),            { locked = true, repeating = true })
hl.bind("XF86AudioMicMute",      hl.dsp.exec_cmd("swayosd-client --input-volume mute-toggle"),             { locked = true, repeating = true })

-- No /sys/class/backlight on this desktop; brightness goes over DDC/CI to the
-- OMEN 27 G2. ~1s per i2c round trip, so deliberately not `repeating`.
--
-- edited by claude opus 5
-- deliberately NOT swayosd-client --brightness: that path goes through
-- brightnessctl, which needs a backlight class this machine does not have.
-- ddcutil stays, and brightness simply has no OSD.
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("ddcutil --noverify setvcp 10 + 5"), { locked = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("ddcutil --noverify setvcp 10 - 5"), { locked = true })

-- edited by claude opus 5
-- routed through swayosd so media keys get the same pill as volume
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("swayosd-client --playerctl next"),       { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("swayosd-client --playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("swayosd-client --playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("swayosd-client --playerctl prev"),       { locked = true })
