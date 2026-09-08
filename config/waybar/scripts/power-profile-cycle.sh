#!/usr/bin/env bash
set -euo pipefail
DEST=net.hadess.PowerProfiles
OBJ=/net/hadess/PowerProfiles

cur=$(busctl get-property "$DEST" "$OBJ" "$DEST" ActiveProfile | sed 's/^s "//; s/"$//')
case "$cur" in
    power-saver) next=balanced    ;;
    balanced)    next=performance ;;
    performance) next=power-saver ;;
    *)           next=balanced    ;;
esac

busctl set-property "$DEST" "$OBJ" "$DEST" ActiveProfile s "$next"
command -v notify-send >/dev/null && notify-send -a waybar -t 1500 "Power profile" "$next" || true
