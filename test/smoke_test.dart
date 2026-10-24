import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xlamp/main.dart' show AppScope;
import 'package:xlamp/models/lamp_device.dart';
import 'package:xlamp/pages/add_device_page.dart';
import 'package:xlamp/pages/device_page.dart';
import 'package:xlamp/pages/root_page.dart';
import 'package:xlamp/state/app_state.dart';

Widget wrap(AppState state, Widget child) {
  return AppScope(
    state: state,
    child: MaterialApp(home: child),
  );
}

void main() {
  testWidgets('home renders empty state', (WidgetTester tester) async {
    final AppState state = AppState();
    await tester.pumpWidget(wrap(state, const RootPage()));
    await tester.pump();
    expect(find.text('xLamp'), findsWidgets);
    expect(find.text('还没有添加设备'), findsOneWidget);
  });

  testWidgets('device page renders controls', (WidgetTester tester) async {
    final AppState state = AppState();
    final LampDevice device = LampDevice(
      id: 'test',
      name: '客厅主灯',
      type: 256,
      address: 1,
      paired: true,
      power: true,
    );
    state.addDevice(device);
    await tester.pumpWidget(wrap(state, DevicePage(device: device)));
    await tester.pump();
    expect(find.text('客厅主灯'), findsWidgets);
    expect(find.text('亮度'), findsOneWidget);
    expect(find.text('色温'), findsOneWidget);
    expect(find.byType(Slider), findsWidgets);
  });

  testWidgets('add device page renders', (WidgetTester tester) async {
    final AppState state = AppState();
    await tester.pumpWidget(wrap(state, const AddDevicePage()));
    await tester.pump();
    expect(find.text('设备名称'), findsOneWidget);
    expect(find.text('高级参数'), findsOneWidget);
  });
}
