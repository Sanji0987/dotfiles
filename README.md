# dotfiles

Configuration for my CachyOS box: Hyprland with Omarchy 4 "Quattro"'s
Quickshell desktop shell (run standalone, not as an Omarchy install), plus
KDE Plasma as the second session.

Everything here is symlinked into place — the repo is the single source of
truth, the home directory just points at it.

## Layout

| path | goes to | what |
|---|---|---|
| `config/hypr/` | `~/.config/hypr` | Hyprland (lua config) |
| `config/kitty/` | `~/.config/kitty` | kitty + a stack of colour schemes |
| `config/nvim/` | `~/.config/nvim` | LazyVim; colorscheme follows the desktop theme |
| `config/omarchy/` | `~/.config/omarchy` | shell.json, theme templates, hooks |
| `config/walker/` `config/elephant/` | `~/.config/…` | launcher + provider daemon |
| `config/fish/` `home/.zshrc` … | | shells (zsh + p10k is the daily driver) |
| `config/tmux/` `config/alacritty/` `config/mako/` `config/btop/` | | the usual suspects |
| `config/fontconfig/` `config/uwsm/` | | session plumbing |
| `bin/` | `~/.local/bin` | small hand-rolled scripts |
| `omarchy-shell/` | — | tooling + notes for the standalone shell — see below |
| `help.sh` | `~/help.sh` | command reference for the whole setup |

## The desktop shell

The interesting part. Omarchy 4 replaced Waybar/Walker/Mako/hyprlock/etc. with
one Quickshell (QML) process; this repo runs that shell on plain CachyOS
without any of Omarchy-the-distro. The shell tree itself lives at
`~/.local/share/omarchy` as a pruned, self-owned vendored copy (no git, no
upstream, ~21M) and is deliberately **not** in this repo —
`omarchy-shell/NOTES.md` documents the whole architecture, why it is detached,
and how to pull individual upstream fixes in by hand.

`omarchy-shell/resync.sh` (on PATH as `omarchy-shell-update`) re-derives
everything generated from that tree: theme files, the walker stylesheet, the
neovim colorscheme link and the glyph font. The launcher, CLI shim and walker
sync in `bin/` are symlinked into `~/.local/bin` by `install.sh`, not copied.

One theme change retints the shell, walker, kitty-adjacent terminals, btop and
neovim from a single `colors.toml`.

## Install

```sh
git clone https://github.com/Sanji0987/dotfiles ~/dotfiles
~/dotfiles/install.sh
```

`install.sh` only creates symlinks and refuses to overwrite anything that
already exists — it tells you what is in the way instead. The shell tree and
AUR packages (`quickshell-git`, `elephant-all`, `walker`) are separate; the
script prints what else is needed at the end.

## Notes

- `quickshell-git` links Qt's private ABI and must be rebuilt after most
  `qt6-base` updates (`yay -S --rebuild quickshell-git`). `resync.sh` checks
  and warns about this on every run.
- Third-party shell themes are one-time clones into
  `config/omarchy/themes/` (gitignored):
  `omarchy-shell-update --theme <git-url>`.
- `~/help.sh` prints a searchable reference for every command in this setup.
