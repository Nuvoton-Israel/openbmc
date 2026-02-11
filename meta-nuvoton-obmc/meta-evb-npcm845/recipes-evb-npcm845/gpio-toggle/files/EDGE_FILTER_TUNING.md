# Edge Filter Adjustment - Final Tuning

## Problem: Overly Aggressive Edge Filtering

### Observed Behavior
```
Initial measurement (fast): 50.00% ✓ Correct
10-second capture:         ~29%   ✗ Wrong
```

Despite removing the moving average filter, duty cycle measurements were still incorrect during long capture phases.

---

## Root Cause: Too Strict Edge Filtering

### The Problematic Logic

```c
// BEFORE: Too strict
if (value == last_edge_value) {
    if (time_diff < DEBOUNCE_TIME_US) {
        continue;  // Reject if < 100μs
    }
    if (time_diff < DEBOUNCE_TIME_US * 2) {  // < 200μs
        continue;  // ALSO reject! ← TOO STRICT
    }
}
```

### Why This Failed

For 50% duty cycle @ 20kHz:
- High time: 25μs
- Low time: 25μs  
- Period: 50μs

**Problem**: The filter was rejecting valid same-edge events that occurred between 60-120μs apart.

#### Scenario
```
Time 0:    RISING edge (valid)
Time 25:   FALLING edge (valid)
Time 50:   RISING edge (valid)
Time 75:   FALLING edge (valid)
Time 100:  RISING edge (valid)
Time 110:  RISING edge (noise) ← Should reject

BUT: Filter was also rejecting valid edges in certain timing conditions!
```

---

## The Fix

### 1. Reduced Debounce Time
```c
// BEFORE
#define DEBOUNCE_TIME_US 100  // 2 PWM periods

// AFTER  
#define DEBOUNCE_TIME_US 60   // 1.2 PWM periods
```

**Rationale**: 60μs is enough to filter noise but not so large that it interferes with valid signal.

### 2. Removed Double-Debounce Check
```c
// AFTER: More lenient
if (value == last_edge_value) {
    if (time_diff < DEBOUNCE_TIME_US) {  // < 60μs
        continue;  // Reject noise
    }
    // Accept if >= 60μs (could be valid signal)
}
```

**Rationale**: 
- Noise bursts are typically < 30μs (from GPIO logs)
- 60μs debounce catches these
- Don't need additional 2x check
- Valid signals with unusual timing should be accepted

---

## Filter Configuration Summary

### Current Settings
```c
#define DEBOUNCE_TIME_US     60    // 1.2 PWM periods
#define MIN_EDGE_INTERVAL_US 5     // Filter ultra-high freq noise
#define MAX_PWM_FREQ_HZ      20000 // 20kHz PWM
```

### Filter Behavior

| Edge Scenario | Time Diff | Action |
|---------------|-----------|--------|
| **Alternating edges** | Any (> 5μs) | ✅ Accept |
| **Same edge, noise** | < 5μs | ❌ Reject (too close) |
| **Same edge, noise** | 5-60μs | ❌ Reject (debounce) |
| **Same edge, valid?** | >= 60μs | ✅ Accept (might be valid) |

---

## Expected Behavior After Fix

### Capture Phase
```
Starting PWM capture phase (10 seconds)...

  Capturing... Avg Duty:  50.12% (samples: 199, 7s remaining)
  Capturing... Avg Duty:  50.08% (samples: 397, 5s remaining)
  Capturing... Avg Duty:  50.05% (samples: 594, 3s remaining)
  Capturing... Avg Duty:  50.03% (samples: 792, 1s remaining)

✓ PWM Capture Complete!
  Samples Collected: 985
  Raw Average Duty:  50.02%  ← Should match actual PWM
  Final Duty:        50.02%
  TACH Frequency:    505 Hz
```

---

## Technical Analysis

### Why 60μs Debounce?

For 20kHz PWM (50μs period):
```
Minimum pulse width (1% duty):  0.5μs
Typical pulse width (50% duty): 25μs
Period: 50μs

Noise bursts observed: 10-30μs

Debounce choice: 60μs
- Filters all observed noise (< 30μs)
- Allows valid signal (period = 50μs)
- Not too large to interfere with measurements
```

### Filter Layers

1. **Min Edge Interval (5μs)**: Blocks >200kHz noise
2. **Same-Edge Debounce (60μs)**: Blocks noise bursts
3. **Pulse Width Validation (2μs)**: Ensures physical feasibility

---

## Comparison: Before vs After

### Before (100μs debounce + 2x check)
```
Debounce: 100μs
Double check: 200μs
Result: Too strict, rejects valid edges
Measured duty: 29% (should be 50%)
```

### After (60μs debounce, no 2x check)
```
Debounce: 60μs
Double check: None
Result: Balanced filtering
Expected duty: 50% (accurate)
```

---

## Summary

### Changes Made
1. ✅ Reduced `DEBOUNCE_TIME_US` from 100μs to 60μs
2. ✅ Removed double-debounce check (2x multiplier)
3. ✅ Simplified same-edge filtering logic

### Expected Results
- ✅ Accurate duty cycle measurement (50% → 50%)
- ✅ Still filters noise effectively
- ✅ More lenient for edge cases
- ✅ Balanced between accuracy and noise rejection

### Filter Philosophy
**"Filter noise, not signal"**
- Be strict enough to block noise
- Be lenient enough to allow valid signal
- When in doubt, accept (averaging will smooth out outliers)
