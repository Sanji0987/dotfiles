-- The desktop palette, and the two helpers that shape it into Hyprland's
-- colour forms.
--
-- edited by claude opus 5
-- repalletted to the reference desktop's neutral scheme: near-black surfaces
-- carried by alpha rather than by hue, grey hairline borders, and one
-- saturated blue used only for selection
--
-- The look this desktop targets is deliberately colourless. Surfaces are black
-- at low opacity so the wallpaper supplies whatever colour there is, borders
-- are two greys apart (`707070` focused, `393939` not), and the only chroma is
-- the selection blue. That is why there is no second hue here: adding one
-- would fight the wallpaper instead of sitting on it.
--
-- The same values appear in config/waybar/style.css, config/rofi/spotlight.rasi,
-- config/mako/config and config/hypr/hyprlock.conf. Edit them together;
-- nothing keeps them in step.

local M = {
    accent     = "#0860f2",  -- selection only
    background = "#000000",  -- surfaces, always via alpha
    foreground = "#dedede",

    -- edited by claude opus 5
    -- borders carry alpha now, so they pick up the wallpaper instead of
    -- sitting on it as flat grey
    --
    -- These are used as WHITE AT LOW ALPHA (see conf/theme.lua), not as solid
    -- greys. Over a coloured gradient a solid #707070 edge reads as a drawn-on
    -- line; white at 35% picks up whatever is behind it, which is what makes a
    -- macOS window edge look like a highlight rather than a stroke.
    border_active   = "#ffffff",
    border_inactive = "#ffffff",
}

local function channels(hex)
    return tonumber(hex:sub(2, 3), 16),
           tonumber(hex:sub(4, 5), 16),
           tonumber(hex:sub(6, 7), 16)
end

-- Blend two "#rrggbb" strings. amount 0 = all of a, 1 = all of b.
--
-- edited by claude opus 5
-- no callers since the borders became flat greys; kept deliberately
--
-- Nothing calls this right now — conf/theme.lua derived its border shades with
-- it until those became two literal greys. It stays because deriving a shade
-- from the palette is the correct way to add one, and re-deriving this by hand
-- next time is worse than carrying twelve lines.
function M.mix(a, b, amount)
    local ar, ag, ab = channels(a)
    local br, bg, bb = channels(b)
    return string.format("#%02x%02x%02x",
        math.floor(ar + (br - ar) * amount + 0.5),
        math.floor(ag + (bg - ag) * amount + 0.5),
        math.floor(ab + (bb - ab) * amount + 0.5))
end

-- "#rrggbb" + "ff" -> "rgba(rrggbbff)", the form Hyprland wants.
function M.rgba(hex, alpha)
    return "rgba(" .. hex:sub(2) .. alpha .. ")"
end

return M
