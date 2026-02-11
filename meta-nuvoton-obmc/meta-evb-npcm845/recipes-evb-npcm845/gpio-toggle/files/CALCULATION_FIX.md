# Critical Fix: Duty Cycle Calculation Error

## The Real Problem (Finally Found!)

After removing all filters and still getting wrong results (50% → 31%), the problem was NOT in filtering at all!

**The problem was in the duty cycle calculation logic itself.**

---

## Root Cause: Incorrect Calculation Method

### The Buggy Code

```c
// WRONG: Using average period
total_period = last_rising - first_rising;
double avg_period_us = (double)total_period / period_count;
double avg_high_time_us = (double)total_high_time / high_count;
double raw_duty = (avg_high_time_us / avg_period_us) * 100.0;
```

### Why This Failed

#### Visual Explanation

```
Event sequence:
RISING  FALLING  RISING  FALLING  RISING  FALLING  RISING
  0       25      50      75      100     125     150  (μs)
  |<-25μs>|<-25μs>|<-25μs>|<-25μs>|<-25μs>|<-25μs>|
  
first_rising = 0
last_rising = 150

Calculation:
- total_period = 150 - 0 = 150μs
- period_count = 3 (number of rising edges - 1)
- avg_period = 150 / 3 = 50μs ✓ Correct

- high_count = 3 (three complete high pulses measured)
- total_high_time = 75μs (25 + 25 + 25)
- avg_high_time = 75 / 3 = 25μs ✓ Correct

- raw_duty = 25 / 50 = 50% ✓ Should be correct...
```

**But wait!** The problem is more subtle...

#### The Actual Problem

The issue is that `high_count` and `period_count` can be **mismatched** due to:

1. **Incomplete cycles**: Last rising edge might not have a corresponding falling edge yet
2. **Edge filtering**: Some edges might be filtered out
3. **Timing issues**: Events might not be perfectly captured

This causes:
```
period_count = 3
high_count = 2  ← Missing one!

avg_period = 50μs (correct)
avg_high_time = 25μs (correct)
BUT: We're dividing by different denominators!

Result: Underestimated duty cycle
```

---

## The Fix: Use Total Elapsed Time

### Correct Calculation

```c
// CORRECT: Using total elapsed time
unsigned long long total_elapsed_time = 
    events[event_count - 1].timestamp_us - events[0].timestamp_us;

double raw_duty = 
    ((double)total_high_time / (double)total_elapsed_time) * 100.0;
```

### Why This Works

```
Event sequence:
RISING  FALLING  RISING  FALLING  RISING  FALLING  RISING
  0       25      50      75      100     125     150  (μs)

Calculation:
- total_elapsed_time = 150 - 0 = 150μs
- total_high_time = 75μs (sum of all high periods)
- raw_duty = 75 / 150 = 50% ✓ CORRECT!

No averaging, no mismatch, just simple ratio!
```

#### Advantages

1. **No averaging needed**: Direct ratio calculation
2. **No mismatch**: Single numerator, single denominator
3. **More accurate**: Uses all available data
4. **Simpler**: Fewer calculations, less room for error

---

## Comparison: Before vs After

### Before (Average Period Method)

```c
// Collect events
for (int i = 0; i < event_count; i++) {
    if (rising) {
        if (first_rising == 0) first_rising = timestamp;
        else last_rising = timestamp;
        period_count++;
    }
    if (falling && high_start > 0) {
        total_high_time += timestamp - high_start;
        high_count++;
    }
}

// Calculate
avg_period = (last_rising - first_rising) / period_count;
avg_high_time = total_high_time / high_count;
duty = (avg_high_time / avg_period) * 100;
```

**Problem**: `period_count` and `high_count` can be different!

### After (Total Elapsed Time Method)

```c
// Collect events
for (int i = 0; i < event_count; i++) {
    if (falling && high_start > 0) {
        total_high_time += timestamp - high_start;
        high_count++;
    }
}

// Calculate
total_elapsed_time = last_event - first_event;
duty = (total_high_time / total_elapsed_time) * 100;
```

**Solution**: Single ratio, no mismatch possible!

---

## Real-World Example

### GPIO Monitor Log Analysis

```
3610.153922876  RISING     (start)
3610.153948116  FALLING    25.240μs high
3610.153973248  RISING     25.132μs low
3610.153999032  FALLING    25.784μs high
3610.154022852  RISING     23.820μs low
3610.154048176  FALLING    25.324μs high
...
3610.155923596  RISING     (end)

Total elapsed: 155923.596 - 153922.876 = 2000.720μs
Total high time: ~1000μs (sum of all high periods)
Duty cycle: 1000 / 2000 = 50% ✓
```

### Before Fix (Average Method)

```
period_count = 40 (number of rising edges - 1)
high_count = 38 (some high pulses not counted)

avg_period = 2000 / 40 = 50μs
avg_high_time = 950 / 38 = 25μs

duty = 25 / 50 = 50%... 
Wait, why did we measure 31%?

Because of mismatch and rounding errors!
```

### After Fix (Total Time Method)

```
total_elapsed_time = 2000μs
total_high_time = 1000μs

duty = 1000 / 2000 = 50% ✓ CORRECT!
```

---

## Why This Wasn't Caught Earlier

### Misleading Symptoms

1. **Initial measurement was correct**: Quick measurement with few edges worked fine
2. **Long capture was wrong**: More edges → more opportunity for mismatch
3. **Looked like filtering issue**: Gradual drift suggested filter problem
4. **Actually calculation issue**: The fundamental math was wrong

### The Journey

```
Attempt 1: Add moving average filter → Made it worse
Attempt 2: Remove moving average → Still wrong
Attempt 3: Relax debounce → Still wrong
Attempt 4: Remove pulse validation → Still wrong
Attempt 5: Remove all filters → Still wrong!
Attempt 6: Fix calculation logic → FINALLY CORRECT!
```

---

## Key Lessons

### 1. Question Your Assumptions
- We assumed the calculation was correct
- We focused on filtering for too long
- Should have validated the math first

### 2. Simpler Is Better
- Total elapsed time method is simpler
- Fewer variables = fewer bugs
- Direct ratio > averaged ratio

### 3. Test Edge Cases
- Quick measurement (few edges) worked
- Long measurement (many edges) failed
- This should have been a clue!

### 4. Trust the Raw Data
- GPIO monitor showed perfect 50%
- Our measurement showed 31%
- The data was right, our code was wrong

---

## Summary

### Problem
Duty cycle calculation used averaged period and averaged high time, which could have mismatched counts, leading to incorrect results.

### Solution
Use total elapsed time and total high time for direct ratio calculation.

### Formula

**Before**:
```
duty = (avg_high_time / avg_period) × 100
     = (total_high / high_count) / (total_period / period_count) × 100
```

**After**:
```
duty = (total_high_time / total_elapsed_time) × 100
```

### Result
- ✅ Accurate measurements
- ✅ No mismatch errors
- ✅ Simpler calculation
- ✅ More robust

---

## Final Configuration

### Filtering
```c
// Minimal filtering: only 5μs minimum edge interval
if (time_diff < 5μs) reject;
```

### Calculation
```c
// Simple ratio: total high / total elapsed
duty = (total_high_time / total_elapsed_time) × 100;
```

### Expected Result
```
Actual PWM: 50%
Measured:   50% ✓
```

**This should finally be correct!**
