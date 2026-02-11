# PWM to TACH Simulator - GPIO Parameterization

## Overview
The PWM to TACH simulator now supports runtime GPIO configuration through command-line arguments.

## Usage

### Basic Syntax
```bash
pwm_tach_sim [gpiochip] [pwm_line] [tach_line]
```

### Arguments
- **gpiochip**: GPIO chip name (e.g., `gpiochip0`, `gpiochip2`)
  - Default: `gpiochip2`
- **pwm_line**: PWM input GPIO line number
  - Default: `16`
- **tach_line**: TACH output GPIO line number
  - Default: `0`

### Examples

#### 1. Use default configuration
```bash
pwm_tach_sim
```
Uses: `gpiochip2`, PWM=GPIO16, TACH=GPIO0

#### 2. Specify custom GPIO chip and lines
```bash
pwm_tach_sim gpiochip2 16 0
```
Explicitly sets: `gpiochip2`, PWM=GPIO16, TACH=GPIO0

#### 3. Alternative configuration
```bash
pwm_tach_sim gpiochip0 2 3
```
Uses: `gpiochip0`, PWM=GPIO2, TACH=GPIO3

#### 4. Show help
```bash
pwm_tach_sim --help
```

## Filter Configuration

The simulator includes advanced filtering optimized for **20kHz PWM signals**:

### Filter Parameters
- **Debounce Time**: 50μs (1 PWM period)
  - Filters out ripple noise on the same signal level
- **Minimum Edge Interval**: 1μs
  - Rejects ultra-high frequency noise (>1MHz)
- **Duty Cycle Filter**: 5-sample moving average
  - Smooths duty cycle measurements for stable TACH output

### PWM Signal Specifications
- **Expected PWM Frequency**: 20kHz (50μs period)
- **Supported Duty Cycle Range**: 1% - 100%
- **TACH Output Range**: 10Hz - 1000Hz

## Systemd Service

The service is configured to use the default GPIO configuration:

```ini
[Service]
Type=simple
ExecStart=/usr/sbin/pwm_tach_sim gpiochip2 16 0
```

To change the GPIO configuration, edit the service file:
```bash
vi /lib/systemd/system/pwm-tach-sim.service
```

Then reload and restart:
```bash
systemctl daemon-reload
systemctl restart pwm-tach-sim
```

## Output Example

```
PWM to TACH Simulator (GPIO-based)
===================================
GPIO Configuration:
  Chip:        gpiochip2
  PWM Input:   GPIO16 (captures PWM signal)
  TACH Output: GPIO0 (outputs TACH signal)
Frequency Range: 10 Hz - 1000 Hz

PWM Signal Configuration:
  Expected PWM Freq:  20000 Hz (period: 50 us)

Filter Configuration (optimized for 20kHz PWM):
  Debounce Time:      50 us (1.00 PWM periods)
  Min Edge Interval:  1 us (rejects >1000 kHz noise)
  Duty Cycle Filter:  5-sample moving average
Press Ctrl+C to stop

GPIO initialized:
  Chip:        gpiochip2
  PWM Input:   GPIO16
  TACH Output: GPIO0
Starting simulation...
```

## Technical Details

### Edge Detection Filter
The simulator uses a three-layer filtering approach:

1. **Ultra-High Frequency Noise Filter** (< 1μs)
   - Rejects edges with intervals < 1μs
   - Filters noise > 1MHz
   - Allows 20kHz PWM signal to pass

2. **Same-Edge-Type Debounce** (< 50μs)
   - Same edge type (rising→rising or falling→falling) within 50μs = ripple
   - 50μs = 1 PWM period, sufficient to filter output ripple
   - Preserves normal PWM edge transitions

3. **Moving Average Smoothing** (5 samples)
   - Averages duty cycle over 5 samples
   - Smooths transient noise impact
   - Stabilizes TACH output frequency

### Performance Characteristics
- **Fast Response**: 50μs debounce time, minimal delay for 20kHz PWM
- **Strong Noise Rejection**: Filters >1MHz high-frequency noise and ripple
- **Stable Output**: Moving average ensures smooth TACH frequency changes
- **Accurate Measurement**: Correctly captures 1%-100% duty cycle range
