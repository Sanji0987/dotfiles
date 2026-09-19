#!/usr/bin/env bash
#
# resync.sh — re-derive the standalone omarchy-shell install on this machine.
#
# There is NO repo and NO pull anymore. ~/.local/share/omarchy is a pruned,
# self-owned vendored tree (detached from basecamp/omarchy on 2026-09-04); it
# only changes when a file in it is edited by hand. What this script maintains
# is everything DERIVED from or COPIED out of that tree:
#
#   1. ~/.local/state/omarchy/current/theme/shell.toml is GENERATED from
#      default/themed/shell.toml.tpl by omarchy's own template engine.
#   2. ~/.config/omarchy/shell.json and the omarchy glyph font are COPIES.
#   3. The authored files (launcher, CLI shim, walker sync, ...) live in this
#      repo and are SYMLINKED into place by install.sh — not copied here.
#
# So: check, then re-derive. See NOTES.md for the full architecture.
#
# This script used to be update.sh, which also pulled the upstream repo.
# ~/.local/bin/omarchy-shell-update still points here for muscle memory.

set -euo pipefail

# Self-locating, so this folder can be renamed or moved without editing
# anything. readlink -f is required, not optional: the script is reached
# through the ~/.local/bin/omarchy-shell-update symlink, and without
# resolving that first SELF_DIR would be ~/.local/bin.
SELF_DIR="$(cd -- "$(dirname -- "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
REPO_DIR="$(cd -- "$SELF_DIR/.." && pwd)"

OMARCHY_PATH="$HOME/.local/share/omarchy"
STATE_DIR="$HOME/.local/state/omarchy"
CONFIG_DIR="$HOME/.config/omarchy"
FONT_DIR="$HOME/.local/share/fonts/omarchy"
BIN_DIR="$HOME/.local/bin"

# Our own bookkeeping, kept beside this script rather than in omarchy's state.
OWN_STATE="$SELF_DIR/state"
LOG_FILE="$OWN_STATE/update.log"
# Runtime dir, not the repo, so --check writes nothing persistent. Same
# place and pattern omarchy-theme-set:139 uses for its own serialization.
LOCK_FILE="${XDG_RUNTIME_DIR:-/tmp}/omarchy-config-update.lock"

DRY_RUN=0
RESET_CONFIG=0
THEME_OVERRIDE=""
# Set only when --theme was given a git URL rather than a name. Section 3b
# clones it; empty means there is nothing to install.
THEME_REPO_URL=""
THEME_INSTALLED=0

c_bold=$'\e[1m'; c_green=$'\e[32m'; c_yellow=$'\e[33m'; c_red=$'\e[31m'; c_dim=$'\e[2m'; c_off=$'\e[0m'

say()  { printf '%s==>%s %s\n' "$c_bold$c_green" "$c_off" "$*"; }
info() { printf '    %s\n' "$*"; }
warn() { printf '%swarning:%s %s\n' "$c_yellow" "$c_off" "$*" >&2; }
die()  { printf '%serror:%s %s\n' "$c_red" "$c_off" "$*" >&2; exit 1; }
dim()  { printf '%s    %s%s\n' "$c_dim" "$*" "$c_off"; }

usage() {
  cat <<USAGE
Usage: ${0##*/} [options]

Resyncs the standalone omarchy-shell install: deploys the authored files,
then re-derives everything generated or copied from the vendored tree at
~/.local/share/omarchy. Nothing is pulled from anywhere — the tree is
self-owned and only changes when edited by hand.

Options:
  -n, --check           Dry run. Reports what would change, writes nothing.
      --theme <name|url>
                        Regenerate with a different theme. <name> is an
                        installed theme ("Catppuccin", "tokyo-night").
                        A git URL installs it first, one time only: cloned
                        to ~/.config/omarchy/themes/<name>, then applied.
                        A theme already present is applied as-is — this
                        never pulls, resets or deletes an existing clone.
                        Default: whatever is currently active.
      --reset-config    Overwrite ~/.config/omarchy/shell.json with the
                        vendored default. Your current file is backed up
                        first. Without this, shell.json is never touched.
  -h, --help            This message.
USAGE
}

while (( $# )); do
  case "$1" in
    -n|--check)     DRY_RUN=1 ;;
    --theme)        THEME_OVERRIDE="${2:-}"; [[ -n $THEME_OVERRIDE ]] || die "--theme needs a name"; shift ;;
    --reset-config) RESET_CONFIG=1 ;;
    -h|--help)      usage; exit 0 ;;
    *)              die "unknown option: $1 (try --help)" ;;
  esac
  shift
