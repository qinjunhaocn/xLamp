import 'dart:typed_data';

import 'v3_frame.dart';

/// ToolV3 的设备类别常量。
class LampType {
  LampType._();
  static const int lamp = 256; // 0x0100
  static const int fan = 512; // 0x0200
  static const int flp = 1024; // 0x0400
  static const int bath = 2048; // 0x0800

  static const Map<int, String> labels = <int, String>{
    lamp: '灯具',
    fan: '风扇',
    flp: '换气',
    bath: '浴霸',
  };

  static String labelOf(int type) => labels[type] ?? '设备 0x${type.toRadixString(16)}';
}

/// v3 操作码常量（来自 ToolV3 各 wrapper 的立即数）。
class LampOp {
  LampOp._();

  // 配对/解绑共用 0x28 / 0x45。
  static const int bind = 0x28;
  static const int unbind = 0x45;

  // 主灯：0x10 = 开，0x11 = 关。
  static const int on = 0x10;
  static const int off = 0x11;

  static const int dimming = 0x21;
  static const int dimmingNight = 0x23;
  static const int temperature = 0x52;
  static const int rgbSwitch = 0x22;
  static const int rgbOnOff = 0x1c;
  static const int rgbAutoOff = 0x1f;
  static const int rgbAutoOn = 0x1e;
  static const int sceneOn = 0x10;
  static const int sceneSet = 0x46;
  static const int sceneSwitch = 0x47;
  static const int sceneReset = 0x48;
  static const int fanSpeed = 0x31;
  static const int fanMode = 0x33;
}

/// 构造各类命令帧。
///
/// [var1] 对应原 App 的 `DEVICE_ADDRESS + channel`，[var2] 对应设备地址字节。
class LampCommands {
  LampCommands._();

  static Uint8List binding({
    required int type,
    required int var1,
    required int var2,
    required bool bind,
  }) =>
      V3Frame.build(
        type: type,
        var1: var1,
        var2: var2,
        command: bind ? LampOp.bind : LampOp.unbind,
      );

  static Uint8List power({
    required int type,
    required int var1,
    required int var2,
    required bool on,
  }) =>
      V3Frame.build(
        type: type,
        var1: var1,
        var2: var2,
        command: on ? LampOp.on : LampOp.off,
      );

  /// 亮度 1..100，写入参数槽 p22。
  static Uint8List brightness({
    required int type,
    required int var1,
    required int var2,
    required int percent,
  }) =>
      V3Frame.build(
        type: type,
        var1: var1,
        var2: var2,
        command: LampOp.dimming,
        p22: percent.clamp(1, 100),
      );

  /// 色温 0..100，写入参数槽 p21。
  static Uint8List colorTemp({
    required int type,
    required int var1,
    required int var2,
    required int percent,
  }) =>
      V3Frame.build(
        type: type,
        var1: var1,
        var2: var2,
        command: LampOp.temperature,
        p21: percent.clamp(0, 100),
      );

  /// RGB 三通道，写入 p21/p22/p23。
  static Uint8List rgb({
    required int type,
    required int var1,
    required int var2,
    required int r,
    required int g,
    required int b,
  }) =>
      V3Frame.build(
        type: type,
        var1: var1,
        var2: var2,
        command: LampOp.rgbSwitch,
        p21: r.clamp(0, 255),
        p22: g.clamp(0, 255),
        p23: b.clamp(0, 255),
      );

  static Uint8List rgbPower({
    required int type,
    required int var1,
    required int var2,
    required bool on,
  }) =>
      V3Frame.build(
        type: type,
        var1: var1,
        var2: var2,
        command: LampOp.rgbOnOff,
        p21: on ? 1 : 0,
      );

  /// 场景开：命令 0x10 + 模式位 1。
  static Uint8List sceneOn({
    required int type,
    required int var1,
    required int var2,
  }) =>
      V3Frame.build(
        type: type,
        var1: var1,
        var2: var2,
        command: LampOp.sceneOn,
        p21: 1,
      );

  static Uint8List sceneSet({
    required int type,
    required int var1,
    required int var2,
    required int index,
  }) =>
      V3Frame.build(
        type: type,
        var1: var1,
        var2: var2,
        command: LampOp.sceneSet,
        p21: index.clamp(0, 255),
      );

  static Uint8List sceneSwitch({
    required int type,
    required int var1,
    required int var2,
    required int index,
  }) =>
      V3Frame.build(
        type: type,
        var1: var1,
        var2: var2,
        command: LampOp.sceneSwitch,
        p21: index.clamp(0, 255),
      );

  static Uint8List nightLight({
    required int type,
    required int var1,
    required int var2,
  }) =>
      V3Frame.build(
        type: type,
        var1: var1,
        var2: var2,
        command: LampOp.dimmingNight,
      );

  static Uint8List fanSpeed({
    required int type,
    required int var1,
    required int var2,
    required int speed,
  }) =>
      V3Frame.build(
        type: type,
        var1: var1,
        var2: var2,
        command: LampOp.fanSpeed,
        p21: speed.clamp(0, 255),
      );
}
