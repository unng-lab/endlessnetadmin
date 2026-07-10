class AdminUser {
  const AdminUser({
    required this.userId,
    required this.email,
    required this.name,
    required this.expiresAt,
  });

  final String userId;
  final String email;
  final String name;
  final DateTime? expiresAt;

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      userId: stringValue(json['user_id']),
      email: stringValue(json['email']),
      name: stringValue(json['name']),
      expiresAt: dateValue(json['expires_at']),
    );
  }
}

class AccountModel {
  const AccountModel({
    required this.id,
    required this.type,
    required this.name,
    required this.slug,
    required this.status,
    required this.billingCountry,
    required this.currency,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String type;
  final String name;
  final String slug;
  final String status;
  final String billingCountry;
  final String currency;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory AccountModel.fromJson(Map<String, dynamic> json) {
    return AccountModel(
      id: stringValue(json['id']),
      type: stringValue(json['type']),
      name: stringValue(json['name']),
      slug: stringValue(json['slug']),
      status: stringValue(json['status']),
      billingCountry: stringValue(json['billing_country']),
      currency: stringValue(json['currency']),
      createdAt: dateValue(json['created_at']),
      updatedAt: dateValue(json['updated_at']),
    );
  }
}

class NetworkModel {
  const NetworkModel({
    required this.id,
    required this.name,
    required this.cidr,
    required this.ipv6Cidr,
    required this.dns,
    required this.ownerId,
    required this.accountId,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String cidr;
  final String ipv6Cidr;
  final List<String> dns;
  final String ownerId;
  final String accountId;
  final DateTime? createdAt;

  factory NetworkModel.fromJson(Map<String, dynamic> json) {
    return NetworkModel(
      id: stringValue(json['id']),
      name: stringValue(json['name']),
      cidr: stringValue(json['cidr']),
      ipv6Cidr: stringValue(json['ipv6_cidr']),
      dns: stringList(json['dns']),
      ownerId: stringValue(json['owner_id']),
      accountId: stringValue(json['account_id']),
      createdAt: dateValue(json['created_at']),
    );
  }
}

class NodeModel {
  const NodeModel({
    required this.id,
    required this.networkId,
    required this.userId,
    required this.hostname,
    required this.publicKey,
    required this.assignedIp,
    required this.assignedIpv6,
    required this.status,
    required this.advertisedIps,
    required this.tags,
    required this.createdAt,
    required this.updatedAt,
    required this.lastSeen,
  });

  final String id;
  final String networkId;
  final String userId;
  final String hostname;
  final String publicKey;
  final String assignedIp;
  final String assignedIpv6;
  final String status;
  final List<String> advertisedIps;
  final List<String> tags;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? lastSeen;

  factory NodeModel.fromJson(Map<String, dynamic> json) {
    return NodeModel(
      id: stringValue(json['id']),
      networkId: stringValue(json['network_id']),
      userId: stringValue(json['user_id']),
      hostname: stringValue(json['hostname']),
      publicKey: stringValue(json['public_key']),
      assignedIp: stringValue(json['assigned_ip']),
      assignedIpv6: stringValue(json['assigned_ipv6']),
      status: stringValue(json['status']),
      advertisedIps: stringList(json['advertised_ips']),
      tags: stringList(json['tags']),
      createdAt: dateValue(json['created_at']),
      updatedAt: dateValue(json['updated_at']),
      lastSeen: dateValue(json['last_seen']),
    );
  }
}

class MachineModel {
  const MachineModel({
    required this.id,
    required this.networkId,
    required this.networkName,
    required this.userId,
    required this.ownerEmail,
    required this.hostname,
    required this.publicKey,
    required this.identityPublicKey,
    required this.assignedIp,
    required this.assignedIpv6,
    required this.endpoint,
    required this.clientVersion,
    required this.os,
    required this.platform,
    required this.status,
    required this.advertisedIps,
    required this.tags,
    required this.keyExpiryEnabled,
    required this.approvalState,
    required this.lastSeen,
    required this.createdAt,
  });

  final String id;
  final String networkId;
  final String networkName;
  final String userId;
  final String ownerEmail;
  final String hostname;
  final String publicKey;
  final String identityPublicKey;
  final String assignedIp;
  final String assignedIpv6;
  final String endpoint;
  final String clientVersion;
  final String os;
  final String platform;
  final String status;
  final List<String> advertisedIps;
  final List<String> tags;
  final bool keyExpiryEnabled;
  final String approvalState;
  final DateTime? lastSeen;
  final DateTime? createdAt;

  factory MachineModel.fromJson(Map<String, dynamic> json) {
    return MachineModel(
      id: stringValue(json['id']),
      networkId: stringValue(json['network_id']),
      networkName: stringValue(json['network_name']),
      userId: stringValue(json['user_id']),
      ownerEmail: stringValue(json['owner_email']),
      hostname: stringValue(json['hostname']),
      publicKey: stringValue(json['public_key']),
      identityPublicKey: stringValue(json['identity_public_key']),
      assignedIp: stringValue(json['assigned_ip']),
      assignedIpv6: stringValue(json['assigned_ipv6']),
      endpoint: stringValue(json['endpoint']),
      clientVersion: stringValue(json['client_version']),
      os: stringValue(json['os']),
      platform: stringValue(json['platform']),
      status: stringValue(json['status']),
      advertisedIps: stringList(json['advertised_ips']),
      tags: stringList(json['tags']),
      keyExpiryEnabled: boolValue(json['key_expiry_enabled']),
      approvalState: stringValue(json['approval_state']),
      lastSeen: dateValue(json['last_seen']),
      createdAt: dateValue(json['created_at']),
    );
  }
}

class AppModel {
  const AppModel({
    required this.id,
    required this.name,
    required this.targetType,
    required this.target,
    required this.connectorNodes,
    required this.connectorTags,
    required this.policyStatus,
    required this.health,
  });

  final String id;
  final String name;
  final String targetType;
  final String target;
  final List<String> connectorNodes;
  final List<String> connectorTags;
  final String policyStatus;
  final String health;

  factory AppModel.fromJson(Map<String, dynamic> json) {
    return AppModel(
      id: stringValue(json['id']),
      name: stringValue(json['name']),
      targetType: stringValue(json['target_type']),
      target: stringValue(json['target']),
      connectorNodes: stringList(json['connector_nodes']),
      connectorTags: stringList(json['connector_tags']),
      policyStatus: stringValue(json['policy_status']),
      health: stringValue(json['health']),
    );
  }
}

class ServiceModel {
  const ServiceModel({
    required this.id,
    required this.name,
    required this.dnsName,
    required this.description,
    required this.ports,
    required this.tags,
    required this.approvalStatus,
    required this.health,
    required this.hostCount,
  });

  final String id;
  final String name;
  final String dnsName;
  final String description;
  final List<String> ports;
  final List<String> tags;
  final String approvalStatus;
  final String health;
  final int hostCount;

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    final rawPorts = json['ports'];
    return ServiceModel(
      id: stringValue(json['id']),
      name: stringValue(json['name']),
      dnsName: stringValue(json['dns_name']),
      description: stringValue(json['description']),
      ports: rawPorts is List
          ? rawPorts
                .map((item) {
                  if (item is Map) {
                    final protocol = stringValue(item['protocol']);
                    final port = stringValue(item['port']);
                    return port.isEmpty ? protocol : '$protocol:$port';
                  }
                  return stringValue(item);
                })
                .where((item) => item.isNotEmpty)
                .toList(growable: false)
          : const [],
      tags: stringList(json['tags']),
      approvalStatus: stringValue(json['approval_status']),
      health: stringValue(json['health']),
      hostCount: intValue(json['host_count']),
    );
  }
}

class AccountMemberModel {
  const AccountMemberModel({
    required this.userId,
    required this.email,
    required this.name,
    required this.role,
    required this.status,
    required this.createdAt,
  });

  final String userId;
  final String email;
  final String name;
  final String role;
  final String status;
  final DateTime? createdAt;

  factory AccountMemberModel.fromJson(Map<String, dynamic> json) {
    return AccountMemberModel(
      userId: stringValue(json['user_id']),
      email: stringValue(json['email']),
      name: stringValue(json['name']),
      role: stringValue(json['role']),
      status: stringValue(json['status']),
      createdAt: dateValue(json['created_at']),
    );
  }
}

class AuditEventModel {
  const AuditEventModel({
    required this.id,
    required this.type,
    required this.actorUserId,
    required this.targetType,
    required this.targetId,
    required this.createdAt,
  });

  final String id;
  final String type;
  final String actorUserId;
  final String targetType;
  final String targetId;
  final DateTime? createdAt;

  factory AuditEventModel.fromJson(Map<String, dynamic> json) {
    return AuditEventModel(
      id: stringValue(json['id']),
      type: stringValue(json['type']),
      actorUserId: stringValue(json['actor_user_id']),
      targetType: stringValue(json['target_type']),
      targetId: stringValue(json['target_id']),
      createdAt: dateValue(json['created_at']),
    );
  }
}

class DnsSettingsModel {
  const DnsSettingsModel({
    required this.suffix,
    required this.magicDnsEnabled,
    required this.httpsCertsEnabled,
    required this.nameservers,
    required this.searchDomains,
  });

  final String suffix;
  final bool magicDnsEnabled;
  final bool httpsCertsEnabled;
  final List<DnsNameserverModel> nameservers;
  final List<DnsSearchDomainModel> searchDomains;

  factory DnsSettingsModel.fromJson(Map<String, dynamic> json) {
    return DnsSettingsModel(
      suffix: stringValue(json['suffix']),
      magicDnsEnabled: boolValue(json['magicdns_enabled']),
      httpsCertsEnabled: boolValue(json['https_certs_enabled']),
      nameservers: objectList(
        json,
        'nameservers',
      ).map(DnsNameserverModel.fromJson).toList(growable: false),
      searchDomains: objectList(
        json,
        'search_domains',
      ).map(DnsSearchDomainModel.fromJson).toList(growable: false),
    );
  }
}

class DnsNameserverModel {
  const DnsNameserverModel({
    required this.id,
    required this.address,
    required this.scope,
    required this.splitDomains,
    required this.priority,
    required this.enabled,
  });

  final String id;
  final String address;
  final String scope;
  final List<String> splitDomains;
  final int priority;
  final bool enabled;

  factory DnsNameserverModel.fromJson(Map<String, dynamic> json) {
    return DnsNameserverModel(
      id: stringValue(json['id']),
      address: stringValue(json['address']),
      scope: stringValue(json['scope']),
      splitDomains: stringList(json['split_domains']),
      priority: intValue(json['priority']),
      enabled: boolValue(json['enabled']),
    );
  }
}

class DnsSearchDomainModel {
  const DnsSearchDomainModel({required this.id, required this.domain});

  final String id;
  final String domain;

  factory DnsSearchDomainModel.fromJson(Map<String, dynamic> json) {
    return DnsSearchDomainModel(
      id: stringValue(json['id']),
      domain: stringValue(json['domain']),
    );
  }
}

class PolicyFileModel {
  const PolicyFileModel({
    required this.text,
    required this.format,
    required this.hash,
    required this.version,
    required this.editorLocked,
    required this.gitOpsMode,
  });

  final String text;
  final String format;
  final String hash;
  final int version;
  final bool editorLocked;
  final bool gitOpsMode;

  factory PolicyFileModel.fromJson(Map<String, dynamic> json) {
    return PolicyFileModel(
      text: stringValue(json['text']),
      format: stringValue(json['format']),
      hash: stringValue(json['hash']),
      version: intValue(json['version']),
      editorLocked: boolValue(json['editor_locked']),
      gitOpsMode: boolValue(json['gitops_mode']),
    );
  }
}

class BillingPlanModel {
  const BillingPlanModel({
    required this.id,
    required this.name,
    required this.accountType,
    required this.description,
    required this.currency,
    required this.monthlyPrice,
    required this.yearlyPrice,
    required this.public,
    required this.billingProvider,
    required this.features,
    required this.limits,
    required this.periods,
  });

  final String id;
  final String name;
  final String accountType;
  final String description;
  final String currency;
  final int monthlyPrice;
  final int yearlyPrice;
  final bool public;
  final String billingProvider;
  final Map<String, bool> features;
  final Map<String, int> limits;
  final List<String> periods;

  factory BillingPlanModel.fromJson(Map<String, dynamic> json) {
    return BillingPlanModel(
      id: stringValue(json['id']),
      name: stringValue(json['name']),
      accountType: stringValue(json['account_type']),
      description: stringValue(json['description']),
      currency: stringValue(json['currency']),
      monthlyPrice: intValue(json['monthly_price']),
      yearlyPrice: intValue(json['yearly_price']),
      public: boolValue(json['public']),
      billingProvider: stringValue(json['billing_provider']),
      features: boolMap(json['features']),
      limits: intMap(json['limits']),
      periods: stringList(json['periods']),
    );
  }
}

class SubscriptionModel {
  const SubscriptionModel({
    required this.id,
    required this.accountId,
    required this.planId,
    required this.status,
    required this.billingPeriod,
    required this.provider,
    required this.cancelAtPeriodEnd,
    required this.currentPeriodEnds,
  });

  final String id;
  final String accountId;
  final String planId;
  final String status;
  final String billingPeriod;
  final String provider;
  final bool cancelAtPeriodEnd;
  final DateTime? currentPeriodEnds;

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionModel(
      id: stringValue(json['id']),
      accountId: stringValue(json['account_id']),
      planId: stringValue(json['plan_id']),
      status: stringValue(json['status']),
      billingPeriod: stringValue(json['billing_period']),
      provider: stringValue(json['provider']),
      cancelAtPeriodEnd: boolValue(json['cancel_at_period_end']),
      currentPeriodEnds: dateValue(json['current_period_ends_at']),
    );
  }
}

class UsageSnapshotModel {
  const UsageSnapshotModel({
    required this.accountId,
    required this.users,
    required this.nodes,
    required this.networks,
    required this.joinTokensActive,
    required this.relayEndpoints,
    required this.auditEvents,
    required this.limits,
    required this.computedAt,
  });

  final String accountId;
  final int users;
  final int nodes;
  final int networks;
  final int joinTokensActive;
  final int relayEndpoints;
  final int auditEvents;
  final Map<String, int> limits;
  final DateTime? computedAt;

  factory UsageSnapshotModel.fromJson(Map<String, dynamic> json) {
    return UsageSnapshotModel(
      accountId: stringValue(json['account_id']),
      users: intValue(json['users']),
      nodes: intValue(json['nodes']),
      networks: intValue(json['networks']),
      joinTokensActive: intValue(json['join_tokens_active']),
      relayEndpoints: intValue(json['relay_endpoints']),
      auditEvents: intValue(json['audit_events']),
      limits: intMap(json['limits']),
      computedAt: dateValue(json['computed_at']),
    );
  }
}

class InvoiceModel {
  const InvoiceModel({
    required this.id,
    required this.number,
    required this.status,
    required this.provider,
    required this.amount,
    required this.currency,
    required this.checkoutId,
    required this.dueAt,
    required this.paidAt,
    required this.createdAt,
  });

  final String id;
  final String number;
  final String status;
  final String provider;
  final int amount;
  final String currency;
  final String checkoutId;
  final DateTime? dueAt;
  final DateTime? paidAt;
  final DateTime? createdAt;

  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    return InvoiceModel(
      id: stringValue(json['id']),
      number: stringValue(json['number']),
      status: stringValue(json['status']),
      provider: stringValue(json['provider']),
      amount: intValue(json['amount']),
      currency: stringValue(json['currency']),
      checkoutId: stringValue(json['checkout_id']),
      dueAt: dateValue(json['due_at']),
      paidAt: dateValue(json['paid_at']),
      createdAt: dateValue(json['created_at']),
    );
  }
}

class CheckoutSessionModel {
  const CheckoutSessionModel({
    required this.id,
    required this.accountId,
    required this.planId,
    required this.billingPeriod,
    required this.provider,
    required this.status,
    required this.amount,
    required this.currency,
    required this.invoiceId,
    required this.providerPaymentId,
    required this.providerStatus,
    required this.confirmationUrl,
  });