done

run() {
  if (( DRY_RUN )); then dim "would run: $*"; else "$@"; fi
}

# ---------------------------------------------------------------- preflight
#
# Everything asserted anywhere below is validated HERE, before the first
# mutation. A missing theme state must not be discovered halfway through.

(( DRY_RUN )) && say "DRY RUN — nothing is modified"

# Serialize: two concurrent runs would race on the theme regeneration.
exec 9>"$LOCK_FILE"
flock -n 9 || die "another instance is already running (lock: $LOCK_FILE)"


# The tree is not cloned or restored automatically — it has no upstream
# anymore. If it is gone, that is a hand-repair situation, not a bootstrap.
if [[ ! -d $OMARCHY_PATH ]]; then
  die "no vendored tree at $OMARCHY_PATH — restore it by hand
       (a full pre-detach copy may still exist at $OMARCHY_PATH.pre-migration-backup)"
fi

[[ -f $OMARCHY_PATH/shell/shell.qml ]] || die "$OMARCHY_PATH does not look like an omarchy tree"
[[ -f $OMARCHY_PATH/config/omarchy/shell.json ]] || die "missing $OMARCHY_PATH/config/omarchy/shell.json"
[[ -f $OMARCHY_PATH/default/themed/shell.toml.tpl ]] || die "missing $OMARCHY_PATH/default/themed/shell.toml.tpl — the shell.toml template is gone"

export OMARCHY_PATH
export PATH="$OMARCHY_PATH/bin:$PATH"

command -v omarchy-theme-set >/dev/null || die "omarchy-theme-set not found on PATH (looked in $OMARCHY_PATH/bin)"

# The headless flag is what stops omarchy-theme-set from running its 14
# app-retint hooks (omarchy-theme-set:207) against this machine's terminal,
# btop, VSCode and browser. The tree is frozen so this cannot change under us
# anymore, but the check is cheap and the failure mode (a retinted desktop
# with nothing to trace it to) is nasty enough to keep it.
if ! grep -q 'OMARCHY_THEME_HEADLESS' "$OMARCHY_PATH/bin/omarchy-theme-set"; then
  warn "OMARCHY_THEME_HEADLESS is not referenced in bin/omarchy-theme-set anymore."
  warn "The retint hooks (terminal, btop, VSCode, Obsidian, browser) may now run."
  warn "Check what replaced it before trusting this script's theme step."
fi

# --theme also accepts a git URL, which installs the theme before applying it.
# A theme slug never contains ':', '/' or '@' (omarchy-theme-set:238 lowercases
# and hyphenates, and :245 rejects a name with a slash), so this cannot misfire
# on a name.
#
# We do not shell out to omarchy-theme-install for this. Its last line is a
# bare `omarchy-theme-set "$THEME_NAME"` with no OMARCHY_THEME_HEADLESS=1, so
# it fires all 14 app-retint post-hooks — including omarchy-theme-set-browser,
# which writes managed-policy JSON into root-owned /etc/*/policies/managed.
is_repo_url() {
  [[ $1 == *"://"* || $1 == *.git || $1 =~ ^[^/]+@[^/]+: ]]
}

