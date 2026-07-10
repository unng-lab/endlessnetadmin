import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

import 'http_client_stub.dart' if (dart.library.html) 'http_client_web.dart';
import 'models.dart';

class ApiException implements Exception {
  const ApiException(this.statusCode, this.message);

  final int statusCode;
  final String message;

  bool get isAuthFailure =>
      statusCode == 401 ||
      statusCode == 403 ||
      message.toLowerCase().contains('token');

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({required this.baseUrl, this.token = '', http.Client? httpClient})
    : _httpClient = httpClient ?? createHttpClient();

  final String baseUrl;
  final String token;
  final http.Client _httpClient;

  Uri url(String path) {
    final parsed = Uri.tryParse(path);
    if (parsed != null && parsed.hasScheme) {
      return parsed;
    }
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    final base = baseUrl.trim().isEmpty ? 'http://localhost' : baseUrl;
    return Uri.parse(base).resolve(normalizedPath);
  }

  Future<AdminUser> me() {
    return _request(
      'GET',
      '/auth/me',
      decode: (json) => AdminUser.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<List<AccountModel>> listAccounts() {
    return _request(
      'GET',
      '/accounts',
      decode: (json) => objectList(
        json,
        'accounts',
      ).map(AccountModel.fromJson).toList(growable: false),
    );
  }

  Future<List<NetworkModel>> listNetworks({String? accountId}) {
    final query = accountId == null || accountId.isEmpty
        ? ''
        : '?account_id=${Uri.encodeQueryComponent(accountId)}';
    return _request(
      'GET',
      '/networks$query',
      decode: (json) => listOf(json, NetworkModel.fromJson),
    );
  }

  Future<NetworkModel> createNetwork({
    required String name,
    required String cidr,
    required List<String> dns,
    String accountId = '',
    String idempotencyKey = '',
  }) {
    final effectiveIdempotencyKey = idempotencyKey.isEmpty
        ? _newIdempotencyKey()
        : idempotencyKey;
    return _request(
      'POST',
      '/networks',
      body: {
        'name': name,
        'cidr': cidr,
        'dns': dns,
        if (accountId.isNotEmpty) 'account_id': accountId,
        'idempotency_key': effectiveIdempotencyKey,
      },
      decode: (json) => NetworkModel.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<AccountModel> updateAccount(
    String accountId, {
    required String name,
    required String billingCountry,
    required String currency,
  }) {
    return _request(
      'PATCH',
      '/accounts/${Uri.encodeComponent(accountId)}',
      body: {
        'name': name,
        'billing_country': billingCountry,
        'currency': currency,
      },
      decode: (json) => AccountModel.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<List<NodeModel>> listNodes(String networkId) {
    return _request(
      'GET',
      '/networks/${Uri.encodeComponent(networkId)}/nodes',
      decode: (json) => listOf(json, NodeModel.fromJson),
    );
  }

  Future<List<MachineModel>> listMachines(String accountId) {
    return _request(
      'GET',
      '/admin/accounts/${Uri.encodeComponent(accountId)}/machines',
      decode: (json) => objectList(
        json,
        'machines',
      ).map(MachineModel.fromJson).toList(growable: false),
    );
  }

  Future<MachineModel> machine(String machineId) {
    return _request(
      'GET',
      '/admin/machines/${Uri.encodeComponent(machineId)}',
      decode: (json) => MachineModel.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<MachineModel> updateMachine(
    String machineId,
    Map<String, Object?> values,
  ) {
    return _request(
      'PATCH',
      '/admin/machines/${Uri.encodeComponent(machineId)}',
      body: values,
      decode: (json) => MachineModel.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<void> deleteMachine(String machineId) {
    return _request(
      'DELETE',
      '/admin/machines/${Uri.encodeComponent(machineId)}',
      decode: (_) {},
    );
  }

  Future<Map<String, dynamic>> createJoinToken(
    String accountId, {
    String networkId = '',
    required String networkName,
    required String ttl,
    required List<String> tags,
    bool reusable = false,
    bool ephemeral = false,
    bool preauthorized = true,
    String idempotencyKey = '',
  }) {
    final effectiveIdempotencyKey = idempotencyKey.isEmpty
        ? _newIdempotencyKey()
        : idempotencyKey;
    return _request(
      'POST',
      '/admin/accounts/${Uri.encodeComponent(accountId)}/join-tokens',
      body: {
        if (networkId.isNotEmpty) 'network_id': networkId,
        'network_name': networkName,
        'ttl': ttl,
        'tags': tags,
        'reusable': reusable,
        'ephemeral': ephemeral,
        'preauthorized': preauthorized,
        'idempotency_key': effectiveIdempotencyKey,
      },
      decode: mapOf,
    );
  }

  Future<void> revokeJoinToken(String accountId, String tokenId) {
    return _request(
      'DELETE',
      '/admin/accounts/${Uri.encodeComponent(accountId)}/join-tokens/${Uri.encodeComponent(tokenId)}',
      decode: (_) {},
    );
  }

  Future<List<AppModel>> listApps(String accountId) {
    return _request(
      'GET',
      '/admin/accounts/${Uri.encodeComponent(accountId)}/apps',
      decode: (json) => objectList(
        json,
        'apps',
      ).map(AppModel.fromJson).toList(growable: false),
    );
  }

  Future<AppModel> createApp(String accountId, Map<String, Object?> values) {
    return _request(
      'POST',
      '/admin/accounts/${Uri.encodeComponent(accountId)}/apps',
      body: values,
      decode: (json) => AppModel.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<AppModel> updateApp(String appId, Map<String, Object?> values) {
    return _request(
      'PATCH',
      '/admin/apps/${Uri.encodeComponent(appId)}',
      body: values,
      decode: (json) => AppModel.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<void> deleteApp(String appId) {
    return _request(
      'DELETE',
      '/admin/apps/${Uri.encodeComponent(appId)}',
      decode: (_) {},
    );
  }

  Future<List<ServiceModel>> listServices(String accountId) {
    return _request(
      'GET',
      '/admin/accounts/${Uri.encodeComponent(accountId)}/services',
      decode: (json) => objectList(
        json,
        'services',
      ).map(ServiceModel.fromJson).toList(growable: false),
    );
  }

  Future<ServiceModel> createService(
    String accountId,
    Map<String, Object?> values,
  ) {
    return _request(
      'POST',
      '/admin/accounts/${Uri.encodeComponent(accountId)}/services',
      body: values,
      decode: (json) => ServiceModel.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ServiceModel> updateService(
    String serviceId,
    Map<String, Object?> values,
  ) {
    return _request(
      'PATCH',
      '/admin/services/${Uri.encodeComponent(serviceId)}',
      body: values,
      decode: (json) => ServiceModel.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<void> deleteService(String serviceId) {
    return _request(
      'DELETE',
      '/admin/services/${Uri.encodeComponent(serviceId)}',
      decode: (_) {},
    );
  }

  Future<List<AccountMemberModel>> listMembers(String accountId) {
    return _request(
      'GET',
      '/accounts/${Uri.encodeComponent(accountId)}/members',
      decode: (json) => objectList(
        json,
        'members',
      ).map(AccountMemberModel.fromJson).toList(growable: false),
    );
  }

  Future<AccountMemberModel> inviteMember(
    String accountId,
    Map<String, Object?> values,
  ) {
    return _request(
      'POST',
      '/accounts/${Uri.encodeComponent(accountId)}/invites',
      body: values,
      decode: (json) =>
          AccountMemberModel.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<AccountMemberModel> updateMember(
    String accountId,
    String userId,
    Map<String, Object?> values,
  ) {
    return _request(
      'PATCH',
      '/accounts/${Uri.encodeComponent(accountId)}/members/${Uri.encodeComponent(userId)}',
      body: values,
      decode: (json) =>
          AccountMemberModel.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<void> removeMember(String accountId, String userId) {
    return _request(
      'DELETE',
      '/accounts/${Uri.encodeComponent(accountId)}/members/${Uri.encodeComponent(userId)}',
      decode: (_) {},
    );
  }

  Future<PolicyFileModel> policy(String accountId) {
    return _request(
      'GET',
      '/admin/accounts/${Uri.encodeComponent(accountId)}/policy',
      decode: (json) => PolicyFileModel.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<PolicyFileModel> savePolicy(
    String accountId,
    Map<String, Object?> values,
  ) {
    return _request(
      'PUT',
      '/admin/accounts/${Uri.encodeComponent(accountId)}/policy',
      body: values,
      decode: (json) => PolicyFileModel.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<Map<String, dynamic>> validatePolicy(
    String accountId,
    Map<String, Object?> values,
  ) {
    return _request(
      'POST',
      '/admin/accounts/${Uri.encodeComponent(accountId)}/policy/validate',
      body: values,
      decode: mapOf,
    );
  }

  Future<Map<String, dynamic>> previewPolicy(
    String accountId,
    Map<String, Object?> values,
  ) {
    return _request(
      'POST',
      '/admin/accounts/${Uri.encodeComponent(accountId)}/policy/preview',
      body: values,
      decode: mapOf,
    );
  }

  Future<Map<String, dynamic>> runPolicyTests(String accountId) {
    return _request(
      'POST',
      '/admin/accounts/${Uri.encodeComponent(accountId)}/policy/tests/run',
      decode: mapOf,
    );
  }

  Future<DnsSettingsModel> dns(String accountId) {
    return _request(
      'GET',
      '/admin/accounts/${Uri.encodeComponent(accountId)}/dns',
      decode: (json) => DnsSettingsModel.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<DnsSettingsModel> updateDns(
    String accountId,
    Map<String, Object?> values,
  ) {
    return _request(
      'PATCH',
      '/admin/accounts/${Uri.encodeComponent(accountId)}/dns',
      body: values,
      decode: (json) => DnsSettingsModel.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<void> upsertNameserver(
    String accountId,
    String id,
    Map<String, Object?> values,
  ) {
    final suffix = id.isEmpty ? '' : '/${Uri.encodeComponent(id)}';
    return _request(
      id.isEmpty ? 'POST' : 'PATCH',
      '/admin/accounts/${Uri.encodeComponent(accountId)}/dns/nameservers$suffix',
      body: values,
      decode: (_) {},
    );
  }

  Future<void> deleteNameserver(String accountId, String id) {
    return _request(
      'DELETE',
      '/admin/accounts/${Uri.encodeComponent(accountId)}/dns/nameservers/${Uri.encodeComponent(id)}',
      decode: (_) {},
    );
  }

  Future<void> upsertSearchDomain(
    String accountId,
    String id,
    Map<String, Object?> values,
  ) {
    final suffix = id.isEmpty ? '' : '/${Uri.encodeComponent(id)}';
    return _request(
      id.isEmpty ? 'POST' : 'PATCH',
      '/admin/accounts/${Uri.encodeComponent(accountId)}/dns/search-domains$suffix',
      body: values,
      decode: (_) {},
    );
  }

  Future<void> deleteSearchDomain(String accountId, String id) {
    return _request(
      'DELETE',
      '/admin/accounts/${Uri.encodeComponent(accountId)}/dns/search-domains/${Uri.encodeComponent(id)}',
      decode: (_) {},
    );
  }

  Future<List<AuditEventModel>> audit(String accountId) {
    return _request(
      'GET',
      '/admin/accounts/${Uri.encodeComponent(accountId)}/audit',
      decode: (json) => objectList(
        json,
        'events',
      ).map(AuditEventModel.fromJson).toList(growable: false),
    );
  }

  Future<Map<String, dynamic>> flowLogs(String accountId) {
    return _request(
      'GET',
      '/admin/accounts/${Uri.encodeComponent(accountId)}/flow-logs',
      decode: mapOf,
    );
  }

  Future<void> updateFlowLogSettings(
    String accountId,
    Map<String, Object?> values,
  ) {
    return _request(
      'POST',
      '/admin/accounts/${Uri.encodeComponent(accountId)}/flow-logs/settings',
      body: values,
      decode: (_) {},
    );
  }

  Future<List<Map<String, dynamic>>> listLogStreams(String accountId) {
    return _request(
      'GET',
      '/admin/accounts/${Uri.encodeComponent(accountId)}/log-streams',
      decode: (json) => objectList(json, 'streams'),
    );
  }

  Future<void> upsertLogStream(
    String accountId,
    String id,
    Map<String, Object?> values,
  ) {
    final suffix = id.isEmpty ? '' : '/${Uri.encodeComponent(id)}';
    return _request(
      id.isEmpty ? 'POST' : 'PATCH',
      '/admin/accounts/${Uri.encodeComponent(accountId)}/log-streams$suffix',
      body: values,
      decode: (_) {},
    );
  }

  Future<void> deleteLogStream(String accountId, String id) {
    return _request(
      'DELETE',
      '/admin/accounts/${Uri.encodeComponent(accountId)}/log-streams/${Uri.encodeComponent(id)}',
      decode: (_) {},
    );
  }

  Future<List<BillingPlanModel>> listBillingPlans() {
    return _request(
      'GET',
      '/billing/plans',
      decode: (json) => objectList(
        json,
        'plans',
      ).map(BillingPlanModel.fromJson).toList(growable: false),
    );
  }

  Future<SubscriptionModel> billingSubscription(String accountId) {
    return _request(
      'GET',
      '/accounts/${Uri.encodeComponent(accountId)}/billing/subscription',
      decode: (json) =>
          SubscriptionModel.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<UsageSnapshotModel> billingUsage(String accountId) {
    return _request(
      'GET',
      '/accounts/${Uri.encodeComponent(accountId)}/billing/usage',
      decode: (json) =>
          UsageSnapshotModel.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<List<InvoiceModel>> billingInvoices(String accountId) {
    return _request(
      'GET',
      '/accounts/${Uri.encodeComponent(accountId)}/billing/invoices',
      decode: (json) => objectList(
        json,
        'invoices',
      ).map(InvoiceModel.fromJson).toList(growable: false),
    );
  }

  Future<Map<String, dynamic>> billingLegalProfile(String accountId) {
    return _request(
      'GET',
      '/accounts/${Uri.encodeComponent(accountId)}/billing/legal',
      decode: mapOf,
    );
  }

  Future<void> changeBillingPlan({
    required String accountId,
    required String planId,
    required String billingPeriod,
  }) {
    return _request(
      'POST',
      '/accounts/${Uri.encodeComponent(accountId)}/billing/change-plan',
      body: {'plan_id': planId, 'billing_period': billingPeriod},
      decode: (_) {},
    );
  }

  Future<Map<String, dynamic>> license(String accountId) {
    return _request(
      'GET',
      '/accounts/${Uri.encodeComponent(accountId)}/license',
      decode: mapOf,
    );
  }

  Future<List<Map<String, dynamic>>> listTrustCredentials(String accountId) {
    return _request(
      'GET',
      '/admin/accounts/${Uri.encodeComponent(accountId)}/trust-credentials',
      decode: (json) => objectList(json, 'credentials'),
    );
  }

  Future<Map<String, dynamic>> createTrustCredential(
    String accountId,
    Map<String, Object?> values,
  ) {
    return _request(
      'POST',
      '/admin/accounts/${Uri.encodeComponent(accountId)}/trust-credentials',
      body: values,
      decode: mapOf,
    );
  }

  Future<Map<String, dynamic>> updateTrustCredential(
    String accountId,
    String id,
    Map<String, Object?> values,
  ) {
    return _request(
      'PATCH',
      '/admin/accounts/${Uri.encodeComponent(accountId)}/trust-credentials/${Uri.encodeComponent(id)}',
      body: values,
      decode: mapOf,
    );
  }

  Future<void> deleteTrustCredential(String accountId, String id) {
    return _request(
      'DELETE',
      '/admin/accounts/${Uri.encodeComponent(accountId)}/trust-credentials/${Uri.encodeComponent(id)}',
      decode: (_) {},
    );
  }

  Future<List<Map<String, dynamic>>> listWebhooks(String accountId) {
    return _request(
      'GET',
      '/admin/accounts/${Uri.encodeComponent(accountId)}/webhooks',
      decode: (json) => objectList(json, 'webhooks'),
    );
  }

  Future<Map<String, dynamic>> createWebhook(
    String accountId,
    Map<String, Object?> values,
  ) {
    return _request(
      'POST',
      '/admin/accounts/${Uri.encodeComponent(accountId)}/webhooks',
      body: values,
      decode: mapOf,
    );
  }

  Future<Map<String, dynamic>> updateWebhook(
    String accountId,
    String id,
    Map<String, Object?> values,
  ) {
    return _request(
      'PATCH',
      '/admin/accounts/${Uri.encodeComponent(accountId)}/webhooks/${Uri.encodeComponent(id)}',
      body: values,
      decode: mapOf,
    );
  }

  Future<void> deleteWebhook(String accountId, String id) {
    return _request(
      'DELETE',
      '/admin/accounts/${Uri.encodeComponent(accountId)}/webhooks/${Uri.encodeComponent(id)}',
      decode: (_) {},
    );
  }

  Future<Map<String, dynamic>> testWebhook(String accountId, String id) {
    return _request(
      'POST',
      '/admin/accounts/${Uri.encodeComponent(accountId)}/webhooks/${Uri.encodeComponent(id)}/test',
      decode: mapOf,
    );
  }

  Future<CheckoutSessionModel> createBillingCheckout({
    required String accountId,
    required String planId,
    required String billingPeriod,
  }) {
    return _request(
      'POST',
      '/accounts/${Uri.encodeComponent(accountId)}/billing/checkout',
      body: {'plan_id': planId, 'billing_period': billingPeriod},
      decode: (json) =>
          CheckoutSessionModel.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<CheckoutSessionModel> billingCheckoutStatus({
    required String accountId,
    required String checkoutId,
  }) {
    return _request(
      'GET',
      '/accounts/${Uri.encodeComponent(accountId)}/billing/checkout/${Uri.encodeComponent(checkoutId)}',
      decode: (json) =>
          CheckoutSessionModel.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<void> logout() {
    return _request('POST', '/auth/logout', auth: false, decode: (_) {});
  }

  Future<T> _request<T>(
    String method,
    String path, {
    Object? body,
    bool auth = true,
    required T Function(Object? json) decode,
  }) async {
    final headers = <String, String>{
      if (body != null) 'Content-Type': 'application/json',
      if (auth && token.trim().isNotEmpty) 'Authorization': 'Bearer $token',
    };
    final request = http.Request(method, url(path))..headers.addAll(headers);
    if (body != null) {
      request.body = jsonEncode(body);
    }

    final streamed = await _httpClient.send(request);
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final details = response.body.trim().isEmpty
          ? response.reasonPhrase ?? 'request failed'
          : response.body.trim();
      throw ApiException(
        response.statusCode,
        '${response.statusCode}: $details',
      );
    }
    final text = response.body.trim();
    return decode(text.isEmpty ? null : jsonDecode(text));
  }
}

String _newIdempotencyKey() {
  final random = Random.secure();
  final bytes = List<int>.generate(32, (_) => random.nextInt(256));
  return base64UrlEncode(bytes).replaceAll('=', '');
}

List<T> listOf<T>(Object? json, T Function(Map<String, dynamic>) convert) {
  if (json is! List) {
    return const [];
  }
  return json
      .whereType<Map<String, dynamic>>()
      .map(convert)
      .toList(growable: false);
}

Map<String, dynamic> mapOf(Object? json) {
  if (json is Map<String, dynamic>) {
    return json;
  }
  return const {};
}
