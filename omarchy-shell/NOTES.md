# Standalone omarchy-shell on CachyOS

Working notes on the Omarchy 4 "Quattro"
desktop shell running on this machine, which is **CachyOS + Hyprland, not
Omarchy**. Nothing here was installed by Omarchy's installer; it was assembled
by hand and it is not a configuration upstream supports or tests.

---

## Background: why this exists

Omarchy used **Waybar** through v3.8.4 (last v3 release, 2026-07-21). On
2026-05-14 a commit titled *"Remove waybar; relocate bar helper scripts into
the shell tree"* deleted the waybar package, its configs, its indicator
scripts, and the `omarchy-{toggle,restart,refresh}-waybar` binaries. Omarchy
**4.0.0 "Quattro"** (2026-08-14) ships `omarchy-shell` instead: one
long-running Quickshell (QML) process that absorbed the bar, launcher, menus,
notifications, OSDs, control panels, lock screen and polkit agent — replacing
Waybar, Walker, Mako, SwayOSD, hyprlock, hypridle, swaybg and polkit-gnome.

The goal here was to run *that shell*, unmodified, on CachyOS. So this is the
real upstream QML tree — not a reimplementation.

**Detached from upstream on 2026-09-04.** `~/.local/share/omarchy` was a live
git clone until then, hard-reset to `origin/quattro` on every update (last
commit taken: `f99d33a8`, 2026-09-03). It is now a pruned, self-owned vendored
tree: no `.git`, no remote, no migrations, and the self-update pipeline
(`omarchy-update` and its ~24 helper scripts) deleted outright. That closes a
real hazard, not just a preference: upstream's `omarchy-update-dev` ran
`git pull --ff-only` against any tracked `$OMARCHY_PATH`, so a stray click of
the in-shell Update widget could silently re-pull even after our own updater
stopped pulling. `bin/` is otherwise kept **wholesale** — the menu JSONC
references ~170 scripts and the `omarchy` dispatcher builds its command table
by scanning `bin/` at runtime, so any allowlist prune breaks things for a
saving of ~2M. The full pre-detach clone sits at
`~/.local/share/omarchy.pre-migration-backup` until burn-in is done.

One thing survived the rewrite: custom bar widgets still parse **Waybar-style
JSON** (`{text, class, tooltip}`). See `shell/Commons/Util.qml:78`. Old Waybar
module scripts still work.

---

## Status

**The shell is running.** Verified: pid 3305,
`quickshell -n -p ~/.local/share/omarchy/shell`, launched via
`~/.local/bin/omarchy-shell-run`.

Everything else was verified statically: all JSON parses, both QML modules
(`Commons/qmldir`, `Ui/qmldir`) resolve, 29 plugin manifests present, all Qt6
deps installed, the fontconfig alias resolves, and the `omarchy-*` CLI runs
correctly under the launcher environment.

### The package matters: `quickshell-git`, not `quickshell`

This is the one thing that is easy to undo by accident.

| | |
|---|---|
| **works** | `quickshell-git` (AUR, built locally) |
| **does not work** | `quickshell 0.3.1-1.1` (from `cachyos-extra-v3`) |

### Two different symbol errors — read the version node

Both failures print the same mangled symbol. Only the trailing **version node**
tells them apart, and they have completely different fixes:

```
symbol lookup error: undefined symbol:
_ZN23QUntypedPropertyBindingC1EP23QPropertyBindingPrivate, version Qt_6
                                                                   ^^^^
```
**`version Qt_6` — wrong package.** The `cachyos-extra-v3` `quickshell` build
wants the symbol at node `Qt_6`, but `libQt6Core.so.6` only exports it at
`Qt_6_PRIVATE_API`. Fix: install `quickshell-git` instead. Not caused by
anything here — bare `quickshell --version` in a clean `env -i` fails the same.

```
symbol lookup error: quickshell: undefined symbol:
_ZN23QUntypedPropertyBindingC1EP23QPropertyBindingPrivate, version Qt_6_PRIVATE_API
                                                                   ^^^^^^^^^^^^^^^^
```
**`version Qt_6_PRIVATE_API` — right package, stale build.** Quickshell links
Qt's *private* API, and upstream Qt does not keep that ABI stable even across
patch releases. Any `pacman -Syu` that moves `qt6-base` breaks the installed
build. Fix: **rebuild the package**, nothing else works.

```bash
yay -S --rebuild quickshell-git   # ~5 min
omarchy-shell-run &
```

Observed 2026-08-23: `qt6-base 6.11.1-1.1 -> 6.11.2-2.1` in a routine `-Syu`
killed a quickshell built two days earlier. A patch-level Qt bump is enough.
Expect this on roughly every Qt update until quickshell reaches a binary repo.

The AUR package installs `/usr/share/libalpm/hooks/quickshell-check.hook`,
which runs `quickshell --private-check-compat` after any `qt6-base` or
`qt6-wayland` upgrade — but its output scrolls past in the `-Syu` transaction
and is easy to miss. `resync.sh` runs the same check and reports it as the last
line of the run, where it cannot scroll off.

`quickshell-git` moves independently of the omarchy repo, so `resync.sh`
records its version — and `qt6-base`'s — in `state/update.log` on every run.

---

## How it works

The whole thing hinges on one indirection. `shell/shell.qml` resolves
everything it needs from the `OMARCHY_PATH` environment variable:

```qml
property string omarchyPath: Quickshell.env("OMARCHY_PATH")
readonly property string shellPath: omarchyPath + "/shell"
readonly property string firstPartyPluginsDir: shellPath + "/plugins"
readonly property string defaultsPath: omarchyPath + "/config/omarchy/shell.json"
readonly property string userConfigPath: home + "/.config/omarchy/shell.json"
```

So a full repo checkout plus that one variable is sufficient — no system
install, no root, nothing in `/usr`. The launcher sets `OMARCHY_PATH`, puts
`$OMARCHY_PATH/bin` on `PATH`, and execs `quickshell -n -p $OMARCHY_PATH/shell`.

Config resolution: a valid user `shell.json` (with `"version": 1`) **replaces**
the repo default entirely. There is **no deep merge** — see `applyShellConfig()`
in `shell.qml`. Both files are watched, so edits apply live.

---

## Layout

