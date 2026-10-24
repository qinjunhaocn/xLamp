import 'package:flutter/material.dart';
import 'package:flutter_miuix/miuix.dart';

import '../main.dart' show AppScope;
import '../models/lamp_device.dart';
import '../protocol/lamp_commands.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';
import 'add_edit_page.dart';
import 'device_page.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key, required this.padding});

  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final AppState state = AppScope.of(context);
    final List<LampDevice> devices = state.devices;
    return ListView(
      padding: padding.copyWith(top: 6, bottom: 96),
      children: <Widget>[
        _HeroCard(state: state),
        if (devices.isEmpty)
          _EmptyCard(onAdd: () => _openAdd(context))
        else ...<Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 10),
            child: Row(
              children: <Widget>[
                MiuixText('我的设备', style: MiuixTheme.of(context).textStyles.title4),
                const Spacer(),
                MiuixText(
                  '${devices.length} 台',
                  style: MiuixTheme.of(context).textStyles.footnote1,
                  color: MiuixTheme.of(context).colors.onSurfaceVariantSummary,
                ),
              ],
            ),
          ),
          ...devices.map((LampDevice d) => DeviceCard(device: d)),
        ],
        if (state.lastError != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: MiuixText(
              state.lastError!,
              color: MiuixTheme.of(context).colors.error,
              style: MiuixTheme.of(context).textStyles.footnote1,
            ),
          ),
      ],
    );
  }

  void _openAdd(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const AddEditPage()),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final MiuixColors c = MiuixTheme.of(context).colors;
    final MiuixTextStyles t = MiuixTheme.of(context).textStyles;
    final bool ready = state.supported && state.enabled;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: MiuixCard(
        insideMargin: EdgeInsets.zero,
        colors: MiuixCardColors(color: c.primaryContainer, contentColor: c.onPrimaryContainer),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: <Color>[c.primary, c.primaryVariant],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: MiuixIcon(icon: Icons.wb_incandescent_outlined, tint: c.onPrimary, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        MiuixText('xLamp', style: t.title2, color: c.onPrimaryContainer),
                        const SizedBox(height: 2),
                        MiuixText(
                          '基于 v3 广播协议的灯光控制台',
                          style: t.footnote1,
                          color: c.onPrimaryContainer.withValues(alpha: 0.7),
                        ),
                      ],
                    ),
                  ),
                  StatusChip(
                    label: ready ? '广播就绪' : (state.supported ? '蓝牙关闭' : '不支持'),
                    color: ready ? c.primary : c.error,
                    icon: ready ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: <Widget>[
                  _Metric(label: '设备', value: '${state.devices.length}'),
                  _Metric(label: '配对', value: '${state.devices.where((LampDevice d) => d.paired).length}'),
                  _Metric(
                    label: '本机 ID',
                    value: '0x${state.phoneId.toRadixString(16).toUpperCase()}',
                    flex: 2,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value, this.flex = 1});

  final String label;
  final String value;
  final int flex;

  @override
  Widget build(BuildContext context) {
    final MiuixColors c = MiuixTheme.of(context).colors;
    final MiuixTextStyles t = MiuixTheme.of(context).textStyles;
    return Expanded(
      flex: flex,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          MiuixText(label, style: t.footnote2, color: c.onPrimaryContainer.withValues(alpha: 0.6)),
          const SizedBox(height: 4),
          MiuixText(
            value,
            style: t.title3,
            color: c.onPrimaryContainer,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final MiuixColors c = MiuixTheme.of(context).colors;
    final MiuixTextStyles t = MiuixTheme.of(context).textStyles;
    return MiuixCard(
      insideMargin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 34),
        child: Column(
          children: <Widget>[
            IconBadge(icon: Icons.lightbulb_outline, size: 60, iconSize: 30),
            const SizedBox(height: 14),
            MiuixText('还没有设备', style: t.title4),
            const SizedBox(height: 6),
            MiuixText(
              '给灯具通电后 5 秒内完成配对，即可在这里控制它。',
              style: t.footnote1,
              color: c.onSurfaceVariantSummary,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: 180,
              child: MiuixButton(
                onPressed: onAdd,
                colors: MiuixButtonDefaults.buttonColorsPrimary(context),
                child: const MiuixText('添加设备'),
              ),
            ),
          ],
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
    final MiuixColors c = MiuixTheme.of(context).colors;
    final MiuixTextStyles t = MiuixTheme.of(context).textStyles;
    final bool on = device.power;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: MiuixCard(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => DevicePage(device: device)),
          );
        },
        insideMargin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          child: Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  IconBadge(
                    icon: _iconFor(device.type),
                    color: on ? c.primary : c.onSurfaceVariantSummary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        MiuixText(device.name, style: t.title4, maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        MiuixText(
                          device.subtitle,
                          style: t.footnote1,
                          color: c.onSurfaceVariantSummary,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  MiuixSwitch(
                    value: on,
                    onChanged: device.paired
                        ? (bool v) => state.setPower(device, v)
                        : null,
                  ),
                ],
              ),
              if (device.paired) ...<Widget>[
                const SizedBox(height: 6),
                Row(
                  children: <Widget>[
                    MiuixIcon(icon: Icons.brightness_6, size: 16, tint: c.onSurfaceVariantSummary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: MiuixSlider(
                        value: _brightness,
                        min: 1,
                        max: 100,
                        onValueChanged: (double v) =>
                            setState(() => _brightness = v),
                        onValueChangeFinished: () =>
                            state.setBrightness(device, _brightness.round()),
                      ),
                    ),
                    SizedBox(
                      width: 34,
                      child: MiuixText(
                        '${_brightness.round()}',
                        style: t.footnote1,
                        color: c.onSurfaceVariantSummary,
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static IconData _iconFor(int type) {
    switch (type) {
      case LampType.fan:
        return Icons.mode_fan_off_outlined;
      case LampType.bath:
        return Icons.bathtub_outlined;
      case LampType.flp:
        return Icons.air;
      default:
        return Icons.lightbulb_outline;
    }
  }
}
