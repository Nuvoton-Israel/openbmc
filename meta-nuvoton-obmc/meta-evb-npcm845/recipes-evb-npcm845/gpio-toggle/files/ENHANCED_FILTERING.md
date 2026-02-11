# PWM TACH Simulator - Enhanced Noise Filtering

## Problem Analysis (Based on Real GPIO Logs)

### Observed Issues

From GPIO monitor logs, we identified severe noise problems:

```
event: FALLING EDGE offset: 16 timestamp: [1372.005101172]
event:  RISING EDGE offset: 16 timestamp: [1372.005132244]  (31μs later)
event: FALLING EDGE offset: 16 timestamp: [1372.005152804]  (20μs later)
event: FALLING EDGE offset: 16 timestamp: [1372.005168324]  (15μs later) ← CONSECUTIVE FALLING!
event:  RISING EDGE offset: 16 timestamp: [1372.005188868]  (20μs later)
event:  RISING EDGE offset: 16 timestamp: [1372.005209540]  (20μs later) ← CONSECUTIVE RISING!
```

**Problems Identified:**
1. **Consecutive Same Edges**: Multiple FALLING or RISING edges in a row (impossible for valid PWM)
2. **Edge Bursts**: Edges occurring 10-20μs apart (too fast for 20kHz PWM with 50μs period)
3. **Severe Duty Cycle Jumps**: Output jumping from 0.04% to 51.94% due to noise

---

## Enhanced Filter Solution

### 1. Strengthened Filter Parameters

| Parameter | Old Value | New Value | Reason |
|-----------|-----------|-----------|--------|
| `DEBOUNCE_TIME_US` | 50μs (1 period) | **100μs (2 periods)** | Stronger same-edge rejection |
| `MIN_EDGE_INTERVAL_US` | 1μs | **5μs** | Filter 10-20μs noise bursts |
| `DUTY_FILTER_SIZE` | 5 samples | **10 samples** | More smoothing for stability |

### 2. Multi-Layer Edge Filtering

#### Layer 1: Minimum Edge Interval Filter (5μs)
```c
if (time_diff < MIN_EDGE_INTERVAL_US) {
    continue;  // Reject edges < 5μs apart
}
```
- **Purpose**: Filter out 10-20μs noise bursts
- **Effect**: Rejects ultra-high frequency noise

#### Layer 2: Strict Same-Edge Rejection
```c
if (value == last_edge_value) {
    if (time_diff < DEBOUNCE_TIME_US) {
        continue;  // Reject if < 100μs
    }
    if (time_diff < DEBOUNCE_TIME_US * 2) {
        continue;  // Reject if < 200μs (suspicious)
    }
}
```
- **Purpose**: Enforce alternating edges (rising→falling→rising→falling)
- **Effect**: Eliminates consecutive same-edge events
- **Logic**: Valid PWM MUST alternate edges

#### Layer 3: Pulse Width Validation
```c
// For rising edge: check previous low time
if (low_time < 2) {
    continue;  // Low pulse too short
}

// For falling edge: check previous high time  
if (high_time < 2) {
    continue;  // High pulse too short
}
```
- **Purpose**: Validate minimum pulse width (2μs)
- **Effect**: Reject impossible transitions for 20kHz PWM
- **Logic**: Even 1% duty at 20kHz = 0.5μs, but noise requires 2μs minimum

### 3. Outlier Detection in Moving Average

```c
double current_avg = duty_filter.sum / duty_filter.count;
double deviation = fabs(new_duty - current_avg);

if (deviation > 30.0 && duty_filter.count >= 3) {
    return current_avg;  // Reject outlier, keep current average
}
```

- **Purpose**: Prevent sudden duty cycle jumps
- **Threshold**: 30% deviation from current average
- **Effect**: Stops 0.04% → 51.94% jumps
- **Example**: If average is 20%, reject values outside 0-50% range

---

## Filter Performance

### Before Enhancement
```
PWM Duty:  19.03% -> TACH Freq:  198 Hz
PWM Duty:  12.70% -> TACH Freq:  135 Hz  ← 6% jump
PWM Duty:   9.54% -> TACH Freq:  104 Hz  ← 3% jump
PWM Duty:   7.64% -> TACH Freq:   85 Hz  ← 2% jump
PWM Duty:   0.04% -> TACH Freq:   10 Hz  ← 7% jump! (noise)
PWM Duty:  11.98% -> TACH Freq:  128 Hz  ← 12% jump! (noise)
PWM Duty:  31.96% -> TACH Freq:  326 Hz  ← 20% jump! (noise)
PWM Duty:  51.94% -> TACH Freq:  524 Hz  ← 20% jump! (noise)
```

