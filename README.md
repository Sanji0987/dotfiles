# hyprland dotfiles

CachyOS, Hyprland 0.56.2 on Wayland, with KDE Plasma kept installed as a second
session. Everything is symlinked out of this repo — the repo is the source of
truth, `~` just points at it.

```
$ fastfetch --logo none

### PASTE `fastfetch --logo none` OUTPUT HERE ###
### strip the "Local IP" line first -- that is the network, not the config ###
```

This is my take on a desktop that does not fall over. The whole UI is several
small independent daemons rather than one process, every palette is a file I
wrote by hand instead of something generated, and the config is Lua that
Hyprland executes directly. If one piece dies I restart that piece; nothing
else notices.

This is the desktop, so it is the machine that actually games. Nothing here is
tuned for it either way — no frame-time work, no compositor tearing flags, no
game mode. It is a work setup that happens to sit on hardware that can play
things.

## Branches are modular and mutually exclusive

Every branch in this repo is a **self-contained setup for one machine and one
desktop**. These branches are mutually exclusive (to future me incase i forget).

| branch | what |
|---|---|
| `main` | **this one** — CachyOS, Hyprland, waybar, mako, rofi |
| `laptop` | Fedora 44 Sway spin — sway, waybar, rofi |
| `gnome` | Fedora 44, GNOME 50.5 Wayland, WhiteSur |

They are orphan branches: no shared history, no common ancestor, no files in
common. Nothing is meant to be merged, cherry-picked or rebased between them,
and `git diff main gnome` is meaningless by design.

## The desktop

Hyprland reads **Lua natively**. `config/hypr/hyprland.lua` requires the modules
in `conf/` and is executed in-process — there is no generated `hyprland.conf`
anywhere.

The gotcha that costs the most time: **unknown config keys fail silently.** A
typo does not error, it just does nothing. `hyprctl configerrors` after every
edit is the only real check. More in `config/hypr/NOTES.md`.

The UI is deliberately several small processes rather than one:

| process | does |
|---|---|
| `waybar` | bar, including a Claude Code usage module |
| `mako` | notifications |
| `swayosd-server` | volume and media OSD |
| `hyprpaper` | wallpaper |
| `rofi` | launcher (Super+Space), clipboard picker |
| `hyprlock` / `hypridle` | lock and idle |
| `hyprsunset` | night colour temperature |

All started from `conf/autostart.lua`. Any one can be killed and restarted
without touching the others.

This replaced Omarchy 4's Quickshell shell, which hosted all of the above in a
single QML process — so a crash, or a `qt6-base` bump, took the whole desktop's
UI down at once. That shell and its theme pipeline were removed in reverse
order of how they had been added; the commits from `Pop 1` onward are that
teardown, one layer each.

## Theming

There is no theme pipeline. Every palette is a tracked, hand-written file, and
they are kept in step by being edited together:

| file | what it colours |
|---|---|
| `config/hypr/conf/palette.lua` | window borders (via `conf/theme.lua`) |
| `config/hypr/conf/theme.lua` | rounding, gaps, blur, opacity — the window look itself |
| `config/hypr/hyprlock.conf` | lock screen |
| `config/waybar/style.css` | bar |
| `config/mako/config` | notifications |
| `config/rofi/spotlight.rasi` | launcher |
| `config/swayosd/style.css` | volume / media OSD |
| `config/kitty/current-theme.conf` | terminal (and fastfetch, through ANSI names) |

The scheme is deliberately colourless: near-black surfaces carried by alpha,
focus shown as a step between two greys (`707070` / `393939`), and one blue used
only for selection. The wallpaper supplies the colour; the chrome does not.

### Switching back

The previous look — Catppuccin-derived "rainynight", 14px rounding, translucent
windows, indigo borders — is kept at `config/hypr/conf/themes/rainynight.lua`.
It is **dormant**: the `require` for it at the tail of `conf/theme.lua` is
commented out, so uncommenting that line and running `hyprctl reload` restores
the window look.

Nothing else follows automatically. Each file in the table above holds its own
copy of the palette, so a full switch means editing those too.

