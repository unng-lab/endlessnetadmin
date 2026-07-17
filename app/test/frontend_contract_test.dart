import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'admin API consumer surface is present in the pinned OpenAPI contract',
    () {
      final contractFile = File('../contracts/frontend-api.openapi.json');
      expect(
        contractFile.existsSync(),
        isTrue,
        reason: 'Pinned frontend OpenAPI contract is missing',
      );
      final document = jsonDecode(contractFile.readAsStringSync());
      expect(document, isA<Map<String, dynamic>>());
      final spec = document as Map<String, dynamic>;
      expect(spec['openapi'], '3.1.0');
      expect(spec['x-endlessnet-contract-version'], '1.0.0');
      final paths = spec['paths'] as Map<String, dynamic>;

      for (final operation in _operations) {
        final pathItem = paths[operation.path];
        expect(pathItem, isA<Map<String, dynamic>>(), reason: operation.label);
        final method = (pathItem as Map<String, dynamic>)[operation.method];
        expect(method, isA<Map<String, dynamic>>(), reason: operation.label);
        expect(
          (method as Map<String, dynamic>)['operationId'],
          operation.operationId,
          reason: operation.label,
        );
      }
    },
  );

  test('browser authentication contract forbids HTML provider scraping', () {
    final loginSource = File('web/login/index.html').readAsStringSync();
    expect(loginSource, isNot(contains('parseProvidersFromLoginHTML')));
    expect(loginSource, isNot(contains('loadProvidersFromLoginPage')));
    expect(loginSource, contains('/auth/providers'));
  });

  test(
    'device endpoint publication fields are pinned for nodes and machines',
    () {
      final spec =
          jsonDecode(
                File(
                  '../contracts/frontend-api.openapi.json',
                ).readAsStringSync(),
              )
              as Map<String, dynamic>;
      final components = spec['components'] as Map<String, dynamic>;
      final schemas = components['schemas'] as Map<String, dynamic>;

      for (final schemaName in ['Node', 'AdminMachine']) {
        final schema = schemas[schemaName] as Map<String, dynamic>;
        final properties = schema['properties'] as Map<String, dynamic>;
        expect(
          properties.keys,
          containsAll([
            'endpoint',
            'endpoint_candidates',
            'endpoint_generation',
            'endpoint_expires_at',
          ]),
          reason: schemaName,
        );
        expect(
          (properties['endpoint'] as Map<String, dynamic>)['type'],
          'string',
          reason: '$schemaName.endpoint',
        );
        expect(
          (properties['endpoint_candidates'] as Map<String, dynamic>)['type'],
          'array',
          reason: '$schemaName.endpoint_candidates',
        );
        expect(
          (properties['endpoint_generation'] as Map<String, dynamic>)['type'],
          'integer',
          reason: '$schemaName.endpoint_generation',
        );
      }
    },
  );

  test('admin runtime configuration uses the pinned schema version', () {
    final schema =
        jsonDecode(
              File(
                '../contracts/frontend-runtime-config.schema.json',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>;
    expect(schema[r'$schema'], 'https://json-schema.org/draft/2020-12/schema');
    expect(schema['additionalProperties'], isFalse);
    expect(
      schema['required'],
      containsAll(<String>[
        'schema_version',
        'api_base_url',
        'site_url',
        'admin_url',
      ]),
    );
    final properties = schema['properties'] as Map<String, dynamic>;
    expect((properties['schema_version'] as Map<String, dynamic>)['const'], 1);
  });
}

class _Operation {
  const _Operation(this.method, this.path, this.operationId);

  final String method;
  final String path;
  final String operationId;

  String get label => '${method.toUpperCase()} $path';
}

const _operations = <_Operation>[
  _Operation('get', '/auth/providers', 'listAuthProviders'),
  _Operation('get', '/auth/me', 'getCurrentUser'),
  _Operation('post', '/auth/logout', 'logout'),
  _Operation('get', '/accounts', 'listAccounts'),
  _Operation('patch', '/accounts/{account_id}', 'patchAccount'),
  _Operation('get', '/accounts/{account_id}/members', 'listAccountMembers'),
  _Operation('post', '/accounts/{account_id}/invites', 'inviteAccountMember'),
  _Operation(
    'patch',
    '/accounts/{account_id}/members/{user_id}',
    'updateAccountMember',
  ),
  _Operation(
    'delete',
    '/accounts/{account_id}/members/{user_id}',
    'removeAccountMember',
  ),
  _Operation('get', '/networks', 'listNetworks'),
  _Operation('post', '/networks', 'createNetwork'),
  _Operation('get', '/networks/{network_id}/nodes', 'listNetworkNodes'),
  _Operation('get', '/admin/accounts/{account_id}/machines', 'listMachines'),
  _Operation('get', '/admin/machines/{machine_id}', 'getMachine'),
  _Operation('patch', '/admin/machines/{machine_id}', 'patchMachine'),
  _Operation('delete', '/admin/machines/{machine_id}', 'deleteMachine'),
  _Operation(
    'post',
    '/admin/accounts/{account_id}/join-tokens',
    'createJoinToken',
  ),
  _Operation(
    'delete',
    '/admin/accounts/{account_id}/join-tokens/{token_id}',
    'revokeJoinToken',
  ),
  _Operation('get', '/admin/accounts/{account_id}/apps', 'listApps'),
  _Operation('post', '/admin/accounts/{account_id}/apps', 'createApp'),
  _Operation('patch', '/admin/apps/{app_id}', 'updateApp'),
  _Operation('delete', '/admin/apps/{app_id}', 'deleteApp'),
  _Operation('get', '/admin/accounts/{account_id}/services', 'listServices'),
  _Operation('post', '/admin/accounts/{account_id}/services', 'createService'),
  _Operation('patch', '/admin/services/{service_id}', 'updateService'),
  _Operation('delete', '/admin/services/{service_id}', 'deleteService'),
  _Operation('get', '/admin/accounts/{account_id}/policy', 'getPolicy'),
  _Operation('put', '/admin/accounts/{account_id}/policy', 'savePolicy'),
  _Operation(
    'post',
    '/admin/accounts/{account_id}/policy/validate',
    'validatePolicy',
  ),
  _Operation(
    'post',
    '/admin/accounts/{account_id}/policy/preview',
    'previewPolicy',
  ),
  _Operation(
    'post',
    '/admin/accounts/{account_id}/policy/tests/run',
    'runPolicyTests',
  ),
  _Operation('get', '/admin/accounts/{account_id}/dns', 'getDNSSettings'),
  _Operation('patch', '/admin/accounts/{account_id}/dns', 'patchDNSSettings'),
  _Operation(
    'post',
    '/admin/accounts/{account_id}/dns/nameservers',
    'createDNSNameserver',
  ),
  _Operation(
    'patch',
    '/admin/accounts/{account_id}/dns/nameservers/{resource_id}',
    'updateDNSNameserver',
  ),
  _Operation(
    'delete',
    '/admin/accounts/{account_id}/dns/nameservers/{resource_id}',
    'deleteDNSNameserver',
  ),
  _Operation(
    'post',
    '/admin/accounts/{account_id}/dns/search-domains',
    'createDNSSearchDomain',
  ),
  _Operation(
    'patch',
    '/admin/accounts/{account_id}/dns/search-domains/{resource_id}',
    'updateDNSSearchDomain',
  ),
  _Operation(
    'delete',
    '/admin/accounts/{account_id}/dns/search-domains/{resource_id}',
    'deleteDNSSearchDomain',
  ),
  _Operation('get', '/admin/accounts/{account_id}/audit', 'listAuditEvents'),
  _Operation('get', '/admin/accounts/{account_id}/flow-logs', 'listFlowLogs'),
  _Operation(
    'post',
    '/admin/accounts/{account_id}/flow-logs/settings',
    'updateFlowLogSettings',
  ),
  _Operation(
    'get',
    '/admin/accounts/{account_id}/log-streams',
    'listLogStreams',
  ),
  _Operation(
    'post',
    '/admin/accounts/{account_id}/log-streams',
    'createLogStream',
  ),
  _Operation(
    'patch',
    '/admin/accounts/{account_id}/log-streams/{resource_id}',
    'updateLogStream',
  ),
  _Operation(
    'delete',
    '/admin/accounts/{account_id}/log-streams/{resource_id}',
    'deleteLogStream',
  ),
  _Operation('get', '/billing/plans', 'listBillingPlans'),
  _Operation(
    'get',
    '/accounts/{account_id}/billing/subscription',
    'getBillingSubscription',
  ),
  _Operation('get', '/accounts/{account_id}/billing/usage', 'getBillingUsage'),
  _Operation(
    'get',
    '/accounts/{account_id}/billing/invoices',
    'listBillingInvoices',
  ),
  _Operation(
    'get',
    '/accounts/{account_id}/billing/legal',
    'getBillingLegalProfile',
  ),
  _Operation(
    'post',
    '/accounts/{account_id}/billing/change-plan',
    'changeBillingPlan',
  ),
  _Operation('get', '/accounts/{account_id}/license', 'getLicense'),
  _Operation(
    'post',
    '/accounts/{account_id}/billing/checkout',
    'createBillingCheckout',
  ),
  _Operation(
    'get',
    '/accounts/{account_id}/billing/checkout/{checkout_id}',
    'getBillingCheckout',
  ),
  _Operation(
    'get',
    '/admin/accounts/{account_id}/trust-credentials',
    'listTrustCredentials',
  ),
  _Operation(
    'post',
    '/admin/accounts/{account_id}/trust-credentials',
    'createTrustCredential',
  ),
  _Operation(
    'patch',
    '/admin/accounts/{account_id}/trust-credentials/{resource_id}',
    'updateTrustCredential',
  ),
  _Operation(
    'delete',
    '/admin/accounts/{account_id}/trust-credentials/{resource_id}',
    'deleteTrustCredential',
  ),
  _Operation('get', '/admin/accounts/{account_id}/webhooks', 'listWebhooks'),
  _Operation('post', '/admin/accounts/{account_id}/webhooks', 'createWebhook'),
  _Operation(
    'patch',
    '/admin/accounts/{account_id}/webhooks/{resource_id}',
    'updateWebhook',
  ),
  _Operation(
    'delete',
    '/admin/accounts/{account_id}/webhooks/{resource_id}',
    'deleteWebhook',
  ),
  _Operation(
    'post',
    '/admin/accounts/{account_id}/webhooks/{resource_id}/test',
    'testWebhook',
  ),
];
