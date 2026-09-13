-- Colours of the currently active Omarchy theme, read straight from its
-- colors.toml, returned as a module.
--
-- Why parse the TOML rather than load the theme's own hyprland.lua: six of the
-- installed themes ship one, and it is a hypr2lua dump of the *whole* look --
-- rounding, blur, opacity, animations, layer rules -- so loading it would
-- clobber conf/theme.lua wholesale instead of just recolouring the borders.
-- Themes without one get a generated file of a different shape again.
-- colors.toml is the only artefact every theme has, and it holds nothing but
-- colours.
--
-- Hyprland re-executes this config on `hyprctl reload`, which is exactly what
-- omarchy-restart-hyprctl does at the end of a theme change -- so the values
-- below follow the theme with no extra wiring.
--
-- Every lookup falls back, so a sparse or missing colors.toml still yields
-- usable values and the config never errors at load.

local M = {}

local STATE = os.getenv("HOME") .. "/.local/state/omarchy/current"
local THEME_COLORS = STATE .. "/theme/colors.toml"
-- edited by claude opus 5
-- theme.lua needs the theme's slug to pick a per-theme override file
local THEME_NAME = STATE .. "/theme.name"

-- Last-resort values, taken from conf/colors.lua so a failed read still looks
-- like this desktop rather than like nothing.
local fallback = {
    accent     = "#7b8493",
    background = "#060709",
    foreground = "#e7e6cf",
}

local colors = {}

do
    local handle = io.open(THEME_COLORS, "r")
    if handle then
        for line in handle:lines() do
            -- key = "#rrggbb"; anything else in the file is ignored
            local key, value = line:match('^%s*([%w_]+)%s*=%s*"(#%x%x%x%x%x%x)"')
            if key then colors[key] = value end
        end
        handle:close()
    end
end

-- edited by claude opus 5
-- the active theme's slug, e.g. "rainynight"; nil if the file is unreadable
do
    local handle = io.open(THEME_NAME, "r")
    if handle then
        local name = (handle:read("l") or ""):match("^%s*(.-)%s*$")
        handle:close()
        -- A slug, and it is about to be turned into a file path, so refuse
        -- anything that is not one rather than trusting the file's contents.
        if name:match("^[%w._-]+$") then M.name = name end
    end
end

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

-- M.accent, M.background, M.color4, ... straight off the theme, with fallback.
setmetatable(M, {
    __index = function(_, key)
        return colors[key] or fallback[key]
    end,
})

return M
