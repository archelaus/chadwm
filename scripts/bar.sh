#!/usr/bin/env dash

# ^c$var^ = fg color
# ^b$var^ = bg color

printf '%s' "$$" >~/.cache/pidofbar
sec=0

# Load colors
. ~/.local/src/chadwm/scripts/bar_themes/gruvchad

update_cpu() {
	cpu_val=$(grep 'cpu ' /proc/stat | awk '{usage=($3+$4)*100/($2+$4+$5)} END {print usage}')
	cpu=$(printf "^c$black^^b$green^ CPU ^c$white^^b$grey^ %.1f%%" "$cpu_val")
}

update_battery() {
	get_capacity=$(cat /sys/class/power_supply/BAT1/capacity)
	battery=$(printf "^c$blue^ 󰠠 %.0f%%" "$get_capacity")
}

update_brightness() {
	brightness=$(printf "^c$red^  ^c$red^%.0f" "$(xbacklight -get)")
}

update_mem() {
	mem=$(printf "^c$blue^^b$black^  ^c$blue^^b$grey^ %s" \
		"$(free -h | awk '/^Mem/{print $3}' | sed 's|i||g')")
}

update_wlan() {
	case $(cat /sys/class/net/wl*/operstate 2>/dev/null) in
	up) wlan=$(printf "^c$black^ ^b$blue^ 󰤨 ^d^%s" " ^c$blue^Connected") ;;
	down) wlan=$(printf "^c$black^ ^b$blue^ 󰤭 ^d^%s" " ^c$blue^Disconnected") ;;
	esac
}

update_clock() {
	clock=$(printf "^c$black^ ^b$darkblue^  ^c$black^^b$blue^ %s " "$(date +'%a, %H:%M')")
}

update_volume() {
	default=$(pactl info | grep "Default Sink" | cut -f3 -d" ")
	value=$(pactl get-sink-volume @DEFAULT_SINK@ | grep -Po "\d+(?=%)" | head -1)

	if pactl list sinks | grep -A 10 "$default" | grep "Mute: yes" || [ "$value" -eq 0 ]; then
		icon="󰖁"
		value=" 0"
	else
		if [ "$value" -gt 70 ]; then
			icon="󰕾"
		else
			icon=""
		fi
	fi

	volume="$(printf "^c$black^^b$darkblue^ $icon ^c$white^^b$grey^ %s" "$value")"

}

update_vpn() {
	vpn=""
	nmcli con show --active | grep -q -E "tun|vpn" &&
		vpn=$(printf "^c$white^ (%s)^c$green^  " "$(curl -s ipinfo.io | jq -r .country)")
}

update_record() {
	record=""
	[ -f /tmp/recordingpid ] && record=$(printf "^c$green^ %s" " ")
}

# FIX: Not tested
update_spotify() {
	if pgrep -x spotify >/dev/null; then
		PLAYER="spotify"
	elif pgrep -x cmus >/dev/null; then
		PLAYER="cmus"
	else
		PLAYER=""
	fi

	if [ "$PLAYER" ]; then
		ARTIST=$(playerctl --player $PLAYER metadata artist)
		TRACK=$(playerctl --player $PLAYER metadata title)
		DURATION=$(playerctl --player $PLAYER metadata mpris:length | sed 's/.\{6\}$//')
		POSITION=$(playerctl --player $PLAYER position | sed 's/..\{6\}$//')
		STATUS=$(playerctl --player $PLAYER status)

		if [ "$STATUS" = "Playing" ]; then
			STATUS="▶"
		else
			STATUS="⏸"
		fi

		spotify="$(
			printf "^c$white^ ^b$grey^[%s %s - %s %0d:%02d/%0d:%02d]" \
				"$STATUS" "$ARTIST" "$TRACK" $((POSITION % 3600 / 60)) \
				$((POSITION % 60)) $((DURATION % 3600 / 60)) $((DURATION % 60))
		)"
	fi
}

# Modules that don't update on their own need to be run at the start for getting their initial value
update_brightness
update_volume
update_vpn

# SIGNALLING
# trap "<function>;display" "RTMIN+n"
trap "update_volume;display" "RTMIN"
trap "update_brightness;display" "RTMIN+1"
trap "update_vpn;display" "RTMIN+2"
trap "update_record;display" "RTMIN+3"

# To update it from external commands
# kill -m "$(cat ~/.cache/pidofbar)"
# where m = 34 + n

display() {
	xsetroot -name "  $record $vpn $volume $battery $brightness $mem $wlan $clock"
}

while true; do
	sleep 1 &
	wait && {
		# To update item every n seconds with a offset of m
		# [ $((sec % n)) -eq m ] && update_item
		# [ $((sec % 15)) -eq 0 ] && update_spotify
		[ $((sec % 30)) -eq 0 ] && update_wlan
		[ $((sec % 60)) -eq 0 ] && update_battery
		[ $((sec % 60)) -eq 0 ] && update_clock
		[ $((sec % 60)) -eq 0 ] && update_mem
		# [ $((sec % 120)) -eq 0 ] && update_cpu

		# How often the display updates ( 5 seconds )
		[ $((sec % 5)) -eq 0 ] && display
		sec=$((sec + 1))
	}
done
