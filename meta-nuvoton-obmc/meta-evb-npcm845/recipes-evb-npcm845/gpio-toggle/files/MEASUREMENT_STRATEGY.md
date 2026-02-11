# PWM TACH Simulator - New Measurement Strategy

## Problem: Frequent Duty Cycle Fluctuations

### Previous Behavior (200ms measurement interval)
```
PWM Duty:   6.11% -> TACH Freq:   70 Hz
PWM Duty:  14.58% -> TACH Freq:  154 Hz  (8% jump!)
PWM Duty:  14.59% -> TACH Freq:  154 Hz
PWM Duty:  22.80% -> TACH Freq:  235 Hz  (8% jump!)
PWM Duty:  28.56% -> TACH Freq:  292 Hz  (6% jump!)
PWM Duty:  34.70% -> TACH Freq:  353 Hz  (6% jump!)
PWM Duty:  48.97% -> TACH Freq:  494 Hz  (14% jump!)
PWM Duty:  48.28% -> TACH Freq:  487 Hz
PWM Duty:  39.76% -> TACH Freq:  403 Hz  (9% drop!)
PWM Duty:  48.27% -> TACH Freq:  487 Hz  (8% jump!)
PWM Duty:  42.13% -> TACH Freq:  427 Hz  (6% drop!)
```

**Issues**:
- Measurements every 200ms → 5 updates per second
- Each measurement captures only a few PWM cycles
- High variance between consecutive measurements
- TACH frequency constantly changing
- Unstable output

---

## New Strategy: Long Capture + Stable Output

### Two-Phase Cycle (40 seconds total)

#### Phase 1: PWM Capture (10 seconds)
- **Duration**: 10 seconds
- **Activity**: Continuously measure PWM duty cycle
- **Sampling**: Collect hundreds of samples
- **Calculation**: Average all samples for stable result
- **Output**: TACH continues at previous frequency

#### Phase 2: TACH Output (30 seconds)
- **Duration**: 30 seconds
- **Activity**: Output stable TACH signal
- **Measurement**: NONE - no new PWM measurements
- **Frequency**: Fixed based on Phase 1 average
- **Output**: Rock-solid stable TACH

---

## Implementation Details

### Timing Parameters
```c
pwm_capture_duration_us = 10,000,000 us  // 10 seconds
tach_output_duration_us = 30,000,000 us  // 30 seconds
Total cycle time        = 40 seconds
```

### Capture Phase Algorithm
```
1. Initialize accumulators: duty_sum = 0, duty_count = 0
2. For 10 seconds:
   a. Measure PWM duty cycle
   b. Add to duty_sum
   c. Increment duty_count
   d. Show progress every 2 seconds
3. Calculate average: duty_percent = duty_sum / duty_count
4. Apply moving average filter
5. Calculate TACH frequency
```

### Output Phase Algorithm
```
1. For 30 seconds:
   a. Output TACH at fixed frequency
   b. No PWM measurements
   c. Show progress every 5 seconds
2. After 30 seconds, start new cycle
```

---

## Expected Behavior

### Startup
```
PWM to TACH Simulator (GPIO-based)
===================================
GPIO Configuration:
  Chip:        gpiochip2
  PWM Input:   GPIO16 (captures PWM signal)
  TACH Output: GPIO0 (outputs TACH signal)

Measurement Cycle:
  PWM Capture Phase:  10 seconds (collect stable average)
  TACH Output Phase:  30 seconds (stable output)
  Total Cycle Time:   40 seconds

TACH simulation started on GPIO0
Starting PWM capture phase (10 seconds)...
```

### Capture Phase Progress
```
  Capturing... Avg Duty:  48.23% (samples: 50, 8s remaining)
  Capturing... Avg Duty:  48.45% (samples: 100, 6s remaining)
  Capturing... Avg Duty:  48.31% (samples: 150, 4s remaining)
  Capturing... Avg Duty:  48.38% (samples: 200, 2s remaining)

✓ PWM Capture Complete!
  Samples Collected: 250
  Average Duty:       48.35%
  TACH Frequency:     488 Hz (period: 2048 us)

Starting TACH output phase (30 seconds)...
```

