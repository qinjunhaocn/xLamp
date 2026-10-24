import 'package:flutter/material.dart';
import 'package:flutter_miuix/miuix.dart';

import '../main.dart' show AppScope;
import '../models/lamp_device.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';
import 'add_edit_page.dart';
import 'raw_page.dart';

class DevicePage extends StatefulWidget {
  const DevicePage({super.key, required this.device});

  final LampDevice device;

  @override
  State<DevicePage> createState() => _DevicePageState();
}

class _DevicePageState extends State<DevicePage> {
  late double _brightness = widget.device.brightness.toDouble();
  late double _temp = widget.device.colorTemp.toDouble();

  static const List<Color> _swatches = <Color>[
    Color(0xFFFFD9A0),
    Color(0xFFFFB4A2),
    Color(0xFFFF8A80),
    Color(0xFFE57373),
    Color(0xFFBA68C8),
    Color(0xFF7986CB),
    Color(0xFF4FC3F7),
    Color(0xFF4DB6AC),
    Color(0xFF81C784),
    Color(0xFFFFF59D),
  ];

  @override
  Widget build(BuildContext context) {
    final AppState state = AppScope.of(context);
    final LampDevice d = widget.device;
    final MiuixColors c = MiuixTheme.of(context).colors;
    final MiuixTextStyles t = MiuixTheme.of(context).textStyles;
    return MiuixScaffold(
      topBar: MiuixSmallTopAppBar(
        title: d.name,
        subtitle: d.subtitle,
        navigationIcon: MiuixIconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          child: MiuixIcon(icon: Icons.arrow_back, tint: c.onBackground),
        ),
        actions: <Widget>[
          MiuixIconButton(
            onPressed: () => _edit(context),
            child: MiuixIcon(icon: Icons.edit_outlined, tint: c.onBackground),
          ),
        ],
      ),
      content: (EdgeInsets padding) => ListView(
        padding: padding.copyWith(top: 6, bottom: 40),
        children: <Widget>[
          _PowerCard(device: d, state: state),
          SectionCard(
            title: '亮度与色温',
            child: Column(
              children: <Widget>[
                SliderRow(
                  title: '亮度',
                  value: _brightness,
                  min: 1,
                  max: 100,
                  suffix: '%',
                  onChanged: (double v) => setState(() => _brightness = v),
                  onChangeEnd: (double v) => state.setBrightness(d, v.round()),
                ),
                const SizedBox(height: 8),
                SliderRow(
                  title: '色温',
                  value: _temp,
                  min: 0,
                  max: 100,
                  onChanged: (double v) => setState(() => _temp = v),
                  onChangeEnd: (double v) => state.setColorTemp(d, v.round()),
                ),
              ],
            ),
          ),
          SectionCard(
            title: '颜色',
            trailing: MiuixText(
              '#${d.red.toRadixString(16).padLeft(2, '0')}'
              '${d.green.toRadixString(16).padLeft(2, '0')}'
              '${d.blue.toRadixString(16).padLeft(2, '0')}',
              style: t.footnote1,
              color: c.onSurfaceVariantSummary,
            ),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _swatches.map((Color color) {
                final int cr = (color.r * 255).round();
                final int cg = (color.g * 255).round();
                final int cb = (color.b * 255).round();
                final bool selected =
                    cr == d.red && cg == d.green && cb == d.blue;
                return GestureDetector(
                  onTap: () => state.setRgb(d, cr, cg, cb),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: selected ? c.onSurface : Colors.transparent,
                        width: 2.4,
                      ),
                    ),
                    child: selected
                        ? const MiuixIcon(icon: Icons.check, size: 20, tint: Colors.black54)
                        : null,
                  ),
                );
              }).toList(),
            ),
          ),
          SectionCard(
            title: '场景',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: List<Widget>.generate(4, (int i) {
                    final bool selected = d.scene == i;
                    return _SceneChip(
                      label: '场景 ${i + 1}',
                      selected: selected,
                      onTap: () => state.sceneSwitch(d, i),
                    );
                  }),
                ),
                const SizedBox(height: 14),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: MiuixButton(
                        onPressed: () => state.sceneOn(d),
                        child: const MiuixText('场景开'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: MiuixButton(
                        onPressed: () => state.nightLight(d),
                        child: const MiuixText('夜灯'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SectionCard(
            title: '配对',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                MiuixText(
                  '给灯具断电再上电，在 5 秒内点击“配对”。灯闪烁或蜂鸣即表示配对成功。',
                  style: t.footnote1,
                  color: c.onSurfaceVariantSummary,
                ),
                const SizedBox(height: 14),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: MiuixButton(
                        onPressed: () => state.pair(d),
                        colors: MiuixButtonDefaults.buttonColorsPrimary(context),
                        child: const MiuixText('配对'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: MiuixButton(
                        onPressed: () => state.unpair(d),
                        child: const MiuixText('解绑'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: <Widget>[
                    MiuixIcon(
                      icon: d.paired ? Icons.check_circle_outline : Icons.info_outline,
                      size: 15,
                      tint: d.paired ? c.primary : c.onSurfaceVariantSummary,
                    ),
                    const SizedBox(width: 6),
                    MiuixText(
                      d.paired ? '当前状态：已配对' : '当前状态：未配对',
                      style: t.footnote1,
                      color: d.paired ? c.primary : c.onSurfaceVariantSummary,
                    ),
                  ],
                ),
              ],
            ),
          ),
          SectionCard(
            title: '设备信息',
            trailing: MiuixTextButton('编辑', onPressed: () => _edit(context)),
            child: Column(
              children: <Widget>[
                _InfoRow(label: '类型', value: '${d.typeLabel}  (0x${d.type.toRadixString(16)})'),
                _InfoRow(label: '地址', value: '${d.address}'),
                _InfoRow(label: '通道', value: '${d.channel}'),
                _InfoRow(
                  label: 'var1',
                  value: '0x${state.var1For(d).toRadixString(16).toUpperCase()}',
                ),
                _InfoRow(label: '配对', value: d.paired ? '是' : '否', last: true),
              ],
            ),
          ),
          MiuixButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => RawPage(device: d)),
              );
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const MiuixIcon(icon: Icons.terminal, size: 18),
                const SizedBox(width: 8),
                const MiuixText('RAW 调试'),
              ],
            ),
          ),
          const SizedBox(height: 10),
          MiuixButton(
            onPressed: () => _delete(context, state, d),
            child: MiuixText('删除设备', color: c.error),
          ),
          if (state.lastError != null) ...<Widget>[
            const SizedBox(height: 14),
            MiuixText(
              state.lastError!,
              style: t.footnote1,
              color: c.error,
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _edit(BuildContext context) async {
    final AppState state = AppScope.of(context);
    final LampDevice? updated = await Navigator.of(context).push<LampDevice>(
      MaterialPageRoute<LampDevice>(
        builder: (_) => AddEditPage(device: widget.device),
      ),
    );
    if (updated != null) {
      await state.updateDevice(updated);
      if (mounted) setState(() {});
    }
  }

  Future<void> _delete(BuildContext context, AppState state, LampDevice d) async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('删除设备'),
        content: Text('确定从列表中移除「${d.name}」吗？'),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('取消')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('删除')),
        ],
      ),
    );
    if (ok == true) {
      await state.removeDevice(d.id);
      if (context.mounted) Navigator.of(context).maybePop();
    }
  }
}

