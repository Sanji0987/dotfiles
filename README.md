# dotfiles

Configuration for my CachyOS box: Hyprland with a stack of small, independent
daemons, plus KDE Plasma as the second session.

Everything here is symlinked into place — the repo is the single source of
truth, the home directory just points at it.

## Layout

| path | goes to | what |
|---|---|---|
| `config/hypr/` | `~/.config/hypr` | Hyprland (lua config), hyprlock, hypridle, hyprpaper |
| `config/waybar/` | `~/.config/waybar` | the bar |
| `config/rofi/` | `~/.config/rofi` | launcher (SUPER+Space), Spotlight-style |
| `config/mako/` | `~/.config/mako` | notifications |
| `config/kitty/` | `~/.config/kitty` | kitty; `current-theme.conf` holds the palette |
| `config/kitty/themes/` | — | per-theme palette extracts, kept for reference |
| `config/fastfetch/` | `~/.config/fastfetch` | fastfetch, coloured through the terminal palette |
| `config/nvim/` | `~/.config/nvim` | LazyVim |
| `config/fish/` `home/.zshrc` … | | shells (zsh + p10k is the daily driver) |
| `config/tmux/` `config/alacritty/` `config/btop/` `config/cava/` | | the usual suspects |
| `config/fontconfig/` `config/uwsm/` | | session plumbing |
| `bin/` | `~/.local/bin` | small hand-rolled scripts |
| `help.sh` | `~/help.sh` | command reference for the whole setup |

## The desktop

Hyprland 0.56.2, which reads **Lua natively** — `config/hypr/hyprland.lua`
requires the modules in `conf/` and is executed in-process, with no generated
`hyprland.conf` anywhere. Unknown config keys fail *silently*, so
`hyprctl configerrors` after every edit is the only real check. See
`config/hypr/NOTES.md`.

The UI is deliberately several small processes rather than one:

| | |
|---|---|
| `waybar` | bar, including a Claude Code usage module |
| `mako` | notifications |
| `swayosd-server` | volume and media OSD |
| `hyprpaper` | wallpaper |
| `rofi` | launcher, clipboard picker |
| `hyprlock` / `hypridle` | lock and idle |

All are started from `conf/autostart.lua`. Any one of them can be killed and
restarted without touching the others.

This replaced Omarchy 4's Quickshell shell, which hosted all of the above in a
single QML process — so a crash, or a `qt6-base` bump, took the whole desktop's
UI at once. That shell and its theme pipeline were removed in reverse order of
how they had been added; the commits from `Pop 1` onward are that teardown, one
layer each.

## Theming

There is no theme pipeline. Every palette is a tracked, hand-written file, and
they are kept in step by being edited together:

| file | what it colours |
|---|---|
| `config/hypr/conf/palette.lua` | window borders (via `conf/theme.lua`) |
| `config/hypr/conf/themes/rainynight.lua` | rounding, blur, opacity — merged over the base look |
| `config/hypr/hyprlock.conf` | lock screen |
| `config/waybar/style.css` | bar |
| `config/mako/config` | notifications |
| `config/rofi/spotlight.rasi` | launcher |
| `config/kitty/current-theme.conf` | terminal (and fastfetch, through ANSI names) |

The colours are the rainynight theme's, vendored here when the theme that
shipped them was still installed. Wallpapers live in `~/Pictures/Wallpapers/`.

## Install

```sh
git clone https://github.com/Sanji0987/dotfiles ~/dotfiles
~/dotfiles/install.sh
```

`install.sh` only creates symlinks and refuses to overwrite anything that
already exists — it tells you what is in the way instead.

Packages it does not install:

```sh
sudo pacman -S waybar mako swayosd rofi hyprpaper hyprlock hypridle \
               grim slurp wl-clipboard cliphist playerctl pavucontrol jq
```

## Notes

- `bin/agent-usage-*` collect Claude Code, Codex and Fireworks usage into
  `~/.local/state/agent-usage/`; `bin/waybar-claude` renders the Claude record
  as a bar module. Rescued from the Quickshell shell's agents widget, which
  only ever displayed what these scripts produced.
- `~/help.sh` prints a searchable reference for every command in this setup.
