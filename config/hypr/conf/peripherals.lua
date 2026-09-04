hl.config({
    input = {
        kb_layout  = "us",
        kb_variant = "",
        kb_model   = "",
        kb_options = "",
        kb_rules   = "",

        follow_mouse  = 1,
        mouse_refocus = true,

        sensitivity   = 0,
        accel_profile = "flat",

        repeat_rate  = 35,
        repeat_delay = 200,

        numlock_by_default = true,

        touchpad = {
            natural_scroll       = true,
            disable_while_typing = true,
            tap_to_click         = true,
            scroll_factor        = 1.0,
        },
    },
})

hl.gesture({
    fingers   = 3,
    direction = "horizontal",
    action    = "workspace",
})
