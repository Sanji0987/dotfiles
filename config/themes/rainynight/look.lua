-- Rainy Night -- window geometry, merged over conf/theme.lua.
--
-- Moved here from conf/themes/rainynight.lua when themes became switchable;
-- the values are unchanged.
--
--
-- Ported by hand from the theme's own hyprland.conf (atif-1402/omarchy-rainynight-theme).
-- It has to be ported rather than loaded, for two reasons:
--
--   1. Omarchy refuses every .lua file a *cloned* theme ships
--      (omarchy-theme-set:142) because theme Lua would execute inside the
--      compositor. That refusal is correct, so the values live here instead,
--      in this repo, where they have been read.
--   2. The theme's own hyprland.lua is a hypr2lua dump of the whole look --
--      animations, layer rules, gaps, the lot. Loading it would replace
--      conf/theme.lua wholesale rather than recolour and reshape it.
--
-- Loaded by conf/theme.lua only while this theme is active, so it merges over
-- the base look and every other theme is untouched.

hl.config({
    general = {
        -- The theme's own border colours: muted indigo on near-black. This
        -- overrides the accent gradient from conf/palette.lua for this theme
        -- only -- delete this col block to get the gradient back here too.
        col = {
            active_border   = "rgb(303463)",
            inactive_border = "rgb(1a1b26)",
        },
    },

    decoration = {
        rounding = 14,

        active_opacity     = 0.93,
        inactive_opacity   = 0.92,
        fullscreen_opacity = 1.0,

        -- The theme carries focus with opacity alone. The base look also dims
        -- inactive windows, and the two together read far darker than the
        -- screenshots, so dimming is off while this theme is active.
        dim_inactive = false,

        shadow = {
            enabled      = false,
            range        = 15,
            render_power = 5,
            offset       = { 0, 0 },
        },

        -- A bright blur -- brightness and contrast above 1 -- which is what
        -- gives the translucent panels their lit, rained-on look. The base
        -- look darkens instead (brightness 0.72).
        -- edited by claude opus 5
        -- size 1 -> 10: the original value predates the layer blur this
        -- desktop now depends on
        --
        -- size 1 is a one-pixel kernel -- effectively no blur at all, with the
        -- four passes grinding over nothing. That was survivable when this
        -- theme was vendored, because nothing was blurred then. Now the bar,
        -- the launcher, notifications and the OSD are all blurred layers, and
        -- at size 1 every one of them renders flat. 10 is a touch below the
        -- base look's 12, which keeps this theme's softer feel without
        -- throwing the glass away.
        --
        -- The rest of the block is untouched: the bright blur (contrast and
        -- brightness above 1) is this theme's signature and is why it reads
        -- lit rather than darkened.
        blur = {
            enabled           = true,
            size              = 10,
            passes            = 3,
            contrast          = 1.1,
            brightness        = 1.1,
            vibrancy          = 0.2,
            vibrancy_darkness = 0.2,
            noise             = 0.03,
            ignore_opacity    = true,
            new_optimizations = true,
        },
    },
})
