import 'dart:convert';

import 'package:endlessnet_admin/api_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test(
    'cookie session mode does not synthesize bearer authorization',
    () async {
      late http.Request seen;
      final client = ApiClient(
        baseUrl: 'https://api.example.test',
        httpClient: MockClient((request) async {
          seen = request;
          return http.Response(
            '{"user_id":"usr_1","email":"user@example.test","name":"User"}',
            200,
          );
        }),
      );

      await client.me();

      expect(seen.headers, isNot(contains('Authorization')));
    },
  );

  test('savePolicy sends bearer auth and policy body', () async {
    late http.Request seen;
    final client = ApiClient(
      baseUrl: 'https://api.example.test',
      token: 'session-token',
      httpClient: MockClient((request) async {
        seen = request;
        return http.Response(
          '{"text":"{}","format":"json","hash":"abc","version":2}',
          200,
        );
      }),
    );

    final policy = await client.savePolicy('acct_1', {
      'text': '{}',
      'format': 'json',
    });

    expect(seen.method, 'PUT');
    expect(seen.url.path, '/admin/accounts/acct_1/policy');
    expect(seen.headers['Authorization'], 'Bearer session-token');
    expect(seen.body, contains('"text":"{}"'));
    expect(policy.hash, 'abc');
  });

  test('updateDns calls account-scoped DNS endpoint', () async {
    late http.Request seen;
    final client = ApiClient(
      baseUrl: 'https://api.example.test',
      token: 'session-token',
      httpClient: MockClient((request) async {
        seen = request;
        return http.Response(
          '{"suffix":"team.example","magicdns_enabled":true,"https_certs_enabled":false,"nameservers":[],"search_domains":[]}',
          200,
        );
      }),
    );

    final dns = await client.updateDns('acct_1', {
      'suffix': 'team.example',
      'magicdns_enabled': true,
    });

    expect(seen.method, 'PATCH');
    expect(seen.url.path, '/admin/accounts/acct_1/dns');
    expect(dns.suffix, 'team.example');
  });

  test('revokeJoinToken calls account-scoped admin endpoint', () async {
    late http.Request seen;
    final client = ApiClient(
      baseUrl: 'https://api.example.test',
      token: 'session-token',
      httpClient: MockClient((request) async {
        seen = request;
        return http.Response('', 204);
      }),
    );

    await client.revokeJoinToken('acct_1', 'jtk_1');

    expect(seen.method, 'DELETE');
    expect(seen.url.path, '/admin/accounts/acct_1/join-tokens/jtk_1');
    expect(seen.headers['Authorization'], 'Bearer session-token');
  });

  test('createJoinToken sends Windows enrollment tags', () async {
    late http.Request seen;
    final client = ApiClient(
      baseUrl: 'https://api.example.test',
      token: 'session-token',
      httpClient: MockClient((request) async {
        seen = request;
        return http.Response(
          '{"id":"jtk_1","token":"enj_test","network_name":"default","tags":["platform:windows","mode:server"]}',
          201,
        );
      }),
    );

    final response = await client.createJoinToken(
      'acct_1',
      networkId: 'net_1',
      networkName: 'default',
      ttl: '24h',
      tags: const ['platform:windows', 'mode:server'],
    );

    final body = jsonDecode(seen.body) as Map<String, dynamic>;
    expect(seen.method, 'POST');
    expect(seen.url.path, '/admin/accounts/acct_1/join-tokens');
    expect(body['network_id'], 'net_1');
    expect(body['network_name'], 'default');
    expect(body['tags'], ['platform:windows', 'mode:server']);
    expect(body['idempotency_key'], matches(RegExp(r'^[A-Za-z0-9_-]{43}$')));
    expect(response['token'], 'enj_test');
  });

  test('createBillingCheckout uses the payment-backed endpoint', () async {
    late http.Request seen;
    final client = ApiClient(
      baseUrl: 'https://api.example.test',
      httpClient: MockClient((request) async {
        seen = request;
        return http.Response(
          '{"id":"chk_1","account_id":"acc_1","plan_id":"business","billing_period":"monthly","provider":"yookassa","status":"pending","amount":1000,"currency":"RUB","confirmation_url":"https://pay.example.test/chk_1","created_at":"2026-07-10T00:00:00Z","updated_at":"2026-07-10T00:00:00Z","expires_at":"2026-07-10T01:00:00Z"}',
          201,
        );
      }),
    );

    final checkout = await client.createBillingCheckout(
      accountId: 'acc_1',
      planId: 'business',
      billingPeriod: 'monthly',
    );

    expect(seen.method, 'POST');
    expect(seen.url.path, '/accounts/acc_1/billing/checkout');
    expect(checkout.id, 'chk_1');
    expect(checkout.confirmationUrl, 'https://pay.example.test/chk_1');
  });
}
