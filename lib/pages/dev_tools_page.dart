import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../main.dart' show AppScope;
import '../protocol/v3_frame.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';

/// 开发者诊断：手动构造任意 v3 帧。
class DevToolsPage extends StatefulWidget {
  const DevToolsPage({super.key, this.phoneId = 0});

  final int phoneId;

  @override
  State<DevToolsPage> createState() => _DevToolsPageState();
}

class _DevToolsPageState extends State<DevToolsPage> {
  late final TextEditingController _type = TextEditingController(text: '256');
  late final TextEditingController _var1 =
      TextEditingController(text: '${widget.phoneId}');
  final TextEditingController _var2 = TextEditingController(text: '0');
  final TextEditingController _cmd = TextEditingController(text: '0x10');
  final TextEditingController _p21 = TextEditingController(text: '0');
  final TextEditingController _p22 = TextEditingController(text: '0');
  final TextEditingController _p23 = TextEditingController(text: '0');

  @override
  void dispose() {
    for (final TextEditingController c in <TextEditingController>[
      _type,
      _var1,
      _var2,
      _cmd,
      _p21,
      _p22,
      _p23,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  int _parse(TextEditingController c) {
    final String s = c.text.trim();
    if (s.isEmpty) return 0;
    if (s.toLowerCase().startsWith('0x')) return int.tryParse(s.substring(2), radix: 16) ?? 0;
    return int.tryParse(s) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final AppState state = AppScope.of(context);
    final ColorScheme c = Theme.of(context).colorScheme;
    final TextTheme t = Theme.of(context).textTheme;
    final Uint8List preview = V3Frame.build(
      type: _parse(_type),
      var1: _parse(_var1),
      var2: _parse(_var2),
      command: _parse(_cmd),
      p21: _parse(_p21),
      p22: _parse(_p22),
      p23: _parse(_p23),
      tx: V3Frame.txCount,
    );
    return Scaffold(
      appBar: AppBar(title: const Text('开发者工具')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: <Widget>[
          SectionCard(
            title: '帧字段',
            child: Column(
              children: <Widget>[
                _field(_type, 'type'),
                const SizedBox(height: 12),
                _field(_var1, 'var1'),
                const SizedBox(height: 12),
                _field(_var2, 'var2 / 地址'),
                const SizedBox(height: 12),
                _field(_cmd, 'command（支持 0x）'),
                const SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    Expanded(child: _field(_p21, 'p21')),
                    const SizedBox(width: 10),
                    Expanded(child: _field(_p22, 'p22')),
                    const SizedBox(width: 10),
                    Expanded(child: _field(_p23, 'p23')),
                  ],
                ),
              ],
            ),
          ),
          SectionCard(
            title: '预览',
            trailing: Text('tx=${preview[10]}', style: t.bodySmall),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SelectableText(
                  _hex(preview),
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12, height: 1.6),
                ),
                const SizedBox(height: 10),
                Text(
                  V3Frame.serviceUuid16(preview)
                      .map((int e) => e.toRadixString(16).padLeft(4, '0'))
                      .join(' '),
                  style: t.bodySmall?.copyWith(color: c.onSurfaceVariant),
                ),
              ],
            ),
          ),
          FilledButton.icon(
            onPressed: () async {
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
            icon: const Icon(Icons.send),
            label: Text(state.sending ? '发送中…' : '发送'),
          ),
          const SizedBox(height: 10),
          Text(
            state.lastAction ?? '',
            textAlign: TextAlign.center,
            style: t.bodySmall?.copyWith(color: c.onSurfaceVariant),
          ),
          if (state.lastError != null)
            Text(state.lastError!, textAlign: TextAlign.center, style: TextStyle(color: c.error)),
        ],
      ),
    );
  }

  Widget _field(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      inputFormatters: <TextInputFormatter>[
        FilteringTextInputFormatter.allow(RegExp(r'[0-9a-fA-Fx]')),
      ],
    );
  }

  static String _hex(List<int> bytes) => bytes
      .map((int b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
      .join(' ');
}