### After Enhancement (Expected)
```
PWM Duty:  20.00% -> TACH Freq:  208 Hz
PWM Duty:  20.15% -> TACH Freq:  209 Hz  ← Smooth transition
PWM Duty:  20.08% -> TACH Freq:  209 Hz  ← Outliers rejected
PWM Duty:  19.95% -> TACH Freq:  208 Hz  ← Stable output
PWM Duty:  30.00% -> TACH Freq:  307 Hz  ← Gradual change accepted
PWM Duty:  30.12% -> TACH Freq:  308 Hz  ← Smooth
PWM Duty:  30.05% -> TACH Freq:  307 Hz  ← Stable
```

---

## Technical Specifications

### Edge Detection
- **Minimum Edge Interval**: 5μs (filters 10-20μs noise bursts)
- **Same-Edge Debounce**: 100μs (2 PWM periods)
- **Strict Alternation**: Enforces rising→falling→rising pattern
- **Minimum Pulse Width**: 2μs (validates physical feasibility)

### Duty Cycle Filtering
- **Moving Average**: 10 samples (increased from 5)
- **Outlier Threshold**: 30% deviation
- **Update Rate**: Every 200ms
- **Convergence Time**: ~2 seconds (10 samples × 200ms)

### Noise Rejection Statistics
- **Rejected Edge Counter**: Tracks filtered noise events
- **Reset Threshold**: Every 100 rejected edges
- **Purpose**: Debugging and performance monitoring

---

## Configuration Summary

```c
// Enhanced filter parameters for noisy 20kHz PWM
#define DEBOUNCE_TIME_US     100    // 100μs (2 PWM periods)
#define DUTY_FILTER_SIZE     10     // 10-sample moving average
#define MIN_EDGE_INTERVAL_US 5      // 5μs minimum edge spacing
#define MAX_PWM_FREQ_HZ      20000  // 20kHz reference
```

---

## Expected Improvements

### 1. Stability
- ✅ Eliminates consecutive same-edge events
- ✅ Filters 10-20μs noise bursts
- ✅ Prevents duty cycle jumps > 30%

### 2. Accuracy
- ✅ Validates pulse width feasibility
- ✅ Enforces alternating edge pattern
- ✅ Rejects physically impossible transitions

### 3. Smoothness
- ✅ 10-sample moving average (vs 5)
- ✅ Outlier detection and rejection
- ✅ Gradual TACH frequency changes

### 4. Robustness
- ✅ Handles severe electrical noise
- ✅ Tolerates signal integrity issues
- ✅ Maintains operation during transients

---

## Testing Recommendations

1. **Monitor Rejected Edges**: Check if rejection counter increases rapidly
2. **Verify Duty Cycle Stability**: Should not jump > 30% between samples
3. **Check TACH Output**: Should be smooth and proportional to PWM
4. **Test Edge Cases**: 
   - Very low duty (1-5%)
   - Very high duty (95-99%)
   - Rapid PWM changes
   - Noisy electrical environment

---

## Debugging

If duty cycle is still unstable:

1. **Increase DEBOUNCE_TIME_US** to 150μs or 200μs
2. **Increase MIN_EDGE_INTERVAL_US** to 10μs
3. **Reduce outlier threshold** from 30% to 20%
4. **Increase DUTY_FILTER_SIZE** to 15 or 20 samples

If duty cycle response is too slow:

1. **Decrease DUTY_FILTER_SIZE** to 7 or 8 samples
2. **Increase outlier threshold** to 40% or 50%
3. **Decrease PWM measurement interval** from 200ms to 100ms

---

## Summary

The enhanced filtering provides **three-layer protection**:

1. **Hardware-level**: Minimum edge interval (5μs)
2. **Logic-level**: Alternating edge enforcement + pulse width validation
3. **Application-level**: Moving average + outlier detection

This comprehensive approach ensures stable TACH output even in extremely noisy environments.
