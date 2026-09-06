#!/bin/bash
# help.sh — command reference for the standalone omarchy-shell setup on this box.
#
# This machine is CachyOS + Hyprland running Omarchy 4 "Quattro"'s Quickshell
# desktop shell, assembled by hand. Nothing omarchy ships is on PATH by itself,
# which is why almost everything below goes through the `omarchy` shim.
#
# Full notes: ~/dotfiles/omarchy-shell/NOTES.md
#
# Usage:  ./help.sh [section|search term]   e.g.  ./help.sh theme
#         ./help.sh --no-pager
#         ./help.sh --list

set -uo pipefail

# ------------------------------------------------------------------ display

# Colour only for a terminal, and NO_COLOR is honoured. Everything downstream
# reads these, so an unset terminal just prints plain text.
if [[ -t 1 && -z ${NO_COLOR:-} ]]; then
  B=$'\e[1m'; DIM=$'\e[2m'; GRN=$'\e[32m'; YEL=$'\e[33m'; CYN=$'\e[36m'; OFF=$'\e[0m'
else
  B=""; DIM=""; GRN=""; YEL=""; CYN=""; OFF=""
fi

# Command column width. Long commands overflow onto their own line rather than
# pushing the comment off the right edge.
W=52

h()  { printf '\n%s%s%s\n' "$B$GRN" "$*" "$OFF"; }
s()  { printf '%s%s%s\n' "$B" "$*" "$OFF"; }
t()  { printf '  %s\n' "$*"; }
n()  { printf '  %s%s%s\n' "$DIM" "$*" "$OFF"; }
b()  { printf '\n'; }