# theme.name holds a SLUG, not a display name: omarchy-theme-set:125 lowercases
# and hyphenates its argument before writing it at :168. Feeding the slug back
# in is safe because slugifying a slug is idempotent.
THEME_FILE="$STATE_DIR/current/theme.name"
# Both guards are upstream's (omarchy-theme-install:23), and they run on the
# RAW argument rather than inside the URL branch below. That is deliberate:
# neither dangerous form is detected as a URL by is_repo_url — `ext::sh -c ...`
# has no scheme and no `@host:`, and a leading dash has neither — so guarding
# only the URL path would leave both to be silently reinterpreted as a theme
# name. A theme slug can never legitimately start with `-` or contain `::`, so
# rejecting them outright is both safer and simpler.
if [[ -n $THEME_OVERRIDE ]]; then
  [[ $THEME_OVERRIDE != -* ]] \
    || die "--theme '$THEME_OVERRIDE' starts with a dash — git would read it as an option, not a repository"
  [[ ! $THEME_OVERRIDE =~ ^[A-Za-z0-9][A-Za-z0-9+.-]*:: ]] \
    || die "--theme '$THEME_OVERRIDE' names a git transport helper, not a repository (ext:: runs arbitrary commands at clone time)"
fi

if [[ -n $THEME_OVERRIDE ]] && is_repo_url "$THEME_OVERRIDE"; then
  command -v git >/dev/null || die "--theme was given a URL but git is not on PATH"

  THEME_REPO_URL="$THEME_OVERRIDE"

  # Derived with upstream's exact rules (omarchy-theme-install:30-33) so a
  # theme installed either way lands in the same directory.
  repo_path="$THEME_REPO_URL"
  [[ $repo_path != *"://"* && $repo_path == *:*/* ]] && repo_path="${repo_path#*:}"
  THEME_NAME=$(basename -- "$repo_path" .git \
               | sed -E 's/^omarchy-//; s/-theme$//' \
               | tr '[:upper:]' '[:lower:]')

  # The name is about to be joined into a path that gets written to, so a repo
  # called `..` would take ~/.config/omarchy with it.
  if [[ -z $THEME_NAME || $THEME_NAME == .* || $THEME_NAME == */* ]]; then
    die "'$THEME_REPO_URL' does not give a usable theme name (derived: '$THEME_NAME')"
  fi

  # omarchy-theme-dir prefers ~/.config/omarchy/themes over the vendored
  # tree's own, so a clone named after a built-in shadows it everywhere,
  # silently.
  if [[ -d $OMARCHY_PATH/themes/$THEME_NAME ]]; then
    warn "'$THEME_NAME' is also a built-in theme — the clone will shadow $OMARCHY_PATH/themes/$THEME_NAME"
  fi
elif [[ -n $THEME_OVERRIDE ]]; then
  THEME_NAME="$THEME_OVERRIDE"
elif [[ -r $THEME_FILE ]]; then
  THEME_NAME=$(<"$THEME_FILE")
  [[ -n $THEME_NAME ]] || die "$THEME_FILE is empty — pass --theme <name> to pick one"
else
  die "no active theme recorded at $THEME_FILE — pass --theme <name> to pick one"
fi

QS_VERSION=$(pacman -Q quickshell-git 2>/dev/null || pacman -Q quickshell 2>/dev/null || echo "quickshell not from pacman")
info "quickshell: $QS_VERSION"

# --------------------------------------------- 2. verify the authored files

