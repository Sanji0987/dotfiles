hl.monitor({
	output = "DP-1",
	mode = "1920x1080@179.98",
	position = "0x0",
	scale = "1",
})

-- hl.env("XCURSOR_SIZE", "20")
-- hl.env("HYPRCURSOR_SIZE", "20")
hl.env("HYPRCURSOR_THEME", "Capitaine Cursors")
hl.env("HYPRCURSOR_SIZE", "20")

hl.config({
	cursor = {
		inactive_timeout = 0,
		hide_on_key_press = false,
	},

	misc = {
		force_default_wallpaper = 0,
		disable_hyprland_logo = true,
		disable_splash_rendering = true,
		focus_on_activate = true,
	},
})