```
~/.local/share/omarchy/            21M  pruned vendored tree, NO .git
  ├─ shell/                        175 files — the QML shell, kept in full
  │   ├─ shell.qml                 entry point
  │   ├─ Commons/  Ui/             singletons (Color, Style) + widget library
  │   ├─ plugins/                  29 plugins, each with manifest.json
  │   └─ services/                 PluginRegistry, BarWidgetRegistry, AppLibrary
  ├─ bin/                          420 omarchy-* scripts — wholesale, minus the
  │                                24-script self-update/migration pipeline
  ├─ default/                      templates (shell.toml.tpl …), menu JSONC,
  │                                glyph font, stock hypr config — in full
  ├─ config/                       vendored default shell.json
  └─ themes/                       catppuccin, solitude, tokyo-night only
                                   (the 19 others were never used here;
                                   pull one back from upstream if wanted)

  gone entirely: .git (210M), migrations/, install/, etc/, applications/,
  agents/, manual/, docs/, plans/, test/ — Omarchy-the-distro machinery

~/.local/share/omarchy.pre-migration-backup/   287M  full pre-detach clone,
                                   kept until burn-in is done, then delete

~/.config/omarchy/
  ├─ shell.json                    bar layout + idle timings   [COPIED]
  ├─ fontconfig.conf               scoped Nerd Font alias      [AUTHORED]
  ├─ themed/walker.css.tpl         walker stylesheet source    [AUTHORED]
  ├─ themed/waybar.css.tpl         waybar palette source       [AUTHORED]
  ├─ hooks/theme-set.d/walker-css  runs the walker sync        [AUTHORED]
  ├─ hooks/theme-set.d/kitty-theme runs the kitty sync         [AUTHORED]
  ├─ themes/  backgrounds/         empty user overlay dirs
  └─ plugins/                      third-party plugin dir (scanned by registry)

~/.local/state/omarchy/current/
  ├─ theme/                        ~25 files                   [GENERATED]
  │   └─ shell.toml                the file the shell reads
  ├─ theme.name
  └─ background -> theme/backgrounds/...

~/.local/share/fonts/omarchy/omarchy.ttf    menu glyph font    [COPIED]
~/.local/bin/omarchy-shell-run              launcher           [AUTHORED]
~/.local/bin/omarchy                        CLI shim           [AUTHORED]
~/.local/bin/omarchy-walker-theme-sync      walker stage 2     [AUTHORED]
~/.local/bin/omarchy-kitty-theme-sync       kitty palette      [AUTHORED]
~/.local/bin/omarchy-shell-update           -> resync.sh       [SYMLINK]

~/.config/walker/
  ├─ config.toml                   walker's own config     [AUTHORED, not in pipeline]
  └─ themes/omarchy/style.css      rendered stylesheet         [GENERATED]

~/.config/kitty/current-theme.conf          terminal palette   [GENERATED]
~/.config/btop/themes/current.theme -> current/theme/btop.theme  [SYMLINK]

~/help.sh                          command reference       [AUTHORED]

~/dotfiles/                        the repo — single source of truth
  ├─ bin/                          AUTHORED scripts, symlinked to ~/.local/bin
  │   ├─ omarchy-shell-run
  │   ├─ omarchy
  │   ├─ omarchy-walker-theme-sync
  │   └─ omarchy-kitty-theme-sync
  ├─ config/omarchy/               symlinked to ~/.config/omarchy
  │   ├─ fontconfig.conf
  │   ├─ themed/walker.css.tpl
  │   ├─ themed/waybar.css.tpl
  │   ├─ hooks/theme-set.d/walker-css
  │   └─ hooks/theme-set.d/kitty-theme
  ├─ config/hypr/conf/themes/      per-theme look overrides, by theme slug
  ├─ config/kitty/themes/          per-theme terminal palettes, by theme slug
  └─ omarchy-shell/                this folder
      ├─ NOTES.md
      ├─ resync.sh                 was update.sh until 2026-09-04
      └─ state/                    written by resync.sh
          ├─ last-known-good       stale — SHA from the pulled era
          └─ update.log            one line per run
```

The four provenance classes matter for updating — see below.

---

## The authored files (not from Omarchy)

Ten files were written by hand rather than coming from the repo. They live in
the dotfiles repo and are **symlinked** into place by `install.sh`, so the repo
plus the vendored tree really is enough to rebuild the setup:

| in the repo | symlinked to |
|---|---|
| `bin/omarchy-shell-run` | `~/.local/bin/omarchy-shell-run` |
| `bin/omarchy` | `~/.local/bin/omarchy` |
| `bin/omarchy-walker-theme-sync` | `~/.local/bin/omarchy-walker-theme-sync` |
| `bin/omarchy-kitty-theme-sync` | `~/.local/bin/omarchy-kitty-theme-sync` |
| `bin/omarchy-sidra-theme-sync` | `~/.local/bin/omarchy-sidra-theme-sync` |
| `config/omarchy/fontconfig.conf` | `~/.config/omarchy/fontconfig.conf` |
| `config/omarchy/themed/walker.css.tpl` | `~/.config/omarchy/themed/walker.css.tpl` |
| `config/omarchy/hooks/theme-set.d/walker-css` | `~/.config/omarchy/hooks/theme-set.d/walker-css` |
| `config/omarchy/hooks/theme-set.d/kitty-theme` | `~/.config/omarchy/hooks/theme-set.d/kitty-theme` |
| `config/omarchy/hooks/theme-set.d/sidra-theme` | `~/.config/omarchy/hooks/theme-set.d/sidra-theme` |

The last five need no link of their own: `config/omarchy/` is itself the
symlink for `~/.config/omarchy`, so they are already live where they sit.

Until 2026-09-06 these were **copies**: `resync.sh` section 2 held a
`sync_file` helper that re-deployed all six on every run, diffed any drift and
backed up before overwriting. Three of them were being copied repo → repo,
which never did anything. That is all gone — a symlink cannot drift, and the
repo is under git, so `git status` is the drift detector. Section 2 now only
checks the six are present (`-e`, so a dangling link fails too) and points at
`install.sh` if not.

Order still matters, but for rendering, not deployment: `walker.css.tpl` is
the input to the section 4 theme render, `omarchy-walker-theme-sync` finishes
it in section 4b, `omarchy-kitty-theme-sync` regenerates the terminal palette
in section 4d and `omarchy-sidra-theme-sync` the Sidra palette in 4e.

`~/.config/walker/config.toml` is authored too but is deliberately **not**
part of this pipeline — it is walker's own config, and having the resync
touch it would be surprising.

### `bin/omarchy-shell-run`

Sets `OMARCHY_PATH`, prepends `bin/` to `PATH`, sets `FONTCONFIG_FILE`,
sets `QS_DISABLE_FILE_WATCHER=1` and `QS_NO_RELOAD_POPUP=1` (mirroring
upstream `bin/omarchy-launch-shell`, which disables Quickshell's own hot
reload because Omarchy restarts the shell deliberately), then execs
`quickshell -n -p "$OMARCHY_PATH/shell"`.

### `config/omarchy/fontconfig.conf`

The bar draws its icons through the fontconfig `monospace` alias. On this
machine `monospace` resolves to **Noto Sans Mono**, which has no Nerd Font
glyphs — the bar would render tofu.

Upstream's fix is `omarchy-font-set`, which **overwrites
`~/.config/fontconfig/fonts.conf` wholesale**. That file here contains this
machine's KDE oblique/emboldening rules, which that would have destroyed.