# None of these come from the vendored tree — we wrote them, and this repo is
# their single source of truth. They used to be COPIED into place here, which
# meant the deployed copy could drift from ours and the copy had to be
# re-made on every run. They are symlinks now, created once by install.sh, so
# there is nothing to deploy and nothing that can drift — git is the drift
# detector. All this step does is confirm they are actually in place, because
# everything below assumes they are.
#
# The walker three matter most: walker.css.tpl is the input to the section 4
# render, and omarchy-walker-theme-sync resolves the geometry tokens that
# render leaves behind.
say "Checking authored files"
authored_missing=0
check_installed() {
  # -e, not -f: these are symlinks, and -e fails on a dangling one, which is
  # exactly the case worth catching.
  if [[ -e $1 ]]; then
    info "$2 ok"
  else
    warn "missing or dangling: $1"
    authored_missing=1
  fi
}
check_installed "$BIN_DIR/omarchy-shell-run"               "omarchy-shell-run"
check_installed "$BIN_DIR/omarchy"                         "omarchy"
check_installed "$BIN_DIR/omarchy-walker-theme-sync"       "omarchy-walker-theme-sync"
# edited by claude opus 5
# the kitty palette is generated now, so its script and hook are load-bearing
check_installed "$BIN_DIR/omarchy-kitty-theme-sync"        "omarchy-kitty-theme-sync"
check_installed "$CONFIG_DIR/fontconfig.conf"              "fontconfig.conf"
check_installed "$CONFIG_DIR/themed/walker.css.tpl"        "walker.css.tpl"
check_installed "$CONFIG_DIR/hooks/theme-set.d/walker-css" "walker-css hook"
check_installed "$CONFIG_DIR/hooks/theme-set.d/kitty-theme" "kitty-theme hook"
if (( authored_missing )); then
  die "authored files are not installed — run $REPO_DIR/install.sh"
fi

# ----------------------------------------------------------- 3. glyph font

say "Checking glyph font"
FONT_SRC="$OMARCHY_PATH/default/fonts/omarchy/omarchy.ttf"
FONT_DST="$FONT_DIR/omarchy.ttf"
if [[ ! -f $FONT_SRC ]]; then
  warn "glyph font missing from the vendored tree: $FONT_SRC"
elif [[ -f $FONT_DST ]] && cmp -s "$FONT_SRC" "$FONT_DST"; then
  info "omarchy.ttf unchanged"
else
  info "updating omarchy.ttf"
  run install -Dm644 "$FONT_SRC" "$FONT_DST"
  run fc-cache -f "$HOME/.local/share/fonts"
fi

# -------------------------------------------------------- 3b. install theme

# Before section 4 so the theme exists by the time omarchy-theme-set wants it.
#
# ONE-TIME INSTALL. A theme already on disk is applied as-is: no fetch, no
# pull, no reset, no delete. To take a theme's upstream changes, remove the
# directory and re-run with the URL.

USER_THEMES_DIR="$CONFIG_DIR/themes"
THEME_DIR="$USER_THEMES_DIR/$THEME_NAME"

# A theme carrying its own walker.css suppresses ours completely:
# omarchy-theme-set-templates:396 writes a template's output only
# `if [[ ! -f $output_path ]]`, and theme files are staged first. Every
# third-party theme seen so far ships one, and every one is a partial override
# — colours only, no row height, padding, icon size or radius — written for
# omarchy 3, where omarchy itself supplied the base stylesheet underneath.
# Letting one win drops walker back to stock GTK layout.
#
# Renamed, not deleted: `git checkout walker.css` in the theme dir restores it.
neutralize_theme_walker_css() {
  local dir="$1"
  [[ -f $dir/walker.css ]] || return 0
  info "moving its walker.css aside -> walker.css.theme-shipped"
  dim "it would suppress $CONFIG_DIR/themed/walker.css.tpl (templates skip existing outputs)"
  run mv "$dir/walker.css" "$dir/walker.css.theme-shipped"
}

if [[ -n $THEME_REPO_URL ]]; then
  say "Installing theme"
  if [[ -d $THEME_DIR ]]; then
    info "'$THEME_NAME' is already installed at $THEME_DIR — applying as-is"
    dim "this never pulls; delete the directory and re-run to reinstall"
  else
    info "$THEME_REPO_URL -> $THEME_DIR"
    mkdir -p "$USER_THEMES_DIR"
    # `--` because the URL is user input; --depth 1 because this is explicitly
    # a one-time install and theme repos carry wallpapers.
    if run git clone --depth 1 -- "$THEME_REPO_URL" "$THEME_DIR"; then
      (( DRY_RUN )) || THEME_INSTALLED=1
    else
      die "failed to clone $THEME_REPO_URL"
    fi
  fi
fi

