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

-- edited by claude opus 5
-- a floating scratch terminal, launched on its own class so only it floats
--
-- ── FLOATING TERMINAL ── bound to SUPER + SHIFT + Return in conf/keybinds.lua
--
-- The bind runs `kitty --class kitty-float`, which is the same kitty with a
-- different app-id. Matching on that id rather than on "kitty" is what keeps
-- ordinary terminals tiled — a rule on the plain class would float every one.
--
-- Size is in PIXELS, not percentages. `size = "55% 60%"` is accepted by the
-- config without complaint and then silently ignored — hyprctl configerrors
-- stays clean and the window keeps its own size. Tested: the percent form
-- left kitty at 942x1024; the pixel form below applies exactly.
--
-- 1056x648 is 55% x 60% of this 1920x1080 display. On a different monitor,
-- recompute rather than reaching for percentages again.
hl.window_rule({
    name   = "float-terminal",
    match  = { class = "^kitty-float$" },
    float  = true,
    size   = "1056 648",
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

-- edited by claude opus 5
-- five persistent workspaces, so the overview always shows exactly five
--
-- Hyprland creates a workspace on demand and destroys it when its last window
-- closes, so without this the overview showed however many happened to exist —
-- one, most of the time. Persistent keeps 1-5 alive and empty, which is also
-- what waybar's persistent-workspaces already assumed.
for i = 1, 5 do
    hl.workspace_rule({ workspace = tostring(i), persistent = true })
end

hl.window_rule({
    name  = "no-gaps-f1",
    match = { float = false, workspace = "f[1]" },
    border_size = 0,
    rounding    = 0,
})

-- edited by claude opus 5
-- the shell's namespaces are gone; these are the real surfaces now, and they
-- finally get blur
--
-- Blur was deliberately off for the Quickshell layers, and the recorded reason
-- was sound: `omarchy-background` and `omarchy-notifications` were FULL-SCREEN
-- layers, so blurring them blurred the whole screen rather than the toast.
-- None of the replacements is full-screen except the wallpaper, which is
-- excluded, so that reason is gone with the shell.
--
-- ignore_alpha is the field 0.56 exposes; hyprlang's old `ignorezero` does not
-- exist here, and `ignore_zero` is rejected outright (which is how this was
-- found). Below 0.2 opacity a pixel is left unblurred, so the transparent
-- margins around a bar or a toast do not paint a blurred slab, while the
-- surface's own translucent background still frosts.
hl.layer_rule({
    name  = "blur-bar",
    match = { namespace = "waybar" },
    blur = true, ignore_alpha = 0.2,
    -- xray samples the wallpaper rather than the windows underneath, so the
    -- bar keeps one steady look instead of smearing whatever is beneath it.
    xray = true,
})

hl.layer_rule({
    name  = "blur-surfaces",
    match = { namespace = "^(rofi|notifications|swayosd)$" },
    blur = true, ignore_alpha = 0.2,
})

hl.layer_rule({ name = "blur-selection", match = { namespace = "^selection$" },     no_anim = true })
