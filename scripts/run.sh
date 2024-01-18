#!/bin/sh

setroot --restore
# xmodmap ~/.Xmodmap
xrdb merge ~/.config/x11/xresources

dunst &
greenclip daemon &
sxhkd &

xidlehook --not-when-fullscreen --detect-sleep --not-when-audio \
	--timer 300 "xrandr --output eDP1 --brightness .1" "xrandr --output eDP1 --brightness 1" \
	--timer 300 "xrandr --output eDP1 --brightness 1; i3lock-extra" "" \
	--timer 300 "sudo systemctl suspend" "" &

# for id in $(xinput list | grep "AT Translated Set 2 keyboard" | sed -E 's|.*=([0-9]+).*|\1|'); do
# 	xinput float "$id"
# done

# https://gist.github.com/bumbummen99/fcab50dad5638399375693a70a8c17f4
# xinput set-button-map 15 1 0 3 4 5 6 7

firefox &
kdeconnect-indicator &
syncthing serve --no-browser &
workrave &

~/.local/share/virtualenvs/yt/bin/python ~/.local/src/youtube-local/server.py &
# python -m http.server 7389 --directory ~/.local/src/_traichu/ &

~/.local/src/chadwm/scripts/bar.sh &

while type chadwm >/dev/null; do
	chadwm && continue || break
done
