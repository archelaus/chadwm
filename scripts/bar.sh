#!/bin/sh

# ^c$var^ = fg color
# ^b$var^ = bg color

printf "%s" $$ >~/.cache/pidofbar
sec=0

# Load colors
. ~/.local/src/chadwm/scripts/bar_themes/gruvchad

update_cpu() {
	cpu_val=$(grep "cpu " /proc/stat | awk '{usage=($3+$4)*100/($2+$4+$5)} END{print usage}')
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
		"$(free -h | awk "/^Mem/{print \$3}" | sed "s|i||g")")
}

update_wlan() {
	case $(cat /sys/class/net/wl*/operstate 2>/dev/null) in
	up)
		wlan=$(printf "^c$black^ ^b$blue^ 󰤨 ^d^%s" " ^c$blue^Connected")
		;;
	down)
		wlan=$(printf "^c$black^ ^b$blue^ 󰤭 ^d^%s" " ^c$blue^Disconnected")
		;;
	esac
}

update_clock() {
	clock=$(printf "^c$black^ ^b$darkblue^  ^c$black^^b$blue^ %s " "$(date +"%a, %H:%M")")
}

update_volume() {
	default=$(pactl info | grep "Default Sink" | cut -d" " -f3)

	if pactl list sinks | grep -A10 "$default" | grep -q "Mute: yes"; then
		icon="󰖁"
		value=" 0"
	else
		value=$(pactl get-sink-volume "$default" | grep -oP "\d+(?=%)" | head -1)
		if test "$value" -gt 70; then
			icon="󰕾"
		else
			icon=""
		fi
	fi

	volume=$(printf "^c$black^^b$darkblue^ $icon ^c$white^^b$grey^ %s" "$value")
}

update_vpn() {
	vpn=""
	nmcli con show --active | grep -qE "tun|vpn" &&
		vpn=$(printf "^c$white^ (%s)^c$green^  " "$(curl -s ipinfo.io | jq -r .country)")
}

update_record() {
	record=""
	test -f /tmp/recordingpid && record=$(printf "^c$green^ %s" " ")
}

update_spotify() {
	if pgrep -x spotify >/dev/null; then
		player="spotify"
	elif pgrep -x cmus >/dev/null; then
		player="cmus"
	else
		player=""
	fi

	if test -n "$player"; then
		artist=$(playerctl --player $player metadata artist)
		duration=$(playerctl --player $player metadata mpris:length | sed -E "s|.{6}$||")
		position=$(playerctl --player $player position | sed "s|..{6}$||")
		status=$(playerctl --player $player status)
		track=$(playerctl --player $player metadata title)

		if test "$status" = "Playing"; then
			status="▶"
		else
			status="⏸"
		fi

		spotify=$(
			printf "^c$white^ ^b$grey^[%s %s - %s %0d:%02d/%0d:%02d]" \
				"$status" "$artist" "$track" $((position % 3600 / 60)) \
				$((position % 60)) $((duration % 3600 / 60)) $((duration % 60))
		)
	fi
}

# Modules that don't update on their own need to be run at the start
# for getting their initial value
update_brightness
update_volume
update_vpn

# SIGNALLING: trap "<function>;display" "RTMIN+n"
trap "update_brightness;display" "RTMIN+2"
trap "update_record;display    " "RTMIN+4"
trap "update_volume;display    " "RTMIN+1"
trap "update_vpn;display       " "RTMIN+3"

# To update it from external commands
# kill -m "$(cat ~/.cache/pidofbar)"
# where m = 34 + n

display() {
	xsetroot -name " $record $vpn $volume $battery $brightness $mem $wlan $clock"
}

while true; do
	sleep 1 &
	wait && {
		# To update item every n seconds with a offset of m
		# [ $((sec % n)) -eq m ] && update_item

		# [ $((sec % 120)) -eq 0 ] && update_cpu
		# [ $((sec % 15)) -eq 0 ] && update_spotify
		[ $((sec % 30)) -eq 0 ] && update_wlan
		[ $((sec % 60)) -eq 0 ] && update_battery
		[ $((sec % 60)) -eq 0 ] && update_clock
		[ $((sec % 60)) -eq 0 ] && update_mem

		# How often the display updates? (5 seconds)
		[ $((sec % 5)) -eq 0 ] && display
		sec=$((sec + 1))
	}
done
