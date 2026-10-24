# xLamp

xLamp 是一个 Android 端的 BLE 灯具控制客户端，基于对 **LampSmartPro 1.4.0** 的静态逆向结果独立实现。
它复刻了原 App 的核心链路：**不建立 GATT 连接**，而是把 31 字节的 v3 指令帧编码成
13 个 16-bit Service UUID 并通过 BLE 广播发送。

- 包名：`com.voxyn.xlamp`
- UI：Flutter + [flutter_miuix](https://github.com/ChuxinNeko/flutter_miuix)（HyperOS/MIUI 风格）
- 仅 Android

## 功能

- 设备管理：灯具 / 风扇 / 换气 / 浴霸，独立地址与通道
- 配对 / 解绑（对应 `blevbBinding` 的 `0x28` / `0x45`）
- 开关、亮度、色温、RGB、场景、夜灯
- 广播参数可调（时长、重复窗口、间隔）
- 本机 ID（对应原 App 的 `DEVICE_ADDRESS`）可查看与修改
- RAW 调试页：手动构造任意 v3 帧并预览 31 字节与 13 个 UUID

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

## 构建

```bash
flutter pub get
flutter analyze
flutter build apk --debug
```

APK 输出：`build/app/outputs/flutter-apk/app-debug.apk`。

仓库自带 GitHub Actions（`.github/workflows/android.yml`），push 到 `main` 或手动
`workflow_dispatch` 即可产出 `xlamp-debug-apk` artifact。

## 已知边界

- 未连接真实灯具验证；`type`/地址/通道的实际取值需要在设备上确认。
- 原 App 还会交替广播一组 Dart 侧辅助 payload；本实现只发送 v3 帧。
- 若灯具之前被原 App 配对过，可能需要先用原 App 解绑，或在本 App 里重新配对。