## Repos this is pieced together from

Credit where it's due:

| what | repo |
|---|---|
| Compositor | [hyprwm/Hyprland](https://github.com/hyprwm/Hyprland) 0.56.2 |
| Lock / idle / wallpaper / sunset | [hyprwm](https://github.com/hyprwm) — hyprlock, hypridle, hyprpaper, hyprsunset |
| Bar | [Alexays/Waybar](https://github.com/Alexays/Waybar) |
| Notifications | [emersion/mako](https://github.com/emersion/mako) |
| Launcher | [davatorium/rofi](https://github.com/davatorium/rofi) |
| OSD | [ErikReider/SwayOSD](https://github.com/ErikReider/SwayOSD) |
| Editor | [LazyVim/LazyVim](https://github.com/LazyVim/LazyVim) |
| Prompt | [romkatv/powerlevel10k](https://github.com/romkatv/powerlevel10k) |
| Previous theme | [atif-1402/omarchy-rainynight-theme](https://github.com/atif-1402/omarchy-rainynight-theme) |

The layout owes its shape to **Omarchy 4**, which is what this started as
before the Quickshell teardown. The `rainynight` palette came from there.

## What is NOT in here, and why

See `.gitignore`. Machine state and scratch, not config:

- `local/`, `*.local.md` — personal scratch notes
- `config/fish/fish_variables` — fish rewrites this at runtime
- `*.bak`, `*.bak.*`, `*.pre-dotfiles` — what `install.sh` moves aside
- `~/Pictures/Wallpapers/` — binaries, refetch them instead

## How to install

```sh
git clone https://github.com/Sanji0987/dotfiles ~/dotfiles
cd ~/dotfiles && git checkout main
./install.sh
```

`install.sh` only creates symlinks, and refuses to overwrite anything that
already exists — it tells you what is in the way instead of clobbering it.

Packages it does **not** install:

```sh
sudo pacman -S waybar mako swayosd rofi hyprpaper hyprlock hypridle hyprsunset \
               grim slurp wl-clipboard cliphist playerctl pavucontrol jq
```

Then `hyprctl configerrors` to confirm the Lua config loaded clean.

## Layout

| path | goes to | what |
|---|---|---|
| `config/hypr/` | `~/.config/hypr` | Hyprland (Lua), hyprlock, hypridle, hyprpaper, hyprsunset |
| `config/waybar/` | `~/.config/waybar` | the bar |
| `config/rofi/` | `~/.config/rofi` | launcher (Super+Space), Spotlight-style |
| `config/mako/` | `~/.config/mako` | notifications |
| `config/swayosd/` | `~/.config/swayosd` | volume / media OSD |
| `config/kitty/` | `~/.config/kitty` | kitty; `current-theme.conf` holds the live palette |
| `config/kitty/themes/` | — | per-theme palette extracts, kept for reference |
| `config/nvim/` | `~/.config/nvim` | LazyVim |
| `config/fastfetch/` | `~/.config/fastfetch` | coloured through the terminal palette |
| `config/fish/`, `home/.zshrc`, `home/.p10k.zsh` | | shells — zsh + p10k is the daily driver |
| `config/tmux/`, `config/alacritty/`, `config/btop/`, `config/cava/` | | the usual suspects |
| `config/fontconfig/`, `config/uwsm/` | | session plumbing |
| `bin/` | `~/.local/bin` | small hand-rolled scripts |
| `help.sh` | `~/help.sh` | command reference for the whole setup |

## Notes

- `bin/agent-usage-*` collect Claude Code, Codex and Fireworks usage into
  `~/.local/state/agent-usage/`; `bin/waybar-claude` renders the Claude record
  as a bar module. Rescued from the Quickshell shell's agents widget, which only
  ever displayed what these scripts produced.
- `~/help.sh` prints a searchable reference for every command in this setup.

---

I'm sick of doing this from scratch every time I reinstall. That's the whole
point of this branch — next time it's a clone and one script, not an afternoon.

And no, I don't care that AI wrote the commits and the readme(edited heavily by
me). I can't be bothered to type all this out when automation exists.
