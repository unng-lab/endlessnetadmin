import 'package:endlessnet_admin/features/resource_hub/windows_enrollment.dart';
import 'package:endlessnet_admin/features/resource_hub/resource_hub_screen.dart';
import 'package:endlessnet_admin/models.dart';
import 'package:endlessnet_admin/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'windowsEnrollmentCommand renders bootstrap command with token metadata',
    () {
      final command = windowsEnrollmentCommand(
        installScriptUrl: 'https://endlessnet.ru/install.ps1',
        serverUrl: 'https://api.endlessnet.ru/',
        enrollToken: "enr_test'quoted",
        mode: 'server',
      );

      expect(command, contains('powershell'));
      expect(command, contains('https://endlessnet.ru/install.ps1'));
      expect(command, contains("-Server 'https://api.endlessnet.ru'"));
      expect(command, contains("-EnrollToken 'enr_test''quoted'"));
      expect(command, contains("-Mode 'server'"));
      expect(command, isNot(contains('session-token')));
    },
  );

  test('windowsCompatibilityCommand preserves CLI up join-token shape', () {
    final command = windowsCompatibilityCommand(
      serverUrl: 'https://api.endlessnet.ru/',
      enrollToken: 'enr_test',
    );

    expect(
      command,
      "endlessnet-client.exe up --server 'https://api.endlessnet.ru' --join-token 'enr_test'",
    );
  });

  test('windowsEnrollmentLink renders tray deep link', () {
    final link = windowsEnrollmentLink(
      serverUrl: 'https://api.endlessnet.ru/',
      enrollToken: 'enr_test',
      mode: 'server',
    );

    expect(
      link,
      'endlessnet://enroll?server=https%3A%2F%2Fapi.endlessnet.ru&token=enr_test&mode=server',
    );
  });

  test('windowsInteractiveEnrollmentLink renders no-secret tray deep link', () {
    final link = windowsInteractiveEnrollmentLink(
      serverUrl: 'https://api.endlessnet.ru/',
      mode: 'server',
    );

    expect(
      link,
      'endlessnet://enroll?server=https%3A%2F%2Fapi.endlessnet.ru&mode=server',
    );
    expect(link, isNot(contains('token=')));
  });

  test('tokenTTLLabel renders compact remaining lifetime', () {
    final now = DateTime.utc(2026, 7, 7, 10);
    expect(tokenTTLLabel(now.add(const Duration(hours: 1)), now), '1h');
    expect(
      tokenTTLLabel(now.add(const Duration(hours: 2, minutes: 5)), now),
      '2h 5m',
    );
    expect(tokenTTLLabel(now.add(const Duration(minutes: 7)), now), '7m');
    expect(
      tokenTTLLabel(now.subtract(const Duration(seconds: 1)), now),
      'expired',
    );
  });

  test('windowsEnrollmentTags includes platform and normalized mode', () {
    expect(windowsEnrollmentTags('server'), [
      'platform:windows',
      'mode:server',
    ]);
    expect(windowsEnrollmentTags('unknown'), [
      'platform:windows',
      'mode:workstation',
    ]);
  });

  testWidgets(
    'Resource Hub separates interactive connect and unattended join token',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      String? seenMode;
      String? seenNetworkId;
      String? seenNetworkName;
      String? openedInstaller;
      String? launchedLink;
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAdminTheme(Brightness.light),
          home: Scaffold(
            body: ResourceHubScreen(
              account: const AccountModel(
                id: 'acct_1',
                type: 'team',
                name: 'Team',
                slug: 'team',
                status: 'active',
                billingCountry: 'RU',
                currency: 'RUB',
                createdAt: null,
                updatedAt: null,
              ),
              networks: const [
                NetworkModel(
                  id: 'net_default',
                  name: 'default',
                  cidr: '100.64.0.0/10',
                  ipv6Cidr: '',
                  dns: [],
                  ownerId: 'usr_1',
                  accountId: 'acct_1',
                  createdAt: null,
                ),
                NetworkModel(
                  id: 'net_prod',
                  name: 'prod',
                  cidr: '100.80.0.0/16',
                  ipv6Cidr: '',
                  dns: [],
                  ownerId: 'usr_1',
                  accountId: 'acct_1',
                  createdAt: null,
                ),
              ],
              apiBaseUrl: 'https://api.example.test',
              canMutate: true,
              openExternal: (url) => openedInstaller = url,
              launchEnrollmentLink: (url) => launchedLink = url,
              onCreateJoinToken: (mode, networkId, networkName) async {
                seenMode = mode;
                seenNetworkId = networkId;
                seenNetworkName = networkName;
                return {
                  'id': 'jtk_1',
                  'token': 'enj_test',
                  'network_name': networkName,
                  'expires_at': DateTime.utc(2026, 7, 7, 12).toIso8601String(),
                  'reusable': false,
                  'tags': windowsEnrollmentTags(mode),
                };
              },
              onRevokeJoinToken: (_) async {},
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.download_rounded));
      await tester.pumpAndSettle();
      expect(openedInstaller, windowsInstallerURL);

      await tester.tap(find.text('default').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('prod').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.link_rounded));
      await tester.pumpAndSettle();

      expect(seenMode, isNull);
      expect(seenNetworkId, isNull);
      expect(seenNetworkName, isNull);
      expect(
        launchedLink,
        'endlessnet://enroll?server=https%3A%2F%2Fapi.example.test&mode=workstation',
      );
      expect(launchedLink, isNot(contains('token=')));
      expect(find.textContaining('enj_test'), findsNothing);

      await tester.tap(find.text('Create join token'));
      await tester.pumpAndSettle();

      expect(seenMode, 'workstation');
      expect(seenNetworkId, 'net_prod');
      expect(seenNetworkName, 'prod');
      expect(find.textContaining("-EnrollToken 'enj_test'"), findsOneWidget);
      expect(find.textContaining('enj_test'), findsOneWidget);
    },
  );
}
