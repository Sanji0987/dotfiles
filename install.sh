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
# edited by claude sonnet 5
# added waybar so the fallback bar's config gets symlinked like every other
# edited by claude opus 5
# added fastfetch and cava so their new configs get symlinked like every other
for d in hypr kitty nvim walker elephant omarchy fish tmux alacritty mako \
         btop fontconfig uwsm waybar fastfetch cava; do
  link "config/$d" "$HOME/.config/$d"
done
link "config/libinput-gestures.conf" "$HOME/.config/libinput-gestures.conf"

# user services (enable with: systemctl --user enable --now <unit>)
for u in walker.service elephant.service; do
  link "config/systemd/user/$u" "$HOME/.config/systemd/user/$u"
done

# home dotfiles
for f in .zshrc .p10k.zsh .bashrc .bash_profile .profile .gitconfig; do
  link "home/$f" "$HOME/$f"
done

# scripts. The omarchy three (launcher, CLI shim, walker theme sync) are ours
# and are linked like anything else — resync.sh used to deploy them as copies,
# which meant the deployed copy could silently drift from the repo.
# edited by claude opus 5
# added the kitty theme sync, which the theme-set.d hook and resync.sh both call
for b in hermes update-appimage env env.fish \
         omarchy omarchy-shell-run omarchy-walker-theme-sync \
         omarchy-kitty-theme-sync; do
  link "bin/$b" "$HOME/.local/bin/$b"
done

link "help.sh" "$HOME/help.sh"

# resync entry point on PATH
link "omarchy-shell/resync.sh" "$HOME/.local/bin/omarchy-shell-update"

echo
echo "done: $ok in place, $skipped skipped"
if (( skipped )); then
  echo "move the skipped obstacles aside and re-run"
fi

cat <<'EOF'

Not handled by this script (see omarchy-shell/NOTES.md):
  - ~/.local/share/omarchy — the vendored shell tree; restore from a backup
  - omarchy-shell-update    — run once after the tree is in place; it installs
                              the glyph font and regenerates the theme files
  - third-party themes      — omarchy-shell-update --theme <git-url>
EOF
