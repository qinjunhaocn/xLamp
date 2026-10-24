import 'package:flutter/material.dart';

import '../main.dart' show AppScope;
import '../state/app_state.dart';
import '../widgets/common.dart';
import 'dev_tools_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final AppState state = AppScope.of(context);
    final ColorScheme c = Theme.of(context).colorScheme;
    final TextTheme t = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: <Widget>[
          SectionCard(
            title: '外观',
            child: Column(
              children: <Widget>[
                SegmentedButton<ThemeMode>(
                  showSelectedIcon: false,
                  segments: const <ButtonSegment<ThemeMode>>[
                    ButtonSegment(value: ThemeMode.system, label: Text('跟随系统')),
                    ButtonSegment(value: ThemeMode.light, label: Text('浅色')),
                    ButtonSegment(value: ThemeMode.dark, label: Text('深色')),
                  ],
                  selected: <ThemeMode>{state.themeMode},
                  onSelectionChanged: (Set<ThemeMode> value) => state.setThemeMode(value.first),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('莫奈取色'),
                  subtitle: const Text('使用系统壁纸生成的配色（Android 12+）'),
                  value: state.monetEnabled,
                  onChanged: state.setMonet,
                ),
              ],
            ),
          ),
          SectionCard(
            title: '蓝牙',
            trailing: StatusPill(
              label: state.enabled ? '已开启' : '未开启',
              color: state.enabled ? c.primary : c.error,
              icon: state.enabled ? Icons.bluetooth : Icons.bluetooth_disabled,
            ),
            child: Column(
              children: <Widget>[
                InfoRow(
                  label: 'BLE 外设广播',
                  value: state.supported ? '支持' : '不支持',
                ),
                InfoRow(
                  label: '权限',
                  value: state.permissionGranted ? '已授予' : '未授予',
                  last: true,
                ),
                const SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    if (state.needsPermission)
                      Expanded(
                        child: FilledButton.tonal(
                          onPressed: () => state.requestBleAccess(),
                          child: const Text('授予权限'),
                        ),
                      )
                    else
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: state.refreshBluetooth,
                          icon: const Icon(Icons.refresh),
                          label: const Text('重新检测'),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          SectionCard(
            title: '广播时序',
            subtitle: '默认 8 个 500ms 窗口，与原 App 一致',
            child: Column(
              children: <Widget>[
                _SliderTile(
                  label: '单次广播时长',
                  value: state.duration.toDouble(),
                  min: 500,
                  max: 5000,
                  step: 500,
                  suffix: ' ms',
                  onChanged: (double v) => state.setDuration(((v / 500).round() * 500)),
                ),
                _SliderTile(
                  label: '重复窗口',
                  value: state.repeats.toDouble(),
                  min: 1,
                  max: 16,
                  step: 1,
                  onChanged: (double v) => state.setRepeats(v.round()),
                ),
                _SliderTile(
                  label: '窗口间隔',
                  value: state.interval.toDouble(),
                  min: 100,
                  max: 1000,
                  step: 50,
                  suffix: ' ms',
                  onChanged: (double v) => state.setInterval((v / 50).round() * 50),
                ),
              ],
            ),
          ),
          SectionCard(
            title: '高级',
            child: Column(
              children: <Widget>[
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.fingerprint),
                  title: const Text('本机 ID'),
                  subtitle: Text(
                    '0x${state.phoneId.toRadixString(16).toUpperCase()}（${state.phoneId}）',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _editPhoneId(context, state),
                ),
                const Divider(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.terminal),
                  title: const Text('开发者工具'),
                  subtitle: const Text('手动构造 v3 帧，用于排查问题'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => DevToolsPage(phoneId: state.phoneId)),
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
                Text('xLamp 1.0.0', style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(
                  '基于 LampSmartPro 1.4.0 的静态逆向结果独立实现。'
                  '仅使用 BLE 广播，不建立 GATT 连接，也不采集任何数据。',
                  style: t.bodySmall?.copyWith(color: c.onSurfaceVariant, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editPhoneId(BuildContext context, AppState state) async {
    final TextEditingController controller =
        TextEditingController(text: state.phoneId.toString());
    final int? value = await showDialog<int>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('本机 ID'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text('对应原 App 的 DEVICE_ADDRESS。修改后旧设备需要重新配对。'),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '十进制数值',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, int.tryParse(controller.text.trim())),
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

class _SliderTile extends StatelessWidget {
  const _SliderTile({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.step,
    required this.onChanged,
    this.suffix = '',
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final double step;
  final ValueChanged<double> onChanged;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    final ColorScheme c = Theme.of(context).colorScheme;
    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(child: Text(label)),
            Text(
              '${value.round()}$suffix',
              style: TextStyle(color: c.onSurfaceVariant),
            ),
          ],
        ),
        Slider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          divisions: ((max - min) / step).round(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
