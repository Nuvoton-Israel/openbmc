# PWM Capture 使用指南

## 概述

`pwm_capture` 是一個使用 GPIO edge detection 來測量 PWM 信號的工具。它可以準確測量 PWM 的頻率和 duty cycle。

## 硬體連接

- **GPIO02** (gpiochip0 line 2): PWM 輸入信號

將要測量的 PWM 信號連接到 GPIO02。

## 工作原理

1. 使用 `libgpiod` 監聽 GPIO02 的上升沿和下降沿
2. 記錄每個邊沿的時間戳
3. 計算多個週期的平均值
4. 輸出頻率、週期和 duty cycle

## 使用方法

### 單次測量

```bash
pwm_capture
```

**輸出範例：**
```
PWM Capture Tool
=================
PWM Input: GPIO4 (gpiochip0 line 4)
Sample Count: 10 periods
Mode: Single measurement
Use '-c' for continuous monitoring

GPIO initialized: gpiochip0 line 4 for PWM capture
Waiting for PWM signal...

=== Measurement Results ===
Frequency:    1000.00 Hz
Period:       1000.00 us
Duty Cycle:     50.00 %
High Time:     500.00 us
Low Time:      500.00 us

Cleaning up...
Shutdown complete
```

### 連續監控

```bash
pwm_capture -c
```

**輸出範例：**
```
PWM Capture Tool
=================
PWM Input: GPIO4 (gpiochip0 line 4)
Sample Count: 10 periods
Mode: Continuous monitoring
Press Ctrl+C to stop

GPIO initialized: gpiochip0 line 4 for PWM capture
Waiting for PWM signal...
Frequency:  1000.00 Hz | Duty Cycle:  50.00% | Period:  1000.00 us
Frequency:   505.23 Hz | Duty Cycle:  50.12% | Period:  1979.31 us
Frequency:   257.89 Hz | Duty Cycle:  25.03% | Period:  3877.45 us
...
```

## 測量參數

- **採樣週期數**: 10 個週期（可在源碼中修改 `SAMPLE_COUNT`）
- **超時時間**: 5 秒（可在源碼中修改 `TIMEOUT_SEC`）
- **測量範圍**: 
  - 最低頻率: ~1 Hz
  - 最高頻率: ~100 kHz（取決於系統性能）

## 精度

- **頻率精度**: ±0.1 Hz
- **Duty cycle 精度**: ±0.5%
- **時間解析度**: 1 微秒

## 實際應用範例

### 範例 1: 驗證 PWM 輸出

```bash
# 設定 PWM 為 50% duty cycle
pwm_test.sh setup
pwm_test.sh set 50

# 測量 PWM 信號（假設 PWM 輸出連接到 GPIO02）
pwm_capture

# 預期結果應該接近 50%
```

### 範例 2: 監控動態 PWM

```bash
# 在終端 1: 啟動連續監控
pwm_capture -c

# 在終端 2: 改變 PWM duty cycle
pwm_test.sh set 25
sleep 2
pwm_test.sh set 50
sleep 2
pwm_test.sh set 75
sleep 2
pwm_test.sh set 100

# 終端 1 會顯示即時的測量結果
```

### 範例 3: 測量 TACH 輸出

如果將 GPIO03 (TACH 輸出) 連接到 GPIO02 (PWM 輸入):

```bash
# 啟動 TACH 模擬器
systemctl start pwm-tach-sim

# 設定 PWM duty cycle
pwm_test.sh set 50

# 測量 TACH 頻率
pwm_capture

# 應該看到對應的 TACH 頻率（約 505 Hz for 50% duty）
```

## 故障排除

### 問題: "Timeout waiting for PWM signal"

**原因**: GPIO02 沒有接收到 PWM 信號

**解決方法**:
1. 檢查硬體連接
2. 確認 PWM 信號源正在輸出
3. 使用示波器驗證信號

```bash
# 檢查 GPIO02 狀態
gpioinfo gpiochip0 | grep -A 1 "line   2"

# 手動測試 GPIO02 是否可用
gpioget 0 2
```

### 問題: "Failed to request GPIO line for events"

**原因**: GPIO02 已被其他程式使用

**解決方法**:
```bash
# 檢查哪個程式在使用 GPIO02
lsof | grep gpio

# 或檢查 GPIO 狀態
gpioinfo gpiochip0 | grep -A 1 "line   2"
```

### 問題: 測量結果不穩定

**原因**: 信號品質不佳或干擾

**解決方法**:
1. 使用較短的連接線
2. 添加地線連接
3. 增加採樣週期數（修改源碼中的 `SAMPLE_COUNT`）

## 進階使用

### 修改採樣週期數

編輯 `pwm_capture.c`:

```c
#define SAMPLE_COUNT    20      // 增加到 20 個週期以提高精度
```

### 修改超時時間

編輯 `pwm_capture.c`:

```c
#define TIMEOUT_SEC     10      // 增加到 10 秒
```

### 使用不同的 GPIO

編輯 `pwm_capture.c`:

```c
#define PWM_GPIO_LINE   5       // 改為 GPIO05
```

## 與其他工具整合

### 與 pwm_test.sh 整合

```bash
#!/bin/bash
# 自動測試腳本

for duty in 0 25 50 75 100; do
    echo "Testing ${duty}% duty cycle..."
    pwm_test.sh set $duty
    sleep 1
    pwm_capture
    echo ""
done
```

### 與 TACH 模擬器整合

```bash
#!/bin/bash
# 閉迴路驗證腳本

# 啟動 TACH 模擬器
systemctl start pwm-tach-sim

# 測試不同的 duty cycle
for duty in 25 50 75; do
    echo "Setting PWM to ${duty}%..."
    pwm_test.sh set $duty
    sleep 1
    
    echo "Measuring TACH output..."
    pwm_capture
    echo ""
done

# 停止 TACH 模擬器
systemctl stop pwm-tach-sim
```

## 技術細節

### 測量演算法

1. **邊沿檢測**: 使用 `gpiod_line_request_both_edges_events()` 監聽上升沿和下降沿
2. **時間戳記錄**: 使用 kernel 提供的高精度時間戳
3. **週期計算**: 測量連續上升沿之間的時間差
4. **Duty cycle 計算**: 測量高電平時間佔週期的百分比
5. **平均值**: 對多個週期取平均以提高精度

### 性能考量

- **CPU 使用率**: 極低（事件驅動）
- **記憶體使用**: < 1 MB
- **響應時間**: < 100ms（取決於 PWM 頻率）

## 限制

1. **最高頻率**: 受限於 GPIO 中斷處理速度（通常 < 100 kHz）
2. **最低頻率**: 受限於超時設定（預設 5 秒，最低約 0.2 Hz）
3. **精度**: 受系統負載影響，高負載時可能降低精度

## 參考資料

- libgpiod 文檔: https://git.kernel.org/pub/scm/libs/libgpiod/libgpiod.git/
- Linux GPIO 子系統: https://www.kernel.org/doc/html/latest/driver-api/gpio/
