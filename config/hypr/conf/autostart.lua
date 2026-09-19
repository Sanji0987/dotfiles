hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("QT_QPA_PLATFORMTHEME", "kde")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")
hl.env("MOZ_ENABLE_WAYLAND", "1")

hl.on("hyprland.start", function()
	-- edited by claude opus 5
	-- the single Quickshell process is replaced by four small daemons: it
	-- hosted the bar, notifications, OSD and wallpaper in one PID, so a crash
	-- or a qt6 bump took the whole desktop's UI with it
	hl.exec_cmd("waybar")          -- bar
	hl.exec_cmd("mako")            -- notifications
	hl.exec_cmd("swayosd-server")  -- volume/media OSD
	hl.exec_cmd("hyprpaper")       -- wallpaper
	hl.exec_cmd("gsr-ui launch-hide-announce")
	hl.exec_cmd("hyprctl setcursor Capitaine Cursors 20")
	hl.exec_cmd("hyprsunset")
	hl.exec_cmd("hypridle")
	hl.exec_cmd("wl-paste --watch cliphist store")
	hl.exec_cmd("wl-clip-persist --clipboard regular")
	hl.exec_cmd("dex -a")
	hl.exec_cmd("/usr/lib/polkit-kde-authentication-agent-1")
end)
