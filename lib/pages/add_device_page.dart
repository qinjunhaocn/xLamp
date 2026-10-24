import 'package:flutter/material.dart';

import '../main.dart' show AppScope;
import '../models/lamp_device.dart';
import '../protocol/lamp_commands.dart';
import '../state/app_state.dart';
import 'device_page.dart';

class AddDevicePage extends StatefulWidget {
  const AddDevicePage({super.key, this.device});

  final LampDevice? device;

  @override
  State<AddDevicePage> createState() => _AddDevicePageState();
}

class _AddDevicePageState extends State<AddDevicePage> {
  late final TextEditingController _name;
  late int _type = widget.device?.type ?? LampType.lamp;
  late double _address = (widget.device?.address ?? 0).toDouble();
  late double _channel = (widget.device?.channel ?? 0).toDouble();
  bool _advanced = false;
  bool _addressInitialized = false;

  static const Map<int, _TypeInfo> _types = <int, _TypeInfo>{
    LampType.lamp: _TypeInfo('吸顶灯 / 台灯', Icons.lightbulb_outline),
    LampType.fan: _TypeInfo('风扇灯', Icons.wind_power),
    LampType.flp: _TypeInfo('换气扇', Icons.air),
    LampType.bath: _TypeInfo('浴霸', Icons.bathtub_outlined),
  };

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.device?.name ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  int _nextAddress(AppState state) {
    if (widget.device != null) return widget.device!.address;
    int max = 0;
    for (final LampDevice d in state.devices) {
      if (d.address > max) max = d.address;
    }
    return (max + 1).clamp(0, 255);
  }

  @override
  Widget build(BuildContext context) {
    final AppState state = AppScope.of(context);
    final ColorScheme c = Theme.of(context).colorScheme;
    final TextTheme t = Theme.of(context).textTheme;
    final bool editing = widget.device != null;
    if (!_addressInitialized) {
      _addressInitialized = true;
      if (!editing) _address = _nextAddress(state).toDouble();
    }
    return Scaffold(
      appBar: AppBar(title: Text(editing ? '编辑设备' : '添加设备')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: <Widget>[
          Text(
            editing ? '修改设备名称或类型' : '给新设备起个名字，稍后再完成配对',
            style: t.bodyMedium?.copyWith(color: c.onSurfaceVariant),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _name,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: '设备名称',
              hintText: '例如：客厅主灯',
              prefixIcon: Icon(Icons.drive_file_rename_outline),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 22),
          Text('设备类型', style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _types.entries.map((MapEntry<int, _TypeInfo> e) {
              final bool selected = _type == e.key;
              return ChoiceChip(
                selected: selected,
                onSelected: (_) => setState(() => _type = e.key),
                avatar: Icon(e.value.icon, size: 18),
                label: Text(e.value.label),
                showCheckmark: false,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              );
            }).toList(),
          ),
          const SizedBox(height: 22),
          Card(
            color: c.surfaceContainerLow,
            child: ExpansionTile(
              initiallyExpanded: _advanced,
              onExpansionChanged: (bool v) => setState(() => _advanced = v),
              leading: const Icon(Icons.tune),
              title: const Text('高级参数'),
              subtitle: const Text('通常不需要修改'),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              children: <Widget>[
                Row(
                  children: <Widget>[
                    const Text('设备地址'),
                    const Spacer(),
                    Text('${_address.round()}', style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
                Slider(
                  value: _address,
                  min: 0,
                  max: 255,
                  divisions: 255,
                  onChanged: (double v) => setState(() => _address = v),
                ),
                Row(
                  children: <Widget>[
                    const Text('通道'),
                    const Spacer(),
                    Text('${_channel.round()}', style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
                Slider(
                  value: _channel,
                  min: 0,
                  max: 15,
                  divisions: 15,
                  onChanged: (double v) => setState(() => _channel = v),
                ),
                Text(
                  'var1 = 本机 ID + 通道 = 0x${(state.phoneId + _channel.round()).toRadixString(16).toUpperCase()}',
                  style: t.bodySmall?.copyWith(color: c.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '添加后请在灯具上电 5 秒内完成配对。\n若灯具之前被其他手机占用，需要先解绑。',
            style: t.bodySmall?.copyWith(color: c.onSurfaceVariant),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: FilledButton.icon(
          onPressed: () => _save(state),
          icon: Icon(editing ? Icons.check : Icons.add),
          label: Text(editing ? '保存修改' : '添加设备'),
        ),
      ),
    );
  }

  void _save(AppState state) {
    final String name = _name.text.trim().isEmpty
        ? (_types[_type]?.label ?? '我的灯')
        : _name.text.trim();
    if (widget.device != null) {
      final LampDevice d = widget.device!
        ..name = name
        ..type = _type
        ..address = _address.round()
        ..channel = _channel.round();
      Navigator.of(context).pop(d);
      return;
    }
    final LampDevice device = LampDevice(
      id: LampDevice.newId(),
      name: name,
      type: _type,
      address: _address.round(),
      channel: _channel.round(),
    );
    state.addDevice(device);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => DevicePage(device: device, autoPair: true),
      ),
    );
  }
}

class _TypeInfo {
  const _TypeInfo(this.label, this.icon);
  final String label;
  final IconData icon;
}
