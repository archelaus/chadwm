#!/bin/sh

setroot --restore
setxkbmap -option caps:swapescape
xrdb merge ~/.config/x11/xresources

dunst &
greenclip daemon &
sxhkd &

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
