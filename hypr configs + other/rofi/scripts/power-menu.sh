#!/bin/bash

options="⏻ Shutdown\n⏾ Reboot\n⏼ Suspend\n Lock\n Logout"

chosen=$(echo -e "$options" | rofi -dmenu -p "Power Menu")

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
        hyprctl dispatch exec swaylock
        ;;
    " Logout")
        hyprctl dispatch exit
        ;;
esac