  final String id;
  final String accountId;
  final String planId;
  final String billingPeriod;
  final String provider;
  final String status;
  final int amount;
  final String currency;
  final String invoiceId;
  final String providerPaymentId;
  final String providerStatus;
  final String confirmationUrl;

  factory CheckoutSessionModel.fromJson(Map<String, dynamic> json) {
    return CheckoutSessionModel(
      id: stringValue(json['id']),
      accountId: stringValue(json['account_id']),
      planId: stringValue(json['plan_id']),
      billingPeriod: stringValue(json['billing_period']),
      provider: stringValue(json['provider']),
      status: stringValue(json['status']),
      amount: intValue(json['amount']),
      currency: stringValue(json['currency']),
      invoiceId: stringValue(json['invoice_id']),
      providerPaymentId: stringValue(json['provider_payment_id']),
      providerStatus: stringValue(json['provider_status']),
      confirmationUrl: stringValue(json['confirmation_url']),
    );
  }
}

String stringValue(Object? value) => value == null ? '' : value.toString();

List<String> stringList(Object? value) {
  if (value is! List) {
    return const [];
  }
  return value
      .map((item) => item?.toString().trim() ?? '')
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
}

List<Map<String, dynamic>> objectList(Object? json, String key) {
  if (json is! Map<String, dynamic>) {
    return const [];
  }
  final value = json[key];
  if (value is! List) {
    return const [];
  }
  return value.whereType<Map<String, dynamic>>().toList(growable: false);
}

DateTime? dateValue(Object? value) {
  final raw = stringValue(value).trim();
  return raw.isEmpty ? null : DateTime.tryParse(raw);
}

int intValue(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.round();
  }
  return int.tryParse(stringValue(value)) ?? 0;
}

bool boolValue(Object? value) {
  if (value is bool) {
    return value;
  }
  final raw = stringValue(value).trim().toLowerCase();
  return raw == 'true' || raw == '1' || raw == 'yes';
}

Map<String, bool> boolMap(Object? value) {
  if (value is! Map) {
    return const {};
  }
  return value.map((key, item) => MapEntry(key.toString(), boolValue(item)));
}

Map<String, int> intMap(Object? value) {
  if (value is! Map) {
    return const {};
  }
  return value.map((key, item) => MapEntry(key.toString(), intValue(item)));
}
