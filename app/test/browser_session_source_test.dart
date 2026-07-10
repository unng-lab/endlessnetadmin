import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('browser session sources never persist bearer tokens', () {
    final runtime = File('lib/runtime_web.dart').readAsStringSync();
    final index = File('web/index.html').readAsStringSync();
    final login = File('web/login.html').readAsStringSync();

    expect(runtime, isNot(contains('endlessnet.token')));
    expect(runtime, isNot(contains('takeTokenFromLocationHash')));
    expect(login, isNot(contains('endlessnet.token')));
    expect(login, isNot(contains('location.hash')));
    expect(index, contains('Content-Security-Policy'));
    expect(index, contains("object-src 'none'"));
    expect(login, contains('Content-Security-Policy'));
  });

  test('installer never places a session token in process arguments', () {
    final installer = File('web/install.sh').readAsStringSync();

    expect(installer, isNot(contains('--token "\$auth_token"')));
    expect(installer, contains('login --server "\$server_url" --token-file -'));
    expect(installer, contains('--join-token-file <owner-only-token-file>'));
  });
}
