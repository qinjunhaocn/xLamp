import 'package:flutter/material.dart';

import '../main.dart' show AppScope;
import '../models/lamp_device.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';
import 'add_device_page.dart';

class DevicePage extends StatefulWidget {
  const DevicePage({super.key, required this.device, this.autoPair = false});

  final LampDevice device;
  final bool autoPair;

  @override
  State<DevicePage> createState() => _DevicePageState();
}

class _DevicePageState extends State<DevicePage> {
  late double _brightness = widget.device.brightness.toDouble();
  late double _temp = widget.device.colorTemp.toDouble();

  static const List<Color> _palette = <Color>[
    Color(0xFFFFD9A0),
    Color(0xFFFFB4A2),
    Color(0xFFFF8A80),
    Color(0xFFF06292),
    Color(0xFFBA68C8),
    Color(0xFF7986CB),
    Color(0xFF64B5F6),
    Color(0xFF4DD0E1),
    Color(0xFF4DB6AC),
    Color(0xFF81C784),
    Color(0xFFDCE775),
    Color(0xFFFFFFFF),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.autoPair) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _openPairing());
    }
  }

  LampDevice get device => widget.device;

  @override
  Widget build(BuildContext context) {
    final AppState state = AppScope.of(context);
    final ColorScheme c = Theme.of(context).colorScheme;
    final TextTheme t = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(device.name),
            Text(
              device.paired ? '已配对 · ${device.typeLabel}' : '未配对 · ${device.typeLabel}',
              style: t.bodySmall?.copyWith(color: c.onSurfaceVariant),
            ),
          ],
        ),
        actions: <Widget>[
          PopupMenuButton<String>(
            onSelected: (String value) => _onMenu(context, state, value),
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(value: 'edit', child: Text('编辑设备')),
              if (device.paired)
                const PopupMenuItem<String>(value: 'unpair', child: Text('解除配对')),
              const PopupMenuItem<String>(value: 'delete', child: Text('删除设备')),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: <Widget>[
          _PowerButton(device: device, state: state, onTap: () => _toggle(state)),
          if (!device.paired)
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 14),
              child: _SetupCard(onPair: _openPairing),
            ),
          SectionCard(
            title: '亮度',
            child: Row(
              children: <Widget>[
                Icon(Icons.brightness_low, color: c.onSurfaceVariant),
                Expanded(
                  child: Slider(
                    value: _brightness,
                    min: 1,
                    max: 100,
                    divisions: 99,
                    label: '${_brightness.round()}%',
                    onChanged: device.paired
                        ? (double v) => setState(() => _brightness = v)
                        : null,
                    onChangeEnd: (double v) => state.setBrightness(device, v.round()),
                  ),
                ),
                Icon(Icons.brightness_high, color: c.onSurfaceVariant),
              ],
            ),
          ),
          SectionCard(
            title: '色温',
            child: Column(
              children: <Widget>[
                Container(
                  height: 10,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    gradient: const LinearGradient(
                      colors: <Color>[Color(0xFFFFE0B2), Color(0xFFFFFDE7), Color(0xFFE3F2FD)],
                    ),
                  ),
                ),
                Slider(
                  value: _temp,
                  min: 0,
                  max: 100,
                  divisions: 100,
                  label: _temp < 33 ? '暖光' : (_temp < 66 ? '中性' : '冷光'),
                  onChanged: device.paired
                      ? (double v) => setState(() => _temp = v)
                      : null,
                  onChangeEnd: (double v) => state.setColorTemp(device, v.round()),
                ),
              ],
            ),
          ),
          SectionCard(
            title: '颜色',
            trailing: TextButton(
              onPressed: device.paired ? () => _pickColor(state) : null,
              child: const Text('自定义'),
            ),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: <Widget>[
                for (final Color color in _palette)
                  _Swatch(
                    color: color,
                    selected: _isSelected(color),
                    onTap: () => state.setRgb(
                      device,
                      (color.r * 255).round(),
                      (color.g * 255).round(),
                      (color.b * 255).round(),
                    ),
                  ),
              ],
            ),
          ),
          SectionCard(
            title: '场景',
            subtitle: '场景编号由灯具固件定义',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: <Widget>[
                    for (int i = 0; i < 4; i++)
                      ChoiceChip(
                        selected: device.scene == i,
                        onSelected: device.paired
                            ? (_) => state.sceneSwitch(device, i)
                            : null,
                        label: Text('场景 ${i + 1}'),
                        showCheckmark: false,
                      ),
                    ActionChip(
                      onPressed: device.paired ? () => state.sceneOn(device) : null,
                      avatar: const Icon(Icons.auto_awesome, size: 18),
                      label: const Text('场景开'),
                    ),
                    ActionChip(
                      onPressed: device.paired ? () => state.nightLight(device) : null,
                      avatar: const Icon(Icons.nightlight_round, size: 18),
                      label: const Text('夜灯'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SectionCard(
            title: '设备信息',
            child: Column(
              children: <Widget>[
                InfoRow(label: '类型', value: device.typeLabel),
                InfoRow(label: '地址', value: '${device.address}'),
                InfoRow(label: '通道', value: '${device.channel}'),
                InfoRow(
                  label: 'var1',
                  value: '0x${state.var1For(device).toRadixString(16).toUpperCase()}',
                  last: true,
                ),
              ],
            ),
          ),
          if (state.lastError != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                state.lastError!,
                textAlign: TextAlign.center,
                style: t.bodySmall?.copyWith(color: c.error),
              ),
            ),
        ],
      ),
    );
  }

  bool _isSelected(Color color) {
    return (color.r * 255).round() == device.red &&
        (color.g * 255).round() == device.green &&
        (color.b * 255).round() == device.blue;
  }

  Future<void> _toggle(AppState state) async {
    if (!device.paired) {
      await _openPairing();
      return;
    }
    final bool ok = await state.setPower(device, !device.power);
    if (!ok && mounted) _toast(state.lastError ?? '发送失败');
  }

  Future<void> _openPairing() async {
    final AppState state = AppScope.of(context);
    final bool? paired = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (BuildContext ctx) => _PairingSheet(device: device, state: state),
    );
    if (paired == true && mounted) {
      setState(() {});
      _toast('配对完成，试试开关吧');
    }
  }

  Future<void> _pickColor(AppState state) async {
    final HSVColor initial = HSVColor.fromColor(
      Color.fromARGB(255, device.red, device.green, device.blue),
    );
    final Color? picked = await showDialog<Color>(
      context: context,
      builder: (BuildContext ctx) => _ColorDialog(initial: initial),
    );
    if (picked != null) {
      await state.setRgb(
        device,
        (picked.r * 255).round(),
        (picked.g * 255).round(),
        (picked.b * 255).round(),
      );
    }
  }

  Future<void> _onMenu(BuildContext context, AppState state, String value) async {
    switch (value) {
      case 'edit':
        final LampDevice? updated = await Navigator.of(context).push<LampDevice>(
          MaterialPageRoute<LampDevice>(builder: (_) => AddDevicePage(device: device)),
        );
        if (updated != null) {
          await state.updateDevice(updated);
          if (mounted) setState(() {});
        }
        break;
      case 'unpair':
        final bool ok = await state.unpair(device);
        if (mounted) {
          setState(() {});
          _toast(ok ? '已发送解绑指令' : (state.lastError ?? '发送失败'));
        }
        break;
      case 'delete':
        final bool? sure = await showDialog<bool>(
          context: context,
          builder: (BuildContext ctx) => AlertDialog(
            title: const Text('删除设备'),
            content: Text('确定移除「${device.name}」吗？'),
            actions: <Widget>[
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
              FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('删除')),
            ],
          ),
        );
        if (sure == true) {
          await state.removeDevice(device.id);
          if (context.mounted) Navigator.of(context).maybePop();
        }
        break;
    }
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _PowerButton extends StatelessWidget {
  const _PowerButton({required this.device, required this.state, required this.onTap});

  final LampDevice device;
  final AppState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme c = Theme.of(context).colorScheme;
    final TextTheme t = Theme.of(context).textTheme;
    final bool on = device.power;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Column(
        children: <Widget>[
          Semantics(
            button: true,
            label: on ? '关闭' : '开启',
            child: GestureDetector(
              onTap: onTap,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                width: 152,
                height: 152,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: on ? c.primary : c.surfaceContainerHighest,
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: (on ? c.primary : Colors.black).withValues(alpha: on ? 0.35 : 0.06),
                      blurRadius: on ? 32 : 12,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.power_settings_new,
                  size: 58,
                  color: on ? c.onPrimary : c.onSurfaceVariant,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            on ? '已开启' : '已关闭',
            style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(
            device.paired ? '轻触切换' : '配对后即可控制',
            style: t.bodySmall?.copyWith(color: c.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _SetupCard extends StatelessWidget {
  const _SetupCard({required this.onPair});

  final Future<void> Function() onPair;

  @override
  Widget build(BuildContext context) {
    final ColorScheme c = Theme.of(context).colorScheme;
    final TextTheme t = Theme.of(context).textTheme;
    return Card(
      color: c.tertiaryContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        child: Row(
          children: <Widget>[
            Icon(Icons.link, color: c.onTertiaryContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '还差一步：完成配对',
                style: t.titleSmall?.copyWith(color: c.onTertiaryContainer),
              ),
            ),
            FilledButton.tonal(onPressed: onPair, child: const Text('去配对')),
          ],
        ),
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.color, required this.selected, required this.onTap});

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme c = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? c.onSurface : c.outlineVariant,
            width: selected ? 3 : 1,
          ),
        ),
        child: selected
            ? Icon(
                Icons.check,
                size: 20,
                color: color.computeLuminance() > 0.6 ? Colors.black54 : Colors.white,
              )
            : null,
      ),
    );
  }
}

class _PairingSheet extends StatefulWidget {
  const _PairingSheet({required this.device, required this.state});

  final LampDevice device;
  final AppState state;

  @override
  State<_PairingSheet> createState() => _PairingSheetState();
}

class _PairingSheetState extends State<_PairingSheet> {
  bool _busy = false;
  bool _sent = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final ColorScheme c = Theme.of(context).colorScheme;
    final TextTheme t = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 4, 24, 24 + MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Center(
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(color: c.primaryContainer, shape: BoxShape.circle),
              child: Icon(Icons.link, size: 34, color: c.onPrimaryContainer),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '配对 ${widget.device.name}',
            textAlign: TextAlign.center,
            style: t.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            '1. 给灯具断电，再重新上电\n'
            '2. 上电后 5 秒内点击下面的按钮\n'
            '3. 灯闪烁或蜂鸣即表示成功',
            textAlign: TextAlign.center,
            style: t.bodyMedium?.copyWith(color: c.onSurfaceVariant, height: 1.6),
          ),
          const SizedBox(height: 20),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: c.error)),
            ),
          if (!_sent)
            FilledButton.icon(
              onPressed: _busy ? null : _pair,
              icon: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
              label: Text(_busy ? '正在发送…' : '我已上电，开始配对'),
            )
          else ...<Widget>[
            Text(
              '指令已发送。灯有反应吗？',
              textAlign: TextAlign.center,
              style: t.titleSmall?.copyWith(color: c.primary),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('有反应，完成配对'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => setState(() {
                _sent = false;
                _error = null;
              }),
              child: const Text('没有反应，重试'),
            ),
            const SizedBox(height: 4),
            Text(
              '仍无反应？请确认灯具支持该协议、手机蓝牙已开启，'
              '并尽量靠近灯具；被其他手机占用时先用原 App 解绑。',
              textAlign: TextAlign.center,
              style: t.bodySmall?.copyWith(color: c.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _pair() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final bool ok = await widget.state.pair(widget.device);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _sent = ok;
      _error = ok ? null : (widget.state.lastError ?? '发送失败');
    });
  }
}

