import 'package:flutter/material.dart';

import '../main.dart' show AppScope;
import '../models/lamp_device.dart';
import '../protocol/lamp_commands.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';
import 'add_device_page.dart';
import 'device_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final AppState state = AppScope.of(context);
    final List<LampDevice> devices = state.devices;
    return Scaffold(
      floatingActionButton: devices.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _openAdd(context),
              icon: const Icon(Icons.add),
              label: const Text('添加设备'),
            ),
      body: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar.large(
            title: const Text('xLamp'),
            actions: <Widget>[
              IconButton(
                tooltip: '刷新蓝牙状态',
                onPressed: state.refreshBluetooth,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
            sliver: SliverList(
              delegate: SliverChildListDelegate(<Widget>[
                _StatusCard(state: state),
                if (state.needsPermission) _PermissionCard(state: state),
                if (devices.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: EmptyState(
                      icon: Icons.lightbulb_outline,
                      title: '还没有添加设备',
                      message: '给灯具通电后，点击下方按钮添加设备，\n然后在 5 秒内完成配对。',
                      action: FilledButton.icon(
                        onPressed: () => _openAdd(context),
                        icon: const Icon(Icons.add),
                        label: const Text('添加第一个设备'),
                      ),
                    ),
                  )
                else ...<Widget>[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 22, 4, 10),
                    child: Row(
                      children: <Widget>[
                        Text(
                          '我的设备',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const Spacer(),
                        Text(
                          '${devices.length} 台',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                  ...devices.map((LampDevice d) => DeviceCard(device: d)),
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }

  static void _openAdd(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const AddDevicePage()),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final ColorScheme c = Theme.of(context).colorScheme;
    final TextTheme t = Theme.of(context).textTheme;
    final bool ready = state.supported && state.enabled && state.permissionGranted;
    final String label;
    final String hint;
    if (!state.supported) {
      label = '设备不支持';
      hint = '当前手机不支持 BLE 外设广播';
    } else if (!state.permissionGranted) {
      label = '等待授权';
      hint = '授予“附近的设备”权限后即可控制';
    } else if (!state.enabled) {
      label = '蓝牙未开启';
      hint = '请在系统设置中打开蓝牙';
    } else {
      label = '广播就绪';
      hint = '保持 App 在前台，效果最好';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[c.primaryContainer, c.secondaryContainer],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: c.primary,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(Icons.wb_incandescent_outlined, color: c.onPrimary, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      ready ? '一切就绪' : '需要一点准备',
                      style: t.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: c.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      hint,
                      style: t.bodySmall?.copyWith(
                        color: c.onPrimaryContainer.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ),
              ),
              StatusPill(
                label: label,
                color: ready ? c.primary : c.error,
                icon: ready ? Icons.bluetooth_connected : Icons.info_outline,
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: <Widget>[
              _Metric(label: '设备', value: '${state.devices.length}'),
              _Metric(
                label: '已配对',
                value: '${state.devices.where((LampDevice d) => d.paired).length}',
              ),
              _Metric(label: '主题', value: state.monetEnabled ? '莫奈' : '默认'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ColorScheme c = Theme.of(context).colorScheme;
    final TextTheme t = Theme.of(context).textTheme;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: t.labelSmall?.copyWith(color: c.onPrimaryContainer.withValues(alpha: 0.6)),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: t.titleMedium?.copyWith(
              color: c.onPrimaryContainer,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _PermissionCard extends StatelessWidget {
  const _PermissionCard({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final ColorScheme c = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Card(
        color: c.errorContainer,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: <Widget>[
              Icon(Icons.lock_outline, color: c.onErrorContainer),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '需要“附近的设备”权限才能发送控制指令',
                  style: TextStyle(color: c.onErrorContainer),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.tonal(
                onPressed: () => state.requestBleAccess(),
                child: const Text('授权'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DeviceCard extends StatefulWidget {
  const DeviceCard({super.key, required this.device});

  final LampDevice device;

  @override
  State<DeviceCard> createState() => _DeviceCardState();
}

class _DeviceCardState extends State<DeviceCard> {
  late double _brightness = widget.device.brightness.toDouble();

  @override
  Widget build(BuildContext context) {
    final LampDevice device = widget.device;
    final AppState state = AppScope.of(context);
    final ColorScheme c = Theme.of(context).colorScheme;
    final TextTheme t = Theme.of(context).textTheme;
    final bool on = device.power;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => DevicePage(device: device)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: on ? c.primary : c.surfaceContainerHighest,
                      child: Icon(
                        iconForType(device.type),
                        color: on ? c.onPrimary : c.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            device.name,
                            style: t.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            device.paired
                                ? '${device.typeLabel} · 已配对'
                                : '${device.typeLabel} · 未配对',
                            style: t.bodySmall?.copyWith(color: c.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: on,
                      onChanged: device.paired
                          ? (bool v) => state.setPower(device, v)
                          : null,
                    ),
                  ],
                ),
                if (device.paired) ...<Widget>[
                  const SizedBox(height: 4),
                  Row(
                    children: <Widget>[
                      Icon(Icons.brightness_low, size: 18, color: c.onSurfaceVariant),
                      Expanded(
                        child: Slider(
                          value: _brightness,
                          min: 1,
                          max: 100,
                          divisions: 99,
                          label: '${_brightness.round()}%',
                          onChanged: (double v) => setState(() => _brightness = v),
                          onChangeEnd: (double v) =>
                              state.setBrightness(device, v.round()),
                        ),
                      ),
                      Icon(Icons.brightness_high, size: 18, color: c.onSurfaceVariant),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

IconData iconForType(int type) {
  switch (type) {
    case LampType.fan:
      return Icons.wind_power;
    case LampType.bath:
      return Icons.bathtub_outlined;
    case LampType.flp:
      return Icons.air;
    default:
      return Icons.lightbulb_outline;
  }
}
