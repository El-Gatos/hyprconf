#!/bin/bash

options="⏻ Shutdown\n⏾ Reboot\n⏼ Suspend\n Lock\n Logout"

chosen=$(echo -e "$options" | rofi -dmenu -p "Power Menu" -theme-str 'window {width: 300px;}')

case $chosen in
    "⏻ Shutdown")
        systemctl poweroff
        ;;
    "⏾ Reboot")
        systemctl reboot
        ;;
    "⏼ Suspend")
        systemctl suspend
        ;;
    " Lock")
        swaylock
        ;;
    " Logout")
        hyprctl dispatch exit
        ;;
esac
