# PWM to TACH Simulator

這個套件提供了一個 PWM 到 TACH 的模擬器，用於測試風扇控制系統的閉迴路功能。

## 功能說明

### 硬體連接
- **GPIO03**: TACH OUTPUT (模擬風扇轉速輸出)
- **GPIO02**: PWM INPUT (可選，用於硬體 PWM 輸入捕獲)
- **PWM0**: PWM 輸出 (透過 sysfs 控制)

### 工作原理
1. 程式從 `/sys/class/pwm/pwmchip0/pwm0/` 讀取 PWM 的 duty cycle
2. 根據 duty cycle 計算對應的 TACH 頻率
3. 在 GPIO03 上輸出相應頻率的方波信號

### 頻率映射
- **0% duty cycle** → 10 Hz TACH 頻率
- **100% duty cycle** → 1000 Hz TACH 頻率
- 線性插值計算中間值

## 安裝的檔案

套件會安裝以下檔案到系統：

1. **`/usr/sbin/pwm_tach_sim`** - C 語言實作的 PWM to TACH 模擬器
2. **`/usr/sbin/pwm_capture`** - PWM 捕獲工具（測量 PWM 頻率和 duty cycle）
3. **`/usr/sbin/gpio_toggle.sh`** - 簡單的 GPIO 切換腳本（用於手動測試）
4. **`/usr/sbin/pwm_test.sh`** - PWM 設定和測試腳本
5. **`/usr/sbin/closed_loop_test.sh`** - 完整閉迴路測試腳本
6. **`/lib/systemd/system/pwm-tach-sim.service`** - Systemd 服務

## 使用方法

### 1. 設定 PWM

首先，使用測試腳本設定 PWM：

```bash
# 初始化 PWM0
pwm_test.sh setup

# 設定 PWM duty cycle 為 50%
pwm_test.sh set 50

# 查看 PWM 狀態
pwm_test.sh status
```

### 2. 啟動 TACH 模擬器

#### 方法 A: 使用 systemd 服務（自動啟動）

```bash
# 啟動服務
systemctl start pwm-tach-sim

# 查看狀態
systemctl status pwm-tach-sim

# 查看日誌
journalctl -u pwm-tach-sim -f

# 停止服務
systemctl stop pwm-tach-sim

# 設定開機自動啟動
systemctl enable pwm-tach-sim
```

#### 方法 B: 手動執行（用於測試）

```bash
# 直接執行程式
pwm_tach_sim
```

### 3. 測試閉迴路功能

使用掃描模式測試不同的 duty cycle：

```bash
# 在一個終端啟動 TACH 模擬器
pwm_tach_sim

# 在另一個終端執行 PWM 掃描
pwm_test.sh sweep
```

你會看到：
- PWM duty cycle 從 0% 到 100% 循環變化
- TACH 頻率相應地從 10 Hz 變化到 1000 Hz
- GPIO03 的切換速度會隨著 PWM duty cycle 增加而加快

### 4. 手動設定不同的 duty cycle

```bash
# 設定 25% duty cycle
pwm_test.sh set 25

# 設定 75% duty cycle
pwm_test.sh set 75

# 設定 100% duty cycle
pwm_test.sh set 100
```

### 5. 使用 PWM Capture 測量 PWM 信號

#### 單次測量模式

```bash
# 測量 GPIO02 上的 PWM 信號
pwm_capture

# 輸出範例：
# === Measurement Results ===
# Frequency:    1000.00 Hz
# Period:       1000.00 us
# Duty Cycle:     50.00 %
# High Time:     500.00 us
# Low Time:      500.00 us
```

#### 連續監控模式

```bash
# 持續監控 PWM 信號
pwm_capture -c

# 輸出範例：
# Frequency:  1000.00 Hz | Duty Cycle:  50.00% | Period:  1000.00 us
# Frequency:   505.00 Hz | Duty Cycle:  50.00% | Period:  1980.40 us
# ...
```

### 6. 完整閉迴路測試

使用自動化測試腳本進行完整的系統測試：

