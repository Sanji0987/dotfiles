local c = require("conf.colors")
-- edited by claude opus 5
-- the palette is a static module now; conf/omarchy.lua read it out of the
-- omarchy theme state, which no longer exists
local t = require("conf.palette")

-- edited by claude opus 5
-- white at low alpha instead of solid grey: the edge now picks up the
-- wallpaper behind it rather than sitting on top as a drawn line
--
-- ── BORDERS ── 59 = 35% opaque, 1a = 10%. Raise the first if the focused
-- window is hard to pick out; the inactive one is meant to be near-invisible.
local border_active   = t.rgba(t.border_active,   "59")
local border_inactive = t.rgba(t.border_inactive, "1a")

hl.config({
    general = {
        -- edited by claude opus 5
        -- inner gap 4 -> 6 so the wallpaper actually shows between windows
        --
        -- ── GAPS ── gaps_in is applied to EACH side, so 6 puts 12px between
        -- two windows and matches the 12px to the screen edge: one consistent
        -- spacing everywhere. Raising gaps_in also gives the window shadows
        -- more room to be seen — the two settings are worth tuning together.
        gaps_in  = 6,
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

        -- edited by claude opus 5
        -- shadows on, and this is the one real change: depth was the piece
        -- actually missing
        --
        -- ── SHADOWS ── tweak these four numbers, nothing else matters here
        --
        -- Sized for THIS layout, not for a floating WM. gaps_in is 4, so a
        -- shadow only has 4px of gap to live in before the neighbouring window
        -- covers it; the reference desktop uses range 4 for exactly that
        -- reason. 14 is a deliberate compromise — wide enough that a floating
        -- window visibly lifts off the tiled ones underneath, tight enough
        -- that it does not turn every seam into a grey smear.
        --
        -- Go bigger only if you also raise gaps_in. A 30px shadow with a 4px
        -- gap is mud, which is what "large diffuse shadows" would have given.
        shadow = {
            enabled      = true,
            range        = 14,
            render_power = 3,
            -- Slight downward offset: light from above, the way every
            -- desktop that copies macOS does it.
            offset       = { 0, 4 },
            scale        = 0.97,
            -- Low-opacity black. Floating windows get the stronger one, which
            -- is what separates them from the tiled layer.
            color          = "rgba(0000006e)",
            color_inactive = "rgba(00000033)",
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
            -- edited by claude opus 5
            -- noise down, vibrancy up a touch: keeps colour in what is blurred
            -- behind a panel instead of letting it go flat grey
            noise              = 0.008,
            contrast           = 1.0,
            brightness         = 1.0,
            vibrancy           = 0.25,
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
