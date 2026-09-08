# dotfiles

Fedora 44 Sway spin — sway / waybar / kitty / rofi / GTK.

## Layout

    config/          mirrors ~/.config
    gsettings.sh     dconf settings (dark theme + fonts) as a replayable script
    sync.sh          copy live -> repo (default), or `./sync.sh restore` to go back

`restore` overwrites live configs with no backup — that is its job, but do not
run it by accident.

## What is configured

| Area   | Files | Notes |
|--------|-------|-------|
| sway   | `config.d/*.conf` | drop-ins only; `/etc/sway/config` untouched, so distro updates stay clean |
| waybar | `config.jsonc`, `style.css` | one solid bar, Catppuccin Mocha |
| kitty  | `kitty.conf` | JetBrains Mono 12, Alt+N tab switching |
| rofi   | `omarchy-tokyo-night.rasi` | Omarchy-style menu, Tokyo Night palette |
| GTK    | `gtk-3.0/`, `gtk-4.0/` | dark via prefer-dark on Adwaita |

### sway drop-ins

| File | Does |
|------|------|
| `40-output.conf` | eDP-1 scale 1.15 |
| `41-wallpaper.conf` | wallpaper |
| `42-refresh.conf` | refresh rate, rewritten by the toggle script |
| `45-borders.conf` | no borders, no titlebars |
| `50-font.conf` | JetBrains Mono 11 |
| `50-input-keyboard.conf` | repeat delay 200ms, rate 35/s |
| `50-terminal.conf` | kitty as `$term`; rebuilds `$menu` for rofi |
| `60-bindings-launcher.conf` | Super+Space launcher |
| `60-bindings-swap.conf` | Super+W kill / Super+Shift+Q tabbed |
| `60-bindings-toggles.conf` | animation + refresh toggles |
| `70-window-rules.conf` | nmtui opens floating |

Two sway gotchas worth remembering:

- `/etc/sway/config` expands `$term` into its bindings **before** the `config.d`
  include at the end of the file, so redefining `$term` alone does nothing —
  the affected binding and `$menu` must be restated.
- Rebinding a key that is already bound makes sway warn and pop up swaynag.
  `unbindsym` first.

## Wallpapers

`~/Pictures/wallpapers/rainynight/` — not tracked here (4.4MB of binaries).
Refetch from https://github.com/atif-1402/omarchy-rainynight-theme

Switch by editing `41-wallpaper.conf`, or live:

    swaymsg output '*' bg ~/Pictures/wallpapers/rainynight/snow-night.jpg fill

## Not tracked here

System-level state that lives outside `~/.config`, listed so a rebuild does not
miss it:

    timezone       Asia/Dubai        timedatectl set-timezone Asia/Dubai
    dnf tuning     /etc/dnf/dnf.conf max_parallel_downloads / fastestmirror / ip_resolve=4
    wallpapers     ~/Pictures/wallpapers/rainynight/

## Requires

    kitty jetbrains-mono-fonts rofi waybar blueman
    fontawesome-6-free-fonts fontawesome-6-brands-fonts
    NetworkManager-tui brightnessctl pavucontrol
    jq libnotify

`jq` is a hard dependency of `toggle-refresh.sh`; `libnotify` provides
notify-send, which every script guards with `command -v` so it degrades to
silence rather than failing.

`42-refresh.conf` is rewritten by the refresh toggle, so it shows a git diff
each time you change refresh rate. Add it to `.gitignore` if that noise is
unwanted -- the cost is that a restored machine falls back to the display's
preferred mode.

## Keys

| Key | Action |
|-----|--------|
| `Super+Return` | kitty |
| `Super+Space` | rofi |
| `Super+W` | close window |
| `Super+Shift+Q` | tabbed layout |
| `Super+Tab` | tiling/floating focus toggle |
| `Super+Shift+M` | toggle GTK animations |
| `Super+Shift+~` | toggle 144Hz / 60Hz |
| `Alt+1..0` | kitty: go to tab |
| `Ctrl+Alt+T` / `Ctrl+Alt+W` | kitty: new / close tab |

## Bar

Click targets: wifi → `nmtui` (floating kitty) · bluetooth → `blueman-manager` ·
volume → `pavucontrol` · battery → cycles power profile · ☕ → toggles idle
inhibit · clock → toggles date.
