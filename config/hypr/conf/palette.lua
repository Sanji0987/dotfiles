-- The desktop palette, and the two helpers that shape it into Hyprland's
-- colour forms.
--
-- This replaces conf/omarchy.lua, which parsed these three values out of the
-- active Omarchy theme's colors.toml at config-load time so that a theme
-- switch recoloured the borders for free. That pipeline is gone: there is no
-- theme state to read, no slug to look up, and no reload hook behind it. The
-- values are rainynight's, written out where they can be seen and edited.
--
-- Change a colour here and the same one in config/mako/config,
-- config/hypr/hyprlock.conf and config/waybar/style.css — those four are the
-- whole palette surface now, and nothing keeps them in step but this comment.
--
-- The mix/rgba helpers are kept unchanged: they are plain colour arithmetic
-- and conf/theme.lua still derives its border shades with them.

local M = {
    accent     = "#89b4fa",
    background = "#1e1e2e",
    foreground = "#cdd6f4",
}

local function channels(hex)
    return tonumber(hex:sub(2, 3), 16),
           tonumber(hex:sub(4, 5), 16),
           tonumber(hex:sub(6, 7), 16)
end

-- Blend two "#rrggbb" strings. amount 0 = all of a, 1 = all of b.
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
