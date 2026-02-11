# PWM Duty Cycle to TACH Frequency Mapping Table

## Mapping Formula

```
TACH Frequency (Hz) = 10 + (PWM Duty Cycle % / 100) × 990
```

**Linear Mapping:**
- 0% PWM Duty Cycle → 10 Hz TACH
- 100% PWM Duty Cycle → 1000 Hz TACH

---

## Complete Mapping Table

### Every 1% Increment (0% - 100%)

| PWM Duty Cycle (%) | TACH Frequency (Hz) | TACH Period (ms) | Notes |
|-------------------:|--------------------:|-----------------:|:------|
| 0% | 10 | 100.00 | Minimum frequency |
| 1% | 19.9 | 50.25 | |
| 2% | 29.8 | 33.56 | |
| 3% | 39.7 | 25.19 | |
| 4% | 49.6 | 20.16 | |
| 5% | 59.5 | 16.81 | |
| 6% | 69.4 | 14.41 | |
| 7% | 79.3 | 12.61 | |
| 8% | 89.2 | 11.21 | |
| 9% | 99.1 | 10.09 | |
| 10% | 109 | 9.17 | |
| 11% | 118.9 | 8.41 | |
| 12% | 128.8 | 7.76 | |
| 13% | 138.7 | 7.21 | |
| 14% | 148.6 | 6.73 | |
| 15% | 158.5 | 6.31 | |
| 16% | 168.4 | 5.94 | |
| 17% | 178.3 | 5.61 | |
| 18% | 188.2 | 5.31 | |
| 19% | 198.1 | 5.05 | |
| 20% | 208 | 4.81 | |
| 21% | 217.9 | 4.59 | |
| 22% | 227.8 | 4.39 | |
| 23% | 237.7 | 4.21 | |
| 24% | 247.6 | 4.04 | |
| 25% | 257.5 | 3.88 | Quarter speed |
| 26% | 267.4 | 3.74 | |
| 27% | 277.3 | 3.61 | |
| 28% | 287.2 | 3.48 | |
| 29% | 297.1 | 3.37 | |
| 30% | 307 | 3.26 | |
| 31% | 316.9 | 3.16 | |
| 32% | 326.8 | 3.06 | |
| 33% | 336.7 | 2.97 | |
| 34% | 346.6 | 2.89 | |
| 35% | 356.5 | 2.81 | |
| 36% | 366.4 | 2.73 | |
| 37% | 376.3 | 2.66 | |
| 38% | 386.2 | 2.59 | |
| 39% | 396.1 | 2.52 | |
| 40% | 406 | 2.46 | |
| 41% | 415.9 | 2.40 | |
| 42% | 425.8 | 2.35 | |
| 43% | 435.7 | 2.30 | |
| 44% | 445.6 | 2.24 | |
| 45% | 455.5 | 2.20 | |
| 46% | 465.4 | 2.15 | |
| 47% | 475.3 | 2.11 | |
| 48% | 485.2 | 2.06 | |
| 49% | 495.1 | 2.02 | |
| 50% | 505 | 1.98 | Half speed |
| 51% | 514.9 | 1.94 | |
| 52% | 524.8 | 1.91 | |
| 53% | 534.7 | 1.87 | |
| 54% | 544.6 | 1.84 | |
| 55% | 554.5 | 1.80 | |
| 56% | 564.4 | 1.77 | |
| 57% | 574.3 | 1.74 | |
| 58% | 584.2 | 1.71 | |
| 59% | 594.1 | 1.68 | |
| 60% | 604 | 1.66 | |
| 61% | 613.9 | 1.63 | |
| 62% | 623.8 | 1.60 | |
| 63% | 633.7 | 1.58 | |
| 64% | 643.6 | 1.55 | |
| 65% | 653.5 | 1.53 | |
| 66% | 663.4 | 1.51 | |
| 67% | 673.3 | 1.49 | |
| 68% | 683.2 | 1.46 | |
| 69% | 693.1 | 1.44 | |
| 70% | 703 | 1.42 | |
| 71% | 712.9 | 1.40 | |
| 72% | 722.8 | 1.38 | |
| 73% | 732.7 | 1.37 | |
| 74% | 742.6 | 1.35 | |
| 75% | 752.5 | 1.33 | Three-quarter speed |
| 76% | 762.4 | 1.31 | |
| 77% | 772.3 | 1.29 | |
| 78% | 782.2 | 1.28 | |
| 79% | 792.1 | 1.26 | |
| 80% | 802 | 1.25 | |
| 81% | 811.9 | 1.23 | |
| 82% | 821.8 | 1.22 | |
| 83% | 831.7 | 1.20 | |
| 84% | 841.6 | 1.19 | |
| 85% | 851.5 | 1.17 | |
| 86% | 861.4 | 1.16 | |
| 87% | 871.3 | 1.15 | |
| 88% | 881.2 | 1.13 | |
| 89% | 891.1 | 1.12 | |
| 90% | 901 | 1.11 | |
| 91% | 910.9 | 1.10 | |
| 92% | 920.8 | 1.09 | |
| 93% | 930.7 | 1.07 | |
| 94% | 940.6 | 1.06 | |
| 95% | 950.5 | 1.05 | |
| 96% | 960.4 | 1.04 | |
| 97% | 970.3 | 1.03 | |
| 98% | 980.2 | 1.02 | |
| 99% | 990.1 | 1.01 | |
| 100% | 1000 | 1.00 | Maximum frequency |

