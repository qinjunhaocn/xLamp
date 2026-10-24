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

  /// 计算调光帧里的两个通道值：[冷, 暖]。
  ///
  /// 完全复刻原 App `Order.colorTemp` 的算法。
  static List<int> dimmingChannels(double brightness, double temperature) {
    final double b = brightness.clamp(0.0, 1.0);
    final double t = temperature.clamp(0.0, 1.0) * 100.0;
    final double factor = 0.1 + 0.9 * b;
    final int maxChannel = (255.0 * factor).floor();
    int cool;
    int warm;
    if (t > 50) {
      cool = maxChannel;
      warm = (255.0 * factor * (1.0 - (t - 50.0) / 50.0)).floor();
    } else {
      cool = (255.0 * factor * (t / 50.0)).floor();
      warm = maxChannel;
    }
    return <int>[cool.clamp(0, 255), warm.clamp(0, 255)];
  }

  /// 亮度 + 色温合并的调光帧（对应原 App 的 Order.colorTemp）。
  ///
  /// 原实现把亮度换算成 `factor = 0.1 + 0.9 * brightness`，再按色温在
  /// 暖/冷两个通道间分配，写入 p22（冷）与 p23（暖）。因此：
  ///  - 最亮时两个通道都是 255，而不是 100；
  ///  - 最暗时仍有 10% 的底值，灯具不会把滑到最小当成关机。
  static Uint8List dimming({
    required int type,
    required int var1,
    required int var2,
    required double brightness,
    required double temperature,
  }) {
    final List<int> ch = dimmingChannels(brightness, temperature);
    return V3Frame.build(
      type: type,
      var1: var1,
      var2: var2,
      command: LampOp.dimming,
      p22: ch[0],
      p23: ch[1],
    );
  }

  /// 把 0..255 的颜色通道按亮度系数缩放到原 App 的取值。
  static int scaleChannel(int channel, double brightness) {
    final double factor = 0.1 + 0.9 * brightness.clamp(0.0, 1.0);
    return (channel.clamp(0, 255) * factor).floor().clamp(0, 255);
  }

  /// RGB 三通道，写入 p21/p22/p23。
  ///
  /// 与原 App 一样按亮度系数缩放，避免切换颜色时亮度跳变。
  static Uint8List rgb({
    required int type,
    required int var1,
    required int var2,
    required int r,
    required int g,
    required int b,
    double brightness = 1.0,
  }) {
    int scale(int c) => scaleChannel(c, brightness);
    return V3Frame.build(
      type: type,
      var1: var1,
      var2: var2,
      command: LampOp.rgbSwitch,
      p21: scale(r),
      p22: scale(g),
      p23: scale(b),
    );
  }

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
