import 'package:flutter/material.dart';
import 'package:flutter_miuix/miuix.dart';

import '../main.dart' show AppScope;
import '../models/lamp_device.dart';
import '../protocol/lamp_commands.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';

class AddEditPage extends StatefulWidget {
  const AddEditPage({super.key, this.device});

  final LampDevice? device;

  @override
  State<AddEditPage> createState() => _AddEditPageState();
}

class _AddEditPageState extends State<AddEditPage> {
  late final TextEditingController _name =
      TextEditingController(text: widget.device?.name ?? '我的灯');
  late int _type = widget.device?.type ?? LampType.lamp;
  late double _address = (widget.device?.address ?? 1).toDouble();
  late double _channel = (widget.device?.channel ?? 0).toDouble();

  bool get _isEdit => widget.device != null;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppState state = AppScope.of(context);
    final MiuixColors c = MiuixTheme.of(context).colors;
    final MiuixTextStyles t = MiuixTheme.of(context).textStyles;
    return MiuixScaffold(
      topBar: MiuixSmallTopAppBar(
        title: _isEdit ? '编辑设备' : '添加设备',
        navigationIcon: MiuixIconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          child: MiuixIcon(icon: Icons.close, tint: c.onBackground),
        ),
      ),
      content: (EdgeInsets padding) => Material(
        type: MaterialType.transparency,
        child: ListView(
          padding: padding.copyWith(top: 6, bottom: 40),
          children: <Widget>[
            SectionCard(
              title: '名称',
              child: MiuixTextField(
                controller: _name,
                label: '给设备起个名字',
                singleLine: true,
              ),
            ),
            SectionCard(
              title: '设备类型',
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: LampType.labels.entries.map((MapEntry<int, String> e) {
                  final bool selected = _type == e.key;
                  return GestureDetector(
                    onTap: () => setState(() => _type = e.key),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                      decoration: BoxDecoration(
                        color: selected ? c.primary : c.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: MiuixText(
                        e.value,
                        fontSize: 13,
                        color: selected ? c.onPrimary : c.onSurface,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            SectionCard(
              title: '地址与通道',
              child: Column(
                children: <Widget>[
                  SliderRow(
                    title: '设备地址',
                    value: _address,
                    min: 0,
                    max: 255,
                    onChanged: (double v) => setState(() => _address = v),
                  ),
                  const SizedBox(height: 6),
                  SliderRow(
                    title: '通道',
                    value: _channel,
                    min: 0,
                    max: 15,
                    onChanged: (double v) => setState(() => _channel = v),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: <Widget>[
                      MiuixIcon(icon: Icons.tag, size: 15, tint: c.onSurfaceVariantSummary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: MiuixText(
                          'var1 = 本机 ID + 通道 = 0x'
                          '${(state.phoneId + _channel.round()).toRadixString(16).toUpperCase()}',
                          style: t.footnote1,
                          color: c.onSurfaceVariantSummary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: MiuixButton(
                onPressed: () => _save(state),
                colors: MiuixButtonDefaults.buttonColorsPrimary(context),
                child: Center(
                  child: MiuixText(
                    _isEdit ? '保存修改' : '添加设备',
                    color: c.onPrimary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            MiuixText(
              '提示：添加后请在灯具上电 5 秒内点击“配对”。\n'
              '如果灯具之前被其他 App/手机占用，请先解绑。',
              style: t.footnote1,
              color: c.onSurfaceVariantSummary,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _save(AppState state) {
    final LampDevice d = widget.device ?? LampDevice(
      id: LampDevice.newId(),
      name: _name.text.trim().isEmpty ? '我的灯' : _name.text.trim(),
      type: _type,
      address: _address.round(),
    );
    d.name = _name.text.trim().isEmpty ? '我的灯' : _name.text.trim();
    d.type = _type;
    d.address = _address.round();
    d.channel = _channel.round();
    Navigator.of(context).pop(d);
  }
}
