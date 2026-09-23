local c = require("conf.colors")
-- edited by claude opus 5
-- the palette is a static module now; conf/omarchy.lua read it out of the
-- omarchy theme state, which no longer exists
local t = require("conf.palette")

-- edited by claude opus 5
-- white at low alpha instead of solid grey: the edge now picks up the
-- wallpaper behind it rather than sitting on top as a drawn line
--
-- edited by claude opus 5
-- borders made fainter: 35% -> 22% active, 10% -> 6% inactive
--
-- ── BORDERS ── border_size is already 1, which is the minimum — the only
-- thing below it is 0, i.e. no border at all. So "smaller" here can only mean
-- fainter, and these two alphas are the control: 38 = 22% opaque, 0f = 6%.
-- Raise the first if the focused window becomes hard to pick out; set
-- border_size = 0 below if you want none at all.
local border_active   = t.rgba(t.border_active,   "38")
local border_inactive = t.rgba(t.border_inactive, "0f")

hl.config({
    general = {
        -- edited by claude opus 5
        -- tightened: 6/12 -> 3/7, a more compact layout with less wallpaper
        --
        -- ── GAPS ── gaps_in is applied to EACH side, so 3 puts 6px between
        -- two windows; 7 to the screen edge keeps the outer margin marginally
        -- wider than the inner seam, which stops the tiling looking like it is
        -- falling off the display.
        --
        -- These interact with the shadow below: a shadow only has the gap to
        -- be seen in before the neighbouring window covers it, so shrinking
        -- gaps means shrinking shadow range too, or the seams turn to mud.
        gaps_in  = 3,
        gaps_out = 7,

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
        -- Sized for THIS layout, not for a floating WM. gaps_in is 3, so a
        -- shadow has only 6px between two windows to live in before the
        -- neighbour covers it; the reference desktop uses range 4 for exactly
        -- that reason. 9 is the compromise — enough that a floating window
        -- lifts off the tiled ones, tight enough not to smear every seam.
        --
        -- Range tracks gaps. Raise one and raise the other, or a wide shadow
        -- in a narrow gap just turns the seams to mud.
        shadow = {
            enabled      = true,
            -- edited by claude opus 5
            -- 14 -> 9, following the gaps down: at gaps_in 3 there is only 6px
            -- between windows for a shadow to live in
            range        = 9,
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
-- the look override now comes from the active theme, not a hardcoded name
--
-- Everything above is the base look. Each theme ships a look.lua that merges
-- over it: apple-stock/look.lua is deliberately empty (the values above ARE
-- that look), rainynight/look.lua carries rounding 14, 0.93/0.92 opacity,
-- indigo borders and its own blur.
--
-- dofile for the same reason as conf/palette.lua: require would cache it and
-- survive a theme switch.
dofile("/home/monke/dotfiles/config/themes/current/look.lua")
