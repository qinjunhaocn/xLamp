import 'package:flutter/material.dart';
import 'package:flutter_miuix/miuix.dart';

import '../main.dart' show AppScope;
import '../state/app_state.dart';
import 'add_edit_page.dart';
import 'home_page.dart';
import 'settings_page.dart';

class RootPage extends StatefulWidget {
  const RootPage({super.key});

  @override
  State<RootPage> createState() => _RootPageState();
}

class _RootPageState extends State<RootPage> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final AppState state = AppScope.of(context);
    final MiuixColors c = MiuixTheme.of(context).colors;
    return MiuixScaffold(
      topBar: MiuixSmallTopAppBar(
        title: _index == 0 ? 'xLamp' : '设置',
        subtitle: _index == 0
            ? (state.supported ? (state.enabled ? '蓝牙广播就绪' : '蓝牙未开启') : '设备不支持 BLE 广播')
            : '广播参数与协议',
        actions: <Widget>[
          if (_index == 0)
            MiuixIconButton(
              onPressed: () => _openAdd(context),
              child: MiuixIcon(icon: Icons.add, tint: c.onBackground),
            ),
        ],
      ),
      bottomBar: MiuixNavigationBar(
        children: <Widget>[
          MiuixNavigationBarItem(
            selected: _index == 0,
            onPressed: () => setState(() => _index = 0),
            icon: const MiuixIcon(icon: Icons.lightbulb_outline),
            label: '设备',
          ),
          MiuixNavigationBarItem(
            selected: _index == 1,
            onPressed: () => setState(() => _index = 1),
            icon: const MiuixIcon(icon: Icons.tune),
            label: '设置',
          ),
        ],
      ),
      floatingActionButton: _index == 0
          ? MiuixFloatingActionButton(
              onPressed: () => _openAdd(context),
              child: const MiuixIcon(icon: Icons.add),
            )
          : null,
      content: (EdgeInsets padding) => IndexedStack(
        index: _index,
        children: <Widget>[
          HomeTab(padding: padding),
          SettingsTab(padding: padding),
        ],
      ),
    );
  }

  void _openAdd(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const AddEditPage()),
    );
  }
}
