import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/lamp_device.dart';

/// 本地持久化：设备列表与广播参数。
class DeviceStore {
  static const String _kDevices = 'xlamp.devices';
  static const String _kPhoneId = 'xlamp.phoneId';
  static const String _kDuration = 'xlamp.duration';
  static const String _kRepeats = 'xlamp.repeats';
  static const String _kInterval = 'xlamp.interval';

  Future<SharedPreferences> get _sp => SharedPreferences.getInstance();

  Future<List<LampDevice>> loadDevices() async {
    final SharedPreferences sp = await _sp;
    final String? raw = sp.getString(_kDevices);
    if (raw == null || raw.isEmpty) return <LampDevice>[];
    try {
      final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((dynamic e) => LampDevice.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return <LampDevice>[];
    }
  }

  Future<void> saveDevices(List<LampDevice> devices) async {
    final SharedPreferences sp = await _sp;
    await sp.setString(
      _kDevices,
      jsonEncode(devices.map((LampDevice d) => d.toJson()).toList()),
    );
  }

  Future<int> loadPhoneId() async {
    final SharedPreferences sp = await _sp;
    final int? v = sp.getInt(_kPhoneId);
    if (v != null) return v;
    final int generated = Random().nextInt(0x7fffffff);
    await sp.setInt(_kPhoneId, generated);
    return generated;
  }

  Future<void> savePhoneId(int value) async {
    final SharedPreferences sp = await _sp;
    await sp.setInt(_kPhoneId, value);
  }

  Future<int> loadDuration() async {
    final SharedPreferences sp = await _sp;
    return sp.getInt(_kDuration) ?? 4000;
  }

  Future<void> saveDuration(int value) async {
    final SharedPreferences sp = await _sp;
    await sp.setInt(_kDuration, value);
  }

  Future<int> loadRepeats() async {
    final SharedPreferences sp = await _sp;
    return sp.getInt(_kRepeats) ?? 8;
  }

  Future<void> saveRepeats(int value) async {
    final SharedPreferences sp = await _sp;
    await sp.setInt(_kRepeats, value);
  }

  Future<int> loadInterval() async {
    final SharedPreferences sp = await _sp;
    return sp.getInt(_kInterval) ?? 500;
  }

  Future<void> saveInterval(int value) async {
    final SharedPreferences sp = await _sp;
    await sp.setInt(_kInterval, value);
  }
}
