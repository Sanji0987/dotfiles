local c = require("conf.colors")

hl.config({
    general = {
        gaps_in  = 1,
        gaps_out = 2,

        border_size = 1,

        col = {
            active_border   = "rgba(000000ff)",
            inactive_border = "rgba(000000ff)",
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
            border_active        = "rgba(" .. c.sand .. "ff)",
            border_inactive      = "rgba(000000ff)",
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
