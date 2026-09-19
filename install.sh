#!/usr/bin/env bash
#
# install.sh — symlink this repo's files into place.
#
# Idempotent: a link that already points at us is left alone. A real file or
# directory in the way is NOT overwritten — it is reported and skipped, so a
# machine's existing config is never destroyed by cloning this repo. Move the
# obstacle aside and re-run.

set -euo pipefail

DOTFILES="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

ok=0; skipped=0

link() { # $1 = repo-relative source, $2 = absolute destination
  local src="$DOTFILES/$1" dst="$2"
  if [[ ! -e $src ]]; then
    echo "missing in repo, skipping: $1" >&2
    return
  fi
  if [[ -L $dst && $(readlink "$dst") == "$src" ]]; then
    (( ++ok ))
    return
  fi
  if [[ -e $dst || -L $dst ]]; then
    echo "in the way, NOT touching: $dst" >&2
    (( ++skipped ))
    return
  fi
  mkdir -p "$(dirname "$dst")"
  ln -s "$src" "$dst"
  echo "linked $dst -> $1"
  (( ++ok ))
}

# ~/.config directories
# edited by claude opus 5
# dropped walker, elephant and omarchy: the Quickshell shell and the walker
# launcher are gone, rofi and the four daemons replace them
for d in hypr kitty nvim fish tmux alacritty \
         btop fontconfig uwsm waybar fastfetch cava mako rofi swayosd; do
  link "config/$d" "$HOME/.config/$d"
done
link "config/libinput-gestures.conf" "$HOME/.config/libinput-gestures.conf"

# home dotfiles
for f in .zshrc .p10k.zsh .bashrc .bash_profile .profile .gitconfig; do
  link "home/$f" "$HOME/$f"
done

# scripts.
# edited by claude opus 5
# the agent usage collectors and the waybar module that reads them, rescued
# from the omarchy tree so the Claude usage indicator outlived the shell
# edited by claude opus 5
# dropped the omarchy launcher, CLI shim, walker/kitty/sidra theme syncs and
# the resync entry point: the shell and its theme pipeline are gone
for b in hermes update-appimage env env.fish \
         agent-usage-update agent-usage-claude agent-usage-codex \
         agent-usage-fireworks waybar-claude; do
  link "bin/$b" "$HOME/.local/bin/$b"
done

link "help.sh" "$HOME/help.sh"

echo
echo "done: $ok in place, $skipped skipped"
if (( skipped )); then
  echo "move the skipped obstacles aside and re-run"
fi
