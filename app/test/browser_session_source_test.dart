import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('browser session sources never persist bearer tokens', () {
    final runtime = File('lib/runtime_web.dart').readAsStringSync();
    final main = File('lib/main.dart').readAsStringSync();
    final index = File('web/index.html').readAsStringSync();
    final login = File('web/login/index.html').readAsStringSync();
    final bootstrap = File('web/session_bootstrap.js').readAsStringSync();

    expect(runtime, isNot(contains('endlessnet.token')));
    expect(runtime, isNot(contains('takeTokenFromLocationHash')));
    expect(main, isNot(contains('runtime.replaceAdminPath([_section.slug])')));
    expect(File('web/login.html').existsSync(), isFalse);
    expect(login, isNot(contains('endlessnet.token')));
    expect(login, isNot(contains('location.hash')));
    expect(index, contains('Content-Security-Policy'));
    expect(index, contains("object-src 'none'"));
    expect(index, contains('session_bootstrap.js'));
    expect(index, isNot(contains('src="flutter_bootstrap.js"')));
    expect(bootstrap, contains('new URL("/auth/me", apiBase)'));
    expect(bootstrap, contains('credentials: "include"'));
    expect(bootstrap, contains('location.replace'));
    expect(bootstrap, contains('response.status === 401'));
    expect(bootstrap, contains('new URL("login/", document.baseURI)'));
    expect(login, contains('Content-Security-Policy'));
  });

  test('installer never places a session token in process arguments', () {
    final installer = File('web/install.sh').readAsStringSync();

    expect(installer, isNot(contains('--token "\$auth_token"')));
    expect(installer, contains('login --server "\$server_url" --token-file -'));
    expect(installer, contains('--join-token TOKEN'));
    expect(installer, contains('service enroll'));
    expect(installer, contains('--join-token-file "\$token_file"'));
    expect(installer, contains('service_enroll_args -'));
    expect(installer, contains('service_enroll_args "" ""'));
    expect(installer, contains('client_up_args -'));
    expect(installer, contains('client_up_args "" ""'));
  });
}
