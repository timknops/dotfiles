#!/bin/bash
# Add a small delay to ensure X is fully ready
sleep 2
setxkbmap -option ctrl:nocaps
xcape -e 'Control_L=Escape'
xrandr --output DP-2 --mode 1920x1080 --rate 144.00
.config/wallpaper_cycle &

dunst &

shutdown -h 23:00

shutdown_time=$(date -d "23:00" +%s)
current_time=$(date +%s)
time_until_shutdown=$((shutdown_time - current_time))

if [ $time_until_shutdown -gt 300 ]; then
    sleep $((time_until_shutdown - 300))
    notify-send "System Shutdown" "System will shut down in 5 minutes."
fi
