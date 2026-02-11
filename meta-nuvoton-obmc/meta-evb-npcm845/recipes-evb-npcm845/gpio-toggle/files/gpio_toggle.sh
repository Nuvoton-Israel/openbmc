#!/bin/bash

# GPIO toggle script
# Toggles GPIO pin 3 on gpiochip 0 with 3ms delays

while true; do
    gpioset 0 3=0
    sleep 0.003
    gpioset 0 3=1
    sleep 0.003
done
