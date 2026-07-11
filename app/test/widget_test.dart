import 'package:endlessnet_admin/admin_shell.dart';
import 'package:endlessnet_admin/features/users/users_screen.dart';
import 'package:endlessnet_admin/main.dart';
import 'package:endlessnet_admin/models.dart';
import 'package:endlessnet_admin/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpDesktop(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const EndlessNetAdminApp());
    await tester.pump();
  }

  test('builds help menu URLs', () {
    const root = 'https://endlessnet.unng.ru/';

    expect(adminHelpMenuUrl('docs', root), 'https://endlessnet.unng.ru/docs/');
    expect(
      adminHelpMenuUrl('guides', root),
      'https://endlessnet.unng.ru/#cases',
    );
    expect(
      adminHelpMenuUrl('download', root),
      'https://endlessnet.unng.ru/docs/#install',
    );
    expect(
      adminHelpMenuUrl('support', root),
      'mailto:support@endlessnet.ru?subject=EndlessNet+support',
    );
    expect(
      adminHelpMenuUrl('feedback', root),
      'mailto:support@endlessnet.ru?subject=EndlessNet+feedback',
    );
  });

  testWidgets('does not render dev or manual auth controls', (tester) async {
    await pumpDesktop(tester);

    expect(find.text('Dev token'), findsNothing);
    expect(find.text('Backend API'), findsNothing);
    expect(find.text('Manual token'), findsNothing);
    expect(find.text('Устройства'), findsWidgets);
  });

  testWidgets('toggles between light and dark theme', (tester) async {
    await pumpDesktop(tester);

    expect(find.text('Светлая'), findsOneWidget);
    expect(find.text('Темная'), findsOneWidget);
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.dark,
    );

    await tester.tap(find.text('Светлая'));
    await tester.pump();

    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.light,
    );
  });

  testWidgets('handles help menu selections', (tester) async {
    await pumpDesktop(tester);

    await tester.tap(find.byIcon(Icons.help_outline_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Документация'));
    await tester.pumpAndSettle();

    expect(find.text('Документация'), findsNothing);
  });

  testWidgets('shows platform install options in resource hub', (tester) async {
    await pumpDesktop(tester);

    await tester.tap(find.text('Ресурсы').first);
    await tester.pump();

    expect(find.text('Debian/Ubuntu'), findsOneWidget);
    expect(find.text('Linux/macOS'), findsOneWidget);
    expect(
      find.text('curl -fsSL https://endlessnet.ru/install.sh | sh'),
      findsNWidgets(2),
    );
    expect(find.text('Подключение Windows'), findsOneWidget);
    expect(find.text('Скачать установщик'), findsOneWidget);
    expect(find.text('Connect this device'), findsOneWidget);
    expect(find.text('Create join token'), findsOneWidget);
    expect(
      find.textContaining(
        'Interactive: enrollment request -> approval link -> complete enrollment.',
      ),
      findsOneWidget,
    );
    expect(
      find.textContaining(
        'Unattended: create join token -> copy install command.',
      ),
      findsOneWidget,
    );
    expect(find.text('Android/iOS (WireGuard)'), findsOneWidget);
  });

  testWidgets('renders settings sections inside the admin app', (tester) async {
    await pumpDesktop(tester);

    await tester.tap(find.text('Настройки').first);
    await tester.pump();

    expect(find.text('Настройки'), findsWidgets);
    expect(find.text('Биллинг'), findsOneWidget);
    expect(find.text('Доверенные учетные данные'), findsOneWidget);
    expect(find.text('Вебхуки'), findsOneWidget);
  });

  testWidgets('opens personal settings from the user menu', (tester) async {
    await pumpDesktop(tester);

    await tester.tap(find.byIcon(Icons.account_circle_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Нет сессии'), findsNothing);
    expect(find.text('Профиль не загружен'), findsOneWidget);
    await tester.tap(find.text('Личные настройки'));
    await tester.pumpAndSettle();

    expect(find.text('Личные настройки'), findsOneWidget);
    expect(find.text('ID пользователя'), findsOneWidget);
    expect(find.text('Сессия действительна до'), findsOneWidget);
  });

  testWidgets('keeps user row actions on one line', (tester) async {
    tester.view.physicalSize = const Size(820, 360);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAdminTheme(Brightness.light),
        home: Scaffold(
          body: UsersScreen(
            members: [
              AccountMemberModel(
                userId: 'usr_77f56d3df52d05aa34326e6df',
                email: '',
                name: '',
                role: 'owner',
                status: 'active',
                createdAt: DateTime(2026, 7, 5, 17, 2),
              ),
            ],
            canMutate: true,
            onInvite: (_) async {},
            onUpdate: (_, _) async {},
            onRemove: (_) async {},
          ),
        ),
      ),
    );
    await tester.pump();

    final changeRoleCenter = tester.getCenter(
      find.byIcon(Icons.manage_accounts),
    );
    final removeCenter = tester.getCenter(
      find.byIcon(Icons.person_remove_alt_1_rounded),
    );

    expect(removeCenter.dx, greaterThan(changeRoleCenter.dx));
    expect(removeCenter.dy, changeRoleCenter.dy);
  });

  testWidgets('opens machine network creation dialog', (tester) async {
    await pumpDesktop(tester);

    await tester.tap(find.text('Создать сеть').first);
    await tester.pumpAndSettle();

    expect(find.text('IPv4 CIDR'), findsOneWidget);
    expect(find.text('DNS-резолверы'), findsOneWidget);
  });

  testWidgets('renders policy editor actions', (tester) async {
    await pumpDesktop(tester);

    await tester.tap(find.text('Доступ').first);
    await tester.pump();

    expect(find.text('Проверить'), findsOneWidget);
    expect(find.text('Предпросмотр diff'), findsOneWidget);
    expect(find.text('Запустить тесты'), findsOneWidget);
    expect(find.text('Сохранить'), findsOneWidget);
  });
}
