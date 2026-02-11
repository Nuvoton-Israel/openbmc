/*
 * PWM Capture using GPIO
 * 
 * This program captures PWM signal using GPIO edge detection.
 * - Monitors GPIO02 (gpiochip 0, line 2) for PWM input
 * - Measures period and duty cycle
 * - Displays frequency and duty cycle percentage
 * 
 * Uses libgpiod for GPIO edge detection and timing
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
#include <sys/time.h>

#define GPIO_CHIP       "gpiochip0"
#define PWM_GPIO_LINE   2

// Measurement parameters
#define SAMPLE_COUNT    10      // Number of periods to average
#define TIMEOUT_SEC     5       // Timeout for edge detection

static volatile bool running = true;
static struct gpiod_chip *chip = NULL;
static struct gpiod_line *pwm_line = NULL;

typedef struct {
    unsigned long long timestamp_us;
    int value;
} edge_event_t;

void signal_handler(int signum) {
    printf("\nReceived signal %d, shutting down...\n", signum);
    running = false;
}

unsigned long long get_timestamp_us(void) {
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return (unsigned long long)ts.tv_sec * 1000000ULL + ts.tv_nsec / 1000ULL;
}

int init_gpio(void) {
    chip = gpiod_chip_open_by_name(GPIO_CHIP);
    if (!chip) {
        perror("Failed to open GPIO chip");
        return -1;
    }
    
    pwm_line = gpiod_chip_get_line(chip, PWM_GPIO_LINE);
    if (!pwm_line) {
        perror("Failed to get GPIO line");
        gpiod_chip_close(chip);
        return -1;
    }
    
    // Request line for both edge events
    if (gpiod_line_request_both_edges_events(pwm_line, "pwm-capture") < 0) {
        perror("Failed to request GPIO line for events");
        gpiod_chip_close(chip);
        return -1;
    }
    
    printf("GPIO initialized: %s line %d for PWM capture\n", GPIO_CHIP, PWM_GPIO_LINE);
    return 0;
}

void cleanup_gpio(void) {
    if (pwm_line) {
        gpiod_line_release(pwm_line);
    }
    if (chip) {
        gpiod_chip_close(chip);
    }
}

int wait_for_edge(edge_event_t *event, int timeout_sec) {
    struct timespec timeout = {
        .tv_sec = timeout_sec,
        .tv_nsec = 0
    };
    
    int ret = gpiod_line_event_wait(pwm_line, &timeout);
    if (ret < 0) {
        perror("Error waiting for event");
        return -1;
    } else if (ret == 0) {
        // Timeout
        return 0;
    }
    
    struct gpiod_line_event line_event;
    ret = gpiod_line_event_read(pwm_line, &line_event);
    if (ret < 0) {
        perror("Error reading event");
        return -1;
    }
    
    event->timestamp_us = line_event.ts.tv_sec * 1000000ULL + line_event.ts.tv_nsec / 1000ULL;
    event->value = (line_event.event_type == GPIOD_LINE_EVENT_RISING_EDGE) ? 1 : 0;
    
    return 1;
}

int measure_pwm(double *frequency, double *duty_cycle) {
    edge_event_t events[100];
    int event_count = 0;
    int rising_edge_count = 0;
    
    printf("Waiting for PWM signal...\n");
    
    // Collect events for multiple periods
    while (event_count < 100 && running) {
        edge_event_t event;
        int ret = wait_for_edge(&event, TIMEOUT_SEC);
        
        if (ret < 0) {
            return -1;
        } else if (ret == 0) {
            fprintf(stderr, "Timeout waiting for PWM signal\n");
            return -1;
        }
        
        events[event_count++] = event;
        
        if (event.value == 1) {
            rising_edge_count++;
            if (rising_edge_count >= SAMPLE_COUNT + 1) {
                break;
            }
        }
    }
    
    if (rising_edge_count < 2) {
        fprintf(stderr, "Not enough edges detected\n");
        return -1;
    }
    
    // Find rising edges and calculate period and duty cycle
    unsigned long long first_rising = 0;
    unsigned long long last_rising = 0;
    unsigned long long total_high_time = 0;
    unsigned long long total_period = 0;
    int period_count = 0;
    
    int i;
    for (i = 0; i < event_count; i++) {
        if (events[i].value == 1) {  // Rising edge
            if (first_rising == 0) {
                first_rising = events[i].timestamp_us;
            } else {
                last_rising = events[i].timestamp_us;
                period_count++;
            }
        }
    }
    
    if (period_count == 0) {
        fprintf(stderr, "Could not measure period\n");
        return -1;
    }
    
    // Calculate average period
    total_period = last_rising - first_rising;
    double avg_period_us = (double)total_period / period_count;
    *frequency = 1000000.0 / avg_period_us;
    
    // Calculate duty cycle by measuring high time
    unsigned long long high_start = 0;
    total_high_time = 0;
    int high_count = 0;
    
    for (i = 0; i < event_count; i++) {
        if (events[i].value == 1) {  // Rising edge
            high_start = events[i].timestamp_us;
        } else if (events[i].value == 0 && high_start > 0) {  // Falling edge
            total_high_time += events[i].timestamp_us - high_start;
            high_count++;
            high_start = 0;
        }
    }
    
    if (high_count > 0) {
        double avg_high_time_us = (double)total_high_time / high_count;
        *duty_cycle = (avg_high_time_us / avg_period_us) * 100.0;
    } else {
        *duty_cycle = 0.0;
    }
    
    return 0;
}

int main(int argc, char *argv[]) {
    double frequency = 0.0;
    double duty_cycle = 0.0;
    bool continuous = false;
    
    printf("PWM Capture Tool\n");
    printf("=================\n");
    printf("PWM Input: GPIO%d (gpiochip0 line %d)\n", PWM_GPIO_LINE, PWM_GPIO_LINE);
    printf("Sample Count: %d periods\n", SAMPLE_COUNT);
    
    // Check for continuous mode
    if (argc > 1 && strcmp(argv[1], "-c") == 0) {
        continuous = true;
        printf("Mode: Continuous monitoring\n");
        printf("Press Ctrl+C to stop\n\n");
    } else {
        printf("Mode: Single measurement\n");
        printf("Use '-c' for continuous monitoring\n\n");
    }
    
    // Setup signal handlers
    signal(SIGINT, signal_handler);
    signal(SIGTERM, signal_handler);
    
    // Initialize GPIO
    if (init_gpio() < 0) {
        fprintf(stderr, "Failed to initialize GPIO\n");
        return 1;
    }
    
    if (continuous) {
        // Continuous monitoring mode
        while (running) {
            if (measure_pwm(&frequency, &duty_cycle) == 0) {
                printf("Frequency: %8.2f Hz | Duty Cycle: %6.2f%% | Period: %8.2f us\n",
                       frequency, duty_cycle, 1000000.0 / frequency);
            } else {
                fprintf(stderr, "Measurement failed, retrying...\n");
            }
            usleep(100000);  // 100ms between measurements
        }
    } else {
        // Single measurement mode
        if (measure_pwm(&frequency, &duty_cycle) == 0) {
            printf("\n=== Measurement Results ===\n");
            printf("Frequency:   %8.2f Hz\n", frequency);
            printf("Period:      %8.2f us\n", 1000000.0 / frequency);
            printf("Duty Cycle:  %6.2f %%\n", duty_cycle);
            printf("High Time:   %8.2f us\n", (1000000.0 / frequency) * duty_cycle / 100.0);
            printf("Low Time:    %8.2f us\n", (1000000.0 / frequency) * (100.0 - duty_cycle) / 100.0);
        } else {
            fprintf(stderr, "Failed to measure PWM signal\n");
            cleanup_gpio();
            return 1;
        }
    }
    
    printf("\nCleaning up...\n");
    cleanup_gpio();
    
    printf("Shutdown complete\n");
    return 0;
}
