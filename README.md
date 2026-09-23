# hyprland dotfiles

CachyOS, Hyprland 0.56.2 on Wayland, with KDE Plasma kept installed as a second
session. Everything is symlinked out of this repo — the repo is the source of
truth, `~` just points at it.

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

Themes are switchable. `SUPER+SHIFT+T` opens a picker, or:

```sh
theme-set --list          # apple-stock, rainynight
theme-set rainynight
theme-set --status
theme-menu --gtk          # zenity dialog instead of rofi
```

A theme is a directory of hand-written colour files under `config/themes/`, and
`config/themes/current` is a symlink naming the active one. Nothing is generated
or templated — switching repoints the symlink and reloads.

| file in a theme | reaches the app by |
|---|---|
| `palette.lua` | `conf/palette.lua` shim (`dofile`) |
| `look.lua` | tail of `conf/theme.lua` (`dofile`) |
| `hyprlock.conf` | `source =` |
| `waybar.css` | `@import` |
| `rofi.rasi` | `@import` |
| `swayosd.css` | `@import` |
| `mako.config` | **copied** — mako has no include directive |
| `theme.toml` | metadata; also names which kitty theme to copy in |

Six of the eight follow the symlink live. Only mako and kitty are copies, and
only because neither can include a file — which means mako's geometry is
duplicated per theme, the one place a layout change has to be made twice.

`dofile` rather than `require` for the two Lua files is deliberate: `require`
caches by module name, so after a switch a `hyprctl reload` would keep serving
the previous theme out of `package.loaded`.

Adding a theme is copying a directory and editing colours. `theme-set` checks
every required file exists before changing anything, so a half-written theme
fails cleanly rather than part way through.

The two that ship:

- **apple-stock** — neutral near-black carried by alpha, one blue used only for
  selection. Rounding 10, opaque windows, wide soft blur.
- **rainynight** — Catppuccin-Mocha derived: blue-grey surfaces, lavender-blue
  accent. Rounding 14, 0.93/0.92 opacity, a brighter blur.

Wallpapers are not part of a theme and live in `~/Pictures/Wallpapers/`.

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
| `config/kitty/themes/` | — | kitty palettes; `theme-set` copies the right one in |
| `config/themes/` | — | the switchable themes; `current` symlinks the active one |
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
