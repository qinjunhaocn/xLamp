import 'package:flutter/material.dart';

import '../models/lamp_device.dart';
import '../protocol/lamp_commands.dart';
import '../protocol/v3_frame.dart';
import '../services/ble_service.dart';
import '../services/device_store.dart';

import 'dart:typed_data';

/// 全局状态：设备、广播参数、外观与蓝牙权限。
class AppState extends ChangeNotifier {
  AppState({BleService? ble, DeviceStore? store})
      : _ble = ble ?? BleService(),
        _store = store ?? DeviceStore();

  final BleService _ble;
  final DeviceStore _store;

  final List<LampDevice> _devices = <LampDevice>[];
  List<LampDevice> get devices => List<LampDevice>.unmodifiable(_devices);

  int phoneId = 0;
  int duration = 4000;
  int repeats = 8;
  int interval = 500;

  bool ready = false;
  bool supported = true;
  bool enabled = false;
  bool sending = false;
  String? lastError;
  String? lastAction;
  Uint8List? lastFrame;

  ThemeMode themeMode = ThemeMode.system;
  bool monetEnabled = true;
  bool permissionGranted = false;

  bool get needsPermission => supported && !permissionGranted;

  Future<void> init() async {
    phoneId = await _store.loadPhoneId();
    duration = await _store.loadDuration();
    repeats = await _store.loadRepeats();
    interval = await _store.loadInterval();
    themeMode = await _store.loadThemeMode();
    monetEnabled = await _store.loadMonet();
    _devices
      ..clear()
      ..addAll(await _store.loadDevices());
    supported = await _ble.isSupported();
    enabled = await _ble.isEnabled();
    permissionGranted = await _ble.hasPermissions();
    ready = true;
    notifyListeners();
  }

  Future<void> refreshBluetooth() async {
    enabled = await _ble.isEnabled();
    permissionGranted = await _ble.hasPermissions();
    notifyListeners();
  }

  LampDevice? byId(String id) {
    for (final LampDevice d in _devices) {
      if (d.id == id) return d;
    }
    return null;
  }

  Future<void> addDevice(LampDevice device) async {
    _devices.add(device);
    await _store.saveDevices(_devices);
    notifyListeners();
  }

  Future<void> updateDevice(LampDevice device) async {
    final int i = _devices.indexWhere((LampDevice d) => d.id == device.id);
    if (i >= 0) {
      _devices[i] = device;
      await _store.saveDevices(_devices);
      notifyListeners();
    }
  }

  Future<void> removeDevice(String id) async {
    _devices.removeWhere((LampDevice d) => d.id == id);
    await _store.saveDevices(_devices);
    notifyListeners();
  }

  Future<void> setPhoneId(int value) async {
    phoneId = value;
    await _store.savePhoneId(value);
    notifyListeners();
  }

  Future<void> setDuration(int value) async {
    duration = value;
    await _store.saveDuration(value);
    notifyListeners();
  }

  Future<void> setRepeats(int value) async {
    repeats = value;
    await _store.saveRepeats(value);
    notifyListeners();
  }

  Future<void> setInterval(int value) async {
    interval = value;
    await _store.saveInterval(value);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    themeMode = mode;
    await _store.saveThemeMode(mode);
    notifyListeners();
  }

  Future<void> setMonet(bool value) async {
    monetEnabled = value;
    await _store.saveMonet(value);
    notifyListeners();
  }

  /// 申请蓝牙权限；失败时返回 false。
  Future<bool> requestBleAccess() async {
    if (!supported) return false;
    final bool granted = await _ble.ensurePermissions();
    permissionGranted = granted;
    if (!granted) {
      lastError = '需要“附近的设备”权限才能发送控制指令';
    } else {
      enabled = await _ble.isEnabled();
    }
    notifyListeners();
    return granted;
  }