class _ColorDialog extends StatefulWidget {
  const _ColorDialog({required this.initial});

  final HSVColor initial;

  @override
  State<_ColorDialog> createState() => _ColorDialogState();
}

class _ColorDialogState extends State<_ColorDialog> {
  late HSVColor _hsv = widget.initial;

  @override
  Widget build(BuildContext context) {
    final Color color = _hsv.toColor();
    return AlertDialog(
      title: const Text('自定义颜色'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            height: 56,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)),
          ),
          const SizedBox(height: 12),
          _label('色相'),
          Slider(
            value: _hsv.hue,
            min: 0,
            max: 360,
            onChanged: (double v) => setState(() => _hsv = _hsv.withHue(v)),
          ),
          _label('饱和度'),
          Slider(
            value: _hsv.saturation,
            onChanged: (double v) => setState(() => _hsv = _hsv.withSaturation(v)),
          ),
          _label('明度'),
          Slider(
            value: _hsv.value,
            min: 0.1,
            onChanged: (double v) => setState(() => _hsv = _hsv.withValue(v)),
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
        FilledButton(onPressed: () => Navigator.pop(context, color), child: const Text('应用')),
      ],
    );
  }

  Widget _label(String text) => Align(
        alignment: Alignment.centerLeft,
        child: Text(text, style: Theme.of(context).textTheme.bodySmall),
      );
}
