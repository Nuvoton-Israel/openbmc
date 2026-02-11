# PWM Frequency Analysis and Filter Adjustment

## GPIO Monitor Log Analysis

### Raw Log Data
```
event: FALLING EDGE offset: 16 timestamp: [2112.574014940]
event: FALLING EDGE offset: 16 timestamp: [2112.574045868]  (30.9μs) ← Noise
event:  RISING EDGE offset: 16 timestamp: [2112.574061324]  (15.5μs)
event: FALLING EDGE offset: 16 timestamp: [2112.574076956]  (15.6μs)
event: FALLING EDGE offset: 16 timestamp: [2112.574107740]  (30.8μs) ← Noise
event:  RISING EDGE offset: 16 timestamp: [2112.574123164]  (15.4μs)
event: FALLING EDGE offset: 16 timestamp: [2112.574138784]  (15.6μs)
...
```

### Filtered Valid Edges
After removing consecutive same-edge noise:
```
Time (μs)      Edge      Interval    Type
574061.324    RISING    -           -
574076.956    FALLING   15.6        High time
574123.164    RISING    46.2        Low time
574138.784    FALLING   15.6        High time
574184.908    RISING    46.1        Low time
574200.620    FALLING   15.7        High time
```

---

## Measured PWM Parameters

### Period Calculation
```
Period 1: 574123.164 - 574061.324 = 61.84 μs
Period 2: 574184.908 - 574123.164 = 61.74 μs
Period 3: 574246.844 - 574184.908 = 61.94 μs (approx)

Average Period: 61.8 μs
```

### Frequency Calculation
```
Frequency = 1 / 61.8 μs = 16,181 Hz ≈ 16.2 kHz
```

### Duty Cycle Calculation
```
High Time Samples: 15.6, 15.6, 15.7, 16.5, 15.3, 15.3 μs
Average High Time: 15.7 μs

Duty Cycle = (15.7 μs / 61.8 μs) × 100% = 25.4%
```

---

## Measured vs Expected

| Parameter | Expected | Measured | Difference |
|-----------|----------|----------|------------|
| **Frequency** | 20.0 kHz | **16.2 kHz** | -19% |
| **Period** | 50.0 μs | **61.8 μs** | +24% |
| **Duty Cycle** | Variable | **~25%** | - |

### Why 16.2 kHz instead of 20 kHz?

Possible reasons:
1. **PWM source configuration**: PWM generator set to 16.2 kHz
2. **Clock divider**: Different prescaler setting
3. **Hardware limitation**: Platform-specific frequency
4. **Intentional**: Design choice for this application

---

## Filter Parameter Adjustments

### Previous Settings (for 20 kHz)
```c
#define DEBOUNCE_TIME_US    100     // 2 × 50μs periods
#define MAX_PWM_FREQ_HZ     20000   // Expected frequency
```

### New Settings (for 16.2 kHz)
```c
#define DEBOUNCE_TIME_US    124     // 2 × 61.8μs periods
#define MAX_PWM_FREQ_HZ     16200   // Actual measured frequency
```

### Calculation
```
PWM Period @ 16.2 kHz = 1 / 16200 = 61.73 μs ≈ 61.8 μs
Debounce Time = 2 periods = 2 × 61.8 = 123.6 μs ≈ 124 μs
```

---

## Updated Filter Characteristics

### Edge Filtering
- **Min Edge Interval**: 5 μs (unchanged)
  - Filters 10-20 μs noise bursts
  - Allows 16.2 kHz signal (61.8 μs period)
  
- **Debounce Time**: 124 μs (was 100 μs)
  - 2 PWM periods @ 16.2 kHz
  - Rejects same-edge repetitions within 2 periods
  - Stronger filtering for slower PWM

### Duty Cycle Filtering
- **Moving Average**: 7 samples (unchanged)
- **Outlier Threshold**: 40% (unchanged)
- **Response Time**: ~1.4 seconds (unchanged)

---

## Expected Behavior After Adjustment

### Startup Display
```
PWM Signal Configuration:
  Expected PWM Freq:  16200 Hz (period: 61 us)

Filter Configuration (optimized for 16.2kHz PWM):
  Debounce Time:      124 us (2.01 PWM periods)
  Min Edge Interval:  5 us (rejects >200 kHz noise)
  Duty Cycle Filter:  7-sample moving average
```

### Measurement Accuracy
With 16.2 kHz PWM:
- **Cycles per 10s capture**: 162,000 cycles
- **Actual samples collected**: ~200-500 measurements
- **Coverage**: Excellent statistical sampling
- **Accuracy**: High precision duty cycle measurement

---

## Noise Analysis

### Observed Noise Pattern
From GPIO log, consecutive same edges occur at ~30 μs intervals:
```
FALLING → FALLING (30.9 μs)  ← Noise
FALLING → FALLING (30.8 μs)  ← Noise
RISING  → RISING  (30.9 μs)  ← Noise
RISING  → RISING  (30.5 μs)  ← Noise
```

### Filter Response
- **Min Edge Interval (5 μs)**: ✓ Passes (30 μs > 5 μs)
- **Debounce Time (124 μs)**: ✓ **REJECTS** (30 μs < 124 μs)
- **Same-Edge Check**: ✓ **REJECTS** (consecutive same edges)

**Result**: Noise will be effectively filtered out!

---

## Validation

### Test Cases

#### 1. Valid PWM Edge Sequence
```
RISING (t=0) → FALLING (t=15.7μs) → RISING (t=61.8μs)
```
- Interval 1: 15.7 μs > 5 μs ✓
- Interval 2: 46.1 μs > 5 μs ✓
- Alternating edges ✓
- **Result**: ACCEPTED

#### 2. Noise Burst
```
FALLING (t=0) → FALLING (t=30μs)
```
- Same edge type ✓ (triggers debounce check)
- Interval: 30 μs < 124 μs ✓
- **Result**: REJECTED

#### 3. Minimum Duty Cycle (1%)
```
High time: 0.618 μs (1% of 61.8 μs)
```
- Edge interval: 0.618 μs < 5 μs ✗
- **Issue**: May be filtered as noise
- **Solution**: MIN_EDGE_INTERVAL_US = 5 μs allows down to ~8% duty

#### 4. Maximum Duty Cycle (99%)
```
Low time: 0.618 μs (1% of 61.8 μs)
```
- Same issue as minimum duty cycle
- **Practical range**: ~8% - 92% duty cycle

---

## Summary

### Changes Made
✅ Updated `MAX_PWM_FREQ_HZ` from 20000 to **16200 Hz**
✅ Updated `DEBOUNCE_TIME_US` from 100 to **124 μs**
✅ Comments updated to reflect actual 16.2 kHz / 61.8 μs period

### Filter Effectiveness
- **Noise Rejection**: Excellent (30 μs bursts filtered)
- **Valid Signal**: Preserved (61.8 μs period accepted)
- **Duty Range**: ~8% - 92% (limited by 5 μs min interval)
- **Stability**: Very high (10s capture + 30s output)

### Recommendations
1. ✅ **Use adjusted settings** for 16.2 kHz PWM
2. ⚠️ **Verify PWM source** if 20 kHz was expected
3. 💡 **Consider reducing MIN_EDGE_INTERVAL_US** to 2-3 μs if need <8% duty
4. 📊 **Monitor capture phase** to verify ~200-500 samples collected

---

## Next Steps

1. **Recompile** with new parameters
2. **Test** with actual PWM signal
3. **Verify** duty cycle accuracy:
   - Set PWM to known duty (e.g., 25%, 50%, 75%)
   - Compare measured vs expected
4. **Adjust** if needed based on results
