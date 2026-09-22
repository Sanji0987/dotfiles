# sway dotfiles

Fedora 44 Sway spin — sway / waybar / kitty / rofi / GTK, on the Victus laptop.

```
$ fastfetch --logo none

### PASTE `fastfetch --logo none` OUTPUT HERE ###
### run it from inside the Sway session, and strip the "Local IP" line ###
```

This is my take on a tiling setup that survives distro updates. Everything sway
gets is a **drop-in** — `/etc/sway/config` is never touched, so a Fedora update
cannot fight me for the file. Everything else is small, boring and replaceable.

No gaming was tested here. This is the laptop; the desktop does that.

## Branches are modular and mutually exclusive

Every branch in this repo is a **self-contained setup for one machine and one
desktop**. They are orphan branches: no shared history, no common ancestor, no
files in common. Nothing is meant to be merged, cherry-picked or rebased between
them, and `git diff main laptop` is meaningless by design.

| branch | what |
|---|---|
| `main` | CachyOS — Hyprland, waybar, mako, rofi |
| `laptop` | **this one** — Fedora 44 Sway spin |
| `gnome` | Fedora 44, GNOME 50.5 Wayland, WhiteSur — same laptop, different install |

## What is configured

| Area | Files | Notes |
|---|---|---|
| sway | `config.d/*.conf` | drop-ins only; `/etc/sway/config` untouched, so distro updates stay clean |
| waybar | `config.jsonc`, `style.css` | one solid bar, Catppuccin Mocha |
| kitty | `kitty.conf` | JetBrains Mono 11, Alt+N tab switching |
| rofi | `omarchy-tokyo-night.rasi` | Omarchy-style menu, Tokyo Night palette |
| GTK | `gtk-3.0/`, `gtk-4.0/` | dark via prefer-dark on Adwaita |

### sway drop-ins

| File | Does |
|---|---|
| `40-output.conf` | eDP-1 scale 1.15 |
| `41-wallpaper.conf` | wallpaper |
| `42-refresh.conf` | pins the refresh rate — see below |
| `45-borders.conf` | no borders, no titlebars |
| `50-font.conf` | JetBrains Mono 11 |
| `50-input-keyboard.conf` | repeat delay 200ms, rate 35/s |
| `50-input-touchpad.conf` | tap to click, two-finger right click |
| `50-terminal.conf` | kitty as `$term`; rebuilds `$menu` for rofi |
| `60-bindings-launcher.conf` | Super+Space launcher |
| `60-bindings-swap.conf` | Super+W kill / Super+Shift+Q tabbed |
| `60-bindings-toggles.conf` | animation toggle |
| `70-window-rules.conf` | nmtui opens floating |

Two sway gotchas worth remembering:

- `/etc/sway/config` expands `$term` into its bindings **before** the `config.d`
  include at the end of the file, so redefining `$term` alone does nothing — the
  affected binding and `$menu` must be restated.
- Rebinding a key that is already bound makes sway warn and pop up swaynag. Use
  `bindsym --no-warn`.

## Display refresh rate

The panel is 1920x1080 and does both 60 Hz and 144 Hz, but under sway it
**fails eDP link training on some mode switches**:

```
i915 0000:00:02.0: [drm] *ERROR* [CONNECTOR:eDP-1][DPRX] Failed to enable link training
```

When that happens the screen goes black and sway stops answering IPC, sometimes
permanently — a hard reboot is the only way out. There is deliberately **no
keybind** for this, unlike every other toggle here.

The rate is pinned in `42-refresh.conf` and applied once at sway startup. To see
the current state and the exact commands to change it:

```sh
~/display_rate
```

Change the rate by editing the pin and rebooting, not live.

> Worth knowing: this is a **sway/wlroots problem, not a panel fault.** The same
> physical display switches 60 ↔ 144 live and repeatedly on the `gnome` branch,
> where mutter drives it through `org.gnome.Mutter.DisplayConfig` instead. The
> panel's own EDID flags 144 Hz as its preferred mode. So if this ever stops
> being worth fighting, the mode is fine — it is the path to it that is not.

## Repos this is pieced together from

Credit where it's due:

| what | repo |
|---|---|
| Compositor | [swaywm/sway](https://github.com/swaywm/sway) (Fedora Sway spin) |
| Bar | [Alexays/Waybar](https://github.com/Alexays/Waybar) |
| Launcher | [davatorium/rofi](https://github.com/davatorium/rofi) |
| Bar palette | Catppuccin Mocha — [catppuccin/catppuccin](https://github.com/catppuccin/catppuccin) |
| Menu style + wallpapers | [atif-1402/omarchy-rainynight-theme](https://github.com/atif-1402/omarchy-rainynight-theme) |

## What is NOT in here, and why

Binaries, machine state, and anything that lives outside `~/.config` —
listed so a rebuild does not miss it:

| thing | where | how to get it back |
|---|---|---|
| wallpapers | `~/Pictures/wallpapers/rainynight/` | 4.4 MB of binaries — refetch from the theme repo above |
| timezone | system | `timedatectl set-timezone Asia/Dubai` |
| dnf tuning | `/etc/dnf/dnf.conf` | `max_parallel_downloads`, `fastestmirror`, `ip_resolve=4` |

`.gitignore` also drops `*.bak`, `*~` and `*.swp`.

## How to install

### 1. Packages

```sh
sudo dnf install kitty jetbrains-mono-fonts rofi waybar blueman \
  fontawesome-6-free-fonts fontawesome-6-brands-fonts \
  NetworkManager-tui brightnessctl pavucontrol jq libnotify
```

`jq` is a hard dependency of `display_rate`. `libnotify` provides `notify-send`,
which every script guards with `command -v`, so a missing one degrades to
silence rather than failing.

### 2. Configs

```sh
git clone https://github.com/Sanji0987/dotfiles ~/dotfiles
cd ~/dotfiles && git checkout laptop
./sync.sh restore
```

Then log out and back in — sway does not reload drop-ins in place.

> `restore` overwrites live configs **with no backup**. That is its job, but do
> not run it by accident.

### 3. Keeping it in step

```sh
./sync.sh          # live -> repo (the default)
./sync.sh restore  # repo -> live
```

`sync.sh` mirrors whole directories, so a new file in any tracked directory is
picked up without editing the script, and a file deleted from `~/.config` is
pruned from the repo on the next sync. It also regenerates `gsettings.sh` from
the live dconf values — so that file is **generated, not hand-edited**.

## Keys

| Key | Action |
|---|---|
| `Super+Return` | kitty |
| `Super+Space` | rofi |
| `Super+W` | close window |
| `Super+Shift+Q` | tabbed layout |
| `Super+Tab` | tiling/floating focus toggle |
| `Super+Shift+M` | toggle GTK animations |
| `Alt+1..0` | kitty: go to tab |
| `Ctrl+Alt+T` / `Ctrl+Alt+W` | kitty: new / close tab |

## Bar

Click targets: wifi → `nmtui` (floating kitty) · bluetooth → `blueman-manager` ·
volume → `pavucontrol` · battery → cycles power profile · ☕ → toggles idle
inhibit · clock → toggles date.

## Layout

| path | goes to |
|---|---|
| `config/` | `~/.config` |
| `home/` | `~` (currently just `display_rate`) |
| `gsettings.sh` | — (generated by `sync.sh`; dark theme + fonts) |
| `sync.sh` | — (run it) |

---

I'm sick of doing this from scratch every time I reinstall. That's the whole
point of this branch — next time it's a clone and one script, not an afternoon.

And no, I don't care that AI wrote the commits and the readme(edited heavily by
me). I can't be bothered to type all this out when automation exists.
