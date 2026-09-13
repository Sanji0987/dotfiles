local c = require("conf.colors")
-- edited by claude opus 5
-- window borders now follow the active Omarchy theme instead of the fixed palette
local t = require("conf.omarchy")

-- edited by claude opus 5
-- accent fading into the theme background: reads as a sheen on every theme,
-- including the monochrome ones, where a second hue would clash
local border_active = {
    colors = { t.accent, t.mix(t.accent, t.background, 0.62) },
    angle  = 45,
}

-- edited by claude opus 5
-- inactive is a flat, barely-there lift off the background rather than black
local border_inactive = t.rgba(t.mix(t.background, t.foreground, 0.14), "ff")

hl.config({
    general = {
        -- edited by claude opus 5
        -- gaps_in applies to each side, so 4 shows 8px between two windows and
        -- matches the 8px to the screen edge: one spacing everywhere
        gaps_in  = 4,
        gaps_out = 8,

        -- edited by claude opus 5
        -- 1px of pure black read as no border at all; 2px is visible, not chunky
        border_size = 2,

        col = {
            -- edited by claude opus 5
            -- theme-derived gradient and muted edge replace the hardcoded black
            active_border   = border_active,
            inactive_border = border_inactive,
        },

        resize_on_border        = true,
        extend_border_grab_area = 12,
        hover_icon_on_border    = true,

        allow_tearing = false,
        layout        = "dwindle",
    },

    decoration = {
        rounding       = 0,
        rounding_power = 2,

        active_opacity     = 1.0,
        inactive_opacity   = 0.94,
        fullscreen_opacity = 1.0,

        dim_inactive = true,
        dim_strength = 0.08,
        dim_special  = 0.3,

        shadow = {
            enabled        = true,
            range          = 12,
            render_power   = 3,
            offset         = { 0, 2 },
            scale          = 0.97,
            color          = "rgba(" .. c.black .. "b0)",
            color_inactive = "rgba(" .. c.black .. "60)",
        },

        blur = {
            enabled            = true,
            size               = 6,
            passes             = 3,
            new_optimizations  = true,
            xray               = false,
            ignore_opacity     = true,
            noise              = 0.008,
            contrast           = 0.95,
            brightness         = 0.72,
            vibrancy           = 0.18,
            vibrancy_darkness  = 0.2,
            popups             = true,
            popups_ignorealpha = 0.4,
        },
    },
})

hl.config({
    group = {
        col = {
            -- edited by claude opus 5
            -- grouped windows get the same themed edge, so the two agree
            border_active        = border_active,
            border_inactive      = border_inactive,
            border_locked_active = "rgba(" .. c.red .. "ff)",
        },
        groupbar = {
            enabled          = true,
            height           = 14,
            indicator_height = 2,
            font_size        = 9,
            gradients        = false,
            rounding         = 0,
            col = {
                active        = "rgba(" .. c.slate .. "ff)",
                inactive      = "rgba(" .. c.black .. "cc)",
                locked_active = "rgba(" .. c.red .. "cc)",
            },
            text_color = "rgba(" .. c.cream .. "ff)",
        },
    },
})

-- edited by claude opus 5
-- a theme may override the look in conf/themes/<slug>.lua, merging over
-- everything above; see conf/themes/rainynight.lua for why these live here
-- rather than being loaded out of the theme itself
if t.name then
    local override = package.searchpath("conf.themes." .. t.name, package.path)
    -- dofile, not pcall(require): a missing override is normal and silent,
    -- but a broken one should still fail loudly instead of being swallowed
    if override then dofile(override) end
end
