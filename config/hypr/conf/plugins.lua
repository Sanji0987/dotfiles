-- Out-of-tree Hyprland plugins.
--
-- Installed with hyprpm, which builds them against the compositor's headers
-- and keeps them in /var/cache/hyprpm. They are NOT loaded by this file —
-- conf/autostart.lua runs `hyprpm reload` at session start, and hyprpm decides
-- what is enabled. This file only configures them.
--
--   hyprpm list            what is installed and enabled
--   hyprpm update -f       rebuild after a Hyprland upgrade (see the note
--                          below, it is not optional)
--
-- A plugin is compiled against one exact ABI. After any hyprland, aquamarine,
-- hyprutils or hyprgraphics update it must be rebuilt or it refuses to load —
-- hyprtasking checks the headers itself and says so. `hyprpm update` alone is
-- not always enough: it can refresh the headers and leave an already-built
-- .so in place, which is how this first went wrong. `-f` forces the rebuild.

-- ── hyprtasking ─────────────────────────────────────────────────────────────
--
-- The workspace overview: thumbnails of every workspace, with windows that can
-- be dragged between them. This is the feature the whole desktop was modelled
-- after; Hyprland has nothing like it built in.
--
-- raybbian/hyprtasking, chosen over KZDKM/Hyprspace (the original, and the one
-- in the reference screenshots) because Hyprspace's last compatibility work
-- targeted Hyprland 0.55 and its author has scaled back maintenance, while
-- hyprtasking declares support through 0.56.2 — this compositor exactly.
--
-- Bound to SUPER + G in conf/keybinds.lua.
hl.config({
    plugin = {
        hyprtasking = {
            -- "linear" is the horizontal strip along the screen edge, which is
            -- the layout the reference desktop uses. "grid" is a 3x3 of the
            -- whole screen — more space per workspace, less like the target.
            layout = "linear",

            gap_size    = 12,
            border_size = 1,

            -- Dark enough to read thumbnails against, transparent enough that
            -- the desktop is still visibly underneath rather than replaced.
            --
            -- An INTEGER, not a colour string: this key takes ARGB packed into
            -- an int (0xAARRGGBB), and a "rgba(...)" string is rejected with
            -- "integer type requires a bool or an integer".
            bg_color = 0x99000000,

            -- Leave the overview on the workspace under the cursor rather than
            -- the one that was active — clicking a thumbnail should take you
            -- there, which is the whole point.
            exit_on_hovered = 1,

            linear = {
                height = 300,
            },

            gestures = {
                enabled = 1,
            },
        },
    },
})
