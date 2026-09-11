#!/usr/bin/env bash
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CFG="${XDG_CONFIG_HOME:-$HOME/.config}"
IFACE=org.gnome.desktop.interface

CFG_DIRS=(kitty waybar rofi gtk-3.0 gtk-4.0 sway)
HOME_FILES=(display_rate)

files_in() {
    printf '%s\n' mimeapps.list
    for d in "${CFG_DIRS[@]}"; do
        (cd "$1" 2>/dev/null && find "$d" -type f 2>/dev/null | sort) || true
    done
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

    for f in "${HOME_FILES[@]}"; do
        [[ -f "$HOME/$f" ]] || { echo "  skip (missing): ~/$f" >&2; continue; }
        copy "$HOME/$f" "$REPO/home/$f"
        n=$((n + 1))
    done

    while IFS= read -r f; do
        rel="${f#"$REPO/config/"}"
        [[ -f "$CFG/$rel" ]] || { rm -f "$f"; echo "  pruned: $rel"; }
    done < <(find "$REPO/config" -type f 2>/dev/null)

    {
        echo '#!/usr/bin/env bash'
        for k in color-scheme gtk-theme font-name monospace-font-name \
                 document-font-name enable-animations; do
            printf "gsettings set %s %s %s\n" "$IFACE" "$k" \
                   "$(gsettings get "$IFACE" "$k")"
        done
    } > "$REPO/gsettings.sh"
    chmod +x "$REPO/gsettings.sh"
    echo "synced $n files -> $REPO"
    ;;
restore)
    while read -r f; do
        [[ -f "$REPO/config/$f" ]] || continue
        copy "$REPO/config/$f" "$CFG/$f"
    done < <(files_in "$REPO/config")

    for f in "${HOME_FILES[@]}"; do
        [[ -f "$REPO/home/$f" ]] || continue
        copy "$REPO/home/$f" "$HOME/$f"
    done

    bash "$REPO/gsettings.sh"
    echo "restored -> $CFG/ and $HOME/  (reboot or re-login to apply sway changes)"
    ;;
*)
    echo "usage: $0 [sync|restore]" >&2
    exit 1
    ;;
esac