  /// 发送一帧：确保权限 → 调用原生广播。
  Future<bool> send(Uint8List frame, {String? action}) async {
    if (!supported) {
      lastError = '这台设备的蓝牙不支持 BLE 外设广播';
      notifyListeners();
      return false;
    }
    if (!permissionGranted) {
      final bool granted = await requestBleAccess();
      if (!granted) {
        lastError = '需要“附近的设备”权限才能发送指令';
        notifyListeners();
        return false;
      }
    }
    if (!await _ble.isEnabled()) {
      enabled = false;
      lastError = '蓝牙未开启';
      notifyListeners();
      return false;
    }
    sending = true;
    lastError = null;
    lastAction = action;
    lastFrame = frame;
    notifyListeners();
    try {
      await _ble.advertise(frame, duration: duration, repeats: repeats, interval: interval);
      return true;
    } on BleException catch (e) {
      lastError = e.message;
      return false;
    } finally {
      sending = false;
      notifyListeners();
    }
  }

  int var1For(LampDevice d) => (phoneId + d.channel) & 0x7fffffff;

  Future<bool> pair(LampDevice d) async {
    final bool ok = await send(
      LampCommands.binding(type: d.type, var1: var1For(d), var2: d.address, bind: true),
      action: '配对 ${d.name}',
    );
    if (ok) {
      d.paired = true;
      await updateDevice(d);
    }
    return ok;
  }

  Future<bool> unpair(LampDevice d) async {
    final bool ok = await send(
      LampCommands.binding(type: d.type, var1: var1For(d), var2: d.address, bind: false),
      action: '解绑 ${d.name}',
    );
    if (ok) {
      d.paired = false;
      d.power = false;
      await updateDevice(d);
    }
    return ok;
  }

  Future<bool> setPower(LampDevice d, bool on) async {
    final bool ok = await send(
      LampCommands.power(type: d.type, var1: var1For(d), var2: d.address, on: on),
      action: '${on ? '开灯' : '关灯'} ${d.name}',
    );
    if (ok) {
      d.power = on;
      await updateDevice(d);
    }
    return ok;
  }

  Future<void> setBrightness(LampDevice d, int value) async {
    d.brightness = value;
    notifyListeners();
    await send(
      LampCommands.brightness(
        type: d.type,
        var1: var1For(d),
        var2: d.address,
        percent: value,
      ),
      action: '亮度 ${d.name}',
    );
    await updateDevice(d);
  }

  Future<void> setColorTemp(LampDevice d, int value) async {
    d.colorTemp = value;
    notifyListeners();
    await send(
      LampCommands.colorTemp(
        type: d.type,
        var1: var1For(d),
        var2: d.address,
        percent: value,
      ),
      action: '色温 ${d.name}',
    );
    await updateDevice(d);
  }

  Future<void> setRgb(LampDevice d, int r, int g, int b) async {
    d.red = r;
    d.green = g;
    d.blue = b;
    notifyListeners();
    await send(
      LampCommands.rgb(
        type: d.type,
        var1: var1For(d),
        var2: d.address,
        r: r,
        g: g,
        b: b,
      ),
      action: '颜色 ${d.name}',
    );
    await updateDevice(d);
  }

  Future<void> sceneOn(LampDevice d) async {
    await send(
      LampCommands.sceneOn(type: d.type, var1: var1For(d), var2: d.address),
      action: '场景开 ${d.name}',
    );
  }

  Future<void> sceneSwitch(LampDevice d, int index) async {
    d.scene = index;
    await send(
      LampCommands.sceneSwitch(
        type: d.type,
        var1: var1For(d),
        var2: d.address,
        index: index,
      ),
      action: '场景 ${index + 1} ${d.name}',
    );
    await updateDevice(d);
  }

  Future<void> nightLight(LampDevice d) async {
    await send(
      LampCommands.nightLight(type: d.type, var1: var1For(d), var2: d.address),
      action: '夜灯 ${d.name}',
    );
  }

  Future<void> sendRaw({
    required int type,
    required int var1,
    required int var2,
    required int command,
    required int p21,
    required int p22,
    required int p23,
  }) async {
    await send(
      V3Frame.build(
        type: type,
        var1: var1,
        var2: var2,
        command: command,
        p21: p21,
        p22: p22,
        p23: p23,
      ),
      action: 'RAW 0x${command.toRadixString(16)}',
    );
  }
}