---

## Key Points Summary

### Every 5% Increment (Quick Reference)

| PWM Duty (%) | TACH Freq (Hz) | TACH Period (ms) |
|-------------:|---------------:|-----------------:|
| 0% | 10 | 100.00 |
| 5% | 59.5 | 16.81 |
| 10% | 109 | 9.17 |
| 15% | 158.5 | 6.31 |
| 20% | 208 | 4.81 |
| 25% | 257.5 | 3.88 |
| 30% | 307 | 3.26 |
| 35% | 356.5 | 2.81 |
| 40% | 406 | 2.46 |
| 45% | 455.5 | 2.20 |
| 50% | 505 | 1.98 |
| 55% | 554.5 | 1.80 |
| 60% | 604 | 1.66 |
| 65% | 653.5 | 1.53 |
| 70% | 703 | 1.42 |
| 75% | 752.5 | 1.33 |
| 80% | 802 | 1.25 |
| 85% | 851.5 | 1.17 |
| 90% | 901 | 1.11 |
| 95% | 950.5 | 1.05 |
| 100% | 1000 | 1.00 |

---

## Every 10% Increment (Simplified)

| PWM Duty (%) | TACH Freq (Hz) | TACH Period (ms) | RPM (if 2 pulses/rev) |
|-------------:|---------------:|-----------------:|----------------------:|
| 0% | 10 | 100.00 | 300 |
| 10% | 109 | 9.17 | 3,270 |
| 20% | 208 | 4.81 | 6,240 |
| 30% | 307 | 3.26 | 9,210 |
| 40% | 406 | 2.46 | 12,180 |
| 50% | 505 | 1.98 | 15,150 |
| 60% | 604 | 1.66 | 18,120 |
| 70% | 703 | 1.42 | 21,090 |
| 80% | 802 | 1.25 | 24,060 |
| 90% | 901 | 1.11 | 27,030 |
| 100% | 1000 | 1.00 | 30,000 |

---

## Technical Specifications

### Input (PWM)
- **Frequency**: 20 kHz (50 μs period)
- **Duty Cycle Range**: 0% - 100%
- **Edge Detection**: Both rising and falling edges
- **Filtering**: 
  - Debounce: 50 μs (1 PWM period)
  - Min edge interval: 1 μs
  - Moving average: 5 samples

### Output (TACH)
- **Frequency Range**: 10 Hz - 1000 Hz
- **Mapping**: Linear (proportional to PWM duty cycle)
- **Signal Type**: Square wave (50% duty cycle)
- **Update Rate**: PWM measured every 200 ms

### Conversion Examples

**Example 1: 25% PWM Duty Cycle**
```
TACH Freq = 10 + (25 / 100) × 990 = 10 + 247.5 = 257.5 Hz
TACH Period = 1 / 257.5 = 3.88 ms
Toggle Interval = 3.88 / 2 = 1.94 ms
```

**Example 2: 75% PWM Duty Cycle**
```
TACH Freq = 10 + (75 / 100) × 990 = 10 + 742.5 = 752.5 Hz
TACH Period = 1 / 752.5 = 1.33 ms
Toggle Interval = 1.33 / 2 = 0.665 ms
```

---

## Fan Speed Simulation

If simulating a fan with 2 pulses per revolution:

**Formula**: `RPM = (TACH Frequency × 60) / 2`

| PWM Duty (%) | TACH Freq (Hz) | Simulated RPM |
|-------------:|---------------:|--------------:|
| 0% | 10 | 300 |
| 25% | 257.5 | 7,725 |
| 50% | 505 | 15,150 |
| 75% | 752.5 | 22,575 |
| 100% | 1000 | 30,000 |

---

## Notes

1. **Linear Relationship**: The mapping is perfectly linear, making it easy to predict TACH frequency from any PWM duty cycle.

2. **Resolution**: With a 990 Hz range over 100% duty cycle, each 1% change in PWM duty results in approximately 9.9 Hz change in TACH frequency.

3. **Filtering**: The 5-sample moving average filter means the actual TACH frequency will be the average of the last 5 measurements, providing smooth transitions.

4. **Update Latency**: PWM is measured every 200 ms, so changes in PWM duty cycle will be reflected in TACH output within 200-1000 ms (depending on filter convergence).

5. **Accuracy**: The actual TACH frequency may vary slightly due to:
   - GPIO timing precision
   - System scheduling
   - Moving average filter smoothing