So instead the same `prepend_first` rule lives in a separate file loaded via
`FONTCONFIG_FILE` in the launcher — scoping the Nerd Font to the shell process
only:

```
inside the shell   monospace -> JetBrainsMono Nerd Font
system-wide        monospace -> Noto Sans Mono   (unchanged)
```

If you ever want the change globally, that is what `omarchy font set` does —
but it will eat the KDE rules.

---

## The theme pipeline

The shell does **not** read a theme directly. `Commons/Color.qml` reads:

- `~/.local/state/omarchy/current/theme/colors.toml` — foundational palette
- `~/.local/state/omarchy/current/theme/shell.toml` — per-surface roles
- `~/.config/omarchy/shell.toml` — optional machine-level override

`shell.toml` is **generated** by `omarchy-theme-set-templates`, which
substitutes `{{ token }}` placeholders in `default/themed/shell.toml.tpl`
against the theme's `colors.toml`. The engine is sed: line 200 of that script
builds one `s|{{ key }}|value|g` rule per colour, plus `_strip` and `_rgb`
variants, then applies the whole script to every `*.tpl`.

Two conditions silently skip templating entirely — worth knowing before
debugging a theme that looks wrong:

- **A theme shipping its own output file wins.** `omarchy-theme-set-templates:396`
  only writes `$output_path` `if [[ ! -f $output_path ]]`, and theme dirs are
  copied into the staging dir first. A theme carrying `themes/<name>/shell.toml`
  therefore bypasses the template completely.
- **No `colors.toml`, no templating.** The whole generation block is wrapped in
  `if [[ -f $COLORS_FILE ]]` (`:371`). Themes with only an `alacritty.toml` get
  a `colors.toml` synthesised first by `omarchy-theme-colors-from-alacritty`.

Per-section overrides (`shell.<section>.toml` in a theme dir) are merged in
afterwards by `apply_shell_section_overrides`.

Themes are applied with:

```bash
OMARCHY_THEME_HEADLESS=1 omarchy-theme-set "Tokyo Night"
```

`OMARCHY_THEME_HEADLESS=1` is essential here and is the same flag Omarchy's
own installer uses (`install/user/theme.sh:7`). Without it, `omarchy-theme-set`
runs post-hooks that retint the terminal, btop, VSCode, Obsidian, Claude, and
the browser — i.e. it reconfigures apps that have nothing to do with the shell.
Headless mode writes only the theme state and the background symlink.

The template engine writes exclusively into the staging dir
(`current/next-theme`), which is then atomically moved into place, so it
cannot clobber anything else.

### Third-party themes

Install them with `resync.sh`, which accepts a git URL wherever it accepts a
theme name:

```bash
omarchy-shell-update --theme https://github.com/SeanAnd/omarchy-cyberpunk-theme.git
```

That clones to `~/.config/omarchy/themes/<name>` and applies it in one headless
pass. The name is derived with upstream's exact rules
(`omarchy-theme-install:30-33`) — basename, drop `.git`, strip a leading
`omarchy-` and a trailing `-theme`, lowercase — so a theme installed either way
lands in the same directory.

### A cloned theme is only partly trusted

`omarchy-theme-set` **refuses** some of what an installed (git-cloned) theme
ships, and says so on every switch:

```
Ignored in ~/.config/omarchy/themes/rainynight: alacritty.toml ghostty.conf
hyprland.lua kitty.conf neovim.lua vscode.json
A theme installed from a git repo cannot supply Lua, a terminal config, or vscode.json.
```

The rule is every `.lua` file plus `alacritty.toml`, `foot.ini`, `ghostty.conf`,
`kitty.conf` and `vscode.json` (`omarchy-theme-set:30`, `:142`). It is a sound
rule: theme Lua would execute inside the compositor, and a terminal config can
name the program the terminal launches. A built-in theme is not affected —
those files are trusted, and for a theme that ships none of them the generic
templates render equivalents from `colors.toml` anyway.

The consequence is that a cloned theme whose *look* lives in those files will
not look like its own screenshots. rainynight is the case in point: its
`hyprland.lua` carries rounding 14, a bright blur and 0.93 opacity, and its
`kitty.conf` carries a grey-blue terminal palette quite unlike its
`colors.toml`. Both were refused, so the desktop kept square opaque windows and
whatever `kitten themes` last wrote.

Fix, where it matters: read the refused file, review it, and vendor the values
into this repo, where they are ours and have been read.

| vendored to | supplies |
|---|---|
| `config/hypr/conf/themes/<slug>.lua` | rounding, blur, opacity, borders — merged over `conf/theme.lua` while that theme is active |
| `config/kitty/themes/<slug>.conf` | terminal palette, appended after the generated one so it wins |

Both are keyed on the theme slug, so a theme with no override just gets the
generic theme-derived look. Never copy a refused file in wholesale — the whole
point is that it has been read first.

**Do not use `omarchy-theme-install` here.** Its last line is a bare
`omarchy-theme-set "$THEME_NAME"` with no `OMARCHY_THEME_HEADLESS=1`, so it
fires all 14 app-retint post-hooks including `omarchy-theme-set-browser`, which
writes managed-policy JSON into root-owned `/etc/*/policies/managed`. The
`--theme <url>` path exists precisely to avoid that.

**Install is one-time.** A theme already present is applied as-is: no fetch, no
pull, no reset, no delete. `resync.sh` runs zero git commands against an
existing theme directory. To take a theme's upstream changes:

```bash
rm -rf ~/.config/omarchy/themes/<name>
omarchy-shell-update --theme <url>
```

