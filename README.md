# gnome dotfiles

Fedora 44 Workstation, GNOME 50.5 on Wayland, themed to look like macOS with
WhiteSur.


```
$ fastfetch --logo none

OS: Fedora Linux 44 (Workstation Edition) x86_64
Host: Victus by HP Gaming Laptop 15-fa1xxx
Kernel: Linux 7.2.5-200.fc44.x86_64
Packages: 6 (flatpak-system), 4 (flatpak-user), 2263 (rpm)
Shell: zsh 5.9
Display (BOE094D): 1920x1080 in 15", 60 Hz [Built-in]
Desktop Environment: GNOME 50.5
Window Manager: Mutter (Wayland)
WM Theme: WhiteSur-Dark
Theme: WhiteSur-Dark [GTK2/3/4]
Icons: WhiteSur-dark [GTK2/3/4]
Font: SF Pro Text (11pt) [GTK2/3/4]
Cursor: WhiteSur (24px)
Terminal: kitty 0.47.1
CPU: 13th Gen Intel(R) Core(TM) i7-13700H (12+8) @ 5.00 GHz
GPU 1: NVIDIA GeForce RTX 3050 6GB Laptop GPU [Discrete]
GPU 2: Intel Iris Xe Graphics @ 1.50 GHz [Integrated]
Memory: 5.21 GiB / 15.24 GiB (34%)
Swap: 0 B / 8.00 GiB (0%)
Disk (/): 13.67 GiB / 474.34 GiB (3%) - btrfs
Locale: en_US.UTF-8
```

The four `flatpak-user` packages are the WhiteSur GTK3 theme bundles — see the
caveat under "WhiteSur theme" for why that matters.

This is my take on a smooth desktop to actually do work on. Everything is
keyboard-first: Super is free for Search Light instead of the overview, Super
alone does nothing, workspaces are static at 4 so im not overthinking, and hot
corners are off so the mouse never surprises me. The theming is WhiteSur end to
end — GTK3, GTK4/libadwaita, the shell, icons and cursors — so there is no
half-themed app sitting in the middle of it.

No gaming was tested here — no perf drops, no frame timing, nothing. There is an
RTX 3050 in this laptop and it is not even in use: the `nvidia` module isn't
loaded and everything renders on the Iris Xe. 

## Repos this is pieced together from

Almost none of this is mine. Credit where it's due:

| what | repo | pinned at |
|---|---|---|
| GTK/shell theme | [vinceliuice/WhiteSur-gtk-theme](https://github.com/vinceliuice/WhiteSur-gtk-theme) | `d578265` (2026-09-11) |
| Icons | [vinceliuice/WhiteSur-icon-theme](https://github.com/vinceliuice/WhiteSur-icon-theme) | `73d8040` (2026-09-10) |
| Cursors | [vinceliuice/WhiteSur-cursors](https://github.com/vinceliuice/WhiteSur-cursors) | `e190baf` (2025-04-05) |
| Wallpapers | [vinceliuice/WhiteSur-wallpapers](https://github.com/vinceliuice/WhiteSur-wallpapers) | MIT |
| Spotlight clone | [icedman/search-light](https://github.com/icedman/search-light) | v101 |
| Dock + panel tuning | [jothi-prasath/gnomintosh](https://github.com/jothi-prasath/gnomintosh) | `4a25567` (2024-11-10) |

vinceliuice did the actual work on four of those six. Dash to Dock, Blur my
Shell, User Themes and Just Perfection come from Fedora's own repos, not from
upstream.

gnomintosh is a whole macOS-on-GNOME installer of its own. I did not run it --
its `main.sh` opens with an unguarded `rm -rf WhiteSur*` against `$PWD`, and my
clones live in `~/gitclones`. But its dconf dump is a good reference, and the
Dash to Dock and Just Perfection blocks in `gsettings.sh` came from it. Those
lines are marked `# copied from` in the script.

## What is NOT in here, and why

Generated or non-redistributable — see `.gitignore`. Rebuild them, don't commit
them:

- `~/.themes/WhiteSur-*` — hundreds of MB, output of `install.sh`
- `~/.config/gtk-4.0/{assets,windows-assets,gtk-Dark.css,gtk-Light.css}` — output of `install.sh -l`
### special
- `~/.local/share/icons/WhiteSur*` — output of the icon/cursor `install.sh`
- `~/.local/share/fonts/SF/*.otf` — Apple's font, see below
- the upstream git clones themselves

`dconf/gnome.ini` is scrubbed: an `nm-applet` section keyed by a NetworkManager
connection UUID and a file-chooser path were removed before committing. Neither
had anything to do with theming.

## Fonts (legal something)

**SF Pro is not in this repo and never will be.** It is Apple's system font.
Apple gives it away at [developer.apple.com/fonts](https://developer.apple.com/fonts/),
but the license it ships under permits use for designing interfaces for Apple
platforms — it is not an open font license, and it does not permit
redistribution. 

```sh
# grab the SF Pro .dmg/.pkg from developer.apple.com/fonts, then:
7z x SF-Pro.pkg && 7z x Payload~
mkdir -p ~/.local/share/fonts/SF
cp Library/Fonts/*.otf ~/.local/share/fonts/SF/
fc-cache -f
```

If you skip it, `gsettings.sh` still runs — GNOME falls back to the default sans
and the desktop is maybe 90% as Mac-looking. The honest open alternative is
**Inter** (SIL OFL), which is close enough that most people won't clock it.

`JetBrains Mono` is the monospace font and that one *is* freely licensed
(`dnf install jetbrains-mono-fonts`).

## How to rebuild

### 1. Packages

```sh
sudo dnf install sassc glib2-devel gnome-tweaks \
  gnome-shell-extension-user-theme gnome-shell-extension-dash-to-dock \
  gnome-shell-extension-blur-my-shell gnome-shell-extension-just-perfection \
  jetbrains-mono-fonts ImageMagick p7zip p7zip-plugins fastfetch
```

### 2. WhiteSur theme

```sh
git clone https://github.com/vinceliuice/WhiteSur-gtk-theme.git --depth=1
cd WhiteSur-gtk-theme
./install.sh -l --shell -i fedora   # -l = libadwaita/GTK4, --shell = shell theme
./tweaks.sh -F                      # build the Flatpak GTK3 theme
./tweaks.sh -d                      # Dash to Dock styling
```

`tweaks.sh -d` does exactly two things, and it is worth knowing because it does
not survive a package update: it moves Dash to Dock's own `stylesheet.css` aside
to `stylesheet.css.bak` so the shell theme's dock rules win, and it sets
`apply-custom-theme true`. Dash to Dock is an RPM under `/usr/share`, so this
needs root, and any `dnf reinstall`/upgrade of that package restores the
stylesheet and silently un-themes the dock. Re-run `./tweaks.sh -d` when that
happens.

Then let Flatpak apps see the config:

```sh
sudo flatpak override --filesystem=xdg-config/gtk-3.0 --filesystem=xdg-config/gtk-4.0
```

> Caveat I hit: `tweaks.sh -F` installs the GTK3 theme into the **user** Flatpak
> installation. A **system**-installed Flatpak app cannot see it, so it stays
> unthemed. Either install those apps `--user`, or install the theme bundles
> system-wide from `~/.cache/pakitheme/`. GTK4/libadwaita Flatpaks are fine
> either way, because they pick the theme up through the `xdg-config/gtk-4.0`
> override above.

Optional, not applied on this machine:

```sh
./tweaks.sh -f monterey   #broke for my setup(search and tab overlapped despite buffer applied) # Firefox; needs toolkit.legacyUserProfileCustomizations.stylesheets=true
sudo ./tweaks.sh -g       # GDM theme -- deliberately NOT applied here
```

### 3. Icons and cursors

```sh
git clone https://github.com/vinceliuice/WhiteSur-icon-theme.git --depth=1
cd WhiteSur-icon-theme && ./install.sh        # -> ~/.local/share/icons

git clone https://github.com/vinceliuice/WhiteSur-cursors.git --depth=1
cd WhiteSur-cursors && ./install.sh
```

Run as your user, not root, and they land in `~/.local/share/icons`. Run them
with `sudo` instead if you want the cursor to apply at the GDM login screen too.

### 4. Search Light

```sh
git clone https://github.com/icedman/search-light && cd search-light && make
```

Installs to `~/.local/share/gnome-shell/extensions/search-light@icedman.github.com`.
**Log out and back in before enabling it** — Wayland can't reload the shell in
place.

### 5. Wallpaper

```sh
mkdir -p ~/Pictures/Wallpapers && cd ~/Pictures/Wallpapers
curl -O https://raw.githubusercontent.com/vinceliuice/WhiteSur-wallpapers/main/2k/WhiteSur-dark.jpg
curl -O https://raw.githubusercontent.com/vinceliuice/WhiteSur-wallpapers/main/2k/WhiteSur-light.jpg
```

2k, not 4k — this panel is 1080p, so 2560x1440 downscales cleanly and 4k just
wastes disk. The Sonoma wallpapers in that repo are 3840x3840 (square) and crop
badly on 16:9.

### 6. Settings

```sh
./gsettings.sh
```

Applies every changed key explicitly. Then log out and back in.

To see what this setup actually changes versus a stock GNOME install:

```sh
# everything you have set that differs from the schema defaults
gsettings list-recursively | sort > /tmp/mine.txt
dconf dump /org/gnome/ > /tmp/gnome-now.ini
diff /tmp/gnome-now.ini dconf/gnome.ini
```

`dconf/` holds the captured state: `gnome.ini` (everything under `/org/gnome/`),
`extensions.ini`, `search-light.ini`, `media-keys.ini`. To restore wholesale
rather than key-by-key: `dconf load /org/gnome/ < dconf/gnome.ini`.

## Extensions

```
user-theme@gnome-shell-extensions.gcampax.github.com    (Fedora RPM)
dash-to-dock@micxgx.gmail.com                           (Fedora RPM)
blur-my-shell@aunetx                                    (Fedora RPM)
search-light@icedman.github.com                         (built from source)
media-controller@naimur                                 (pre-existing)
just-perfection-desktop@just-perfection                 (Fedora RPM)
background-logo@fedorahosted.org                        (pre-existing, Fedora)
```

Settings for all of them are in `dconf/extensions.ini`. Search Light's schema is
not in the system path, so reading it needs
`--schemadir ~/.local/share/gnome-shell/extensions/search-light@icedman.github.com/schemas`.
`gsettings.sh` handles that.

Key bindings worth knowing:

| key | does |
|---|---|
| `Super+Space` | Search Light |
| `Super+Return` | kitty |
| `Super+Shift+M` | toggle animations (`bin/toggle-animations`) |
| `Super+Shift+P` | toggle the panel between 60 Hz and 144 Hz (`bin/toggle-refresh-rate`) |
| `Super+Shift+K` | toggle sleep inhibit -- caffeine (`bin/toggle-sleep`) |
| `Super+Shift+S` | rectangular snip -- GNOME's screenshot UI (`Print` also works) |
| `Super` alone | nothing — deliberately freed |

## Refresh rate

The BOE094D panel in this laptop is **144 Hz**, and Fedora came up on the 60 Hz
mode -- `1920x1080@144.003` is flagged `is-preferred` by the panel's own EDID
while `1920x1080@60.001` was the one mutter had selected. If the desktop ever
feels vaguely sluggish for no reason you can measure, check this first.

There is no gsettings key for refresh rate. The tool for it is **`gdctl`**,
which ships inside mutter itself (GNOME 48+) -- `rpm -qf $(which gdctl)` says
`mutter`, so there is nothing to install. `bin/toggle-refresh-rate` is a thin
wrapper over it.

```sh
gdctl show         # current mode, scale, layout
gdctl show -m      # every mode the panel offers
gdctl set --persistent --logical-monitor --primary \
          --monitor eDP-1 --mode 1920x1080@144.003
```

`--persistent` writes the choice to `~/.config/monitors.xml` so it survives a
reboot; without it the mode reverts on its own.

Two things the wrapper handles that a bare `gdctl set` does not:

- **`gdctl show -m` replaces the `Current mode` line with the mode list**, so
  neither view has everything. Reading the current mode *and* the available
  modes needs both calls.
- **`gdctl set` rebuilds the logical monitor from the flags you pass**, so a
  non-default `--scale` silently resets to 1.0 if you leave it out. The script
  reads the live scale and passes it back.

`monitors.xml` is NOT committed -- it names the panel by vendor/product/serial
and is meaningless on any other machine.

## Workspace indicator

Four static workspaces, and the indicator for them is the dots in the top-left
panel corner. Getting those to show took two changes that fight each other:

- **Just Perfection's `activities-button` must be `true`.** In GNOME 45+ that
  element *is* the workspace indicator. gnomintosh sets it `false` for the
  macOS look, which silently takes the dots with it.
- **WhiteSur blanks the dots anyway.** Its `gnome-shell.css` swaps the button
  for a static `activities.svg` and sets
  `.workspace-dot { background-color: transparent }`.

`bin/patch-shell-theme` appends a marker-delimited override that drops the
static icon, gives the dots a colour, **and a size**.

The size is the part that is easy to get wrong. A gnome-shell user theme
*replaces* GNOME's stylesheet rather than cascading on top of it, so while
WhiteSur is active GNOME's own `.workspace-dot` rule — the one carrying
`min-width`/`min-height` — is never loaded. WhiteSur's only rule sets
`background-color`. Colour alone therefore leaves the dots at 0×0 and the whole
button collapses to nothing: an empty panel corner, with no error anywhere.

The colour is solid `#ffffff`, not a translucent white, because the shell
already fades them itself. From `WorkspaceDot._updateVisuals()` in
`libshell-18.so`:

```js
const INACTIVE_WORKSPACE_DOT_SCALE = 0.75;
opacity: Util.lerp(0.50, 1.00, expansion) * 255,
scaleX:  Util.lerp(INACTIVE_WORKSPACE_DOT_SCALE, 1.00, expansion),
```

Inactive dots render at 50% opacity and 0.75 scale; the active one is full
opacity, full scale, and widened into a pill. Baking alpha into the CSS colour
gets multiplied by that 0.50 and comes out muddy. It also means **the macOS
look is native** — that 0.50/0.75 fade is the Launchpad page-dot idiom, so it
only needed a solid colour and a size to work from. White matches WhiteSur's
own `#panel { color: white }`, and 7px sits right in its 28px panel.

```sh
patch-shell-theme            # apply (idempotent)
patch-shell-theme --status   # is it applied?
patch-shell-theme --revert   # take it back out
```

It reloads the stylesheet by bouncing `user-theme name`, since Wayland cannot
restart the shell in place.

**Re-run it after any WhiteSur reinstall** — `install.sh` rewrites
`gnome-shell.css` wholesale, exactly like `tweaks.sh -d` has to be re-run after
a Dash to Dock package update. `gsettings.sh` calls it for you.

## Screenshots

`Super+Shift+S` is bound to GNOME's own screenshot UI, which opens in
region-select mode — drag a rectangle, and it goes to the clipboard *and* to
`~/Pictures/Screenshots`. `Print` still works as well.

There is deliberately no custom snip script here, because all three of the
obvious approaches are dead ends on GNOME:

| approach | why not |
|---|---|
| `grim` / `slurp` | need `wlr-screencopy` and `wlr-layer-shell`, wlroots protocols mutter does not implement. `grim` exits with *"compositor doesn't support the screen capture protocol"* — it is installed here only as leftover from the Sway spin |
| `org.gnome.Shell.Screenshot` D-Bus | gated to privileged callers; a plain script gets `GDBus.Error:org.freedesktop.DBus.Error.AccessDenied: ScreenshotArea is not allowed` |
| `xdg-desktop-portal` | works, but `interactive: true` just opens the same GNOME UI, via a Request/Response handshake |

So the built-in *is* the answer, and rebinding it costs nothing.

## Layout

Mirrors the convention the other branches use — `config/` maps onto `~/.config`,
`bin/` onto `~/.local/bin`.

| path | goes to |
|---|---|
| `gsettings.sh` | — (run it) |
| `dconf/` | — (reference dumps) |
| `bin/toggle-animations` | `~/.local/bin/` |
| `bin/toggle-refresh-rate` | `~/.local/bin/` |
| `bin/toggle-sleep` | `~/.local/bin/` |
| `bin/patch-shell-theme` | `~/.local/bin/` |
| `config/gtk-4.0/settings.ini` | `~/.config/gtk-4.0/` |
| `config/gtk-3.0/settings.ini` | `~/.config/gtk-3.0/` |
| `config/kitty/` | `~/.config/kitty/` |

Every `bin/` toggle takes the same flags, so they are usable from a script or a
bar module as well as from a keybind:

```
-n, --notify   desktop notification (default)
-q, --quiet    change it, say nothing
-p, --print    print the new state to stdout
-s, --status   report state, change nothing   (toggle-sleep, toggle-refresh-rate)
-h, --help
```

Notifications carry `x-canonical-private-synchronous`, so holding a key down
replaces the banner rather than stacking a queue of them.

`gsettings.sh` is the same idea as the `laptop` branch's script of that name,
but it does more than gsettings: it also re-registers the custom keybindings
(appending, so it will not clobber existing ones) and recreates the GTK4
symlinks that actually apply the theme.

kitty is themed to match: `config/kitty/themes/macos.conf` is a palette built
from Apple's published system colours rather than the literal Terminal.app ANSI
set, because Terminal.app's blue is `#492ee1` and sits at about 1.6:1 on a dark
background. `current-theme.conf` is a copy of it; the other palettes live on `main` and are not carried here.

---

I'm sick of doing this from scratch every time I reinstall. That's the whole
point of this branch — next time it's a clone and one script, not an afternoon.

And no, I don't care that AI wrote the commits and the readme(edited heavily by me). I can't be bothered
to type all this out when automation exists.