# Guarded on the directory rather than on THEME_REPO_URL so this also covers a
# plain --theme <name> naming a theme installed some other way.
if [[ -d $THEME_DIR ]]; then
  neutralize_theme_walker_css "$THEME_DIR"

  # Without a palette, omarchy-theme-set-templates:371 skips the whole
  # generation block. Nothing errors — shell.toml and walker.css simply keep
  # the previous theme's colours and this script still reports success.
  # alacritty.toml counts: stage_installed_colors_from_alacritty synthesises a
  # colors.toml from it even though the file itself is on the denied list.
  if [[ ! -f $THEME_DIR/colors.toml && ! -f $THEME_DIR/alacritty.toml ]]; then
    warn "'$THEME_NAME' has neither colors.toml nor alacritty.toml"
    warn "templating is skipped wholesale without a palette (omarchy-theme-set-templates:371) —"
    warn "shell.toml and walker.css will keep the PREVIOUS theme's colours"
  fi
fi

# ------------------------------------------------------ 4. regenerate theme

# The important half. shell.toml is generated from default/themed/shell.toml.tpl
# by omarchy's own template engine; an edited template with a stale output means
# new surface tokens silently fall back to built-in defaults.
say "Regenerating theme"
info "theme: $THEME_NAME"
if (( DRY_RUN )); then
  dim "would run: OMARCHY_THEME_HEADLESS=1 omarchy-theme-set \"$THEME_NAME\""