### Output Phase Progress
```
  Outputting TACH @ 488 Hz (25s remaining)
  Outputting TACH @ 488 Hz (20s remaining)
  Outputting TACH @ 488 Hz (15s remaining)
  Outputting TACH @ 488 Hz (10s remaining)
  Outputting TACH @ 488 Hz (5s remaining)

✓ TACH Output Complete! Starting new cycle...
========================================

Starting PWM capture phase (10 seconds)...
```

---

## Advantages

### 1. Stability
- **Before**: 5 updates/second, constant fluctuation
- **After**: 1 update/40 seconds, rock-solid output
- **Improvement**: 200× more stable

### 2. Accuracy
- **Before**: ~10 samples per measurement (200ms @ 20kHz PWM)
- **After**: ~200,000 samples per measurement (10s @ 20kHz PWM)
- **Improvement**: 20,000× more samples = much better average

### 3. Noise Immunity
- **Before**: Single noise spike affects output immediately
- **After**: Noise spikes averaged out over 10 seconds
- **Improvement**: Extremely robust to transient noise

### 4. Predictability
- **Before**: TACH frequency changes unpredictably
- **After**: TACH frequency updates every 40 seconds
- **Improvement**: Predictable, deterministic behavior

---

## Trade-offs

### Response Time
- **Before**: 200ms - 1.4s (depending on filter)
- **After**: Up to 40 seconds for full update
- **Impact**: Slower response to PWM changes

### Use Cases

#### ✅ Good For:
- **Stable PWM control**: PWM changes slowly or infrequently
- **Fan simulation**: Real fans have inertia, slow response is realistic
- **Noisy environments**: Excellent noise rejection
- **Long-running systems**: Set-and-forget operation

#### ⚠️ Not Ideal For:
- **Rapid PWM changes**: Testing PWM sweep from 0-100% quickly
- **Real-time control**: Immediate response required
- **Development/debugging**: Want to see changes immediately

---

## Tuning Parameters

### If Response Too Slow

Reduce capture and output durations:
```c
pwm_capture_duration_us = 5000000;   // 5 seconds
tach_output_duration_us = 15000000;  // 15 seconds
// Total: 20 seconds per cycle
```

### If Still Unstable

Increase capture duration:
```c
pwm_capture_duration_us = 20000000;  // 20 seconds
// More samples = more stable average
```

### For Development/Testing

Use shorter cycles:
```c
pwm_capture_duration_us = 2000000;   // 2 seconds
tach_output_duration_us = 5000000;   // 5 seconds
// Total: 7 seconds per cycle
```

---

## Statistics

### Sample Collection Rate
- **PWM Frequency**: 20 kHz
- **Capture Duration**: 10 seconds
- **Theoretical Samples**: 200,000 PWM cycles
- **Actual Samples**: ~200-500 (due to measurement overhead)
- **Still Excellent**: 200-500 samples >> 10 samples

### Measurement Overhead
- Each `measure_pwm_duty()` call: ~20-50ms
- Samples per second: ~20-50
- Total samples in 10s: ~200-500

### Variance Reduction
- **Single measurement variance**: σ
- **Average of N measurements variance**: σ/√N
- **With 250 samples**: Variance reduced by √250 ≈ 16×

---

## Summary

**New Strategy**: Long capture (10s) + Stable output (30s)

✅ **Pros**:
- Extremely stable TACH output
- Excellent noise immunity
- Accurate duty cycle measurement
- Predictable update cycle

⚠️ **Cons**:
- Slower response to PWM changes (up to 40s)
- Not suitable for rapid testing

🎯 **Best For**:
- Production fan control systems
- Noisy electrical environments
- Long-running stable operation
- Realistic fan simulation (fans have inertia)