# row <command> [comment]
row() {
  local cmd="$1" note="${2-}"
  if [[ -z $note ]]; then
    printf '  %s%s%s\n' "$CYN" "$cmd" "$OFF"
  elif (( ${#cmd} > W )); then
    printf '  %s%s%s\n  %*s%s# %s%s\n' "$CYN" "$cmd" "$OFF" "$W" "" "$DIM" "$note" "$OFF"
  else
    printf '  %s%-*s%s%s# %s%s\n' "$CYN" "$W" "$cmd" "$OFF" "$DIM" "$note" "$OFF"
  fi
}

# ------------------------------------------------------------------ sections

sec_status() {
  h "STATUS  (live)"
  local pid theme qs qt
  pid=$(pgrep -f 'quickshell -n -p .*omarchy/shell' | head -1)
  if [[ -n $pid ]]; then
    t "shell            ${GRN}running${OFF}  (pid $pid)"
  else
    t "shell            ${YEL}not running${OFF}  — start it with: omarchy-shell-run &"
  fi

  theme=$(cat "$HOME/.local/state/omarchy/current/theme.name" 2>/dev/null)
  t "theme            ${theme:-unknown}"

  qs=$(pacman -Q quickshell-git 2>/dev/null) || qs="quickshell-git NOT INSTALLED"
  qt=$(pacman -Q qt6-base 2>/dev/null)
  t "quickshell       $qs"
  t "qt               ${qt:-unknown}"

  # Quickshell links Qt's private API; a qt6-base bump silently breaks the
  # installed build until it is rebuilt.
  if command -v quickshell >/dev/null 2>&1; then
    if quickshell --private-check-compat >/dev/null 2>&1; then
      t "ABI              ${GRN}ok${OFF}"
    else
      t "ABI              ${YEL}MISMATCH — run: yay -S --rebuild quickshell-git${OFF}"
    fi
  fi

  local w e
  w=$(systemctl --user is-active walker.service 2>/dev/null)
  e=$(systemctl --user is-active elephant.service 2>/dev/null)
  t "walker/elephant  ${w:-unknown} / ${e:-unknown}"

  if [[ -L $HOME/.config/nvim/lua/plugins/theme.lua ]]; then
    if [[ -e $HOME/.config/nvim/lua/plugins/theme.lua ]]; then
      t "nvim theme link  ${GRN}ok${OFF}"
    else
      t "nvim theme link  ${YEL}DANGLING${OFF}"
    fi
  else
    t "nvim theme link  ${YEL}absent${OFF} — omarchy-shell-update creates it"
  fi
}

sec_shell() {
  h "SHELL"
  n "The shell is one long-running quickshell process. It absorbed the bar,"
  n "launcher, menus, notifications, OSDs, lock screen and polkit agent."
  b
  row "omarchy-shell-run &"                       "start it (sets OMARCHY_PATH, FONTCONFIG_FILE)"
  row "pkill quickshell; omarchy-shell-run &"     "restart"
  row "omarchy shell shell ping"                  "IPC health check -> ok"
  row "omarchy shell shell listPlugins"           "JSON: every plugin, id, kinds, enabled"
  row "omarchy shell shell reloadConfig"          "re-read ~/.config/omarchy/shell.json"
  row "omarchy shell shell rescanPlugins"         "pick up a newly added plugin"
  row "omarchy shell shell toggleBarTransparency" ""
  b
  s "  The IPC surface"
  n "  omarchy <route> ... goes through ~/.local/bin/omarchy, the shim that sets"
  n "  OMARCHY_PATH and PATH. Without it the scripts die at exit 127 — see FILES."
  b
  row "omarchy shell <target> <method> [args]"    "the general form"
  row "omarchy shell -q <target> <method>"        "best-effort: never fails, prints nothing"
  b
  n "  The doubled 'shell shell' is not a typo: the first word is the dispatcher"
  n "  route (-> the omarchy-shell binary), the second is the IPC target."
  n "  Targets are the plugin ids from listPlugins. Every popup understands"
  n "  open/close/show/hide/toggle. 2s timeout, OMARCHY_SHELL_IPC_TIMEOUT overrides."
}

sec_launcher() {
  h "LAUNCHER & MENU"
  n "The app launcher is not a separate program — it is the 'apps' route of the"
  n "menu plugin, backed by Quickshell's DesktopEntries via services/AppLibrary.qml."
  b
  row "omarchy menu toggle apps"                  "the app launcher"
  row "omarchy menu summon apps"                  "open, never close-if-visible"
  row "omarchy menu toggle"                       "top-level menu"
  row "omarchy menu close"                        ""
  row "omarchy menu refresh"                      "re-parse the menu JSONC"
  row "omarchy menu ping"                         "health check"
  b
  s "  Useful routes  (omarchy menu toggle <route>)"
  row "apps"                                      "application launcher"
  row "style.theme"                               "theme switcher"
  row "style.background"                          "wallpaper switcher"
  row "style.font"                                "font picker"
  row "style.bar.position"                        "top / bottom / left / right"
  row "system"                                    "lock, suspend, reboot, shutdown"
  row "trigger.capture"                           "screenshot, screenrecord, QR, colour"
  row "trigger.emoji"                             "emoji picker"
  row "setup.keybindings"                         ""
  row "install / remove / update"                 "package and webapp management"
  b
  s "  Standalone menu helpers  (space, not a hyphen)"
  row "omarchy menu clipboard"                    "clipboard history"
  row "omarchy menu emoji"                        ""
  row "omarchy menu keybindings"                  "searchable Hyprland binds"
  row "omarchy menu plugin <enable|disable|clone|remove>" "manage shell plugins"
  row "omarchy menu timezone"                     ""
  row "omarchy menu select <prompt> [option...]"  "pick one option — scriptable"
  row "omarchy menu input <prompt>"               "prompt for text — scriptable"
  row "omarchy menu images <dir>..."              "image picker"
  row "omarchy menu share <clipboard|file|folder>" "LocalSend"
  row "omarchy menu --help"                       "all of the above, with arguments"
  b
  n "  Omarchy's own binds, for reference (default/hypr/bindings/utilities.lua):"
  n "    SUPER+SPACE = menu   SUPER+ALT+SPACE = apps   SUPER+ESCAPE = system"
  n "  This box binds SUPER+space to walker instead — ~/.config/hypr/conf/programs.lua:3"
}

sec_theme() {
  h "THEMES"
  n "One pipeline feeds the shell, walker, neovim and the terminal from a single"
  n "colors.toml through default/themed/*.tpl."
  b
  row "omarchy-shell-update --theme <name>"       "switch theme and re-derive everything"
  row "omarchy-shell-update --theme <git-url>"    "install a theme once, then apply it"
  row "omarchy theme list"                        "every installed theme"
  row "omarchy menu toggle style.theme"           "pick one from the GUI"
  row "cat ~/.local/state/omarchy/current/theme.name" "what is active (a slug, not a display name)"
  b
  s "  Installing from a URL"
  n "  --theme <url> clones to ~/.config/omarchy/themes/<name> and applies it,"
  n "  headless, then never touches it again: no fetch, no pull, no delete."
  n "  To take upstream changes, remove the directory and re-run with the URL."
  n "  It moves a theme's shipped walker.css aside — those are partial overrides"
  n "  written for omarchy 3 and would suppress ours entirely."
  b
  row "omarchy-shell-update --theme https://github.com/user/omarchy-x-theme.git" ""
  row "rm -rf ~/.config/omarchy/themes/<name>"    "then re-run with the URL to refresh it"
  b
  n "  Do NOT use omarchy-theme-install: its last line runs omarchy-theme-set"
  n "  without OMARCHY_THEME_HEADLESS=1, firing 14 app-retint hooks including the"
  n "  browser one, which writes managed-policy JSON into root-owned /etc."
  b
  s "  Verifying a theme applied"
  row "grep -c '{{' ~/.local/state/omarchy/current/theme/shell.toml" "must be 0"
  row "grep @define-color ~/.config/walker/themes/omarchy/style.css" "walker colours"
}

sec_update() {
  h "RESYNCING"
  n "The vendored tree at ~/.local/share/omarchy has NO git and NO upstream"
  n "(detached 2026-09-04). It only changes when you edit it by hand. The"
  n "resync script re-derives everything generated or copied from it."
  b
  row "omarchy-shell-update"                      "check + re-derive everything"
  row "omarchy-shell-update --check"              "dry run, writes nothing"
  row "omarchy-shell-update --theme <name|url>"   "also switch/install a theme"
  row "omarchy-shell-update --reset-config"       "discard your shell.json (backed up first)"
  row "omarchy-shell-update --help"               ""
  b
  n "  shell.json is never touched without --reset-config; drift is only reported."
  n "  To take an upstream fix: clone basecamp/omarchy to /tmp, diff, copy by hand."
  b
  row "tail ~/dotfiles/omarchy-shell/state/update.log" "one line per run"
}

sec_neovim() {
  h "NEOVIM  (LazyVim)"
  n "Follows the theme through one symlink:"
  n "  ~/.config/nvim/lua/plugins/theme.lua"
  n "    -> ~/.local/state/omarchy/current/theme/neovim.lua"
  b
  n "  That target is a LazyVim plugin spec, not a colour file: it pins"
  n "  bjarneo/aether.nvim, passes the palette as opts.colors, and sets"
  n "  colorscheme = \"aether\". Regenerated on every theme change."
  b
  row "nvim --headless '+Lazy! install' +qa"      "fetch the colorscheme plugin"
  row "nvim --headless '+Lazy! sync' +qa"         "update all plugins"
  row "readlink ~/.config/nvim/lua/plugins/theme.lua" "check the link"
  b
  n "  Startup-only: a running nvim keeps the old colours after a theme switch."
  n "  :Lazy reload will not help — the palette is baked in at spec evaluation."
  n "  Restart nvim."
  b
  n "  A git-installed theme's own neovim.lua is dropped (omarchy executes it at"
  n "  startup, so every *.lua from a cloned theme is refused). Those themes get"
  n "  the generated aether spec built from their colors.toml instead."
}

sec_walker() {
  h "WALKER + ELEPHANT"
  n "Walker is a separate GTK4 launcher; elephant is its provider daemon."
  n "Omarchy 4 ships neither — both are ours, kept for the four things the shell"
  n "has no answer for: calculator, web search, '>' runner, window switcher."
  b
  row "walker"                                    "open it"
  row "systemctl --user is-active walker.service elephant.service" ""
  row "systemctl --user restart elephant.service walker.service" "after a config change"
  row "elephant listproviders"                    ""
  row "elephant generate doc [provider]"          "NOT 'generatedoc'"
  row "elephant generate config [provider]"       "keeps your custom config"
  b
  n "  Its stylesheet is a two-stage render: omarchy's engine substitutes colours"
  n "  into current/theme/walker.css, then omarchy-walker-theme-sync resolves the"
  n "  geometry tokens and installs a REAL FILE (walker ignores a symlinked"
  n "  style.css silently). resync.sh section 4b does both."
  b
  row "~/.local/bin/omarchy-walker-theme-sync"    "re-render by hand"
  row "journalctl --user -u walker.service -n 50" "GTK parser errors show up here"
}

sec_quickshell() {
  h "QUICKSHELL / TROUBLESHOOTING"
  n "It must be quickshell-git (AUR), never the cachyos-extra-v3 'quickshell'."
  b
  s "  Two symbol errors that look identical — read the version node"
  n "  ...version Qt_6                -> WRONG PACKAGE. Install quickshell-git."
  n "  ...version Qt_6_PRIVATE_API    -> STALE BUILD. Rebuild it."
  b
  row "yay -S --rebuild quickshell-git"           "~5 min; needed after most qt6-base bumps"
  row "quickshell --private-check-compat"         "ABI check (also run by resync.sh)"
  row "pacman -Q quickshell-git qt6-base"         ""
  b
  n "  Quickshell links Qt's private API and upstream does not keep that ABI"
  n "  stable across patch releases. A routine -Syu is enough to break it."
}

sec_files() {
  h "FILES & PATHS"
  row "~/dotfiles/omarchy-shell/NOTES.md"        "the full notes — read this first"
  row "~/dotfiles/omarchy-shell/resync.sh"       "the resync script (-> ~/.local/bin/omarchy-shell-update)"
  row "~/dotfiles/bin/, ~/dotfiles/config/omarchy/" "the 6 authored files, symlinked into place"
  row "~/.local/share/omarchy/"                   "self-owned vendored tree, no git (OMARCHY_PATH)"
  row "~/.config/omarchy/shell.json"              "bar layout + idle timings — yours, never overwritten"
  row "~/.local/state/omarchy/current/theme/"     "generated theme files"
  row "~/.config/hypr/conf/programs.lua"          "menu = \"walker\" lives here"
  b
  s "  Why the omarchy shim exists"
  n "  On a real Omarchy box OMARCHY_PATH comes from the uwsm session and"
  n "  \$OMARCHY_PATH/bin is on PATH system-wide. Here omarchy-shell-run scopes"
  n "  both to the shell process, so a terminal or a Hyprland bind sees neither:"
  n "    \$ ~/.local/share/omarchy/bin/omarchy-menu toggle apps"
  n "    omarchy-menu: line 21: exec: omarchy-shell: not found     # exit 127"
  n "  ~/.local/bin/omarchy sets both, then execs the upstream dispatcher."
  b
  row "omarchy"                                   "no args: the full upstream command index"
  row "omarchy --help"                            ""
}

# ------------------------------------------------------------------ dispatch

SECTIONS=(status shell launcher theme update neovim walker quickshell files)

render() {
  printf '%somarchy-shell — command reference%s\n' "$B" "$OFF"
  printf '%s%s%s\n' "$DIM" "CachyOS + Hyprland + Omarchy 4 Quattro shell · ~/help.sh [section]" "$OFF"
  local name
  for name in "${SECTIONS[@]}"; do
    "sec_$name"
  done
  b
}

usage() {
  cat <<USAGE
Usage: ${0##*/} [section|term] [--no-pager]

Sections: ${SECTIONS[*]}

  ${0##*/}              everything
  ${0##*/} theme        just the THEMES section
  ${0##*/} clipboard    grep every section for "clipboard"
  ${0##*/} --list       section names only
USAGE
}

PAGE=1
FILTER=""
while (( $# )); do
  case "$1" in
    -h | --help)     usage; exit 0 ;;
    --no-pager | -P) PAGE=0 ;;
    --list | -l)     printf '%s\n' "${SECTIONS[@]}"; exit 0 ;;
    -*)              printf 'unknown option: %s\n' "$1" >&2; usage >&2; exit 2 ;;
    *)               FILTER="$1" ;;
  esac
  shift
done

out() {
  if [[ -z $FILTER ]]; then
    render
    return
  fi
  # An exact section name prints that section; anything else is a search across
  # all of them, with the owning header kept so a hit stays in context.
  local name
  for name in "${SECTIONS[@]}"; do
    if [[ $name == "$FILTER" ]]; then
      "sec_$name"; b; return
    fi
  done
  render | awk -v pat="$FILTER" '
    BEGIN { IGNORECASE = 1 }
    /^\x1b\[[0-9;]*m?[A-Z]/ || /^[A-Z][A-Z ]+/ { header = $0; shown = 0 }
    tolower($0) ~ tolower(pat) {
      if (!shown && header != "") { print ""; print header; shown = 1 }
      print
    }
  '
}

# Page only when it would actually scroll, so a one-section lookup still lands
# in scrollback where it can be copied from.
if (( PAGE )) && [[ -t 1 ]] && command -v less >/dev/null 2>&1; then
  content=$(out)
  if (( $(printf '%s\n' "$content" | wc -l) > ${LINES:-$(tput lines 2>/dev/null || echo 24)} )); then
    printf '%s\n' "$content" | less -R
  else
    printf '%s\n' "$content"
  fi
else
  out
fi
