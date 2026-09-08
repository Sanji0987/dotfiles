#!/usr/bin/env bash
set -euo pipefail

CFG="${XDG_CONFIG_HOME:-$HOME/.config}"
PERSIST="$CFG/sway/config.d/42-refresh.conf"

for dep in jq awk swaymsg; do
    command -v "$dep" >/dev/null || { echo "toggle-refresh: missing $dep" >&2; exit 1; }
done

read -r name w h cur < <(
    swaymsg -t get_outputs |
    jq -r 'map(select(.focused)) + map(select(.active)) | .[0]
           | "\(.name) \(.current_mode.width) \(.current_mode.height) \(.current_mode.refresh)"'
)

mapfile -t rates < <(
    swaymsg -t get_outputs |
    jq -r --arg n "$name" --argjson w "$w" --argjson h "$h" '
        .[] | select(.name == $n) | .modes[]
        | select(.width == $w and .height == $h) | .refresh' |
    sort -n | uniq
)

if [ "${#rates[@]}" -lt 2 ]; then
    command -v notify-send >/dev/null &&
        notify-send -a sway -t 2000 "Refresh rate" "$name has only one mode at ${w}x${h}" || true
    exit 0
fi

lo=${rates[0]}
hi=${rates[-1]}
if [ "$cur" -ge $(( (lo + hi) / 2 )) ]; then target=$lo; else target=$hi; fi

mode="${w}x${h}@$(awk "BEGIN{printf \"%.3f\", $target/1000}")Hz"

swaymsg output "$name" mode "$mode" >/dev/null
printf 'output %s mode %s\n' "$name" "$mode" > "$PERSIST"

command -v notify-send >/dev/null &&
    notify-send -a sway -t 1500 "Refresh rate" "$(awk "BEGIN{printf \"%.0f\", $target/1000}") Hz" || true
