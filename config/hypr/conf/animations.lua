-- edited by claude opus 5
-- retuned for a macOS feel: ease-out everywhere, no springs
--
-- The previous set drove windows off a spring (mass 1, stiffness 238,
-- dampening 24). A spring is a bounce — it overshoots the target and settles
-- back, which is an Android/GNOME gesture feel, not a macOS one. macOS motion
-- decelerates hard into its endpoint and stops dead: fast at the start, slow
-- at the finish, never past it. That is an ease-out bezier, so the springs are
-- gone.
--
-- ── ANIMATION TUNING ────────────────────────────────────────────────────────
-- `speed` is in deciseconds: 4 = 400ms, 2.5 = 250ms. Lower is faster.
-- Everything here is deliberately quick; the slowest thing is 400ms.
-- To make the desktop feel snappier, scale every speed down together rather
-- than changing one — mismatched durations read as jank, not speed.

hl.config({ animations = { enabled = true } })

-- Ease-out curves. The two that matter:
--   macEase   easeOutExpo — near-instant start, long glide to a dead stop.
--             This is the closest single curve to macOS window motion.
--   macQuick  a gentler ease-out for things that should not draw the eye.
hl.curve("macEase",  { type = "bezier", points = { {0.16, 1},   {0.3, 1}  } })
hl.curve("macQuick", { type = "bezier", points = { {0.25, 1},   {0.5, 1}  } })
hl.curve("linear",   { type = "bezier", points = { {0, 0},      {1, 1}    } })
hl.curve("almostLinear", { type = "bezier", points = { {0.5, 0.5}, {0.75, 1} } })

-- Windows: fade in with a slight scale-up. popin 92% means it starts at 92%
-- of final size — a hint of growth, not a zoom. Below about 85% it reads as a
-- pop; above 95% the movement is invisible.
hl.animation({ leaf = "windows",       enabled = true, speed = 4,    bezier = "macEase" })
hl.animation({ leaf = "windowsIn",     enabled = true, speed = 4,    bezier = "macEase",  style = "popin 92%" })
hl.animation({ leaf = "windowsOut",    enabled = true, speed = 2.5,  bezier = "macQuick", style = "popin 92%" })
hl.animation({ leaf = "windowsMove",   enabled = true, speed = 4,    bezier = "macEase" })

-- Border colour crossfade on focus change. Slower than the window itself, so
-- focus reads as a settle rather than a flash.
hl.animation({ leaf = "border",        enabled = true, speed = 5,    bezier = "macQuick" })

hl.animation({ leaf = "fade",          enabled = true, speed = 3,    bezier = "macQuick" })
hl.animation({ leaf = "fadeIn",        enabled = true, speed = 3,    bezier = "macQuick" })
hl.animation({ leaf = "fadeOut",       enabled = true, speed = 2,    bezier = "macQuick" })

-- Layer surfaces: the bar, the launcher, notifications, the OSD. These fade
-- rather than slide — a launcher that flies in from an edge is a Linux tell.
hl.animation({ leaf = "layers",        enabled = true, speed = 3,    bezier = "macEase" })
hl.animation({ leaf = "layersIn",      enabled = true, speed = 3,    bezier = "macEase",  style = "fade" })
hl.animation({ leaf = "layersOut",     enabled = true, speed = 2,    bezier = "macQuick", style = "fade" })
hl.animation({ leaf = "fadeLayersIn",  enabled = true, speed = 2,    bezier = "macQuick" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 2,    bezier = "macQuick" })

-- edited by claude opus 5
-- reverted to fade: the horizontal slide was tried and not wanted
--
-- macOS Spaces slides, and that is why it was changed — but sliding a whole
-- workspace reads as a much bigger movement on one 1920px monitor than it
-- does across a Mac's trackpad gesture, and it was disliked on sight. These
-- are the original values, restored exactly.
hl.animation({ leaf = "workspaces",    enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesIn",  enabled = true, speed = 1.21, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })

hl.animation({ leaf = "global",        enabled = true, speed = 4,    bezier = "macEase" })
hl.animation({ leaf = "zoomFactor",    enabled = true, speed = 5,    bezier = "macQuick" })
