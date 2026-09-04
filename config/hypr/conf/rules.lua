hl.window_rule({
    name  = "suppress-maximize-events",
    match = { class = ".*" },
    suppress_event = "maximize",
})

hl.window_rule({
    name  = "fix-xwayland-drags",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },
    no_focus = true,
})

hl.window_rule({
    name   = "float-dialogs",
    match  = { title = "^(Open File|Save File|Open Folder|Choose Files|Select a File)(.*)$" },
    float  = true,
    size   = "900 600",
    center = true,
})

hl.window_rule({
    name  = "games-raw",
    match = { class = "^(steam_app_.*|cs2|gamescope|hl2_linux|.*\\.exe)$" },
    no_blur   = true,
    no_dim    = true,
    no_shadow = true,
    no_anim   = true,
})

hl.window_rule({
    name  = "pip-on-top",
    match = { title = "^(Picture-in-Picture)$" },
    float = true,
    pin   = true,
})

hl.window_rule({
    name  = "move-hyprland-run",
    match = { class = "hyprland-run" },
    move  = "20 monitor_h-120",
    float = true,
})

hl.workspace_rule({ workspace = "w[tv1]", gaps_out = 0, gaps_in = 0 })
hl.workspace_rule({ workspace = "f[1]",   gaps_out = 0, gaps_in = 0 })

hl.window_rule({
    name  = "no-gaps-wtv1",
    match = { float = false, workspace = "w[tv1]" },
    border_size = 0,
    rounding    = 0,
})

hl.window_rule({
    name  = "no-gaps-f1",
    match = { float = false, workspace = "f[1]" },
    border_size = 0,
    rounding    = 0,
})

hl.layer_rule({ name = "blur-bar",       match = { namespace = "^ashell$" },        blur = true, ignore_alpha = 0.2 })
hl.layer_rule({ name = "blur-notify",    match = { namespace = "^notifications$" }, blur = true, ignore_alpha = 0.3 })
hl.layer_rule({ name = "blur-launcher",  match = { namespace = "^hyprlauncher$" },  blur = true, ignore_alpha = 0.3 })
hl.layer_rule({ name = "blur-selection", match = { namespace = "^selection$" },     no_anim = true })
