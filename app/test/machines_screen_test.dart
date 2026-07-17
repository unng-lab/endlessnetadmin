import 'dart:convert';
import 'dart:io';

import 'package:endlessnet_admin/features/machines/machines_screen.dart';
import 'package:endlessnet_admin/models.dart';
import 'package:endlessnet_admin/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late List<MachineModel> machines;

  setUpAll(() {
    final fixture =
        jsonDecode(
              File('test/fixtures/device_endpoints.json').readAsStringSync(),
            )
            as Map<String, dynamic>;
    machines = (fixture['machines'] as List)
        .cast<Map<String, dynamic>>()
        .map(MachineModel.fromJson)
        .toList(growable: false);
  });

  void useDesktopView(WidgetTester tester) {
    tester.view.physicalSize = const Size(1440, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Widget machinesApp({
    required List<MachineModel> displayedMachines,
    String selectedMachineId = '',
    bool machinesLoaded = true,
    bool isLoading = false,
    Future<void> Function()? onRefresh,
    Duration refreshInterval = const Duration(hours: 1),
  }) {
    return MaterialApp(
      theme: buildAdminTheme(Brightness.light),
      home: Scaffold(
        body: MachinesScreen(
          machines: displayedMachines,
          machinesLoaded: machinesLoaded,
          isLoading: isLoading,
          networks: const [],
          apiBaseUrl: 'https://api.example.test',
          canMutate: false,
          selectedMachineId: selectedMachineId,
          onMachineSelected: (_) {},
          onRefresh: onRefresh ?? () async {},
          onCreateJoinToken: () async => null,
          onCreateNetwork: (_) async {},
          onUpdateMachine: (_, _) async {},
          onDeleteMachine: (_) async {},
          refreshInterval: refreshInterval,
        ),
      ),
    );
  }

  testWidgets('shows compact endpoint summaries and a full accessible list', (
    tester,
  ) async {
    useDesktopView(tester);
    await tester.pumpWidget(
      machinesApp(
        displayedMachines: machines,
        selectedMachineId: 'machine-multiple',
      ),
    );

    expect(find.text('Эндпоинты'), findsOneWidget);
    expect(find.text('основной · +2'), findsOneWidget);
    expect(find.text('Опубликованные эндпоинты'), findsOneWidget);
    expect(find.text('Основной'), findsOneWidget);
    expect(find.text('Кандидат'), findsNWidgets(2));
    expect(find.text('192.0.2.10:41641'), findsOneWidget);
    expect(find.text('[2001:db8::10]:41641'), findsOneWidget);
    expect(find.text('Поколение публикации'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(
      find.textContaining('Кандидаты не означают путь, выбранный клиентом.'),
      findsOneWidget,
    );
    expect(
      _semanticsWithLabel(
        RegExp(r'Основной: 203\.0\.113\.10:41641.*2001:db8::10', dotAll: true),
      ),
      findsWidgets,
    );
  });

  testWidgets('marks expired endpoint values as diagnostic-only', (
    tester,
  ) async {
    useDesktopView(tester);
    await tester.pumpWidget(
      machinesApp(
        displayedMachines: machines,
        selectedMachineId: 'machine-expired',
      ),
    );

    expect(find.text('истекли · 2'), findsOneWidget);
    expect(find.text('истекло'), findsOneWidget);
    expect(
      find.textContaining('показаны только для диагностики'),
      findsOneWidget,
    );
    expect(find.text('198.51.100.12:41641'), findsWidgets);
    expect(find.text('[2001:db8:1::12]:41641'), findsOneWidget);
  });

  testWidgets('renders an explicit empty endpoint state', (tester) async {
    useDesktopView(tester);
    await tester.pumpWidget(
      machinesApp(
        displayedMachines: machines,
        selectedMachineId: 'machine-empty',
      ),
    );

    expect(find.text('Нет опубликованных эндпоинтов.'), findsOneWidget);
    expect(
      _semanticsWithLabel('Опубликованные эндпоинты отсутствуют'),
      findsOneWidget,
    );
  });

  testWidgets('refreshes the machines table periodically', (tester) async {
    var refreshCount = 0;
    await tester.pumpWidget(
      machinesApp(
        displayedMachines: const [],
        onRefresh: () async {
          refreshCount += 1;
        },
        refreshInterval: const Duration(seconds: 1),
      ),
    );

    await tester.pump(const Duration(milliseconds: 999));
    expect(refreshCount, 0);

    await tester.pump(const Duration(milliseconds: 1));
    expect(refreshCount, 1);

    await tester.pump(const Duration(seconds: 1));
    expect(refreshCount, 2);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('shows empty state only after an empty API response', (
    tester,
  ) async {
    await tester.pumpWidget(
      machinesApp(
        displayedMachines: const [],
        machinesLoaded: false,
        isLoading: true,
      ),
    );
    expect(find.text('Загрузка устройств…'), findsOneWidget);
    expect(find.text('Нет устройств'), findsNothing);

    await tester.pumpWidget(
      machinesApp(
        displayedMachines: const [],
        machinesLoaded: false,
        isLoading: false,
      ),
    );
    expect(find.text('Список устройств не загружен'), findsOneWidget);
    expect(find.text('Нет устройств'), findsNothing);

    await tester.pumpWidget(machinesApp(displayedMachines: const []));
    expect(find.text('Нет устройств'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}

Finder _semanticsWithLabel(Pattern expected) {
  return find.byWidgetPredicate((widget) {
    if (widget is! Semantics) {
      return false;
    }
    final label = widget.properties.label ?? '';
    return switch (expected) {
      RegExp() => expected.hasMatch(label),
      String() => label == expected,
      _ => false,
    };
  });
}
