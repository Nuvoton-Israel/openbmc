# PWM to TACH Simulator - 快速入門指南

## 🚀 快速開始（5分鐘上手）

### 步驟 1: 編譯和安裝

```bash
# 在 OpenBMC 建置環境中
cd /home/kwliu/openbmc

# 清理並重新編譯
bitbake -c cleansstate gpio-toggle
bitbake gpio-toggle

# 或重新編譯整個映像檔
bitbake obmc-phosphor-image
```

### 步驟 2: 部署到目標系統

將編譯好的映像檔燒錄到目標板，或使用以下方式更新套件：

```bash
# 在目標系統上
opkg update
opkg install gpio-toggle
```

### 步驟 3: 在目標系統上測試

```bash
# 1. 設定 PWM（一次性設定）
pwm_test.sh setup

# 2. 啟動 TACH 模擬器
systemctl start pwm-tach-sim

# 3. 查看運行狀態
systemctl status pwm-tach-sim

# 4. 測試不同的 PWM duty cycle
pwm_test.sh set 25    # 設定 25%
pwm_test.sh set 50    # 設定 50%
pwm_test.sh set 75    # 設定 75%
pwm_test.sh set 100   # 設定 100%

# 5. 觀察輸出（在另一個終端）
journalctl -u pwm-tach-sim -f
```

## 📊 預期結果

當你改變 PWM duty cycle 時，你應該會看到：

```
PWM Duty:  25.00% -> TACH Freq:  257 Hz (period: 3891 us)
PWM Duty:  50.00% -> TACH Freq:  505 Hz (period: 1980 us)
PWM Duty:  75.00% -> TACH Freq:  752 Hz (period: 1329 us)
PWM Duty: 100.00% -> TACH Freq: 1000 Hz (period: 1000 us)
```

## 🔧 進階測試

### 自動掃描測試

在一個終端執行：
```bash
pwm_test.sh sweep
```

這會自動循環改變 PWM duty cycle，你可以觀察 TACH 頻率的變化。

### 手動 GPIO 測試

如果你只想測試 GPIO 功能：
```bash
gpio_toggle.sh
```

這會以固定的 3ms 間隔切換 GPIO03。

### PWM Capture 測試

測量 PWM 信號的頻率和 duty cycle：

```bash
# 單次測量
pwm_capture

# 連續監控
pwm_capture -c
```

### 完整閉迴路測試

執行自動化的完整系統測試：

```bash
# 執行完整測試（包含 PWM capture 和 TACH 驗證）
closed_loop_test.sh full-test

# 測試特定 duty cycle
closed_loop_test.sh verify 50
```

## 🎯 驗證方法

### 方法 1: 使用日誌
```bash
journalctl -u pwm-tach-sim -f
```

### 方法 2: 使用 PWM Capture
```bash
# 如果將 GPIO03 (TACH) 連接到 GPIO02 (PWM Input)
pwm_capture -c
```

### 方法 3: 使用示波器
將示波器探針連接到 GPIO03，觀察方波頻率。

### 方法 4: 使用邏輯分析儀
連接到 GPIO03，測量實際的切換頻率。

## 🛠️ 常見問題

### Q: 服務無法啟動
```bash
# 檢查詳細錯誤
systemctl status pwm-tach-sim
journalctl -xe
```

### Q: PWM 無法存取
```bash
# 手動設定 PWM
pwm_test.sh setup
```

### Q: GPIO 被佔用
```bash
# 檢查 GPIO 狀態
gpioinfo gpiochip0 | grep -A 1 "line   3"
```

## 📝 檔案位置

安裝後的檔案位置：
- `/usr/sbin/pwm_tach_sim` - TACH 模擬器主程式
- `/usr/sbin/pwm_capture` - PWM 捕獲工具
- `/usr/sbin/pwm_test.sh` - PWM 測試腳本
- `/usr/sbin/closed_loop_test.sh` - 閉迴路測試腳本
- `/usr/sbin/gpio_toggle.sh` - GPIO 測試腳本
- `/lib/systemd/system/pwm-tach-sim.service` - Systemd 服務

## 🔄 完整測試流程

```bash
# === 在目標系統上 ===

# 1. 初始化
pwm_test.sh setup

# 2. 啟動服務
systemctl start pwm-tach-sim

# 3. 在另一個終端監控
journalctl -u pwm-tach-sim -f

# 4. 測試不同 duty cycle
pwm_test.sh set 0
sleep 2
pwm_test.sh set 25
sleep 2
pwm_test.sh set 50
sleep 2
pwm_test.sh set 75
sleep 2
pwm_test.sh set 100

# 5. 自動掃描測試
pwm_test.sh sweep

# 6. 完成後清理
systemctl stop pwm-tach-sim
pwm_test.sh cleanup
```

## 📈 性能指標

- **PWM 讀取間隔**: 100ms
- **TACH 頻率範圍**: 10 Hz - 1000 Hz
- **頻率精度**: ±1 Hz
- **響應時間**: < 100ms

## 🎓 下一步

1. 閱讀完整文檔: `README.md`
2. 查看系統架構: `ARCHITECTURE.txt`
3. 根據需求調整參數
4. 整合到你的風扇控制系統

## 💡 提示

- 使用 `pwm_test.sh sweep` 可以快速驗證整個系統
- 使用 `journalctl -u pwm-tach-sim -f` 即時監控
- GPIO03 輸出的是 50% duty cycle 的方波
- 可以用示波器驗證實際頻率

祝測試順利！🎉
