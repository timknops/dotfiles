#!/bin/bash

if type "xrandr"; then
  for m in $(xrandr --query | grep " connected" | cut -d" " -f1); do
    MONITOR=$m polybar --reload top --config=$HOME/.config/polybar/config.ini &
  done
else
  polybar --reload top &
fi

