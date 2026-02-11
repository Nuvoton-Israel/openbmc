/*
 * PWM to TACH Simulation (GPIO-based PWM Capture)
 * 
 * This program simulates a fan tachometer output based on PWM input from GPIO.
 * - Captures PWM signal from GPIO02 (gpiochip 0, line 2)
 * - Measures PWM duty cycle using edge detection
 * - Calculates corresponding TACH frequency
 * - Outputs simulated TACH signal on GPIO03 (gpiochip 0, line 3)
 * - Higher PWM duty cycle = faster TACH toggle frequency
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <errno.h>
#include <gpiod.h>
#include <signal.h>
#include <stdbool.h>
#include <time.h>
#include <math.h>

#define DEFAULT_GPIO_CHIP    "gpiochip2"
#define DEFAULT_PWM_GPIO_LINE   16  // PWM input
#define DEFAULT_TACH_GPIO_LINE  0   // TACH output

// Simulation parameters
#define MIN_FREQ_HZ     10      // Minimum TACH frequency (10 Hz at 0% duty)
#define MAX_FREQ_HZ     1000    // Maximum TACH frequency (1000 Hz at 100% duty)
#define PWM_SAMPLE_COUNT 5      // Number of PWM periods to average
#define PWM_TIMEOUT_MS  500     // Timeout for PWM measurement (ms)

// Filter parameters (optimized for 1kHz PWM signal)
#define DEBOUNCE_TIME_US     60      // NOT USED - removed for accuracy
#define DUTY_FILTER_SIZE     7       // NOT USED - removed for accuracy  
#define MIN_EDGE_INTERVAL_US 100     // ONLY filter: minimum edge interval (100us)
#define MAX_PWM_FREQ_HZ      1000    // Reference: 1kHz PWM

// Runtime GPIO configuration (can be set via command-line arguments)
static const char *gpio_chip_name = DEFAULT_GPIO_CHIP;
static unsigned int pwm_gpio_line = DEFAULT_PWM_GPIO_LINE;
static unsigned int tach_gpio_line = DEFAULT_TACH_GPIO_LINE;

static volatile bool running = true;
static struct gpiod_chip *chip = NULL;
static struct gpiod_line *pwm_line = NULL;
static struct gpiod_line *tach_line = NULL;

typedef struct {
    unsigned long long timestamp_us;
    int value;
} edge_event_t;

// Moving average filter for duty cycle
typedef struct {
    double samples[DUTY_FILTER_SIZE];
    int index;
    int count;
    double sum;
} duty_filter_t;

static duty_filter_t duty_filter = {0};

void signal_handler(int signum) {
    printf("\nReceived signal %d, shutting down...\n", signum);
    running = false;
}

int init_gpio(void) {
    chip = gpiod_chip_open_by_name(gpio_chip_name);
    if (!chip) {
        fprintf(stderr, "Failed to open GPIO chip '%s': %s\n", gpio_chip_name, strerror(errno));
        return -1;
    }
    
    // Setup PWM input
    pwm_line = gpiod_chip_get_line(chip, pwm_gpio_line);
    if (!pwm_line) {
        fprintf(stderr, "Failed to get PWM GPIO line %u: %s\n", pwm_gpio_line, strerror(errno));
        gpiod_chip_close(chip);
        return -1;
    }
    
    if (gpiod_line_request_both_edges_events(pwm_line, "pwm-tach-sim-pwm") < 0) {
        fprintf(stderr, "Failed to request PWM GPIO line %u for events: %s\n", 
                pwm_gpio_line, strerror(errno));
        gpiod_chip_close(chip);
        return -1;
    }
    
    // Setup TACH output
    tach_line = gpiod_chip_get_line(chip, tach_gpio_line);
    if (!tach_line) {
        fprintf(stderr, "Failed to get TACH GPIO line %u: %s\n", tach_gpio_line, strerror(errno));
        gpiod_line_release(pwm_line);
        gpiod_chip_close(chip);
        return -1;
    }
    
    if (gpiod_line_request_output(tach_line, "pwm-tach-sim-tach", 0) < 0) {
        fprintf(stderr, "Failed to request TACH GPIO line %u as output: %s\n", 
                tach_gpio_line, strerror(errno));
        gpiod_line_release(pwm_line);
        gpiod_chip_close(chip);
        return -1;
    }
    
    printf("GPIO initialized:\n");
    printf("  Chip:        %s\n", gpio_chip_name);
    printf("  PWM Input:   GPIO%u\n", pwm_gpio_line);
    printf("  TACH Output: GPIO%u\n", tach_gpio_line);
    return 0;
}

void cleanup_gpio(void) {
    if (tach_line) {
        gpiod_line_set_value(tach_line, 0);
        gpiod_line_release(tach_line);
    }
    if (pwm_line) {
        gpiod_line_release(pwm_line);
    }
    if (chip) {
        gpiod_chip_close(chip);
    }
}

int wait_for_edge(edge_event_t *event, int timeout_ms) {
    static unsigned long long last_edge_time = 0;
    static int last_edge_value = -1;
    static unsigned long long last_rising_time = 0;
    static unsigned long long last_falling_time = 0;
    static int rejected_count = 0;
    
    struct timespec timeout = {
        .tv_sec = timeout_ms / 1000,
        .tv_nsec = (timeout_ms % 1000) * 1000000
    };
    
    while (1) {
        int ret = gpiod_line_event_wait(pwm_line, &timeout);
        if (ret < 0) {
            return -1;
        } else if (ret == 0) {
            return 0;  // Timeout
        }
        
        struct gpiod_line_event line_event;
        ret = gpiod_line_event_read(pwm_line, &line_event);
        if (ret < 0) {
            return -1;
        }
        
        unsigned long long timestamp_us = line_event.ts.tv_sec * 1000000ULL + 
                                          line_event.ts.tv_nsec / 1000ULL;
        int value = (line_event.event_type == GPIOD_LINE_EVENT_RISING_EDGE) ? 1 : 0;
        
        // Filter for 20kHz PWM (50us period)
        if (last_edge_time > 0) {
            unsigned long long time_diff = timestamp_us - last_edge_time;
            
            // ONLY Filter: Minimum edge interval (5μs)
            // Reject edges that are too close - this catches ultra-high frequency noise
            if (time_diff < MIN_EDGE_INTERVAL_US) {
                rejected_count++;
                continue;  // Skip this edge, it's too close
            }
            
            // That's it! No other filtering.
            // With 1000 samples, averaging will smooth out any remaining noise.
        }
        
        // Valid edge detected - update tracking
        event->timestamp_us = timestamp_us;
        event->value = value;
        last_edge_time = timestamp_us;
        last_edge_value = value;
        
        if (value == 1) {
            last_rising_time = timestamp_us;
        } else {
            last_falling_time = timestamp_us;
        }
        
        // Periodically report rejected edges for debugging
        if (rejected_count > 100) {
            // Reset counter (avoid overflow and reduce log spam)
            rejected_count = 0;
        }
        
        return 1;
    }
}

// Apply moving average filter to duty cycle measurements with outlier detection
double filter_duty_cycle(double new_duty) {
    // Simplified outlier detection: only reject extreme sudden changes
    // Allow legitimate large changes (e.g., 0% to 50% is valid)
    if (duty_filter.count >= 5) {  // Only apply after we have stable history
        double current_avg = duty_filter.sum / duty_filter.count;
        double deviation = fabs(new_duty - current_avg);
        
        // Only reject if deviation is > 40% AND it's a sudden spike (not gradual)
        // This allows: 0% -> 50% (50% change, but gradual)
        // This rejects: 20% -> 80% sudden spike (60% change, sudden)
        if (deviation > 40.0) {
            // Check the last sample to see if there's a trend
            int last_idx = (duty_filter.index - 1 + DUTY_FILTER_SIZE) % DUTY_FILTER_SIZE;
            double last_sample = duty_filter.samples[last_idx];
            double last_deviation = fabs(new_duty - last_sample);
            
            // If the change from last sample is also large (>30%), it's likely a trend
            // If it's small, this is a sudden spike - reject it
            if (last_deviation < 30.0) {
                // Sudden spike detected, reject
                return current_avg;
            }
            // Else: gradual change, allow it
        }
    }
    
    // Remove oldest sample from sum
    if (duty_filter.count >= DUTY_FILTER_SIZE) {
        duty_filter.sum -= duty_filter.samples[duty_filter.index];
    }
    
    // Add new sample
    duty_filter.samples[duty_filter.index] = new_duty;
    duty_filter.sum += new_duty;
    
    // Update index and count
    duty_filter.index = (duty_filter.index + 1) % DUTY_FILTER_SIZE;
    if (duty_filter.count < DUTY_FILTER_SIZE) {
        duty_filter.count++;
    }
    
    // Return average
    return duty_filter.sum / duty_filter.count;
}

int measure_pwm_duty(double *duty_percent) {
    edge_event_t events[50];
    int event_count = 0;
    int rising_edge_count = 0;
    
    // Collect events for multiple complete periods
    int complete_cycles = 0;
    bool last_was_rising = false;
    
    while (event_count < 50 && running) {
        edge_event_t event;
        int ret = wait_for_edge(&event, PWM_TIMEOUT_MS);
        
        if (ret < 0) {
            return -1;
        } else if (ret == 0) {
            // Timeout - no signal detected
            if (event_count == 0) {
                // No edges at all - no PWM signal
                return -1;
            }
            // Had some edges but timed out - treat as incomplete signal
            break;
        }
        
        events[event_count++] = event;
        
        if (event.value == 1) {
            rising_edge_count++;
            last_was_rising = true;
        } else if (event.value == 0 && last_was_rising) {
            // Falling edge after rising = one complete cycle
            complete_cycles++;
            last_was_rising = false;
            
            // Stop after collecting enough complete cycles
            if (complete_cycles >= PWM_SAMPLE_COUNT) {
                break;
            }
        }
    }
    
    if (rising_edge_count < 2) {
        // Not enough edges to measure - no valid signal
        return -1;
    }
    
    // Calculate period and duty cycle
    unsigned long long first_rising = 0;
    unsigned long long last_rising = 0;
    unsigned long long prev_rising = 0;
    unsigned long long total_high_time = 0;
    unsigned long long total_period_time = 0;
    int period_count = 0;
    int rejected_periods = 0;
    int high_count = 0;
    unsigned long long high_start = 0;
    
    // Single pass: calculate both high times and individual periods
    for (int i = 0; i < event_count; i++) {
        if (events[i].value == 1) {  // Rising edge
            // Track first and last rising for debug
            if (first_rising == 0) {
                first_rising = events[i].timestamp_us;
            }
            last_rising = events[i].timestamp_us;
            
            // Calculate period from consecutive rising edges
            if (prev_rising > 0) {
                unsigned long long period = events[i].timestamp_us - prev_rising;
                
                // FILTER: Only accept periods in valid range for 1kHz PWM
                // Expected: 1000µs (1kHz), accept 800-1200µs (0.83-1.25kHz range, ±20%)
                // This rejects: signal gaps (>1200µs), noise spikes (<800µs)
                if (period >= 800 && period <= 1200) {
                    total_period_time += period;
                    period_count++;
                } else {
                    rejected_periods++;
                }
            }
            prev_rising = events[i].timestamp_us;
            high_start = events[i].timestamp_us;
            rising_edge_count++;
            
        } else if (events[i].value == 0 && high_start > 0) {  // Falling edge
            // Count this complete high period
            unsigned long long high_time = events[i].timestamp_us - high_start;
            
            // FILTER: Only accept high times in valid range
            // For 1kHz 50% duty, expected 500µs. 
            // Accept up to 1200µs to be safe (unlikely to have >100% duty valid high time)
            if (high_time <= 1200) {
                total_high_time += high_time;
                high_count++;
            }
            // high_start doesn't need reset effectively as it's set on RISING, 
            // but for safety we can clear it or leave check. 
            // Actually checking high_start > 0 handles the logic.
            high_start = 0;
        }
    }
    
    if (high_count == 0 || period_count == 0) {
        *duty_percent = 0.0;
        return 0;
    }
    
    // QUALITY CHECK: Reject if too many periods were rejected
    // This indicates poor signal quality or too many gaps
    int total_periods = period_count + rejected_periods;
    if (total_periods > 0) {
        double rejection_rate = (double)rejected_periods / (double)total_periods;
        if (rejection_rate > 0.4) {  // More than 40% rejected
            static int quality_warning_count = 0;
            if (quality_warning_count < 3) {
                printf("  [Poor quality: %d/%d periods rejected (%.0f%%), rejecting measurement]\n", 
                       rejected_periods, total_periods, rejection_rate * 100.0);
                quality_warning_count++;
            }
            return -1;  // Reject this measurement
        }
    }
    
    // Calculate averages from individual measurements
    double avg_high_time = (double)total_high_time / (double)high_count;
    double avg_period = (double)total_period_time / (double)period_count;
    
    if (avg_period == 0.0) {
        *duty_percent = 0.0;
        return 0;
    }
    
    // GAP DETECTION: Check if average period indicates we captured across a signal gap
    // For 1kHz PWM (1000µs period), if average period > 2000µs, we hit a gap
    if (avg_period > 2000.0) {
        // Signal gap detected - reject this measurement
        // This prevents corrupting the average with bad data
        static int gap_warning_count = 0;
        if (gap_warning_count < 3) {
            printf("  [Gap detected: avg_period=%.0f us, rejecting measurement]\n", avg_period);
            gap_warning_count++;
        }
        return -1;  // Reject this measurement
    }
    
    // Calculate duty cycle from averages
    double raw_duty = (avg_high_time / avg_period) * 100.0;
    
    // Debug output (first measurement only)
    static int debug_count = 0;
    if (debug_count < 3) {
        printf("DEBUG measure_pwm_duty:\n");
        printf("  event_count: %d\n", event_count);
        printf("  rising_edge_count: %d\n", rising_edge_count);
        printf("  period_count: %d (rejected: %d)\n", period_count, rejected_periods);
        printf("  high_count: %d\n", high_count);
        printf("  first_rising: %llu\n", first_rising);
        printf("  last_rising: %llu\n", last_rising);
        
        // Show all events
        printf("  Events collected:\n");
        for (int i = 0; i < event_count && i < 15; i++) {
            printf("    [%d] %s @ %llu", i, 
                   events[i].value ? "RISING " : "FALLING", 
                   events[i].timestamp_us);
            if (i > 0) {
                printf(" (+%llu us)", events[i].timestamp_us - events[i-1].timestamp_us);
            }
            printf("\n");
        }
        
        printf("  total_high_time: %llu us\n", total_high_time);
        printf("  total_period_time: %llu us\n", total_period_time);
        printf("  avg_high_time: %.2f us\n", avg_high_time);
        printf("  avg_period: %.2f us\n", avg_period);
        printf("  raw_duty: %.2f%%\n", raw_duty);
        debug_count++;
    }
    
    // Clamp raw duty to valid range
    if (raw_duty < 0.0) raw_duty = 0.0;
    if (raw_duty > 100.0) raw_duty = 100.0;
    
    // Return raw measurement - averaging happens at capture phase level
    *duty_percent = raw_duty;
    
    return 0;
}

int calculate_tach_frequency(double duty_percent) {
    // Linear mapping: 0% duty = MIN_FREQ_HZ, 100% duty = MAX_FREQ_HZ
    int freq = MIN_FREQ_HZ + (int)((duty_percent / 100.0) * (MAX_FREQ_HZ - MIN_FREQ_HZ));
    
    // Clamp to valid range
    if (freq < MIN_FREQ_HZ) freq = MIN_FREQ_HZ;
    if (freq > MAX_FREQ_HZ) freq = MAX_FREQ_HZ;
    
    return freq;
}

void toggle_tach(int value) {
    if (tach_line) {
        gpiod_line_set_value(tach_line, value);
    }
}

int main(int argc, char *argv[]) {
    double duty_percent = 0.0;
    int tach_freq = MIN_FREQ_HZ;
    int tach_state = 0;
    unsigned long long current_time = 0;
    unsigned long long toggle_interval_us = 0;
    unsigned long long last_toggle_time = 0;
    unsigned long long last_pwm_measure_time = 0;
    
    // New strategy: Capture PWM for 10 seconds, then output TACH for 60 seconds
    unsigned long long pwm_capture_duration_us = 10000000;   // 10 seconds capture
    unsigned long long tach_output_duration_us = 60000000;   // 60 seconds output
    unsigned long long cycle_start_time = 0;
    bool in_capture_phase = true;
    
    // Parse command-line arguments
    if (argc > 1) {
        if (strcmp(argv[1], "-h") == 0 || strcmp(argv[1], "--help") == 0) {
            printf("Usage: %s [gpiochip] [pwm_line] [tach_line]\n", argv[0]);
            printf("\nArguments:\n");
            printf("  gpiochip   - GPIO chip name (default: %s)\n", DEFAULT_GPIO_CHIP);
            printf("  pwm_line   - PWM input GPIO line number (default: %u)\n", DEFAULT_PWM_GPIO_LINE);
            printf("  tach_line  - TACH output GPIO line number (default: %u)\n", DEFAULT_TACH_GPIO_LINE);
            printf("\nExample:\n");
            printf("  %s gpiochip2 16 0\n", argv[0]);
            printf("  %s gpiochip0 2 3\n", argv[0]);
            return 0;
        }
        
        if (argc >= 2) {
            gpio_chip_name = argv[1];
        }
        if (argc >= 3) {
            pwm_gpio_line = (unsigned int)atoi(argv[2]);
        }
        if (argc >= 4) {
            tach_gpio_line = (unsigned int)atoi(argv[3]);
        }
        
        if (argc > 4) {
            fprintf(stderr, "Warning: Extra arguments ignored\n");
        }
    }
    
    printf("PWM to TACH Simulator (GPIO-based)\n");
    printf("===================================\n");
    printf("GPIO Configuration:\n");
    printf("  Chip:        %s\n", gpio_chip_name);
    printf("  PWM Input:   GPIO%u (captures PWM signal)\n", pwm_gpio_line);
    printf("  TACH Output: GPIO%u (outputs TACH signal)\n", tach_gpio_line);
    printf("Frequency Range: %d Hz - %d Hz\n", MIN_FREQ_HZ, MAX_FREQ_HZ);
    printf("\nPWM Signal Configuration:\n");
    printf("  Expected PWM Freq:  %d Hz (period: %d us)\n", MAX_PWM_FREQ_HZ, 1000000 / MAX_PWM_FREQ_HZ);
    printf("\nFilter Configuration (optimized for 20kHz PWM):\n");
    printf("  Debounce Time:      %d us (%.2f PWM periods)\n", 
           DEBOUNCE_TIME_US, (float)DEBOUNCE_TIME_US * MAX_PWM_FREQ_HZ / 1000000.0);
    printf("  Min Edge Interval:  %d us (rejects >%d kHz noise)\n", 
           MIN_EDGE_INTERVAL_US, 1000 / MIN_EDGE_INTERVAL_US);
    printf("  Duty Cycle Filter:  %d-sample moving average\n", DUTY_FILTER_SIZE);
    printf("\nMeasurement Cycle:\n");
    printf("  PWM Capture Phase:  %d seconds (collect stable average)\n", (int)(pwm_capture_duration_us / 1000000));
    printf("  TACH Output Phase:  %d seconds (stable output)\n", (int)(tach_output_duration_us / 1000000));
    printf("  Total Cycle Time:   %d seconds\n", (int)((pwm_capture_duration_us + tach_output_duration_us) / 1000000));
    printf("Press Ctrl+C to stop\n\n");
    
    // Setup signal handlers
    signal(SIGINT, signal_handler);
    signal(SIGTERM, signal_handler);
    
    // Initialize GPIO
    if (init_gpio() < 0) {
        fprintf(stderr, "Failed to initialize GPIO\n");
        return 1;
    }
    
    printf("Starting simulation...\n");
    printf("Monitoring PWM signal on GPIO%u...\n", pwm_gpio_line);
    printf("Note: If no PWM signal detected, TACH will output minimum frequency (%d Hz)\n\n", MIN_FREQ_HZ);
    
    // Initial PWM measurement (non-blocking)
    printf("Attempting initial PWM measurement (timeout: %dms)...\n", PWM_TIMEOUT_MS);
    if (measure_pwm_duty(&duty_percent) == 0) {
        tach_freq = calculate_tach_frequency(duty_percent);
        toggle_interval_us = (tach_freq > 0) ? (1000000 / (2 * tach_freq)) : 1000000;
        printf("Initial PWM Duty: %6.2f%% -> TACH Freq: %4d Hz\n", duty_percent, tach_freq);
    } else {
        // No PWM signal detected, use minimum frequency
        printf("No PWM signal detected, using minimum frequency (%d Hz)\n", MIN_FREQ_HZ);
        duty_percent = 0.0;
        tach_freq = MIN_FREQ_HZ;
        toggle_interval_us = 1000000 / (2 * MIN_FREQ_HZ);
    }
    
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    cycle_start_time = ts.tv_sec * 1000000ULL + ts.tv_nsec / 1000ULL;
    last_toggle_time = cycle_start_time;
    
    printf("TACH simulation started on GPIO%u\n", tach_gpio_line);
    printf("Starting PWM capture phase (10 seconds)...\n\n");
    
    // Accumulators for PWM capture phase
    double duty_sum = 0.0;
    int duty_count = 0;
    
    while (running) {
        // Get current time
        clock_gettime(CLOCK_MONOTONIC, &ts);
        current_time = ts.tv_sec * 1000000ULL + ts.tv_nsec / 1000ULL;
        unsigned long long elapsed_in_cycle = current_time - cycle_start_time;
        
        // Phase management
        if (in_capture_phase) {
            // PWM Capture Phase (10 seconds)
            if (elapsed_in_cycle < pwm_capture_duration_us) {
                // Continuously measure PWM and accumulate
                double new_duty;
                if (measure_pwm_duty(&new_duty) == 0) {
                    duty_sum += new_duty;
                    duty_count++;
                    
                    // Show progress every 2 seconds
                    static unsigned long long last_progress_time = 0;
                    if (last_progress_time == 0) last_progress_time = current_time;
                    if (current_time - last_progress_time >= 2000000) {
                        double avg_so_far = duty_sum / duty_count;
                        int remaining_sec = (int)((pwm_capture_duration_us - elapsed_in_cycle) / 1000000);
                        printf("  Capturing... Avg Duty: %6.2f%% (samples: %d, %ds remaining)\n", 
                               avg_so_far, duty_count, remaining_sec);
                        last_progress_time = current_time;
                    }
                }
                
                // Output TACH at current frequency during capture
                if (current_time - last_toggle_time >= toggle_interval_us) {
                    tach_state = !tach_state;
                    toggle_tach(tach_state);
                    last_toggle_time = current_time;
                }
                
                usleep(10000);  // 10ms sleep during capture
            } else {
                // Capture phase complete - calculate final duty cycle
                double raw_duty;
                if (duty_count > 0) {
                    raw_duty = duty_sum / duty_count;
                } else {
                    raw_duty = 0.0;
                }
                
                // With 1000 samples, the raw average is already very stable
                // No need for additional filtering - it causes more harm than good
                duty_percent = raw_duty;
                
                // Calculate TACH frequency
                tach_freq = calculate_tach_frequency(duty_percent);
                toggle_interval_us = (tach_freq > 0) ? (1000000 / (2 * tach_freq)) : 1000000;
                
                printf("\n✓ PWM Capture Complete!\n");
                printf("  Samples Collected: %d\n", duty_count);
                printf("  Raw Average Duty:  %6.2f%%\n", raw_duty);
                printf("  Final Duty:        %6.2f%%\n", duty_percent);
                printf("  TACH Frequency:    %4d Hz (period: %lu us)\n", 
                       tach_freq, toggle_interval_us * 2);
                printf("\nStarting TACH output phase (30 seconds)...\n\n");
                
                // Reset for output phase
                duty_sum = 0.0;
                duty_count = 0;
                in_capture_phase = false;
            }
        } else {
            // TACH Output Phase (30 seconds) - just output, no measurement
            if (elapsed_in_cycle < pwm_capture_duration_us + tach_output_duration_us) {
                // Output stable TACH signal
                if (current_time - last_toggle_time >= toggle_interval_us) {
                    tach_state = !tach_state;
                    toggle_tach(tach_state);
                    last_toggle_time = current_time;
                }
                
                // Show progress every 5 seconds
                static unsigned long long last_output_progress = 0;
                if (last_output_progress == 0) last_output_progress = current_time;
                if (current_time - last_output_progress >= 5000000) {
                    unsigned long long output_elapsed = elapsed_in_cycle - pwm_capture_duration_us;
                    int remaining_sec = (int)((tach_output_duration_us - output_elapsed) / 1000000);
                    printf("  Outputting TACH @ %d Hz (%ds remaining)\n", tach_freq, remaining_sec);
                    last_output_progress = current_time;
                }
                
                usleep(100);  // Small sleep during output
            } else {
                // Output phase complete - start new cycle
                printf("\n✓ TACH Output Complete! Starting new cycle...\n");
                printf("========================================\n\n");
                printf("Starting PWM capture phase (10 seconds)...\n\n");
                
                cycle_start_time = current_time;
                in_capture_phase = true;
            }
        }
    }
    
    printf("\nCleaning up...\n");
    cleanup_gpio();
    
    printf("Shutdown complete\n");
    return 0;
}
