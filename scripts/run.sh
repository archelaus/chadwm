#!/bin/sh

_px() {
	pgrep -x "$@"
}

_ka() {
	killall "$@"
}

setxkbmap -option caps:swapescape
xrdb merge ~/.config/x11/xresources

# Run once and never kill
_px sxhkd >/dev/null || sxhkd 2>&1 | tee ~/.cache/logs/autostart/sxhkd.log &
_px greenclip >/dev/null || greenclip daemon 2>&1 | tee ~/.cache/logs/autostart/greenclip.log &

# Kill all already running autostart programs
_ka dunst >/dev/null
_ka xidlehook >/dev/null

# Set wallpaper
setroot --restore

# Create a log directory for autostarted apps
[ -d ~/.cache/logs ] || mkdir ~/.cache/logs
[ -d ~/.cache/logs/autostart ] || mkdir ~/.cache/logs/autostart

# Start dunst and log
dunst -verbosity warn 2>&1 | tee ~/.cache/logs/autostart/dunst.log &

# Start xidlehook
xidlehook --not-when-fullscreen --detect-sleep --not-when-audio \
	--timer 300 "xrandr --output eDP1 --brightness .1" "xrandr --output eDP1 --brightness 1" \
	--timer 300 "xrandr --output eDP1 --brightness 1; i3lock-extra" "" \
	--timer 300 "systemctl suspend" "" &

firefox -P default &
kdeconnect-indicator &
syncthing serve --no-browser &
workrave &

~/.local/share/virtualenvs/yt/bin/python ~/.local/src/youtube-local/server.py &

~/.local/src/chadwm/scripts/bar.sh &

while type chadwm >/dev/null; do
	chadwm && continue || break
done
