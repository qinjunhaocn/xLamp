import 'package:flutter_test/flutter_test.dart';
import 'package:xlamp/protocol/lamp_commands.dart';

void main() {
  List<int> channels(double brightness, double temperature) {
    final frame = LampCommands.dimming(
      type: LampType.lamp,
      var1: 0x1234,
      var2: 1,
      brightness: brightness,
      temperature: temperature,
    );
    expect(frame.length, 31);
    return LampCommands.dimmingChannels(brightness, temperature);
  }

  test('最亮中性光两个通道都是 255', () {
    expect(channels(1.0, 0.5), <int>[255, 255]);
  });

  test('最暖端只剩暖通道', () {
    expect(channels(1.0, 0.0), <int>[0, 255]);
  });

  test('最冷端只剩冷通道', () {
    expect(channels(1.0, 1.0), <int>[255, 0]);
  });

  test('最暗时仍有 10% 底值，不会归零', () {
    final List<int> c = channels(0.0, 0.5);
    expect(c, <int>[25, 25]);
    expect(c[0], greaterThan(0));
    expect(c[1], greaterThan(0));
  });

  test('中间亮度按系数缩放', () {
    expect(channels(0.5, 0.25), <int>[70, 140]);
  });

  test('RGB 按亮度缩放', () {
    final f = LampCommands.rgb(
      type: LampType.lamp,
      var1: 1,
      var2: 1,
      r: 255,
      g: 255,
      b: 255,
      brightness: 0.0,
    );
    expect(f.length, 31);
    // 0.1 系数下 255 * 0.1 = 25.5，向下取整为 25。
    expect(LampCommands.scaleChannel(255, 0.0), 25);
    expect(LampCommands.scaleChannel(255, 1.0), 255);
  });
}
