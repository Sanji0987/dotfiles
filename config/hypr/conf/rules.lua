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

-- edited by claude opus 5
-- smart gaps now apply to real fullscreen only; a single tiled window used to
-- lose its gaps and its border, which undid both on the commonest layout
hl.workspace_rule({ workspace = "f[1]", gaps_out = 0, gaps_in = 0 })

hl.window_rule({
    name  = "no-gaps-f1",
    match = { float = false, workspace = "f[1]" },
    border_size = 0,
    rounding    = 0,
})

-- edited by claude opus 5
-- all three blur rules named surfaces that no longer exist; replaced with the
-- Omarchy shell's real namespaces, which want animation rules and NOT blur
--
-- The old rules targeted `ashell` (replaced by the Quickshell bar),
-- `notifications` (mako, now uninstalled) and `hyprlauncher` (never used, the
-- launcher is `omarchy menu`). `hyprctl layers` showed none of them, so all
-- three had been dead for a while.
--
-- Deliberately no blur on the replacements. Upstream does not blur its own
-- layers either: the shell paints its surfaces from shell.toml, and both
-- `omarchy-background` and `omarchy-notifications` are FULL-SCREEN layers, so
-- a compositor blur would blur the entire screen rather than the toast.
hl.layer_rule({
    name  = "bar-instant",
    match = { namespace = "omarchy-bar" },
    no_anim = true, animation = "none",
})

hl.layer_rule({
    name  = "panels-instant",
    match = { namespace = "^(omarchy-menu|omarchy-image-selector|omarchy-emojis|omarchy-clipboard|omarchy-keyboard-panel)$" },
    no_anim = true, animation = "none",
})

hl.layer_rule({ name = "blur-selection", match = { namespace = "^selection$" },     no_anim = true })
