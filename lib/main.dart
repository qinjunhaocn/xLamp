import 'package:flutter/material.dart';
import 'package:flutter_miuix/miuix.dart';

import 'pages/root_page.dart';
import 'state/app_state.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const XLampApp());
}

class XLampApp extends StatefulWidget {
  const XLampApp({super.key});

  @override
  State<XLampApp> createState() => _XLampAppState();
}

class _XLampAppState extends State<XLampApp> {
  late final AppState _state = AppState()..init();

  @override
  void dispose() {
    _state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: _state,
      child: MiuixSystemTheme(
        child: Builder(
          builder: (BuildContext context) {
            final MiuixThemeData theme = MiuixTheme.of(context);
            return MaterialApp(
              title: 'xLamp',
              debugShowCheckedModeBanner: false,
              theme: ThemeData(
                useMaterial3: true,
                brightness: theme.brightness,
                colorScheme: ColorScheme.fromSeed(
                  seedColor: theme.colors.primary,
                  brightness: theme.brightness,
                ),
                scaffoldBackgroundColor: theme.colors.background,
              ),
              home: const RootPage(),
            );
          },
        ),
      ),
    );
  }
}

/// 向整棵树提供 [AppState]。
class AppScope extends InheritedNotifier<AppState> {
  const AppScope({
    super.key,
    required AppState state,
    required super.child,
  }) : super(notifier: state);

  static AppState of(BuildContext context) {
    final AppScope? scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope not found');
    return scope!.notifier!;
  }
}
