-- edited by claude opus 5
-- was a symlink into ~/.local/state/omarchy/current/theme/neovim.lua, which is
-- being deleted; frozen to a plain file holding what that link resolved to.
-- NvChad is replacing this config, so the aether/kanagawa drift in
-- lazy-lock.json is deliberately left as-is rather than fixed twice.

return {
  {
    "bjarneo/aether.nvim",
    branch = "v3",
    name = "aether",
    priority = 1000,
    opts = {
      colors = {
        bg = "#1e1e2e",
        dark_bg = "#171723",
        darker_bg = "#0f0f17",
        lighter_bg = "#1e1e2e",

        fg = "#cdd6f4",
        dark_fg = "#585b70",
        light_fg = "#cdd6f4",
        bright_fg = "#cdd6f4",
        muted = "#585b70",

        red = "#f38ba8",
        yellow = "#f9e2af",
        orange = "#f9e2af",
        green = "#a6e3a1",
        cyan = "#94e2d5",
        blue = "#89b4fa",
        magenta = "#cba6f7",
        brown = "#7d7158",

        bright_red = "#f38ba8",
        bright_yellow = "#f9e2af",
        bright_green = "#a6e3a1",
        bright_cyan = "#94e2d5",
        bright_blue = "#89b4fa",
        bright_magenta = "#cba6f7",

        accent = "#89b4fa",
        cursor = "#cdd6f4",
        foreground = "#cdd6f4",
        background = "#1e1e2e",
        selection = "#292b3b",
        selection_foreground = "#e8f1ff",
        selection_background = "#292b3b",
      },
    },
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "aether",
    },
  },
}
