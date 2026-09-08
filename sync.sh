#!/usr/bin/env bash
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CFG="${XDG_CONFIG_HOME:-$HOME/.config}"
IFACE=org.gnome.desktop.interface

# simplified by Claude Code Opus: sway/config.d is globbed rather than listed by
# hand, and the sync/restore loops share one copy helper
files_in() {
    printf '%s\n' \
        kitty/kitty.conf \
        kitty/current-theme.conf \
        waybar/config.jsonc \
        waybar/style.css \
        waybar/scripts/power-profile-cycle.sh \
        rofi/config.rasi \
        rofi/omarchy-tokyo-night.rasi \
        gtk-3.0/settings.ini \
        gtk-4.0/settings.ini
    (cd "$1" 2>/dev/null && find sway/config.d -name '*.conf' -type f 2>/dev/null | sort) || true
    (cd "$1" 2>/dev/null && find sway/scripts -name '*.sh' -type f 2>/dev/null | sort) || true
}

copy() {
    mkdir -p "$(dirname "$2")"
    cp -a "$1" "$2"
}

case "${1:-sync}" in
sync)
    n=0
    while read -r f; do
        [[ -f "$CFG/$f" ]] || { echo "  skip (missing): $f" >&2; continue; }
        copy "$CFG/$f" "$REPO/config/$f"
        n=$((n + 1))
    done < <(files_in "$CFG")

    {
        echo '#!/usr/bin/env bash'
        for k in color-scheme gtk-theme font-name monospace-font-name \
                 document-font-name enable-animations; do
            printf "gsettings set %s %s %s\n" "$IFACE" "$k" \
                   "$(gsettings get "$IFACE" "$k")"
        done
    } > "$REPO/gsettings.sh"
    chmod +x "$REPO/gsettings.sh"
    echo "synced $n files -> $REPO/config/"
    ;;
restore)
    while read -r f; do
        [[ -f "$REPO/config/$f" ]] || continue
        copy "$REPO/config/$f" "$CFG/$f"
    done < <(files_in "$REPO/config")
    bash "$REPO/gsettings.sh"
    echo "restored -> $CFG/  (run: swaymsg reload)"
    ;;
*)
    echo "usage: $0 [sync|restore]" >&2
    exit 1
    ;;
esac
