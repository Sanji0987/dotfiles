#!/usr/bin/env bash
# Re-apply the GNOME theming settings from this branch.
#
# Safe to re-run. Only touches keys this setup actually changed -- it does not
# reset anything else, so running it on a dirty machine will not wipe unrelated
# settings. Run it AFTER the build steps in README.md, because several of these
# keys name themes that must already exist on disk.
#
# The full captured state is in dconf/gnome.ini if you would rather load
# everything at once:  dconf load /org/gnome/ < dconf/gnome.ini
# That is blunter -- it also restores window sizes and notification prefs.

set -euo pipefail

SL_SCHEMA="$HOME/.local/share/gnome-shell/extensions/search-light@icedman.github.com/schemas"

say() { printf '\033[1;34m==>\033[0m %s\n' "$1"; }

# --- shell / theme ------------------------------------------------------------
say "shell + theme"
gsettings set org.gnome.shell disable-user-extensions            false
gsettings set org.gnome.shell.extensions.user-theme name         'WhiteSur-Dark'
gsettings set org.gnome.desktop.interface gtk-theme              'WhiteSur-Dark'
gsettings set org.gnome.desktop.interface color-scheme           'prefer-dark'
gsettings set org.gnome.desktop.interface icon-theme             'WhiteSur-dark'
gsettings set org.gnome.desktop.interface cursor-theme           'WhiteSur-cursors'
gsettings set org.gnome.desktop.interface cursor-size            24

# --- fonts --------------------------------------------------------------------
# SF Pro is NOT in this repo (see README, "Fonts"). If it is missing these two
# lines silently fall back to the default sans and everything still works.
say "fonts"
gsettings set org.gnome.desktop.interface font-name              'SF Pro Text 11'
gsettings set org.gnome.desktop.interface document-font-name     'SF Pro Text 11'
gsettings set org.gnome.desktop.interface monospace-font-name    'JetBrains Mono 11'
# copied from https://github.com/jothi-prasath/gnomintosh
# Their config set titlebar-font at all, which is how I noticed mine was still
# Adwaita Sans while everything else was SF Pro. Value is mine, not theirs --
# they use 'SF Pro Display 13'; Text at 11 matches the rest of this setup.
gsettings set org.gnome.desktop.wm.preferences titlebar-font      'SF Pro Text Bold 11'

# --- behaviour ----------------------------------------------------------------
say "behaviour"
gsettings set org.gnome.desktop.interface enable-hot-corners     false
# Static workspaces, fixed at 4, instead of GNOME's dynamic ones.
gsettings set org.gnome.mutter dynamic-workspaces                false
gsettings set org.gnome.desktop.wm.preferences num-workspaces    4
# Super alone does NOT open the overview -- it is freed up for Search Light.
gsettings set org.gnome.mutter overlay-key                       ''
# macOS button order, on the left.
gsettings set org.gnome.desktop.wm.preferences button-layout     'close,minimize,maximize:'
# Freed so Super+Space reaches Search Light instead of switching input source.
gsettings set org.gnome.desktop.wm.keybindings switch-input-source          "[]"
gsettings set org.gnome.desktop.wm.keybindings switch-input-source-backward "[]"
# Recorded as observed. Toggled at runtime by bin/toggle-animations, so this is
# a starting value, not a fixed part of the config.
gsettings set org.gnome.desktop.interface enable-animations      true
gsettings set org.gnome.desktop.search-providers disable-external false

# --- Dash to Dock -------------------------------------------------------------
say "dash to dock"
gsettings set org.gnome.shell.extensions.dash-to-dock hot-keys           false
# Set by `tweaks.sh -d`; needs the WhiteSur shell theme to look right.
gsettings set org.gnome.shell.extensions.dash-to-dock apply-custom-theme true

# copied from https://github.com/jothi-prasath/gnomintosh
# DOTS is the single running-app dot under the icon. FIXED holds the dock
# translucency constant -- GNOME's default shifts it as windows approach, which
# macOS never does. focus-minimize-or-previews is click-again-to-minimise.
D2D=org.gnome.shell.extensions.dash-to-dock
gsettings set $D2D running-indicator-style  'DOTS'
gsettings set $D2D transparency-mode        'FIXED'
gsettings set $D2D background-opacity       0.45
gsettings set $D2D customize-alphas         true
gsettings set $D2D max-alpha                0.75
gsettings set $D2D min-alpha                0.40
gsettings set $D2D click-action             'focus-minimize-or-previews'

# --- Search Light -------------------------------------------------------------
# Needs --schemadir: this extension is user-installed, so its schema is not in
# the system schema path.
if [[ -d "$SL_SCHEMA" ]]; then
  say "search light"
  sl() { gsettings --schemadir "$SL_SCHEMA" set org.gnome.shell.extensions.search-light "$@"; }
  sl shortcut-search    "['<Super>space']"
  sl background-color   "(0.12, 0.12, 0.13, 0.85)"
  sl border-color       "(1.0, 1.0, 1.0, 0.12)"
  sl border-radius      3.0      # index into [0,16,18,20,22,24,28,32] px
  sl border-thickness   1
  sl entry-font-size    1        # index into [0,16,18,20,22,24] pt
  sl scale-width        0.0
  sl scale-height       0.0
  sl blur-background    false
  sl show-panel-icon    false