```bash
# 執行完整測試（測試多個 duty cycle）
closed_loop_test.sh full-test

# 測試特定的 duty cycle
closed_loop_test.sh verify 50

# 只測試 PWM capture
closed_loop_test.sh capture-only

# 只測試 TACH 模擬器
closed_loop_test.sh tach-only
```

完整測試會：
1. 設定 PWM 為不同的 duty cycle (0%, 25%, 50%, 75%, 100%)
2. 使用 `pwm_capture` 測量實際的 PWM 信號
3. 驗證 TACH 模擬器輸出的頻率
4. 顯示測試結果摘要

### 7. 清理

```bash
# 停止 TACH 模擬器
systemctl stop pwm-tach-sim

# 清理 PWM 設定
pwm_test.sh cleanup
```

## 測試腳本說明

### pwm_test.sh 命令

```bash
pwm_test.sh setup              # 匯出並啟用 PWM
pwm_test.sh cleanup            # 停用並取消匯出 PWM
pwm_test.sh set <duty_percent> # 設定 PWM duty cycle (0-100%)
pwm_test.sh sweep              # 掃描 duty cycle 從 0% 到 100%
pwm_test.sh status             # 顯示目前 PWM 狀態
```

### pwm_capture 命令

```bash
pwm_capture                    # 單次測量 PWM 信號
pwm_capture -c                 # 連續監控模式
```

### closed_loop_test.sh 命令

```bash
closed_loop_test.sh full-test      # 執行完整閉迴路測試
closed_loop_test.sh verify <duty>  # 驗證特定 duty cycle
closed_loop_test.sh capture-only   # 只測試 PWM capture
closed_loop_test.sh tach-only      # 只測試 TACH 模擬器
```

## 監控和除錯

### 查看 TACH 輸出

使用示波器或邏輯分析儀連接到 GPIO03 來觀察 TACH 信號。

### 查看程式輸出

```bash
# 即時查看日誌
journalctl -u pwm-tach-sim -f

# 查看最近的日誌
journalctl -u pwm-tach-sim -n 100
```

### 手動測試 GPIO

```bash
# 使用簡單的切換腳本測試 GPIO03
gpio_toggle.sh
```

## 技術細節

### PWM 參數
- **預設週期**: 1ms (1 kHz)
- **Duty cycle 範圍**: 0-100%
- **更新間隔**: 100ms

### TACH 參數
- **最小頻率**: 10 Hz
- **最大頻率**: 1000 Hz
- **輸出**: 方波 (50% duty cycle)

### 依賴套件
- `libgpiod` - GPIO 控制函式庫
- `systemd` - 系統服務管理

## 故障排除

### PWM 無法存取

如果看到 "Cannot access PWM duty cycle" 錯誤：

```bash
# 檢查 PWM 是否已匯出
ls /sys/class/pwm/pwmchip0/

# 手動匯出 PWM
echo 0 > /sys/class/pwm/pwmchip0/export

# 啟用 PWM
echo 1 > /sys/class/pwm/pwmchip0/pwm0/enable
```

### GPIO 無法存取

確認 GPIO03 沒有被其他功能使用：

```bash
# 檢查 GPIO 狀態
gpioinfo gpiochip0 | grep -A 1 "line   3"
```

### 服務無法啟動

```bash
# 檢查詳細錯誤訊息
systemctl status pwm-tach-sim
journalctl -xe
```

## 進階使用

### 修改頻率範圍

編輯 `/usr/sbin/pwm_tach_sim` 的源碼並重新編譯：

```c
#define MIN_FREQ_HZ     10      // 修改最小頻率
#define MAX_FREQ_HZ     1000    // 修改最大頻率
```

### 使用不同的 GPIO

修改源碼中的 GPIO 定義：

```c
#define TACH_GPIO_LINE  3       // 修改為其他 GPIO
```

### 使用不同的 PWM

修改測試腳本中的 PWM 參數：

```bash
PWM_CHIP=0          # PWM chip 編號
PWM_CHANNEL=0       # PWM channel 編號
```
