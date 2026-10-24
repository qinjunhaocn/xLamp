# xLamp

xLamp 是一个 Android 端的 BLE 灯具控制客户端，基于对 **LampSmartPro 1.4.0** 的静态逆向结果独立实现。
它复刻了原 App 的核心链路：**不建立 GATT 连接**，而是把 31 字节的 v3 指令帧编码成
13 个 16-bit Service UUID 并通过 BLE 广播发送。

- 包名：`com.voxyn.xlamp`
- UI：Material Design 3，支持 Android 12+ **莫奈取色**（Monet / 动态取色）
- 仅 Android（minSdk 24）

## 使用流程

1. 首次打开时授予「附近的设备」权限（Android 12+）。
2. 点击「添加设备」，起个名字、选择类型，保存。
3. 给灯具断电再上电，在 **5 秒内**点击「我已上电，开始配对」。
4. 灯闪烁或蜂鸣即配对成功，之后即可开关、调亮度/色温/颜色、切换场景。

不需要手动填写任何协议参数；地址与通道会在添加设备时自动分配，只有排查问题时才需要
打开「高级参数」。

## 功能

- 设备管理：灯具 / 风扇 / 换气 / 浴霸
- 一键配对 / 解绑（对应 `blevbBinding` 的 `0x28` / `0x45`）
- 开关、亮度、色温、颜色（预设 + HSV 自定义）、场景、夜灯
- Material 3 + 动态取色，浅色/深色/跟随系统
- 广播参数可调（时长、重复窗口、间隔）
- 开发者工具：手动构造任意 v3 帧并预览

## 协议实现

`lib/protocol/v3_frame.dart` 是 `libencodeV3.so` 中 `ble_v3_encoder` 的逐指令移植：

| 偏移 | 内容 |
|---|---|
| 0..6 | `02 01 02 1b 16 f0 08` |
| 7..9 | `30 80 00` |
| 10 | tx_count |
| 11..12 | type |
| 13..16 | var1（本机 ID + 通道） |
| 17 | var2（设备地址） |
| 18..21 | 命令 + 参数 |
| 22..23 | 参数 |
| 24..25 | AES-128(PDU[8..23]) 前两字节 |
| 26 | 0 |
| 27..28 | rand |
| 29..30 | CRC-16/CCITT |

移植结果已用 Unicorn 模拟原始 ARM64 代码做过逐字节比对（`tool/verify.dart`，5/5 通过）。

### 亮度与色温

原 App 的亮度/色温共用一条调光帧（命令 `0x21`）：

- `factor = 0.1 + 0.9 * 亮度`（最暗保留 10%，不会把灯调成“关机”）
- 色温 `0..100` 在暖/冷两个通道间分配，分别写入 `p22`（冷）与 `p23`（暖）
- 最亮时两个通道都是 `255`；最暖时冷通道为 `0`，最冷时暖通道为 `0`

`LampCommands.dimmingChannels()` 与 `scaleChannel()` 复刻了这套算法，并有单元测试覆盖。

## 构建

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```

APK 输出：`build/app/outputs/flutter-apk/app-debug.apk`。

仓库自带 GitHub Actions（`.github/workflows/android.yml`），push 到 `main` 或手动
`workflow_dispatch` 会构建 APK 并发布到 Release（tag `build-<run_number>`）。

## 已知边界

- 未连接真实灯具验证；`type`/地址/通道的取值若与固件不符，可在「高级参数」中调整。
- 原 App 还会交替广播一组 Dart 侧辅助 payload；本实现只发送 v3 帧。
- 若灯具之前被原 App 配对过，可能需要先用原 App 解绑，或在本 App 里重新配对。