class _PowerCard extends StatelessWidget {
  const _PowerCard({required this.device, required this.state});

  final LampDevice device;
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final MiuixColors c = MiuixTheme.of(context).colors;
    final MiuixTextStyles t = MiuixTheme.of(context).textStyles;
    final bool on = device.power;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: MiuixCard(
        insideMargin: EdgeInsets.zero,
        colors: MiuixCardColors(
          color: on ? c.primaryContainer : c.surfaceContainer,
          contentColor: on ? c.onPrimaryContainer : c.onSurfaceContainer,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 26),
          child: Column(
            children: <Widget>[
              GestureDetector(
                onTap: device.paired ? () => state.setPower(device, !on) : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutCubic,
                  width: 118,
                  height: 118,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: on
                          ? <Color>[c.primary, c.primaryVariant]
                          : <Color>[c.surfaceContainerHigh, c.surfaceContainerHighest],
                    ),
                    boxShadow: on
                        ? <BoxShadow>[
                            BoxShadow(
                              color: c.primary.withValues(alpha: 0.32),
                              blurRadius: 28,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                  child: MiuixIcon(
                    icon: Icons.power_settings_new,
                    size: 46,
                    tint: on ? c.onPrimary : c.onSurfaceVariantSummary,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              MiuixText(on ? '已开启' : '已关闭', style: t.title4),
              const SizedBox(height: 4),
              MiuixText(
                device.paired ? '轻触圆环切换开关' : '尚未配对，请先完成配对',
                style: t.footnote1,
                color: c.onSurfaceVariantSummary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SceneChip extends StatelessWidget {
  const _SceneChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final MiuixColors c = MiuixTheme.of(context).colors;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? c.primary : c.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(14),
        ),
        child: MiuixText(
          label,
          fontSize: 13,
          color: selected ? c.onPrimary : c.onSurface,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value, this.last = false});

  final String label;
  final String value;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final MiuixColors c = MiuixTheme.of(context).colors;
    final MiuixTextStyles t = MiuixTheme.of(context).textStyles;
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 9),
          child: Row(
            children: <Widget>[
              Expanded(child: MiuixText(label, style: t.body1, color: c.onSurfaceVariantSummary)),
              MiuixText(value, style: t.body2),
            ],
          ),
        ),
        if (!last) Divider(height: 1, color: c.dividerLine),
      ],
    );
  }
}
