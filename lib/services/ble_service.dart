import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

/// 与原生 BLE 广播插件的桥接。
class BleService {
  BleService();

  static const MethodChannel _channel = MethodChannel('xlamp/ble');

  Future<bool> isSupported() async {
    try {
      final bool? v = await _channel.invokeMethod<bool>('isSupported');
      return v ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  Future<bool> isEnabled() async {
    try {
      final bool? v = await _channel.invokeMethod<bool>('isEnabled');
      return v ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  Future<bool> hasPermissions() async {
    final PermissionStatus advertise = await Permission.bluetoothAdvertise.status;
    final PermissionStatus connect = await Permission.bluetoothConnect.status;
    return (advertise.isGranted || advertise.isLimited) &&
        (connect.isGranted || connect.isLimited);
  }

  /// 申请 Android 12+ 的蓝牙广播/连接运行时权限。
  Future<bool> ensurePermissions() async {
    final Map<Permission, PermissionStatus> statuses =
        await <Permission>[Permission.bluetoothAdvertise, Permission.bluetoothConnect]
            .request();
    return statuses.values.every((PermissionStatus s) => s.isGranted || s.isLimited);
  }

  Future<void> advertise(
    Uint8List frame, {
    int duration = 4000,
    int repeats = 8,
    int interval = 500,
  }) async {
    try {
      await _channel.invokeMethod<void>('advertise', <String, dynamic>{
        'payload': frame,
        'duration': duration,
        'repeats': repeats,
        'interval': interval,
      });
    } on PlatformException catch (e) {
      throw BleException(e.message ?? '广播失败（${e.code}）');
    } on MissingPluginException {
      throw const BleException('当前平台没有 BLE 广播实现');
    }
  }

  Future<void> stop() async {
    try {
      await _channel.invokeMethod<void>('stop');
    } on MissingPluginException {
      // 忽略：非 Android 平台。
    }
  }
}

class BleException implements Exception {
  const BleException(this.message);
  final String message;

  @override
  String toString() => message;
}
