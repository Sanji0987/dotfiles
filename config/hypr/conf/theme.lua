local c = require("conf.colors")
-- edited by claude opus 5
-- the palette is a static module now; conf/omarchy.lua read it out of the
-- omarchy theme state, which no longer exists
local t = require("conf.palette")

-- edited by claude opus 5
-- flat greys, not an accent gradient: the reference look carries focus with a
-- brightness step between two neutrals, so nothing competes with the wallpaper
local border_active   = t.rgba(t.border_active, "ff")
local border_inactive = t.rgba(t.border_inactive, "ff")

hl.config({
    general = {
        -- edited by claude opus 5
        -- 4/12 matches the reference look: a tight seam between windows and a
        -- wider margin to the screen edge, so the tiling reads as cards on a
        -- wallpaper rather than panes in a frame
        gaps_in  = 4,
        gaps_out = 12,

        -- edited by claude opus 5
        -- back to 1px. 2px was right when the border was near-black and needed
        -- the weight; against the 707070/393939 greys a hairline is enough and
        -- a thick edge looks drawn-on
        border_size = 1,

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

    -- edited by claude opus 5
    -- the whole decoration block is retuned to the reference look, which is
    -- quieter than what was here: nothing dims, nothing fades, and the only
    -- effect is a wide soft blur
    decoration = {
        rounding       = 10,
        rounding_power = 2,

        -- Windows are fully opaque. The reference desktop gets its depth from
        -- blur on the *shell* surfaces, not from see-through windows — and
        -- translucent app windows over a busy wallpaper is what made the old
        -- 0.93/0.92 look muddy rather than glassy.
        active_opacity     = 1.0,
        inactive_opacity   = 1.0,
        fullscreen_opacity = 1.0,

        -- Focus is carried by the border greys alone. Dimming on top of that
        -- reads as two competing signals for the same thing.
        dim_inactive = false,

        -- No shadow. At 1px borders and 10px rounding a drop shadow just
        -- muddies the gap between windows.
        shadow = {
            enabled = false,
        },

        -- A wide, soft, neutral blur. size 12 is the reference value: large
        -- enough that the wallpaper behind a panel becomes colour rather than
        -- shapes. Brightness and contrast sit at 1.0 — the previous 1.1/1.1
        -- lifted everything toward grey, and 0.72 before that crushed it.
        blur = {
            enabled            = true,
            size               = 12,
            passes             = 3,
            new_optimizations  = true,
            xray               = false,
            ignore_opacity     = true,
            noise              = 0.012,
            contrast           = 1.0,
            brightness         = 1.0,
            vibrancy           = 0.18,
            vibrancy_darkness  = 0.0,
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
-- rainynight kept as a switchable look rather than deleted, so going back is
-- uncommenting one line
--
-- Everything above is the active look: the neutral "glass" one. An override
-- file merges over it, so a look only has to state what it changes.
--
--   conf/themes/rainynight.lua   rounding 14, 0.93/0.92 opacity, indigo
--                                borders, a near-zero blur — the Catppuccin
--                                -derived look this desktop used before
--
-- To switch, uncomment the require below and run `hyprctl reload`. Note the
-- rest of the desktop does NOT follow: the bar, launcher, notifications, OSD
-- and terminal carry their own copies of the palette (see README.md), so a
-- full switch means changing those too.
--
-- require("conf.themes.rainynight")