else
  echo "  !! search-light not installed, skipping its settings" >&2
fi

# --- Just Perfection ----------------------------------------------------------
# copied from https://github.com/jothi-prasath/gnomintosh
# The two panel differences macOS has that stock GNOME does not: no Activities
# button, and the clock at the right rather than centred. Fedora packages this:
#   sudo dnf install gnome-shell-extension-just-perfection
JP=org.gnome.shell.extensions.just-perfection
if gsettings list-schemas | grep -qx "$JP"; then
  say "just perfection"
  # TRUE on purpose. In GNOME 45+ this element IS the workspace indicator --
  # the dots. gnomintosh sets it false for the macOS look, which also loses the
  # indicator; the dots are worth more than the empty corner. bin/patch-shell-theme
  # makes them visible again, because WhiteSur blanks them.
  gsettings set $JP activities-button            true
  gsettings set $JP clock-menu-position          1    # 0 centre, 1 right, 2 left
  gsettings set $JP clock-menu-position-offset   20
  gsettings set $JP window-demands-attention-focus true
else
  echo "  !! just-perfection not installed, skipping its settings" >&2
fi

# --- custom keybindings -------------------------------------------------------
# APPENDS rather than overwrites. Blindly setting custom-keybindings would drop
# any binding already on the machine (here: Super+Return -> kitty).
say "custom keybindings"
KEY_BASE="org.gnome.settings-daemon.plugins.media-keys.custom-keybinding"
LIST_KEY="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings"

add_binding() { # slug  name  command  binding
  local path="$LIST_KEY/$1/"
  local cur; cur=$(gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings)
  if [[ "$cur" != *"$path"* ]]; then
    if [[ "$cur" == "@as []" || "$cur" == "[]" ]]; then
      gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "['$path']"
    else
      gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings \
        "${cur%]}, '$path']"
    fi
    echo "    + registered $1"
  else
    echo "    = $1 already registered"
  fi
  gsettings set "$KEY_BASE:$path" name    "$2"
  gsettings set "$KEY_BASE:$path" command "$3"
  gsettings set "$KEY_BASE:$path" binding "$4"
}

add_binding custom0     'kitty'             'kitty'                          '<Super>Return'
add_binding toggle-anim 'Toggle animations' "$HOME/.local/bin/toggle-animations" '<Super><Shift>m'
add_binding toggle-refresh 'Toggle refresh rate' "$HOME/.local/bin/toggle-refresh-rate" '<Super><Shift>p'
add_binding toggle-sleep 'Toggle sleep inhibit' "$HOME/.local/bin/toggle-sleep" '<Super><Shift>k'

# --- screenshots --------------------------------------------------------------
# grim/slurp do NOT work under GNOME -- they need wlr-screencopy and
# wlr-layer-shell, which are wlroots protocols that mutter does not implement.
# The org.gnome.Shell.Screenshot D-Bus API is gated to privileged callers and
# answers AccessDenied to a plain script, so a custom snip tool is out too.
# GNOME's own screenshot UI is the rectangular snip: it opens in region-select
# mode, and copies to the clipboard as well as saving to ~/Pictures/Screenshots.
say "screenshots"
gsettings set org.gnome.shell.keybindings show-screenshot-ui "['<Super><Shift>s', 'Print']"

# --- GTK4 symlinks ------------------------------------------------------------
# install.sh -l writes gtk-Dark.css / gtk-Light.css + assets into ~/.config/gtk-4.0,
# but libadwaita only reads gtk.css. These links are what actually apply the theme.
say "gtk-4.0 symlinks"
if [[ -f "$HOME/.config/gtk-4.0/gtk-Dark.css" ]]; then
  ln -sfn "$HOME/.config/gtk-4.0/gtk-Dark.css" "$HOME/.config/gtk-4.0/gtk.css"
  ln -sfn "$HOME/.config/gtk-4.0/gtk-Dark.css" "$HOME/.config/gtk-4.0/gtk-dark.css"
  echo "    linked gtk.css and gtk-dark.css -> gtk-Dark.css"
else
  echo "  !! gtk-Dark.css missing -- run WhiteSur install.sh -l first" >&2
fi

# --- shell theme override -----------------------------------------------------
# WhiteSur's gnome-shell.css hides the workspace dots outright. This puts them
# back. Kept out of the theme itself because install.sh rewrites that file --
# re-run after any WhiteSur reinstall, like `tweaks.sh -d`.
if [[ -x "$HOME/.local/bin/patch-shell-theme" ]]; then
  say "shell theme override"
  "$HOME/.local/bin/patch-shell-theme" || true
fi

say "done. Log out and back in (Wayland cannot restart the shell in place)."
