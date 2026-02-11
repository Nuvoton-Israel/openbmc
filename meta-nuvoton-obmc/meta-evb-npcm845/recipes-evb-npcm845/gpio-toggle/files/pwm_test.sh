#!/bin/bash

# PWM Setup and Test Script
# This script helps setup PWM0 and test the PWM to TACH simulator

PWM_CHIP=0
PWM_CHANNEL=0
PWM_PATH="/sys/class/pwm/pwmchip${PWM_CHIP}"
PWM_DEVICE="${PWM_PATH}/pwm${PWM_CHANNEL}"

# Default PWM parameters
PWM_PERIOD=1000000      # 1ms = 1kHz
PWM_DUTY=500000         # 50% duty cycle

usage() {
    echo "Usage: $0 [command] [options]"
    echo ""
    echo "Commands:"
    echo "  setup              - Export and enable PWM"
    echo "  cleanup            - Disable and unexport PWM"
    echo "  set <duty_percent> - Set PWM duty cycle (0-100%)"
    echo "  sweep              - Sweep duty cycle from 0% to 100%"
    echo "  status             - Show current PWM status"
    echo ""
    echo "Examples:"
    echo "  $0 setup           # Initialize PWM"
    echo "  $0 set 75          # Set 75% duty cycle"
    echo "  $0 sweep           # Test with sweeping duty cycle"
    echo "  $0 cleanup         # Clean up PWM"
}

setup_pwm() {
    echo "Setting up PWM${PWM_CHANNEL}..."
    
    # Export PWM if not already exported
    if [ ! -d "$PWM_DEVICE" ]; then
        echo "Exporting PWM${PWM_CHANNEL}..."
        echo $PWM_CHANNEL > "${PWM_PATH}/export"
        sleep 0.5
    fi
    
    # Configure PWM
    echo "Configuring PWM period and duty cycle..."
    echo $PWM_PERIOD > "${PWM_DEVICE}/period"
    echo $PWM_DUTY > "${PWM_DEVICE}/duty_cycle"
    
    # Enable PWM
    echo "Enabling PWM..."
    echo 1 > "${PWM_DEVICE}/enable"
    
    echo "PWM setup complete!"
    show_status
}

cleanup_pwm() {
    echo "Cleaning up PWM${PWM_CHANNEL}..."
    
    if [ -d "$PWM_DEVICE" ]; then
        # Disable PWM
        echo 0 > "${PWM_DEVICE}/enable" 2>/dev/null
        
        # Unexport PWM
        echo $PWM_CHANNEL > "${PWM_PATH}/unexport" 2>/dev/null
    fi
    
    echo "PWM cleanup complete!"
}

set_duty_cycle() {
    local duty_percent=$1
    
    if [ -z "$duty_percent" ]; then
        echo "Error: Please specify duty cycle percentage (0-100)"
        return 1
    fi
    
    if [ "$duty_percent" -lt 0 ] || [ "$duty_percent" -gt 100 ]; then
        echo "Error: Duty cycle must be between 0 and 100"
        return 1
    fi
    
    if [ ! -d "$PWM_DEVICE" ]; then
        echo "Error: PWM not setup. Run '$0 setup' first"
        return 1
    fi
    
    # Calculate duty cycle value
    local duty_value=$((PWM_PERIOD * duty_percent / 100))
    
    echo "Setting duty cycle to ${duty_percent}% (${duty_value} ns)..."
    echo $duty_value > "${PWM_DEVICE}/duty_cycle"
    
    show_status
}

show_status() {
    if [ ! -d "$PWM_DEVICE" ]; then
        echo "PWM${PWM_CHANNEL} is not exported"
        return
    fi
    
    local enabled=$(cat "${PWM_DEVICE}/enable")
    local period=$(cat "${PWM_DEVICE}/period")
    local duty=$(cat "${PWM_DEVICE}/duty_cycle")
    local duty_percent=$((duty * 100 / period))
    local freq_hz=$((1000000000 / period))
    
    echo ""
    echo "PWM${PWM_CHANNEL} Status:"
    echo "  Enabled:     $enabled"
    echo "  Period:      ${period} ns (${freq_hz} Hz)"
    echo "  Duty Cycle:  ${duty} ns (${duty_percent}%)"
    echo ""
}

sweep_duty_cycle() {
    echo "Sweeping PWM duty cycle from 0% to 100%..."
    echo "Press Ctrl+C to stop"
    echo ""
    
    if [ ! -d "$PWM_DEVICE" ]; then
        echo "Error: PWM not setup. Run '$0 setup' first"
        return 1
    fi
    
    while true; do
        # Sweep up from 0% to 100%
        for duty in $(seq 0 5 100); do
            set_duty_cycle $duty
            sleep 1
        done
        
        # Sweep down from 100% to 0%
        for duty in $(seq 100 -5 0); do
            set_duty_cycle $duty
            sleep 1
        done
    done
}

# Main script
case "$1" in
    setup)
        setup_pwm
        ;;
    cleanup)
        cleanup_pwm
        ;;
    set)
        set_duty_cycle "$2"
        ;;
    sweep)
        sweep_duty_cycle
        ;;
    status)
        show_status
        ;;
    *)
        usage
        exit 1
        ;;
esac