else
  mkdir -p "$STATE_DIR/current"
  # HEADLESS skips the post-hooks that would retint your terminal, btop,
  # VSCode, Obsidian and browser. We only want the shell's own theme files.
  if theme_out=$(OMARCHY_THEME_HEADLESS=1 omarchy-theme-set "$THEME_NAME" 2>&1); then
    [[ -n $theme_out ]] && printf '%s\n' "$theme_out" | sed 's/^/      /'
    SHELL_TOML="$STATE_DIR/current/theme/shell.toml"
    if [[ -f $SHELL_TOML ]]; then
      # Count tokens, not lines: one line can carry several.
      mapfile -t leftover < <(grep -o '{{[^}]*}}' "$SHELL_TOML" 2>/dev/null || true)
      if (( ${#leftover[@]} == 0 )); then
        info "shell.toml regenerated, all tokens substituted"
      else
        warn "shell.toml has ${#leftover[@]} unsubstituted tokens:"
        printf '%s\n' "${leftover[@]}" | sort -u | head -10 | sed 's/^/      /' >&2
      fi
    else
      warn "shell.toml was not produced."
      warn "Either the theme ships its own (templates skip existing outputs,"
      warn "omarchy-theme-set-templates:396) or it has no colors.toml (:371)."
    fi
  else
    warn "omarchy-theme-set failed for '$THEME_NAME'"
    printf '%s\n' "$theme_out" | sed 's/^/      /' >&2
  fi
fi

# --------------------------------------------------- 4b. walker stylesheet

# ~/.config/omarchy/themed/walker.css.tpl renders to current/theme/walker.css
# along with shell.toml above — but that render is stage 1 of 2. omarchy's
# template engine substitutes colours only (it builds its sed script from
# colors.toml alone), so the geometry tokens pass through untouched and
# omarchy-walker-theme-sync resolves them against shell.toml's [font]/[spacing]
# and decoration:rounding before installing. That second stage is why this
# section cannot be replaced by a plain copy.
#
# Walker also cannot read the file from current/theme/ directly: it silently
# ignores a symlinked themes/<name>/style.css (proven with deliberately invalid
# CSS — a real file makes GTK print a parser error, a symlink produces no output
# at all), so the result has to be a real file copied in.
#
# omarchy has a hook for exactly this, ~/.config/omarchy/hooks/theme-set.d/,
# but omarchy-theme-set:207 runs hooks only when OMARCHY_THEME_HEADLESS is
# unset — and this script always sets it. So the hook covers theme-switcher
# changes and this covers ours. Both call the same script.

WALKER_SYNC="$HOME/.local/bin/omarchy-walker-theme-sync"
WALKER_THEME_DIR="$HOME/.config/walker/themes/omarchy"

if [[ -d $WALKER_THEME_DIR && -x $WALKER_SYNC ]]; then
  say "Syncing walker stylesheet"
  if (( DRY_RUN )); then
    dim "would run: $WALKER_SYNC"
  elif walker_out=$("$WALKER_SYNC" 2>&1); then
    info "style.css rendered from current/theme/walker.css"
    [[ -n $walker_out ]] && printf '%s\n' "$walker_out" | sed 's/^/      /'
  else
    warn "omarchy-walker-theme-sync failed"
    printf '%s\n' "$walker_out" | sed 's/^/      /' >&2
  fi
fi

# ------------------------------------------------------- 4d. kitty palette

# edited by claude opus 5
# kitty used to hold whatever `kitten themes` last wrote, ignoring the theme
#
# kitty.conf ends with `include current-theme.conf`. That file used to be
# written by `kitten themes`, so the terminal sat on whatever palette was
# picked last (Moonfly) no matter what the desktop theme was.
#
# It is generated now, from two layers: omarchy's own render of the theme's
# colors.toml, plus a reviewed per-theme extract from
# config/kitty/themes/<slug>.conf where this repo has one. The second layer
# exists because omarchy refuses a cloned theme's kitty.conf outright
# (omarchy-theme-set:30) — a kitty config can name the program the terminal
# launches — and some themes ship a terminal palette that is deliberately
# different from their colors.toml.
#
# Same hook arrangement as walker above: the theme-set.d hook covers
# theme-switcher changes, this covers ours, both call the same script.

KITTY_SYNC="$HOME/.local/bin/omarchy-kitty-theme-sync"

if [[ -x $KITTY_SYNC ]]; then
  say "Syncing kitty palette"
  if (( DRY_RUN )); then
    dim "would run: $KITTY_SYNC"
  elif kitty_out=$("$KITTY_SYNC" 2>&1); then
    info "current-theme.conf rendered from current/theme/kitty.conf"
    [[ -n $kitty_out ]] && printf '%s\n' "$kitty_out" | sed 's/^/      /'
  else
    warn "omarchy-kitty-theme-sync failed"
    printf '%s\n' "$kitty_out" | sed 's/^/      /' >&2
  fi
fi

# ------------------------------------------------------ 4c. neovim colorscheme

# LazyVim picks the theme up through one symlink:
#
#   ~/.config/nvim/lua/plugins/theme.lua
#     -> ~/.local/state/omarchy/current/theme/neovim.lua
#
# That target is a LazyVim plugin spec, not a colour file — it pins
# bjarneo/aether.nvim, feeds it the palette, and sets colorscheme = "aether".
# Section 4 regenerates it on every run (default/themed/neovim.lua.tpl), so the
# link is the whole integration: nothing to copy, nothing to re-render.
#
# ABSOLUTE target, deliberately. The nvim config dir lives in ~/dotfiles and is
# reached through a ~/.config/nvim symlink; a relative target would resolve
# against the link's real directory inside ~/dotfiles and dangle.
#
# A cloned theme's own neovim.lua never reaches here — omarchy-theme-set:22 drops
# every *.lua from a git-installed theme because Neovim executes it at startup —
# so cyberpunk and rainynight get the generated aether spec instead of the
# author's. Same palette, different plugin.
#
# Neovim reads this at startup only; a running instance keeps its old colours.

NVIM_PLUGINS_DIR="$HOME/.config/nvim/lua/plugins"
NVIM_THEME_LINK="$NVIM_PLUGINS_DIR/theme.lua"
NVIM_THEME_TARGET="$HOME/.local/state/omarchy/current/theme/neovim.lua"

# Guarded on the plugins directory: no LazyVim here means nothing to wire up.
if [[ -d $NVIM_PLUGINS_DIR ]]; then
  if [[ -L $NVIM_THEME_LINK && $(readlink "$NVIM_THEME_LINK") == "$NVIM_THEME_TARGET" ]]; then
    : # already ours
  elif [[ -e $NVIM_THEME_LINK && ! -L $NVIM_THEME_LINK ]]; then
    # A real file here is hand-written: someone chose their own colorscheme.
    # Never overwrite it — say so and move on.
    warn "$NVIM_THEME_LINK is a regular file, not a link — leaving it alone"
    dim "delete it and re-run to have neovim follow the omarchy theme"
  else
    say "Linking neovim colorscheme"
    info "theme.lua -> current/theme/neovim.lua"
    run ln -sfn "$NVIM_THEME_TARGET" "$NVIM_THEME_LINK"
  fi

  # A dangling link is worse than none: lazy.nvim errors on every startup.
  if [[ -L $NVIM_THEME_LINK && ! -e $NVIM_THEME_LINK ]]; then
    warn "$NVIM_THEME_LINK dangles — current/theme/neovim.lua was not generated"
    warn "the theme has no palette, or it ships a neovim.lua that was denied and"
    warn "the template did not run; nvim will fall back to LazyVim's default"
  fi
fi

# ------------------------------------------------------- 5. shell.json drift

# Never clobbered: this is the file you customize. We only report drift.
say "Checking shell.json"
USER_JSON="$CONFIG_DIR/shell.json"
REPO_JSON="$OMARCHY_PATH/config/omarchy/shell.json"

if (( RESET_CONFIG )); then
  if [[ -f $USER_JSON ]]; then
    backup="$USER_JSON.bak.$(date +%s)"
    info "backing up -> $backup"
    run cp "$USER_JSON" "$backup"
  fi
  info "resetting to vendored default"
  run install -Dm644 "$REPO_JSON" "$USER_JSON"
elif [[ ! -f $USER_JSON ]]; then
  info "no user shell.json — installing vendored default"
  run install -Dm644 "$REPO_JSON" "$USER_JSON"
elif cmp -s "$USER_JSON" "$REPO_JSON"; then
  info "identical to vendored default"
else
  warn "your shell.json differs from the vendored default"
  dim "(expected if you customized the bar; run with --reset-config to discard yours)"
  diff -u "$USER_JSON" "$REPO_JSON" 2>/dev/null | sed -n '3,15p' | sed 's/^/      /' || true
fi

# ------------------------------------------------- 6. quickshell ABI check

# Quickshell links Qt's *private* API — its symbols carry the Qt_6_PRIVATE_API
# version node, which upstream Qt deliberately does not keep ABI-stable, not
# even across patch releases. So any `pacman -Syu` that moves qt6-base leaves
# the installed quickshell unable to start:
#
#   quickshell: symbol lookup error: quickshell: undefined symbol: <mangled>,
#   version Qt_6_PRIVATE_API
#
# Nothing in the vendored tree can fix that and nothing here causes it — the
# package has to be rebuilt against the new Qt. The check lives here because
# the failure presents as "omarchy broke" and sends you looking in the wrong
# place.

QS_REBUILD_NEEDED=0
QS_REBUILD_CMD=""

# Build/install times as epoch seconds. expac is the clean source; fall back to
# parsing pacman -Qi under LC_ALL=C, since that date string is locale-formatted.
pkg_epoch() { # $1=pkg  $2=%b (build) | %l (install)
  local out field
  if command -v expac >/dev/null 2>&1; then
    out=$(expac --timefmt=%s -Q "$2" "$1" 2>/dev/null) || out=""
    if [[ -n $out ]]; then printf '%s' "$out"; return 0; fi
  fi
  field="Build Date"; [[ $2 == '%l' ]] && field="Install Date"
  out=$(LC_ALL=C pacman -Qi "$1" 2>/dev/null \
        | awk -F': +' -v f="$field" '$1 ~ "^"f {print $2; exit}') || out=""
  [[ -n $out ]] || return 1
  date -d "$out" +%s 2>/dev/null
}

say "Checking quickshell"

QS_PKG=""
for p in quickshell-git quickshell; do
  if pacman -Q "$p" >/dev/null 2>&1; then QS_PKG=$p; break; fi
done

QT_VERSION=$(pacman -Q qt6-base 2>/dev/null || echo "qt6-base not installed")

if [[ -z $QS_PKG ]]; then
  info "quickshell is not a pacman package — skipping ABI check"
elif ! qt_epoch=$(pkg_epoch qt6-base '%l') || [[ -z $qt_epoch ]]; then
  info "could not read the qt6-base install date — skipping ABI check"
else
  qs_epoch=$(pkg_epoch "$QS_PKG" '%b') || qs_epoch=""
  info "$QS_VERSION  built ${qs_epoch:+$(date -d "@$qs_epoch" '+%Y-%m-%d %H:%M')}"
  info "$QT_VERSION  installed $(date -d "@$qt_epoch" '+%Y-%m-%d %H:%M')"

  # Authoritative when present: the binary compares its own recorded Qt build
  # against the installed one. Shipped by the AUR package, which also wires it
  # to a pacman hook on qt6-base/qt6-wayland upgrades.
  if quickshell --private-check-compat >/dev/null 2>&1; then
    info "ABI check passed — no rebuild needed"
  elif [[ -n $qs_epoch ]] && (( qs_epoch > qt_epoch )); then
    # Reached when --private-check-compat is unavailable (older package, or the
    # flag got renamed). Times are the next best evidence: built after the Qt
    # currently installed means it was built against it.
    info "built after the current qt6-base — no rebuild needed"
  else
    QS_REBUILD_NEEDED=1
    # Prefer whichever helper actually has a build tree for it, so the rebuild
    # reuses the existing clone instead of starting a fresh one.
    for h in yay paru; do
      if [[ -d $HOME/.cache/$h/$QS_PKG ]] && command -v "$h" >/dev/null 2>&1; then
        QS_REBUILD_CMD="$h -S --rebuild $QS_PKG"; break
      fi
    done
    if [[ -z $QS_REBUILD_CMD ]]; then
      for h in paru yay; do
        if command -v "$h" >/dev/null 2>&1; then
          QS_REBUILD_CMD="$h -S --rebuild $QS_PKG"; break
        fi
      done
    fi
    [[ -n $QS_REBUILD_CMD ]] || QS_REBUILD_CMD="rebuild $QS_PKG from the AUR"
    warn "quickshell was built before the installed qt6-base"
  fi
fi

# ------------------------------------------------------------------ 7. done

if (( ! DRY_RUN )); then
  mkdir -p "$OWN_STATE"
  printf '%s  resync  %s  %s  theme=%s%s%s\n' \
    "$(date -Is)" \
    "$QS_VERSION" \
    "$QT_VERSION" \
    "$THEME_NAME" \
    "$( (( THEME_INSTALLED )) && printf '  INSTALLED-THEME' )" \
    "$( (( QS_REBUILD_NEEDED )) && printf '  REBUILD-QUICKSHELL' )" >>"$LOG_FILE"
fi

say "Done"
if (( DRY_RUN )); then
  info "dry run — nothing changed"
elif ! pgrep -x quickshell >/dev/null 2>&1; then
  info "shell is not running — start it with: omarchy-shell-run &"
fi

# Printed last, after everything else, so it is the line still on screen when
# the run ends. Without the rebuild none of the work above can be seen anyway:
# the shell will not start at all.
if (( QS_REBUILD_NEEDED )); then
  printf '\n'
  warn "RECOMPILE QUICKSHELL BEFORE STARTING THE SHELL"
  info "qt6-base moved since $QS_PKG was built. Quickshell links Qt's private"
  info "API, which is not ABI-stable across Qt releases, so the shell will die"
  info "on startup with:"
  dim "  symbol lookup error: quickshell: undefined symbol: ..., version Qt_6_PRIVATE_API"
  info ""
  info "Rebuild it, then start the shell:"
  dim "  $QS_REBUILD_CMD"
  dim "  omarchy-shell-run &"
fi
