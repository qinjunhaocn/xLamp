import 'dart:math';

import '../protocol/lamp_commands.dart';

/// 一台被控灯具（或风扇/浴霸）的本地模型。
class LampDevice {
  LampDevice({
    required this.id,
    required this.name,
    required this.type,
    required this.address,
    this.channel = 0,
    this.paired = false,
    this.power = false,
    this.brightness = 80,
    this.colorTemp = 50,
    this.red = 255,
    this.green = 214,
    this.blue = 170,
    this.scene = 0,
  });

  final String id;
  String name;
  int type;
  int address;
  int channel;
  bool paired;
  bool power;
  int brightness;
  int colorTemp;
  int red;
  int green;
  int blue;
  int scene;

  String get typeLabel => LampType.labelOf(type);

  String get subtitle {
    final String p = paired ? '已配对' : '未配对';
    return '$typeLabel · $p · 地址 $address';
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'type': type,
        'address': address,
        'channel': channel,
        'paired': paired,
        'power': power,
        'brightness': brightness,
        'colorTemp': colorTemp,
        'red': red,
        'green': green,
        'blue': blue,
        'scene': scene,
      };

  factory LampDevice.fromJson(Map<String, dynamic> json) {
    return LampDevice(
      id: json['id'] as String? ?? _newId(),
      name: json['name'] as String? ?? '未命名设备',
      type: (json['type'] as num?)?.toInt() ?? LampType.lamp,
      address: (json['address'] as num?)?.toInt() ?? 0,
      channel: (json['channel'] as num?)?.toInt() ?? 0,
      paired: json['paired'] as bool? ?? false,
      power: json['power'] as bool? ?? false,
      brightness: (json['brightness'] as num?)?.toInt() ?? 80,
      colorTemp: (json['colorTemp'] as num?)?.toInt() ?? 50,
      red: (json['red'] as num?)?.toInt() ?? 255,
      green: (json['green'] as num?)?.toInt() ?? 214,
      blue: (json['blue'] as num?)?.toInt() ?? 170,
      scene: (json['scene'] as num?)?.toInt() ?? 0,
    );
  }

  static String newId() => _newId();

  static String _newId() {
    final Random r = Random();
    return '${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}'
        '${r.nextInt(1 << 20).toRadixString(36)}';
  }
}
