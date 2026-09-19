# waybar

Fallback bar. The daily driver is the Quickshell shell
(`~/.local/share/omarchy`, started with `omarchy-shell-run`) — this exists for
the times that shell isn't the thing running: mid-rebuild after a `qt6-base`
bump, debugging a Quickshell problem from outside it, or just wanting a
plain-GTK bar for a minute. Nothing here starts it automatically.

## Launch

```sh
waybar
```

Waybar finds `~/.config/waybar/config.jsonc` and `~/.config/waybar/style.css`
on its own (this directory is symlinked there by `install.sh`), so no flags
are needed. To point it at a different config while testing:

```sh
waybar --config ~/dotfiles/config/waybar/config.jsonc \
       --style  ~/dotfiles/config/waybar/style.css
```

Quit with the usual `pkill waybar` or Ctrl-C in the terminal it was started
from.

## Layout

Mirrors `~/.config/omarchy/shell.json`'s `bar.layout` as closely as a Waybar
module set allows — same three columns, same rough order. `config.jsonc`
carries an `omarchy.*` comment above each module naming what it stands in
for. Two things were dropped entirely:

- `omarchy.agents` — specific to the Quickshell shell's own agent-runner
  panel; nothing in Waybar corresponds.
- `omarchy.indicators` — a bundle of manual toggles (dictation, screen
  recording, DND, night light, stay-awake, ...). Waybar has no bundle widget
  for that; `idle_inhibitor` stands in for the one toggle in that set
  (stay-awake) that has a real Waybar module.

`omarchy.menu` has no Waybar equivalent either, but rather than drop it,
`custom/launcher` just runs `walker` — the launcher this machine actually
uses — so clicking it does the same thing the shell's menu button does.

`omarchy.weather` has no built-in Waybar module; `custom/weather` shells out
to `wttr.in` on a 30-minute interval instead. `omarchy.power` has no
menu binary on this machine to call into (no `wlogout` or similar installed),
so its three click regions go straight to `loginctl`/`systemctl` rather than
the Quickshell IPC lock (`omarchy-shell lock lock`) — this bar should still
work when Quickshell itself isn't running.

## Theming

<!-- edited by claude opus 5 -->
<!-- the template/render pipeline this described is gone; colours live in
     style.css now -->

Self-contained. The `@define-color` block at the top of `style.css` is the
whole palette — rainynight's, the same values as `config/hypr/conf/palette.lua`,
`config/mako/config` and `config/hypr/hyprlock.conf`. Edit those four together;
nothing keeps them in step automatically.

This used to `@import` a file rendered from `config/omarchy/themed/waybar.css.tpl`
on every theme change. That render only ever substituted two of the ten colours
the template declared, so `@muted`, `@accent`, `@red`, `@bright_red` and
`@dark_background` were undefined the whole time it was in use.

Waybar re-reads `style.css` fully at startup, so restart it to pick up a
colour change.

Font is set explicitly to `JetBrainsMono Nerd Font` in `style.css` — this
machine's `monospace` alias resolves to Noto Sans Mono, which has none of the
glyphs the module icons need.
