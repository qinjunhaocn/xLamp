import 'package:flutter/material.dart';
import 'package:flutter_miuix/miuix.dart';

import '../main.dart' show AppScope;
import '../state/app_state.dart';
import '../widgets/common.dart';
import 'raw_page.dart';

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key, required this.padding});

  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final AppState state = AppScope.of(context);
    final MiuixColors c = MiuixTheme.of(context).colors;
    final MiuixTextStyles t = MiuixTheme.of(context).textStyles;
    return ListView(
      padding: padding.copyWith(top: 6, bottom: 40),
      children: <Widget>[
        SectionCard(
          title: '蓝牙广播',
          trailing: StatusChip(
            label: state.enabled ? '已开启' : '未开启',
            color: state.enabled ? c.primary : c.error,
            icon: state.enabled ? Icons.bluetooth : Icons.bluetooth_disabled,
          ),
          child: Column(
            children: <Widget>[
              _Row(
                label: 'BLE 外设广播',
                value: state.supported ? '支持' : '不支持',
              ),
              _Row(
                label: '当前状态',
                value: state.enabled ? '可用' : '请先在系统里打开蓝牙',
                last: true,
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: MiuixButton(
                  onPressed: state.refreshBluetooth,
                  child: const Center(child: MiuixText('重新检测')),
                ),
              ),
            ],
          ),
        ),
        SectionCard(
          title: '本机 ID',
          trailing: MiuixTextButton('修改', onPressed: () => _editPhoneId(context, state)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              MiuixText(
                '0x${state.phoneId.toRadixString(16).toUpperCase()}  (${state.phoneId})',
                style: t.title3,
              ),
              const SizedBox(height: 6),
              MiuixText(
                '对应原 App 的 DEVICE_ADDRESS。配对与后续控制必须使用同一个 ID，'
                '修改后旧设备需要重新配对。',
                style: t.footnote1,
                color: c.onSurfaceVariantSummary,
              ),
            ],
          ),
        ),
        SectionCard(
          title: '广播时序',
          child: Column(
            children: <Widget>[
              SliderRow(
                title: '单次广播时长',
                value: state.duration.toDouble(),
                min: 500,
                max: 5000,
                suffix: ' ms',
                onChanged: (double v) => state.setDuration((v / 500).round() * 500),
              ),
              SliderRow(
                title: '重复窗口',
                value: state.repeats.toDouble(),
                min: 1,
                max: 16,
                onChanged: (double v) => state.setRepeats(v.round()),
              ),
              SliderRow(
                title: '窗口间隔',
                value: state.interval.toDouble(),
                min: 100,
                max: 1000,
                suffix: ' ms',
                onChanged: (double v) => state.setInterval((v / 50).round() * 50),
              ),
              const SizedBox(height: 4),
              MiuixText(
                '默认 8 个 500 ms 窗口，与原 App 的 startAdv 一致。',
                style: t.footnote1,
                color: c.onSurfaceVariantSummary,
              ),
            ],
          ),
        ),
        SectionCard(
          title: '协议',
          child: Column(
            children: <Widget>[
              _Row(label: '编码器', value: 'v3 / 31 字节'),
              _Row(label: '承载方式', value: '13 个 16-bit Service UUID'),
              _Row(label: '结束标记', value: 'bbaa · 3412'),
              _Row(label: '校验', value: 'CRC-16/CCITT + AES-128'),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: MiuixButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => const RawPage()),
                    );
                  },
                  child: const Center(child: MiuixText('RAW 发送工具')),
                ),
              ),
            ],
          ),
        ),
        SectionCard(
          title: '关于',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              MiuixText('xLamp 1.0.0', style: t.title4),
              const SizedBox(height: 4),
              MiuixText(
                '基于对 LampSmartPro 1.4.0 的静态逆向结果独立实现：'
                '仅使用 BLE 广播，不建立 GATT 连接。',
                style: t.footnote1,
                color: c.onSurfaceVariantSummary,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _editPhoneId(BuildContext context, AppState state) async {
    final TextEditingController controller = TextEditingController(
      text: state.phoneId.toString(),
    );
    final int? value = await showDialog<int>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('本机 ID'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: '十进制，小于 2147483647'),
        ),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('取消')),
          TextButton(
            onPressed: () {
              final int? v = int.tryParse(controller.text.trim());
              Navigator.of(ctx).pop(v);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value != null && value >= 0) {
      await state.setPhoneId(value & 0x7fffffff);
    }
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value, this.last = false});

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
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: <Widget>[
              Expanded(
                child: MiuixText(label, style: t.body1, color: c.onSurfaceVariantSummary),
              ),
              MiuixText(value, style: t.body2),
            ],
          ),
        ),
        if (!last) Divider(height: 1, color: c.dividerLine),
      ],
    );
  }
}
