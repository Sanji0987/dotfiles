-- Rainy Night -- Hyprland border palette.
--
-- Loaded through conf/palette.lua, which is a shim pointing at whichever theme
-- config/themes/current resolves to. mix()/rgba() live here so a theme can be
-- swapped without touching conf/.

local M = {
    accent     = "#89b4fa",
    background = "#1e1e2e",
    foreground = "#cdd6f4",

    -- Used as WHITE AT LOW ALPHA by conf/theme.lua, not as solid colours.
    border_active   = "#6c7086",
    border_inactive = "#45475a",
}

local function channels(hex)
    return tonumber(hex:sub(2, 3), 16),
           tonumber(hex:sub(4, 5), 16),
           tonumber(hex:sub(6, 7), 16)
end

-- Blend two "#rrggbb" strings. amount 0 = all a, 1 = all b.
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
