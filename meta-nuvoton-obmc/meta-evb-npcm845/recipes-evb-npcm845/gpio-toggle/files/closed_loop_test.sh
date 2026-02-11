#!/bin/bash

# Closed-Loop PWM to TACH Test Script
# This script performs a complete closed-loop test of the PWM to TACH system

set -e

PWM_CHIP=0
PWM_CHANNEL=0
GPIO_PWM_OUT=2  # GPIO for PWM output (to be captured)
GPIO_TACH_OUT=3 # GPIO for TACH output

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ $1${NC}"
}

usage() {
    echo "Closed-Loop PWM to TACH Test Script"
    echo ""
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  full-test     - Run complete closed-loop test"
    echo "  capture-only  - Test PWM capture only"
    echo "  tach-only     - Test TACH simulation only"
    echo "  verify <duty> - Verify specific duty cycle"
    echo ""
    echo "Examples:"
    echo "  $0 full-test      # Run complete test suite"
    echo "  $0 verify 50      # Verify 50% duty cycle"
}

setup_pwm() {
    print_header "Setting up PWM"
    
    if pwm_test.sh setup > /dev/null 2>&1; then
        print_success "PWM setup complete"
    else
        print_error "PWM setup failed"
        return 1
    fi
}

cleanup_pwm() {
    print_info "Cleaning up PWM"
    pwm_test.sh cleanup > /dev/null 2>&1 || true
}

start_tach_sim() {
    print_header "Starting TACH Simulator"
    
    # Check if already running
    if systemctl is-active --quiet pwm-tach-sim; then
        print_info "TACH simulator already running"
        return 0
    fi
    
    systemctl start pwm-tach-sim
    sleep 1
    
    if systemctl is-active --quiet pwm-tach-sim; then
        print_success "TACH simulator started"
    else
        print_error "Failed to start TACH simulator"
        return 1
    fi
}

stop_tach_sim() {
    print_info "Stopping TACH simulator"
    systemctl stop pwm-tach-sim 2>/dev/null || true
}

test_pwm_capture() {
    local duty=$1
    
    print_info "Testing PWM capture at ${duty}% duty cycle"
    
    # Set PWM duty cycle
    pwm_test.sh set $duty > /dev/null 2>&1
    sleep 0.5
    
    # Capture PWM signal
    local output=$(timeout 10 pwm_capture 2>&1)
    
    if [ $? -eq 0 ]; then
        local measured_duty=$(echo "$output" | grep "Duty Cycle:" | awk '{print $3}')
        local measured_freq=$(echo "$output" | grep "Frequency:" | awk '{print $2}')
        
        echo "  Set: ${duty}% | Measured: ${measured_duty}% | Freq: ${measured_freq} Hz"
        
        # Check if measurement is within tolerance (±5%)
        local diff=$(echo "$measured_duty - $duty" | bc | sed 's/-//')
        if (( $(echo "$diff < 5" | bc -l) )); then
            print_success "PWM capture test passed"
            return 0
        else
            print_error "PWM capture test failed (difference: ${diff}%)"
            return 1
        fi
    else
        print_error "PWM capture failed"
        echo "$output"
        return 1
    fi
}

test_tach_output() {
    local duty=$1
    
    print_info "Testing TACH output at ${duty}% duty cycle"
    
    # Set PWM duty cycle
    pwm_test.sh set $duty > /dev/null 2>&1
    sleep 0.5
    
    # Check TACH simulator logs
    local log_output=$(journalctl -u pwm-tach-sim -n 5 --no-pager 2>&1)
    
    if echo "$log_output" | grep -q "TACH Freq"; then
        local tach_freq=$(echo "$log_output" | grep "TACH Freq" | tail -1 | awk '{print $8}')
        echo "  PWM Duty: ${duty}% | TACH Freq: ${tach_freq} Hz"
        print_success "TACH output test passed"
        return 0
    else
        print_error "TACH output test failed"
        return 1
    fi
}

verify_duty_cycle() {
    local duty=$1
    
    print_header "Verifying ${duty}% Duty Cycle"
    
    # Setup
    setup_pwm || return 1
    start_tach_sim || return 1
    
    # Test PWM capture
    test_pwm_capture $duty
    local capture_result=$?
    
    # Test TACH output
    test_tach_output $duty
    local tach_result=$?
    
    if [ $capture_result -eq 0 ] && [ $tach_result -eq 0 ]; then
        print_success "Verification complete for ${duty}%"
        return 0
    else
        print_error "Verification failed for ${duty}%"
        return 1
    fi
}

run_full_test() {
    print_header "Running Full Closed-Loop Test"
    
    local test_duties=(0 25 50 75 100)
    local passed=0
    local failed=0
    
    # Setup
    setup_pwm || exit 1
    start_tach_sim || exit 1
    
    echo ""
    print_header "Testing Multiple Duty Cycles"
    
    for duty in "${test_duties[@]}"; do
        echo ""
        if verify_duty_cycle $duty; then
            ((passed++))
        else
            ((failed++))
        fi
    done
    
    echo ""
    print_header "Test Summary"
    echo "Total Tests: $((passed + failed))"
    print_success "Passed: $passed"
    if [ $failed -gt 0 ]; then
        print_error "Failed: $failed"
    else
        echo -e "${GREEN}Failed: $failed${NC}"
    fi
    
    # Cleanup
    stop_tach_sim
    cleanup_pwm
    
    if [ $failed -eq 0 ]; then
        echo ""
        print_success "All tests passed! ✓"
        return 0
    else
        echo ""
        print_error "Some tests failed!"
        return 1
    fi
}

test_capture_only() {
    print_header "Testing PWM Capture Only"
    
    setup_pwm || exit 1
    
    local test_duties=(25 50 75)
    
    for duty in "${test_duties[@]}"; do
        echo ""
        test_pwm_capture $duty
    done
    
    cleanup_pwm
}

test_tach_only() {
    print_header "Testing TACH Simulation Only"
    
    setup_pwm || exit 1
    start_tach_sim || exit 1
    
    local test_duties=(25 50 75)
    
    for duty in "${test_duties[@]}"; do
        echo ""
        test_tach_output $duty
    done
    
    stop_tach_sim
    cleanup_pwm
}

# Main script
case "$1" in
    full-test)
        run_full_test
        ;;
    capture-only)
        test_capture_only
        ;;
    tach-only)
        test_tach_only
        ;;
    verify)
        if [ -z "$2" ]; then
            print_error "Please specify duty cycle (0-100)"
            exit 1
        fi
        verify_duty_cycle "$2"
        ;;
    *)
        usage
        exit 1
        ;;
esac
