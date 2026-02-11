#!/bin/bash
# Test script for parameterized pwm_tach_sim
# Demonstrates different GPIO configurations

echo "PWM TACH Simulator - Parameter Test"
echo "====================================="
echo ""

# Show help
echo "1. Showing help:"
pwm_tach_sim --help
echo ""

# Test with default parameters (no arguments)
echo "2. Test with default parameters:"
echo "   Command: pwm_tach_sim"
echo "   (Uses: gpiochip2, PWM=GPIO16, TACH=GPIO0)"
echo ""

# Test with custom parameters
echo "3. Test with custom parameters:"
echo "   Command: pwm_tach_sim gpiochip2 16 0"
echo "   (Explicitly set: gpiochip2, PWM=GPIO16, TACH=GPIO0)"
echo ""

# Test with alternative GPIO configuration
echo "4. Test with alternative configuration:"
echo "   Command: pwm_tach_sim gpiochip0 2 3"
echo "   (Uses: gpiochip0, PWM=GPIO2, TACH=GPIO3)"
echo ""

echo "To run the simulator, use one of the following commands:"
echo "  pwm_tach_sim                    # Use defaults"
echo "  pwm_tach_sim gpiochip2 16 0     # Specify all parameters"
echo "  pwm_tach_sim gpiochip0 2 3      # Alternative configuration"