`omarchy-theme-update` (upstream's `git -C … pull` over every git theme) will
**fail** on both themes here — the walker rename below leaves the tree dirty.
That is fine; it is the same one-time contract stated a different way.

`--theme` rejects a value starting with `-` or matching `<helper>::<address>`
before anything is fetched, whether or not it looks like a URL. `ext::sh -c …`
is arbitrary command execution at clone time, and neither form is recognised as
a URL, so the guard runs on the raw argument rather than inside the URL branch.

#### Installed here

| | `rainynight` | `cyberpunk` |
|---|---|---|
| source | [atif-1402](https://github.com/atif-1402/omarchy-rainynight-theme) | [SeanAnd](https://github.com/SeanAnd/omarchy-cyberpunk-theme) |
| installed | 2026-08-24 | 2026-08-24 |
| `background` | `#1e1e2e` | `#200000` |
| `foreground` | `#cdd6f4` | `#ff4040` |
| `accent` | `#89b4fa` | `#26bdfd` |

**rainynight's palette is Catppuccin Mocha** — base/text/blue verbatim. Its
character is in the wallpapers and app configs, not the shell colours; do not
expect the bar to look different from `catppuccin`.

**cyberpunk's `foreground` is bright red**, so all shell body text is `#ff4040`
on near-black `#200000`, with cyan accents. That is the theme working as
designed, not a fault.

#### Every third-party theme ships a `walker.css`, and it must be moved aside

`omarchy-theme-set-templates:396` writes a template's output only
`if [[ ! -f $output_path ]]`, and theme files are staged *before* templating. A
theme carrying `walker.css` therefore suppresses
`~/.config/omarchy/themed/walker.css.tpl` completely.

Both themes ship one, and both are **partial** — colours only, no layout:

| theme | lines | styles |
|---|---|---|
| rainynight | 46 | `.search`, `.search-container`, `.box-wrapper`, `child:selected` |
| cyberpunk | 30 | `window`, `.box-wrapper`, `.search-container`, `child:selected .item-box` |

Neither sets a row height, padding, icon size or radius. They were written for
Omarchy 3, where Walker was *the* launcher and omarchy supplied a full base
stylesheet underneath. Letting either win drops Walker back to stock GTK layout
— which is exactly what "the theme didn't apply, it's still default" looked
like when it was first diagnosed.

So `resync.sh` section 3b renames a shipped `walker.css` to
`walker.css.theme-shipped` on every run, idempotently, for any theme resolving
into `~/.config/omarchy/themes/`. Renamed, not deleted — `git checkout
walker.css` in the theme dir restores the author's version to compare.
rainynight also carries a hand-written `WALKER-NOTE.md` saying the same thing.

#### Upstream refuses some theme files

`omarchy-theme-set:30` holds the denylist:

```bash
INSTALLED_THEME_DENIED=(alacritty.toml foot.ini ghostty.conf kitty.conf vscode.json)
```

plus anything matching `*.lua` (`is_denied_installed_file:140`), plus **any
symlink** inside the theme (`stage_installed_theme:218`). The rest are named on
stderr:

```
Ignored in ~/.config/omarchy/themes/cyberpunk: neovim.lua vscode.json
A theme installed from a git repo cannot supply Lua, a terminal config, or vscode.json.
```

Deliberate upstream restriction, not a broken theme — an extra theme may not
ship executable Lua or hijack a terminal/editor config. Everything else is
staged normally: `colors.toml`, `backgrounds/`, `hyprlock.conf`, `waybar.css`,
`btop.theme`, `gtk.css`, and `mako.ini` and `swayosd.css` too, though neither of
those has a reader here any more.

One exception worth knowing: `alacritty.toml` is denied as a *file* but still
read for its palette. `stage_installed_colors_from_alacritty` copies it into a
scratch dir and synthesises a `colors.toml` from it when the theme has none.
That is why section 3b's "no palette" warning accepts either file.

### `theme.name` holds a slug

`~/.local/state/omarchy/current/theme.name` does **not** hold a display name.
`omarchy-theme-set:125` lowercases its argument and replaces spaces with
hyphens before anything else, and writes that slug at `:168`:

```
"Tokyo Night"  ->  tokyo-night
```

`resync.sh` reads that file to preserve your active theme across updates, which
is safe only because slugifying a slug is idempotent. Do not "fix" it into a
display name.

Active theme at time of writing: **solitude** (started as Tokyo Night, briefly
catppuccin). Read it, do not assume it — `cat ~/.local/state/omarchy/current/theme.name`.

---

### Neovim (LazyVim) follows the theme through one symlink

```
~/.config/nvim/lua/plugins/theme.lua
  -> ~/.local/state/omarchy/current/theme/neovim.lua   (absolute)
```

That target is **a LazyVim plugin spec, not a colour file**. It pins
`bjarneo/aether.nvim` (branch `v3`), passes the theme's palette as `opts.colors`,
and sets `colorscheme = "aether"` on `LazyVim/LazyVim`. Omarchy regenerates it on
every theme change from `default/themed/neovim.lua.tpl`, so the link is the
entire integration — nothing to copy, nothing to re-render, no second stage
(unlike walker).

The absolute spelling is deliberate (since 2026-09-04, when the nvim config
moved into `~/dotfiles` behind a `~/.config/nvim` symlink): a relative target
would resolve against the link's real directory inside `~/dotfiles` and
dangle. Upstream's own migration wrote a relative link, but migrations are no
longer in the vendored tree and can never run here, so nothing depends on
that spelling anymore.

`resync.sh` section 4c maintains it. Silent when already correct; it creates the
link when missing or pointing somewhere stale, **refuses to touch a regular
file** at that path (that is a hand-written colorscheme choice), and warns on a
dangling link, which is worse than no link at all — lazy.nvim errors on every
startup.

**A cloned theme's own `neovim.lua` never reaches Neovim.** `omarchy-theme-set:22`
drops every `*.lua` from a git-installed theme, because Neovim executes it at
startup. So `cyberpunk` and `rainynight` get the generated aether spec built from
their `colors.toml` rather than the spec their author shipped — same palette,
different plugin. Only built-in themes and themes you wrote by hand in
`~/.config/omarchy/themes/` supply their own.

**Neovim reads this at startup only.** A running instance keeps the old colours
after a theme switch; `:Lazy reload` will not do it either, since the palette is
baked into the plugin's `opts` at spec-evaluation time. Restart nvim.

First wiring on this machine also needs the plugin fetched once —
`nvim --headless "+Lazy! install" +qa`. It is cloned into
`~/.local/share/nvim/lazy/aether`.

---

## Sidra (Apple Music client), themed off the same pipeline

Sidra is an Electron client (`wimpysworld/sidra`, an AppImage at
`~/.local/bin/Sidra`). Its **only** extension point is a `custom-theme.json` in
its Electron userData directory, `~/.config/Sidra/`:

- `dist/customTheme.js` accepts exactly twelve hex slots — `base`, `mantle`,
  `crust`, `surface0..2`, `overlay`, `text`, `subtext1`, `subtext0`, `accent`,
  `accentHover` — each `/^#[0-9a-f]{6}$/i` and all twelve required. Anything
  else returns null and the app silently falls back to stock Apple Music.
- `dist/themeTemplate.js` renders those into an override stylesheet injected
  with `insertCSS()` on every page load.
- **There is no custom-CSS setting.** The full config key list is
  `autoUpdate.enabled`, `classical.*`, `closeToTray.enabled`, `discord.enabled`,
  `language`, `lastfm.*`, `lastPageUrl`, `musicService`,
  `notifications.enabled`, `startPage`, `storefront`, `theme`, `zoomFactor`.
  Nothing for CSS injection, animation or motion. Anything beyond colour means
  repacking `app.asar`, which `autoUpdate` would then overwrite.

Sidra **watches** the file (150ms debounce) and re-applies live, so the hook
only has to write it — no restart, no reload call.

The slot names are Catppuccin's, and the mix amounts in
`bin/omarchy-sidra-theme-sync` were tuned by feeding it Catppuccin's own
`colors.toml` and diffing against the Catppuccin Mocha palette Sidra ships in
`dist/palettes.js`. All ten structural slots land within **one** channel value
of 255, six of them exact. Change the amounts only with that comparison in hand.

`theme` must be `"custom"` in `~/.config/Sidra/config.json` for any of it to
show. That file also holds a Last.fm session key, so the sync script writes it
only when it does not exist; an existing one is edited by hand or through
Settings → Style, never rewritten wholesale.

## Walker + Elephant (launcher), themed off the same pipeline

Walker is a separate GTK4 launcher; Elephant is its backend provider daemon.
Neither is part of Omarchy. They are wired in here so a theme switch retints
them along with everything else, and so the launcher reads as the same surface
as the shell's own `apps` menu.

### The hook: `~/.config/omarchy/themed/`

`omarchy-theme-set-templates:7` reads `USER_TEMPLATES_DIR="$HOME/.config/omarchy/themed"`
in addition to the repo's `default/themed/`, and **user templates win on name
collision**. Any `<name>.tpl` dropped there is rendered to
`~/.local/state/omarchy/current/theme/<name>` on every theme change. This is the
supported extension point for theming apps Omarchy does not ship a template for
— no patching of the repo, so nothing here is lost on update.

### Two-stage render

The template engine substitutes **colours only**. `omarchy-theme-set-templates:383`
builds its sed script purely from `THEME_COLORS`, which `:380` fills from
`colors.toml` alone. Radii, font sizes and padding live in `shell.toml`'s
`[font]` / `[spacing]` and in Hyprland's `decoration:rounding` — none of which
that engine reads. So geometry gets a second pass:

```
~/.config/omarchy/themed/walker.css.tpl          template (edit this)
  │  stage 1 — omarchy-theme-set-templates, on every theme change:
  │            colour tokens, from the theme's colors.toml
  ▼
~/.local/state/omarchy/current/theme/walker.css  generated (never edit)
  │  stage 2 — ~/.local/bin/omarchy-walker-theme-sync:
  │            ui_* geometry tokens, from shell.toml + decoration:rounding
  ▼
~/.config/walker/themes/omarchy/style.css        what walker actually reads
```

**What makes this work:** sed only rewrites tokens it has a rule for, so an
unknown `{{ token }}` passes through stage 1 untouched. Every geometry token is
namespaced `ui_*`; no `colors.toml` key begins with `ui_`, so stage 1 can never
claim one by accident. Nothing in the omarchy repo is patched.

The stage-2 resolver mirrors `Commons/Style.qml:213-229` (`space`,
`spacingToken`) and `:284-340` (`fontScale`, `fontPx`, `fontToken`) exactly, and
honours the same precedence `Color.qml:202` applies — a machine-level
`~/.config/omarchy/shell.toml` wins over the theme's. **Keep the two in step**:
if upstream changes a multiplier, the launcher silently drifts again.

| token | from | at `base-size = 12` |
|---|---|---|
| `ui_rounding` | `decoration:rounding` | `0` |
| `ui_panel_padding` | `[spacing] panel-padding` | `18` |
| `ui_row_padding_x` | `[spacing] row-padding-x` | `12` |
| `ui_row_gap` | `[spacing] xs` — `Menu.qml:107` | `3` |
| `ui_row_height` | `Menu.qml:102` baseRowHeight | `50` |
| `ui_header_height` | `Menu.qml:100` headerHeight | `34` |
| `ui_icon_large` | `Style.font.iconLarge` | `18` |
| `ui_heading` | `Style.font.heading` | `16` |
| `ui_body_small` | `Style.font.bodySmall` | `11` |
| `ui_display` | `Style.font.display` | `24` |
| `ui_menu_border` | `[menu] border` | `#798186` |

Two deliberate simplifications, both noted in the script:

- **`ui_menu_border` collapses a gradient.** `[menu] border` is an indirection
  into `[hyprland]`, whose value is a Hyprland gradient
  (`"rgba(798186ee) rgba(caccccee)"`). GTK cannot paint a gradient border, so
  only the first stop is used and the alpha byte is dropped.
- **Row gap is a margin.** GtkGridView row spacing is a widget property, not
  CSS, so `ui_row_gap` is applied as `margin-bottom` on `.item-box`.

If any token fails to resolve, the script **aborts before installing**. A stray
`{{ ui_x }}` reaching GTK is a CSS parser error, and walker then degrades
silently to its stock theme — the exact failure mode that is hardest to notice.

### It must be a copy, not a symlink

Walker silently ignores a symlinked `themes/<name>/style.css`. Proven by putting
deliberately invalid CSS at that path both ways:

| style.css | GTK output |
|---|---|
| real file | `Theme parser error: style.css:1:24-25: Expected an identifier` |
| symlink | *nothing* — never read, falls back to the default theme |

There is no warning; walker just looks unthemed. If the launcher ever reverts to
its stock colors, check that this path is a regular file first.

The render is triggered from two places, because neither covers both cases:

- `~/.config/omarchy/hooks/theme-set.d/walker-css` — fires on ordinary theme
  changes (`omarchy-theme-set`, the theme switcher).
- `resync.sh` section 4b — fires on resync runs. Needed because
  `omarchy-theme-set:207` runs hooks **only when `OMARCHY_THEME_HEADLESS` is
  unset**, and `resync.sh` always sets it.

Both `exec` the same script, so there is one implementation. The hook is mode
`644` on purpose: `omarchy-hook:20` runs hooks via `bash "$hook"`, never `exec`,
so it does not need to be executable.

Walker themes **inherit the default theme**, so `themes/omarchy/` needs only
`style.css`; `layout.xml` and `item*.xml` fall back to
`/etc/xdg/walker/themes/default/` and keep tracking walker upstream (confirmed
by strace: walker probes `~/.config/walker/themes/omarchy/*.xml`, gets ENOENT,
and reads the `/etc/xdg` copies). Do not copy those in — it pins the layout.

### Known limit: the card is wider than the shell's

The shell menu card is `Style.space(300)`. Walker's is 600x570, and its list is
500px, from `width-request` / `height-request` on `BoxWrapper` and
`min-content-width` on `Scroll` in `/etc/xdg/walker/themes/default/layout.xml`.

Those are GTK **widget properties**, not CSS. `min-width` can grow a widget but
never shrink it below `width-request`, so **the width cannot be fixed from the
stylesheet**. Matching it would mean copying `layout.xml` into `themes/omarchy/`
— which pins the layout against walker upstream, per the paragraph above. That
trade was considered and declined; the launcher matches the shell in texture
(corners, type scale, density, chrome) but not in width.

### The keybind footer and F1-F4 badges are hidden

`hide_action_hints` and `hide_quick_activation` are set in
`~/.config/walker/config.toml`; the shell menu has neither. The CSS for both is
still in the template, so unhiding is a one-line revert. They are genuinely
useful affordances walker has and the shell menu lacks — this is a consistency
choice, not a verdict that they are useless.

### Services — walker is slow without them

Walker parses its CSS and builds its GTK tree once, in a background service.
Without it every launch cold-starts GTK4 **and** waits for elephant, which is
the "slow to open" symptom.

```
~/.config/systemd/user/elephant.service   written by `elephant service enable`
~/.config/systemd/user/walker.service     written here (walker ships no unit)
```

Both are `WantedBy=graphical-session.target`. Note that enabling a unit *after*
that target is already active does not start it for the current session —
elephant was found `enabled` but `inactive` for exactly this reason, with a
stray hand-started `elephant` holding the socket instead. `systemctl --user
start` once, and it comes up on its own from the next login.

Check with:

```bash
systemctl --user is-active elephant.service walker.service
walker            # a "make sure 'walker --gapplication-service' is running!"
                  # line means the client missed the service and cold-started
```

`omarchy-walker-theme-sync` restarts the walker unit via `try-restart`, which
is a no-op when the unit is stopped — so it never starts walker on a machine
where it is deliberately off.

### Install

Walker is in `cachyos` (`walker 2.17.0`). Elephant is AUR-only and versioned
separately — its 2.22.0 against walker's 2.17.0 is normal, they are different
release lines.

```bash
yay -S elephant-all      # meta: elephant + every official provider
elephant service enable  # writes ~/.config/systemd/user/elephant.service
systemctl --user start elephant.service
systemctl --user enable --now walker.service
```

`elephant service enable` must be run **as the user, not with sudo** — a
system-level unit would not inherit the session environment.

The launcher is bound in `~/.config/hypr/conf/keybinds.lua:6`, which resolves
`menu` from `~/.config/hypr/conf/programs.lua:4`:

```lua
-- programs.lua
menu = "walker",
-- keybinds.lua
hl.bind(mainMod .. " + space", hl.dsp.exec_cmd(apps.menu))
```

Those two files are hands-off from here; nothing in this folder writes them.

### Settled: config precedence and elephant's doc command

Both of these were open questions and are now answered.

**`~/.config/walker/config.toml` MERGES over `/etc/xdg/walker/config.toml`; it
does not replace it.** Walker 2.x is Rust and links the `config-0.15.19` crate —
a layered configuration source — and its binary carries `XDG_CONFIG_DIRS` and
`/etc/xdg` alongside all-optional `PartialWalker` / `PartialProviders` /
`PartialKeybinds` / `PartialShell` structs. An unset key falls through to the
system file. This is why omitting `[providers.actions]` is safe, and why
`global_argument_delimiter` matches elephant's `"#"` without appearing in the
user file at all.

**The caveat that matters:** config-rs replaces **arrays wholesale** rather than
appending. That is why the full `[[providers.prefixes]]` list has to stay
enumerated in the user config — drop one and it is gone, not inherited.

**`elephant generatedoc` does not exist.** In 2.22.0 the command is
`elephant generate doc [provider]` (alias `elephant g d`). There is also
`elephant generate config [provider]`, which materialises full default configs
and explicitly *keeps your custom config*. Six installed providers (`1password`,
`bitwarden`, `dnfpackages`, `menus`, `niriactions`, `nirisessions`) do not show
up in `elephant listproviders` here — they need a backing CLI or a different
distro/compositor.

### What walker gives you that the shell does not

Worth knowing before considering dropping it. The shell has an `apps` route
(`omarchy-menu toggle apps`, backed by `services/AppLibrary.qml`) plus
`omarchy-menu-clipboard`, `-emoji`, `-file` and `-images`. It has **no
calculator, no web search, no `>` runner and no window switcher** anywhere —
checked against every plugin, panel and route in
`default/omarchy/omarchy-menu.jsonc`. Those four are walker-only.

### The shell's own launcher API

The shell exposes plain IPC, so anything walker is bound to can be rebound to
the shell without touching QML.

**Nothing omarchy ships is on PATH here, so all of it goes through the
`omarchy` shim** (`bin/omarchy` -> `~/.local/bin/omarchy`). On a real Omarchy
box `OMARCHY_PATH` comes from the uwsm session environment and
`$OMARCHY_PATH/bin` is on PATH system-wide; on this machine `omarchy-shell-run`
scopes both to the shell process, so a terminal or a Hyprland bind sees neither.
Calling the real script directly fails — `omarchy-menu toggle apps` dies at
`exec: omarchy-shell: not found`, exit 127. The shim sets the same two variables
and hands off to `$OMARCHY_PATH/bin/omarchy`, the upstream dispatcher.

```bash
omarchy menu toggle apps            # the app launcher
omarchy menu summon apps            # open, never close-if-visible
omarchy menu close
omarchy menu refresh                # re-parse the menu JSONC

omarchy shell shell toggle omarchy.menu '{"menu":"apps"}'   # what the above runs
omarchy shell shell listPlugins                             # JSON: every plugin, id, kinds, enabled
omarchy shell shell ping
omarchy shell -q omarchy.indicators refresh                 # best-effort, never fails

omarchy                             # no args: the full command index
```

**The doubled `shell shell` is not a typo.** The first is the dispatcher route
(-> the `omarchy-shell` binary); the second is the IPC *target*. `omarchy shell
ping` sends `ping` as the target and gets a usage error.

`omarchy-shell <target> <method> [args...]` is a thin wrapper over
`qs ipc -n -p $OMARCHY_PATH/shell call`. It recovers `WAYLAND_DISPLAY` from the
compositor socket when called from a TTY or ssh, and turns quickshell's
exit-0-with-an-error-on-stdout responses (`Target not found.`,
`Not ready to accept queries yet`) into real failures. `-q` suppresses all of
that for best-effort callers. Timeout is 2s, override with
`OMARCHY_SHELL_IPC_TIMEOUT`.

Targets are the plugin ids from `listPlugins`. Every popup plugin inherits
`open`/`close`/`show`/`hide`/`toggle` from `Ui/Panel.qml:48` on the `ipcTarget`
it declares, and `shell.qml:873` adds the generic
`summon`/`hide`/`toggle`/`call`/`togglePanelAt`/`rescanPlugins`/`reloadConfig`.

**The app launcher is a menu route, not a separate plugin.** `apps` is declared
in `default/omarchy/omarchy-menu.jsonc:24` with `"provider":"apps"`, and that
provider is QML-native (`plugins/menu/Menu.qml:287`) rather than one of the bash
enumerators — rows come from `services/AppLibrary.qml` over Quickshell's
`DesktopEntries`, so they carry real icons, launch feedback and uninstall
support. Hidden entries come from `default/omarchy/launcher.hides`.

Omarchy 4's stock binds, for reference (`default/hypr/bindings/utilities.lua`):

```lua
o.bind("SUPER + SPACE",       "Omarchy menu", "omarchy-menu toggle")
o.bind("SUPER + ALT + SPACE", "Apps menu",    "omarchy-menu toggle apps")
o.bind("SUPER + ESCAPE",      "System menu",  "omarchy-menu toggle system")
```

Omarchy 4 ships **no walker at all** — the only mention left in the tree is
`omarchy-upgrade-to-quattro`, which uninstalls `omarchy-walker`, `walker` and
every `elephant-*` package and removes the walker autostart unit and pacman
hook. Walker on this box is ours, kept deliberately for the four things the
shell has no answer for (calculator, web search, `>` runner, window switcher).

---

## Resyncing — run `omarchy-shell-update` (-> `resync.sh`)

**There is no pull anymore.** The vendored tree is frozen; it changes only
when a file in it is edited by hand. What still needs a script is everything
DERIVED from or COPIED out of that tree:

1. **`shell.toml` is GENERATED** from `default/themed/shell.toml.tpl`. Edit
   the template (or any theme) and the output is stale until
   `omarchy-theme-set` re-runs.
2. **`shell.json` and the glyph font are COPIES.**
3. **The authored files** live in the repo and are SYMLINKED into place by
   `install.sh` — `resync.sh` only checks they are there.

`resync.sh` checks and re-derives all of it.

```bash
omarchy-shell-update                 # check + re-derive
omarchy-shell-update --check         # dry run, writes nothing
omarchy-shell-update --theme nord
omarchy-shell-update --theme https://github.com/user/omarchy-x-theme.git
                                     # install a theme, once, then apply it
omarchy-shell-update --reset-config  # discard your shell.json, backed up first
```

Idempotent; safe to re-run. `--rollback` is gone — there is no upstream and
no local git, so there is nothing scriptable to roll back to. Undo means the
`.pre-migration-backup` copy (while it exists) or restoring a file by hand.

`omarchy-shell-update` is a symlink in `~/.local/bin` (already on `PATH`)
pointing at `resync.sh` here — the old name, kept for muscle memory.
`./resync.sh` works identically. The script locates itself with
`readlink -f "${BASH_SOURCE[0]}"` — resolving the symlink first is required,
or `SELF_DIR` would come out as `~/.local/bin` — so the repo can be renamed
or moved without editing anything.

### Preflight

Everything the script asserts is validated **before the first mutation**. It
checks that the six authored files are installed, that the vendored tree is present and has
`shell.json` and `shell.toml.tpl`, that `omarchy-theme-set` is on `PATH`, and
that a theme is resolvable (`theme.name` present, or `--theme` passed — a
missing one is a hard error, not a silent fallback to some default theme).

**A missing tree is a hard error, not a bootstrap.** The old script cloned
upstream when `~/.local/share/omarchy` was absent; there is no upstream now,
so the error message points at `.pre-migration-backup` instead.

When `--theme` is a git URL, the name is derived and validated in preflight
too — the clone itself happens later, in section 3b, so a malformed URL fails
before anything is written. Section 3b also warns if the theme has neither
`colors.toml` nor `alacritty.toml`: without a palette
`omarchy-theme-set-templates:371` skips templating **wholesale**, which means
`shell.toml` and `walker.css` silently keep the previous theme's colours while
the run still reports success.

It also greps `bin/omarchy-theme-set` for `OMARCHY_THEME_HEADLESS` and warns
if it is gone — cheap insurance kept from the pulled era; the flag could now
only vanish through a hand-edit.

### Behaviour worth knowing

- **`shell.json` is never clobbered.** It only reports drift, since that is the
  file you customize — and the shell itself rewrites it when you change the bar
  through the UI. `--reset-config` overwrites it, with a timestamped backup.
- **Authored files cannot drift.** They are symlinks into the repo, so there
  is one copy and editing it through either path edits the same file. Git is
  the drift detector. Section 2 only verifies they are present; a dangling
  link fails the `-e` test and stops the run.
- **Locked.** `flock` on `$XDG_RUNTIME_DIR/omarchy-config-update.lock` — the
  same pattern `omarchy-theme-set:139` uses.
- **Checks the quickshell/Qt ABI.** After everything else, it compares the
  installed quickshell against the installed `qt6-base` — via
  `quickshell --private-check-compat` where available, falling back to
  comparing the package build date against the `qt6-base` install date. On a
  mismatch it prints a rebuild reminder as the very last thing on screen, with
  the exact command, preferring whichever AUR helper already has a build tree
  under `~/.cache/`. This runs in `--check` too, since it reads nothing but the
  package database. See the two-symbol-errors section above for why.
- **Logged.** Every run appends timestamp, `resync`, `quickshell-git` version,
  `qt6-base` version and theme to `state/update.log`, plus a trailing
  `REBUILD-QUICKSHELL` marker when the ABI check failed. Lines from before
  2026-09-04 carry `old -> new` commit SHAs instead — those are from the
  pulled era.

### Taking a specific upstream improvement by hand

The only sanctioned way to bring upstream code in now — no remotes, no
cherry-picks, no re-tracking:

```bash
git clone --depth 1 --branch quattro https://github.com/basecamp/omarchy.git /tmp/omarchy-upstream
diff -ru ~/.local/share/omarchy/shell /tmp/omarchy-upstream/shell | less
# copy over exactly what you want, then:
rm -rf /tmp/omarchy-upstream
```

There is no changelog upstream, so "what did they fix" only ever means reading
the diff. After copying anything under `default/themed/` or `themes/`, run
`omarchy-shell-update` to regenerate; after anything under `shell/`, restart
the shell (`pkill quickshell; omarchy-shell-run &`). Never `git init` the
vendored tree and never re-clone over it — a `.git` directory there is what
made the old self-repull hazard possible (`omarchy-update-dev` ran
`git pull --ff-only` against any tracked `$OMARCHY_PATH`; both that script and
the `.git` are gone, and both halves of that removal matter).

---

## Package redundancy

The shell subsumes a lot. Verified against Omarchy's own `retired_packages`
list in `bin/omarchy-upgrade-to-quattro` plus direct inspection of each plugin.

**Replaced** — safe to drop from `~/.config/hypr/conf/autostart.lua`:

| package | replaced by |
|---|---|
| `ashell` | `plugins/bar` |
| `hyprpaper` | `plugins/background` — native QML `Image` |
| `hyprlock` | `plugins/lock` — Quickshell session lock |
| `hypridle` | `plugins/services/idle` — native `IdleMonitor` |
| `mako` | `plugins/notifications` |
| `cliphist` | `plugins/clipboard` — own `capture.sh` + history |
| `playerctl` | `plugins/services/media` — `Quickshell.Services.Mpris` |
| `pavucontrol` | `plugins/panels/audio` |

Idle timings move into `shell.json`'s `idle` block.

**Duplication, as of 2026-09-13.** `autostart.lua` launches `omarchy-shell-run`
on line 8, and used to launch replaced daemons alongside it. Two are resolved
and two are not:

| daemon | state |
|---|---|
| `mako` | **gone** — line removed from `autostart.lua`, package uninstalled |
| `hyprpaper` | **gone** — not started, not running; `hyprpaper.conf` is dead weight |
| `hypridle` | still started (line 12) and running, alongside `plugins/services/idle` |
| `hyprsunset` | still started (line 11) and running, alongside the shell's `nightlight` IPC target |

`cliphist` (line 13) overlaps `plugins/clipboard` too, though the shell's own
capture script is the one the clipboard panel reads.

The notification case is worth understanding, because it was not what it looked
like. D-Bus name ownership is **exclusive**: only one process can own
`org.freedesktop.Notifications`, so there were never duplicate notifications.
mako simply won the race at login and the shell's notification service sat idle
and shadowed — `busctl --user call ... GetNameOwner s org.freedesktop.Notifications`
names the winner, and it was mako's PID. Killing mako handed the name to
Quickshell within the same second, no shell restart needed. Expect the same
shape from the two that remain: not double behaviour, but whichever one grabbed
the resource first silently winning.

Nothing from mako's config needed porting. The shell already implements all of
it natively:

| mako setting | shell equivalent |
|---|---|
| `default-timeout=5000`, low `3000` | `normalPopupDuration 8000` / `lowPopupDuration 5000` as floors, app-requested timeout honoured up to `maxPopupDuration 30000` |
| `[urgency=critical] default-timeout=0` | `durationFor()` returns 0 for Critical — same never-expire behaviour |
| `[mode=do-not-disturb] invisible=1` | `doNotDisturb`, with an IPC toggle and a bypass allowlist for user-action toasts |
| `anchor=top-right` | follows `bar.position` via `barPosition` / `barClearance` |
| colours, font, border | `[notifications]` in `shell.toml`, so theme-driven |
| `group-by=app-name`, `max-visible=5` | the popup stack and a 10-entry history (`historyLimit`) |

Line 17 (`polkit-kde-authentication-agent-1`) can go too — the polkit plugin
supersedes it inside Hyprland — but leave the *package* installed, see below.

**Traps — do NOT remove:**

- **`hyprsunset`** — not replaced, *driven*. `omarchy-toggle-nightlight`
  spawns it (`setsid uwsm-app -- hyprsunset`) and talks to it via
  `hyprctl hyprsunset temperature`.
- **`wl-clipboard`** — the clipboard plugin replaced cliphist's *history*, but
  its capture path is `wl-paste --watch .../capture.sh`.
- **`polkit-kde-agent`** — `pactree -r` shows **`plasma-desktop` depends on
  it**; removing it takes Plasma with it. The polkit plugin does supersede it
  inside Hyprland, so drop the `exec_cmd` line but keep the package.

For most of these the real action is editing `autostart.lua`, not
`pacman -Rns`. What matters is not running two notification daemons or two
wallpaper setters at once.

---

## Gotchas

- **`omarchy-restart-shell` will not work.** Its kill loop needs Omarchy's
  patched Quickshell build; a comment in the script notes stock 0.3.0's `kill`
  returns immediately, which is what the repos ship. Use
  `pkill quickshell; omarchy-shell-run &`. The `omarchy-shell <target> <method>`
  IPC calls are fine.
- **Hyprland is mandatory.** Five files import `Quickshell.Hyprland`, including
  `plugins/bar/Bar.qml` and `Workspaces.qml`. This will not run on another
  compositor.
- **Some widgets assume a real Omarchy install.** `omarchy.agents` looks for
  its agent configs and sits inert rather than breaking the bar.
  `omarchy.system-update` was removed from `shell.json` (both the user copy
  and the vendored default) on 2026-09-04, the same day its backing scripts
  were deleted from `bin/` — do not re-add it; clicking it would run the
  deleted `omarchy-update`.
- **Autostart is wired, but not cleaned up.** `autostart.lua:9` launches
  `omarchy-shell-run`; the superseded daemons on lines 10-17 were never
  removed. See "Currently duplicated" above.
- The tree was cut from branch **`quattro`** at `f99d33a8` (2026-09-03).
  `version` reads `4.0.0.alpha` even though v4.0.0 was released; no shell code
  reads that file, so it does not matter.
- **`quickshell-git` is not pinned by anything here**, and it is the single
  most likely cause of a broken shell. It is an AUR package linking Qt's
  private ABI, so it breaks whenever `qt6-base` moves — not when omarchy does.
  If the shell dies right after a system update, run `resync.sh` (it reports
  the ABI state) or check `state/update.log`, before suspecting the repo.
  A `pacman -Syu` that touches `qt6-base` should be assumed to require
  `yay -S --rebuild quickshell-git` afterwards.

---

## Modularity — a precise answer

The plugin system is real: 29 plugins, each with a `manifest.json` declaring
`kinds` — 12 `bar-widget`, 8 `service`, 5 `panel`, 4 `overlay`, 1 `menu`,
1 `bar` — discovered by `services/PluginRegistry.qml`, which also scans
`~/.config/omarchy/plugins` for third-party ones. That architecture is what
made lifting the shell out of Omarchy possible at all.

But Omarchy-the-distro did not become modular. The shell hard-requires
Hyprland, and between the QML, the menu JSONC (~170 script references) and the
`omarchy` dispatcher's runtime scan of `bin/`, no reliable allowlist of "just
the scripts the shell needs" exists — which is why the vendored tree keeps
`bin/` wholesale (2.4M) and prunes only the self-update pipeline, unused
themes and distro machinery. The plugins are modular *within* the shell; the
shell is not modular within Omarchy.

---

## Uninstall

```bash
rm -rf ~/.local/share/omarchy ~/.local/share/omarchy.pre-migration-backup \
       ~/.config/omarchy ~/.local/state/omarchy \
       ~/.local/share/fonts/omarchy \
       ~/.local/bin/omarchy-shell-run ~/.local/bin/omarchy \
       ~/.local/bin/omarchy-walker-theme-sync ~/.local/bin/omarchy-shell-update
fc-cache -f ~/.local/share/fonts
```

The launcher half is separate, since walker and elephant are their own packages:

```bash
systemctl --user disable --now walker.service elephant.service
rm ~/.config/systemd/user/walker.service ~/.config/systemd/user/elephant.service
systemctl --user daemon-reload
rm -rf ~/.config/walker ~/.config/elephant
yay -Rns walker elephant-all       # nothing else depends on either (pactree -r)
```

Nothing outside those paths was modified, and nothing was added to `PATH` beyond
`~/.local/bin`. Two caveats to the "clean" claim:

- **Two user services were enabled** — `walker.service` (written here) and
  `elephant.service` (written by `elephant service enable`). The block above is
  what removes them.
- **`quickshell-git`, `walker` and `elephant-all` were installed separately**
  and are not removed by the first block.

`autostart.lua:9` and `programs.lua:4` must also be reverted by hand — this
setup never edited either.
