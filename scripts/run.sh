#!/bin/sh

_px() {
	pgrep -x "$@"
}

_ka() {
	killall "$@"
}

# Set wallpaper
setroot --restore

setxkbmap -option caps:swapescape
xrdb merge ~/.config/x11/xresources

# Create a log directory for autostarted apps
LOG_DIR=~/.cache/logs/autostart
[ -d "$LOG_DIR" ] || mkdir -p "$LOG_DIR"

# Run once and never kill
_px greenclip >/dev/null || greenclip daemon 2>&1 &
_px sxhkd >/dev/null || sxhkd 2>&1 | tee "$LOG_DIR/sxhkd.log" &

# Kill all already running autostart programs
_ka bar.sh >/dev/null
_ka dunst >/dev/null
_ka python >/dev/null
_ka xidlehook >/dev/null

# Start dunst and log
dunst -verbosity warn 2>&1 | tee "$LOG_DIR/dunst.log" &

# Start xidlehook
xidlehook --detect-sleep --not-when-audio --not-when-fullscreen \
	--timer 300 "xrandr --output eDP1 --brightness .1" "xrandr --output eDP1 --brightness 1" \
	--timer 300 "xrandr --output eDP1 --brightness 1; i3lock-extra" "" \
	--timer 300 "systemctl suspend" "" &

firefox -P default &
kdeconnect-indicator &
syncthing serve --no-browser &
workrave &

~/.local/share/virtualenvs/yt/bin/python ~/.local/src/youtube-local/server.py &

~/.local/src/chadwm/scripts/bar.sh 2>&1 | tee "$LOG_DIR/dwm-bar.log" &

while type chadwm >/dev/null; do
	chadwm && continue || break
done
