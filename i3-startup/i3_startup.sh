#!/bin/bash
# Add a small delay to ensure X is fully ready
sleep 2
setxkbmap -option ctrl:nocaps
xcape -e 'Control_L=Escape'
xrandr --output DP-3 --mode 1920x1080 --rate 144.00
