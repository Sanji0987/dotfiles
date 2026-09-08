#!/usr/bin/env bash
set -euo pipefail

IFACE=org.gnome.desktop.interface
CFG="${XDG_CONFIG_HOME:-$HOME/.config}"

if [ "$(gsettings get "$IFACE" enable-animations)" = "true" ]; then
    new=false; flag=0; state=off
else
    new=true;  flag=1; state=on
fi

gsettings set "$IFACE" enable-animations "$new"

for d in gtk-3.0 gtk-4.0; do
    f="$CFG/$d/settings.ini"
    [ -f "$f" ] || continue
    if grep -q '^gtk-enable-animations=' "$f"; then
        sed -i "s/^gtk-enable-animations=.*/gtk-enable-animations=$flag/" "$f"
    else
        printf 'gtk-enable-animations=%s\n' "$flag" >> "$f"
    fi
done

command -v notify-send >/dev/null && notify-send -a sway -t 1500 "Animations" "$state" || true
