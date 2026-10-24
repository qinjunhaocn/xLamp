import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_miuix/miuix.dart';

import '../main.dart' show AppScope;
import '../models/lamp_device.dart';
import '../protocol/v3_frame.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';

/// 手动构造并发送一帧 v3 命令，便于在真实设备上核对参数含义。
class RawPage extends StatefulWidget {
  const RawPage({super.key, this.device, this.phoneId = 0});

  final LampDevice? device;
  final int phoneId;

  @override
  State<RawPage> createState() => _RawPageState();
}

class _RawPageState extends State<RawPage> {
  late final TextEditingController _type =
      TextEditingController(text: '${widget.device?.type ?? 256}');
  late final TextEditingController _var1;
  late final TextEditingController _var2 =
      TextEditingController(text: '${widget.device?.address ?? 1}');
  final TextEditingController _cmd = TextEditingController(text: '0x10');
  final TextEditingController _p21 = TextEditingController(text: '0');
  final TextEditingController _p22 = TextEditingController(text: '0');
  final TextEditingController _p23 = TextEditingController(text: '0');

  @override
  void initState() {
    super.initState();
    _var1 = TextEditingController(
      text: '${widget.phoneId + (widget.device?.channel ?? 0)}',
    );
  }

  @override
  void dispose() {
    _type.dispose();
    _var1.dispose();
    _var2.dispose();
    _cmd.dispose();
    _p21.dispose();
    _p22.dispose();
    _p23.dispose();
    super.dispose();
  }

  int _parse(TextEditingController c) {
    final String s = c.text.trim();
    if (s.isEmpty) return 0;
    if (s.toLowerCase().startsWith('0x')) {
      return int.tryParse(s.substring(2), radix: 16) ?? 0;
    }
    return int.tryParse(s) ?? 0;
  }

  Uint8List _preview() {
    return V3Frame.build(
      type: _parse(_type),
      var1: _parse(_var1),
      var2: _parse(_var2),
      command: _parse(_cmd),
      p21: _parse(_p21),
      p22: _parse(_p22),
      p23: _parse(_p23),
      tx: V3Frame.txCount,
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppState state = AppScope.of(context);
    final MiuixColors c = MiuixTheme.of(context).colors;
    final MiuixTextStyles t = MiuixTheme.of(context).textStyles;
    final Uint8List preview = _preview();
    return MiuixScaffold(
      topBar: MiuixSmallTopAppBar(
        title: 'RAW 调试',
        subtitle: '手动构造 v3 帧',
        navigationIcon: MiuixIconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          child: MiuixIcon(icon: Icons.arrow_back, tint: c.onBackground),
        ),
      ),
      content: (EdgeInsets padding) => Material(
        type: MaterialType.transparency,
        child: ListView(
          padding: padding.copyWith(top: 6, bottom: 40),
          children: <Widget>[
            SectionCard(
              title: '帧字段',
              child: Column(
                children: <Widget>[
                  _Field(controller: _type, label: 'type（十进制）'),
                  const SizedBox(height: 12),
                  _Field(controller: _var1, label: 'var1'),
                  const SizedBox(height: 12),
                  _Field(controller: _var2, label: 'var2 / 地址'),
                  const SizedBox(height: 12),
                  _Field(controller: _cmd, label: 'command（支持 0x 前缀）'),
                  const SizedBox(height: 12),
                  Row(
                    children: <Widget>[
                      Expanded(child: _Field(controller: _p21, label: 'p21')),
                      const SizedBox(width: 10),
                      Expanded(child: _Field(controller: _p22, label: 'p22')),
                      const SizedBox(width: 10),
                      Expanded(child: _Field(controller: _p23, label: 'p23')),
                    ],
                  ),
                ],
              ),
            ),
            SectionCard(
              title: '预览',
              trailing: MiuixText(
                'tx=${preview[10]}',
                style: t.footnote1,
                color: c.onSurfaceVariantSummary,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  SelectableText(
                    _hex(preview),
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 12, height: 1.6),
                  ),
                  const SizedBox(height: 10),
                  MiuixText(
                    '13 个 UUID：${V3Frame.serviceUuid16(preview).map((int e) => e.toRadixString(16).padLeft(4, '0')).join(' ')}',
                    style: t.footnote2,
                    color: c.onSurfaceVariantSummary,
                  ),
                ],
              ),
            ),
            MiuixButton(
              onPressed: () async {
                setState(() {});
                await state.sendRaw(
                  type: _parse(_type),
                  var1: _parse(_var1),
                  var2: _parse(_var2),
                  command: _parse(_cmd),
                  p21: _parse(_p21),
                  p22: _parse(_p22),
                  p23: _parse(_p23),
                );
                if (mounted) setState(() {});
              },
              colors: MiuixButtonDefaults.buttonColorsPrimary(context),
              child: Center(
                child: MiuixText(
                  state.sending ? '发送中…' : '发送',
                  color: c.onPrimary,
                ),
              ),
            ),
            if (state.lastAction != null) ...<Widget>[
              const SizedBox(height: 12),
              MiuixText(
                '最近：${state.lastAction}',
                style: t.footnote1,
                color: c.onSurfaceVariantSummary,
                textAlign: TextAlign.center,
              ),
            ],
            if (state.lastError != null) ...<Widget>[
              const SizedBox(height: 10),
              MiuixText(state.lastError!, style: t.footnote1, color: c.error, textAlign: TextAlign.center),
            ],
          ],
        ),
      ),
    );
  }

  static String _hex(List<int> bytes) => bytes
      .map((int b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
      .join(' ');
}

class _Field extends StatelessWidget {
  const _Field({required this.controller, required this.label});

  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    return MiuixTextField(
      controller: controller,
      label: label,
      singleLine: true,
      keyboardType: TextInputType.text,
    );
  }
}
