import 'dart:async';

import 'package:flutter/material.dart';

import 'admin_shell.dart';
import 'api_client.dart';
import 'features/access_controls/access_controls_screen.dart';
import 'features/apps/apps_screen.dart';
import 'features/dns/dns_screen.dart';
import 'features/logs/logs_screen.dart';
import 'features/machines/machines_screen.dart';
import 'features/resource_hub/resource_hub_screen.dart';
import 'features/resource_hub/windows_enrollment.dart';
import 'features/services/services_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/users/users_screen.dart';
import 'components.dart';
import 'models.dart';
import 'runtime.dart' as runtime;
import 'theme.dart';

void main() {
  runApp(const EndlessNetAdminApp());
}

class EndlessNetAdminApp extends StatefulWidget {
  const EndlessNetAdminApp({super.key});

  @override
  State<EndlessNetAdminApp> createState() => _EndlessNetAdminAppState();
}

class _EndlessNetAdminAppState extends State<EndlessNetAdminApp> {
  ThemeMode _themeMode = ThemeMode.dark;

  @override
  void initState() {
    super.initState();
    _themeMode = _themeModeFromStorage(runtime.readStoredThemeMode());
  }

  void _setThemeMode(ThemeMode value) {
    setState(() => _themeMode = value);
    runtime.writeStoredThemeMode(value.name);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Консоль EndlessNet',
      debugShowCheckedModeBanner: false,
      theme: buildAdminTheme(Brightness.light),
      darkTheme: buildAdminTheme(Brightness.dark),
      themeMode: _themeMode,
      initialRoute: '/',
      onGenerateRoute: (settings) {
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => AdminConsole(
            themeMode: _themeMode,
            onThemeModeChanged: _setThemeMode,
          ),
        );
      },
    );
  }
}

ThemeMode _themeModeFromStorage(String value) {
  return switch (value.trim().toLowerCase()) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.dark,
  };
}

class AdminConsole extends StatefulWidget {
  const AdminConsole({
    super.key,
    required this.themeMode,
    required this.onThemeModeChanged,
  });

  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;

  @override
  State<AdminConsole> createState() => _AdminConsoleState();
}

class _AdminConsoleState extends State<AdminConsole> {
  static const _machineRefreshErrorPrefix =
      'Не удалось автоматически обновить устройства:';

  VoidCallback? _removeHistoryListener;

  AdminSection _section = AdminSection.machines;
  String _settingsDetail = '';
  String _selectedMachineId = '';

  String _apiBase = '';
  bool _loading = true;
  String? _alert;
  String _routeEnrollmentRequestId = '';
  String _handledEnrollmentRequestId = '';
  bool _machineRefreshInFlight = false;

  AdminUser? _me;
  List<AccountModel> _accounts = const [];
  String _selectedAccountId = '';
  List<NetworkModel> _networks = const [];
  List<MachineModel> _machines = const [];
  bool _machinesLoaded = false;
  List<AppModel> _apps = const [];
  List<ServiceModel> _services = const [];
  List<AccountMemberModel> _members = const [];
  List<AuditEventModel> _auditEvents = const [];
  List<Map<String, dynamic>> _logStreams = const [];
  List<Map<String, dynamic>> _trustCredentials = const [];
  List<Map<String, dynamic>> _webhooks = const [];
  DnsSettingsModel? _dnsSettings;
  PolicyFileModel? _policy;
  List<BillingPlanModel> _billingPlans = const [];
  SubscriptionModel? _subscription;
  UsageSnapshotModel? _usage;
  List<InvoiceModel> _invoices = const [];
  Map<String, dynamic> _license = const {};

  @override
  void initState() {
    super.initState();
    _apiBase = runtime.defaultApiBase();
    _readRoute();
    _removeHistoryListener = runtime.listenAdminHistory(() {
      if (!mounted) {
        return;
      }
      setState(_readRoute);
    });
    Future<void>.microtask(_loadAll);
  }

  @override
  void dispose() {
    _removeHistoryListener?.call();
    super.dispose();
  }

  ApiClient _client() => ApiClient(baseUrl: _apiBase);

  AccountModel? get _selectedAccount {
    for (final account in _accounts) {
      if (account.id == _selectedAccountId) {
        return account;
      }
    }
    return _accounts.isEmpty ? null : _accounts.first;
  }

  String get _planLabel {
    final subscription = _subscription;
    if (subscription != null && subscription.planId.isNotEmpty) {
      for (final plan in _billingPlans) {
        if (plan.id == subscription.planId) {
          return plan.name.isEmpty ? plan.id : plan.name;
        }
      }
      return subscription.planId;
    }
    final account = _selectedAccount;
    if (account == null) {
      return '';
    }
    final type = account.type.isEmpty ? 'аккаунт' : account.type;
    return account.status.isEmpty
        ? type
        : '$type / ${statusLabel(account.status)}';
  }

  bool get _canMutate {
    if (_me == null || _members.isEmpty) {
      return true;
    }
    for (final member in _members) {
      if (member.userId == _me!.userId) {
        final role = member.role.trim().toLowerCase();
        return role != 'viewer' && role != 'support';
      }
    }
    return true;
  }

  void _readRoute() {
    final route = runtime.currentAdminRouteSegments();
    _routeEnrollmentRequestId = runtime.currentEnrollmentRequestID().trim();
    final first = route.isEmpty ? '' : route[0];
    _section = switch (first) {
      '' => AdminSection.machines,
      'nodes' => AdminSection.machines,
      'networks' => AdminSection.dns,
      'access' => AdminSection.accessControls,
      'connect' => AdminSection.resourceHub,
      'billing' => AdminSection.settings,
      _ => sectionFromSlug(first),
    };
    _selectedMachineId = _section == AdminSection.machines
        ? runtime.currentMachineID().trim()
        : '';
    _settingsDetail = switch (first) {
      'billing' => 'billing',
      _ =>
        _section == AdminSection.settings && route.length > 1 ? route[1] : '',
    };
  }

  Future<void> _loadAll() async {
    setState(() {
      _loading = true;
      _alert = null;
    });

    final api = _client();
    final warnings = <String>[];
    try {
      final me = await api.me();
      final accounts = await _loadOptional(
        warnings,
        'аккаунты',
        api.listAccounts,
        const <AccountModel>[],
      );
      final selectedAccountId = _resolveAccount(accounts);
      final keepExistingMachineState = selectedAccountId == _selectedAccountId;

      var networks = const <NetworkModel>[];
      var machines = keepExistingMachineState
          ? _machines
          : const <MachineModel>[];
      var machinesLoaded = keepExistingMachineState && _machinesLoaded;
      var apps = const <AppModel>[];
      var services = const <ServiceModel>[];
      var members = const <AccountMemberModel>[];
      var auditEvents = const <AuditEventModel>[];
      var logStreams = const <Map<String, dynamic>>[];
      var trustCredentials = const <Map<String, dynamic>>[];
      var webhooks = const <Map<String, dynamic>>[];
      DnsSettingsModel? dnsSettings;
      PolicyFileModel? policy;
      SubscriptionModel? subscription;
      UsageSnapshotModel? usage;
      var invoices = const <InvoiceModel>[];
      var license = const <String, dynamic>{};

      final billingPlans = await _loadOptional(
        warnings,
        'тарифы',
        api.listBillingPlans,
        const <BillingPlanModel>[],
      );

      if (selectedAccountId.isNotEmpty) {
        networks = await _loadOptional(
          warnings,
          'сети',
          () => api.listNetworks(accountId: selectedAccountId),
          const <NetworkModel>[],
        );
        try {
          machines = await api.listMachines(selectedAccountId);
          machinesLoaded = true;
        } catch (error) {
          if (error is ApiException && error.isAuthFailure) {
            rethrow;
          }
          warnings.add('Не удалось загрузить устройства: $error');
        }
        apps = await _loadOptional(
          warnings,
          'приложения',
          () => api.listApps(selectedAccountId),
          const <AppModel>[],
        );
        services = await _loadOptional(
          warnings,
          'сервисы',
          () => api.listServices(selectedAccountId),
          const <ServiceModel>[],
        );
        members = await _loadOptional(
          warnings,
          'участников',
          () => api.listMembers(selectedAccountId),
          const <AccountMemberModel>[],
        );
        auditEvents = await _loadOptional(
          warnings,
          'аудит',
          () => api.audit(selectedAccountId),
          const <AuditEventModel>[],
        );
        logStreams = await _loadOptional(
          warnings,
          'потоки журналов',
          () => api.listLogStreams(selectedAccountId),
          const <Map<String, dynamic>>[],
        );
        trustCredentials = await _loadOptional(
          warnings,
          'доверенные учетные данные',
          () => api.listTrustCredentials(selectedAccountId),
          const <Map<String, dynamic>>[],
        );
        webhooks = await _loadOptional(
          warnings,
          'вебхуки',
          () => api.listWebhooks(selectedAccountId),
          const <Map<String, dynamic>>[],
        );
        dnsSettings = await _loadOptional<DnsSettingsModel?>(
          warnings,
          'DNS',
          () => api.dns(selectedAccountId),
          null,
        );
        policy = await _loadOptional<PolicyFileModel?>(
          warnings,
          'политику',
          () => api.policy(selectedAccountId),
          null,
        );
        subscription = await _loadOptional<SubscriptionModel?>(
          warnings,
          'подписку',
          () => api.billingSubscription(selectedAccountId),
          null,
        );
        usage = await _loadOptional<UsageSnapshotModel?>(
          warnings,
          'использование',
          () => api.billingUsage(selectedAccountId),
          null,
        );
        invoices = await _loadOptional(
          warnings,
          'счета',
          () => api.billingInvoices(selectedAccountId),
          const <InvoiceModel>[],
        );
        license = await _loadOptional(
          warnings,
          'лицензию',
          () => api.license(selectedAccountId),
          const <String, dynamic>{},
        );
      } else {
        networks = await _loadOptional(
          warnings,
          'сети',
          () => api.listNetworks(),
          const <NetworkModel>[],
        );
      }

      if (!mounted) {
        return;
      }
      setState(() {
        _me = me;
        _accounts = accounts;
        _selectedAccountId = selectedAccountId;
        _networks = networks;
        _machines = machines;
        _machinesLoaded = machinesLoaded;
        _apps = apps;
        _services = services;
        _members = members;
        _auditEvents = auditEvents;
        _logStreams = logStreams;
        _trustCredentials = trustCredentials;
        _webhooks = webhooks;
        _dnsSettings = dnsSettings;
        _policy = policy;
        _billingPlans = billingPlans;
        _subscription = subscription;
        _usage = usage;
        _invoices = invoices;
        _license = license;
        _loading = false;
        _alert = warnings.isEmpty ? null : warnings.take(3).join('\n');
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          unawaited(_maybeOpenEnrollmentRequestApproval());
        }
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      if (error is ApiException && error.isAuthFailure) {
        setState(() {
          _loading = false;
          _alert = 'Сессия истекла. Войдите снова.';
        });
        runtime.redirectTo(runtime.adminLoginUrl());
        return;
      }
      setState(() {
        _loading = false;
        _alert = error.toString();
      });
    }
  }

  Future<T> _loadOptional<T>(
    List<String> warnings,
    String label,
    Future<T> Function() load,
    T fallback,
  ) async {
    try {
      return await load();
    } catch (error) {
      if (error is ApiException && error.isAuthFailure) {
        rethrow;
      }
      warnings.add('Не удалось загрузить $label: $error');
      return fallback;
    }
  }

  String _resolveAccount(List<AccountModel> accounts) {
    if (accounts.isEmpty) {
      return '';
    }
    if (_selectedAccountId.isNotEmpty &&
        accounts.any((account) => account.id == _selectedAccountId)) {
      return _selectedAccountId;
    }
    return accounts.first.id;
  }

  Future<void> _setAccount(String accountId) async {
    if (accountId == _selectedAccountId) {
      return;
    }
    setState(() {
      _selectedAccountId = accountId;
      _selectedMachineId = '';
      _machines = const [];
      _machinesLoaded = false;
    });
    if (_section == AdminSection.machines) {
      runtime.replaceMachineSelection('');
    }
    await _loadAll();
  }

  void _setSection(AdminSection section) {
    setState(() {
      _section = section;
      _selectedMachineId = '';
      _settingsDetail = '';
    });
    runtime.pushAdminPath([section.slug]);
  }

  void _openPersonalSettings() {
    setState(() {
      _section = AdminSection.settings;
      _selectedMachineId = '';
      _settingsDetail = 'personal';
    });
    runtime.pushAdminPath([AdminSection.settings.slug, 'personal']);
  }

  void _selectMachine(String machineId) {
    setState(() => _selectedMachineId = machineId);
    runtime.pushMachineSelection(machineId);
  }

  Future<void> _refreshMachines() async {
    final accountId = _selectedAccountId.trim();
    if (_loading ||
        _machineRefreshInFlight ||
        _section != AdminSection.machines ||
        accountId.isEmpty) {
      return;
    }

    _machineRefreshInFlight = true;
    try {
      final machines = await _client().listMachines(accountId);
      if (!mounted ||
          _loading ||
          _section != AdminSection.machines ||
          accountId != _selectedAccountId) {
        return;
      }
      final selectionWasRemoved =
          _selectedMachineId.isNotEmpty &&
          !machines.any((machine) => machine.id == _selectedMachineId);
      setState(() {
        _machines = machines;
        _machinesLoaded = true;
        if (selectionWasRemoved) {
          _selectedMachineId = '';
        }
        if (_alert?.startsWith(_machineRefreshErrorPrefix) ?? false) {
          _alert = null;
        }
      });
      if (selectionWasRemoved) {
        runtime.replaceMachineSelection('');
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      if (error is ApiException && error.isAuthFailure) {
        setState(() => _alert = 'Сессия истекла. Войдите снова.');
        runtime.redirectTo(runtime.adminLoginUrl());
        return;
      }
      setState(() => _alert = '$_machineRefreshErrorPrefix $error');
    } finally {
      _machineRefreshInFlight = false;
    }
  }

  Future<Map<String, dynamic>?> _createJoinTokenPayload([
    String mode = '',
    String networkId = '',
    String networkName = '',
  ]) async {
    final accountId = _selectedAccountId;
    if (accountId.isEmpty) {
      setState(
        () => _alert = 'Выберите аккаунт перед созданием токена подключения.',
      );
      return null;
    }
    final fallbackNetwork = _networks.isEmpty ? null : _networks.first;
    final selectedNetworkId = networkId.trim().isEmpty
        ? fallbackNetwork?.id ?? ''
        : networkId.trim();
    final selectedNetworkName = networkName.trim().isEmpty
        ? fallbackNetwork?.name ?? 'default'
        : networkName.trim();
    try {
      final response = await _client().createJoinToken(
        accountId,
        networkId: selectedNetworkId,
        networkName: selectedNetworkName,
        ttl: '24h',
        tags: mode.trim().isEmpty ? const [] : windowsEnrollmentTags(mode),
        reusable: false,
        ephemeral: false,
        preauthorized: true,
      );
      final token = stringValue(response['token']).trim();
      if (token.isEmpty) {
        throw const ApiException(
          500,
          'ответ на создание токена подключения не содержит токен',
        );
      }
      await _loadAll();
      return response;
    } catch (error) {
      if (!mounted) {
        return null;
      }
      setState(() => _alert = 'Не удалось создать токен подключения: $error');
      return null;
    }
  }

  Future<String?> _createJoinToken() async {
    final response = await _createJoinTokenPayload();
    if (response == null) {
      return null;
    }
    return stringValue(response['token']).trim();
  }

  Future<void> _revokeJoinToken(String tokenId) async {
    final accountId = _selectedAccountId;
    if (accountId.isEmpty || tokenId.trim().isEmpty) {
      return;
    }
    try {
      await _client().revokeJoinToken(accountId, tokenId.trim());
      await _loadAll();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _alert = 'Revoke join token failed: $error');
    }
  }

  Future<void> _maybeOpenEnrollmentRequestApproval() async {
    final requestId = _routeEnrollmentRequestId.trim();
    final accountId = _selectedAccountId.trim();
    if (requestId.isEmpty ||
        accountId.isEmpty ||
        _handledEnrollmentRequestId == requestId) {
      return;
    }
    _handledEnrollmentRequestId = requestId;
    Map<String, dynamic> request;
    try {
      request = await _client().nodeEnrollmentRequest(accountId, requestId);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _alert = 'Enrollment request load failed: $error');
      return;
    }
    if (!mounted) {
      return;
    }
    final status = stringValue(request['status']).trim();
    final canDecide = _canMutate && status == 'pending';
    final action = await showDialog<String>(
      context: context,
      builder: (context) {
        final colors = context.adminColors;
        final hostname = stringValue(request['hostname']).trim();
        final publicKey = stringValue(request['public_key']).trim();
        final identityKey = stringValue(request['identity_public_key']).trim();
        final fingerprint = stringValue(request['device_fingerprint']).trim();
        final createdAt = stringValue(request['created_at']).trim();
        final expiresAt = stringValue(request['expires_at']).trim();
        return AlertDialog(
          title: const Text('Enrollment request'),
          content: SizedBox(
            width: 460,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Status: ${status.isEmpty ? '-' : status}'),
                Text('Hostname: ${hostname.isEmpty ? '-' : hostname}'),
                Text('Created: ${createdAt.isEmpty ? '-' : createdAt}'),
                Text('Expires: ${expiresAt.isEmpty ? '-' : expiresAt}'),
                const SizedBox(height: 12),
                SelectableText(
                  [
                    'request_id=$requestId',
                    if (publicKey.isNotEmpty) 'public_key=$publicKey',
                    if (identityKey.isNotEmpty)
                      'identity_public_key=$identityKey',
                    if (fingerprint.isNotEmpty)
                      'device_fingerprint=$fingerprint',
                  ].join('\n'),
                  style: TextStyle(
                    color: colors.muted,
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop('close'),
              child: const Text('Close'),
            ),
            if (canDecide)
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop('reject'),
                child: const Text('Reject'),
              ),
            if (canDecide)
              FilledButton(
                onPressed: () => Navigator.of(context).pop('approve'),
                child: const Text('Approve'),
              ),
          ],
        );
      },
    );
    if (!mounted) {
      return;
    }
    if (action == 'approve') {
      await _mutate((api) {
        return api.approveNodeEnrollmentRequest(accountId, requestId);
      });
    } else if (action == 'reject') {
      await _mutate((api) {
        return api.rejectNodeEnrollmentRequest(accountId, requestId);
      });
    }
  }

  Future<void> _logout() async {
    try {
      await _client().logout();
    } catch (_) {
      // The static frontend clears local state even if the API session is gone.
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _me = null;
      _accounts = const [];
      _selectedAccountId = '';
      _networks = const [];
      _machines = const [];
      _machinesLoaded = false;
      _apps = const [];
      _services = const [];
      _members = const [];
      _auditEvents = const [];
      _logStreams = const [];
      _trustCredentials = const [];
      _webhooks = const [];
      _dnsSettings = null;
      _policy = null;
      _subscription = null;
      _usage = null;
      _invoices = const [];
      _license = const {};
    });
    runtime.redirectTo(runtime.adminLoginUrl());
  }

  Future<void> _mutate(Future<void> Function(ApiClient api) action) async {
    final accountId = _selectedAccountId;
    if (accountId.isEmpty) {
      setState(() => _alert = 'Сначала выберите аккаунт.');
      return;
    }
    setState(() {
      _loading = true;
      _alert = null;
    });
    try {
      await action(_client());
      await _loadAll();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _alert = error.toString();
      });
    }
  }

  Future<void> _createNetwork(Map<String, Object?> values) async {
    await _mutate((api) async {
      await api.createNetwork(
        name: stringValue(values['name']),
        cidr: stringValue(values['cidr']),
        dns:
            (values['dns'] as List?)?.map((item) => item.toString()).toList() ??
            const [],
        accountId: _selectedAccountId,
      );
    });
  }

  Future<void> _updateAccount(Map<String, Object?> values) async {
    await _mutate((api) async {
      await api.updateAccount(
        _selectedAccountId,
        name: stringValue(values['name']),
        billingCountry: stringValue(values['billing_country']),
        currency: stringValue(values['currency']),
      );
    });
  }

  Future<void> _updateMachine(String id, Map<String, Object?> values) async {
    await _mutate((api) => api.updateMachine(id, values));
  }

  Future<void> _deleteMachine(String id) async {
    await _mutate((api) => api.deleteMachine(id));
    if (!mounted || id != _selectedMachineId) {
      return;
    }
    if (!_machines.any((machine) => machine.id == id)) {
      setState(() => _selectedMachineId = '');
      runtime.replaceMachineSelection('');
    }
  }

  Future<void> _saveApp(String id, Map<String, Object?> values) async {
    await _mutate((api) async {
      if (id.isEmpty) {
        await api.createApp(_selectedAccountId, values);
      } else {
        await api.updateApp(id, values);
      }
    });
  }

  Future<void> _deleteApp(String id) async {
    await _mutate((api) => api.deleteApp(id));
  }

  Future<void> _saveService(String id, Map<String, Object?> values) async {
    await _mutate((api) async {
      if (id.isEmpty) {
        await api.createService(_selectedAccountId, values);
      } else {
        await api.updateService(id, values);
      }
    });
  }

  Future<void> _deleteService(String id) async {
    await _mutate((api) => api.deleteService(id));
  }

  Future<void> _inviteMember(Map<String, Object?> values) async {
    await _mutate((api) => api.inviteMember(_selectedAccountId, values));
  }

  Future<void> _updateMember(String userId, Map<String, Object?> values) async {
    await _mutate(
      (api) => api.updateMember(_selectedAccountId, userId, values),
    );
  }

  Future<void> _removeMember(String userId) async {
    await _mutate((api) => api.removeMember(_selectedAccountId, userId));
  }

  Future<Map<String, dynamic>> _validatePolicy(Map<String, Object?> values) {
    return _client().validatePolicy(_selectedAccountId, values);
  }

  Future<Map<String, dynamic>> _previewPolicy(Map<String, Object?> values) {
    return _client().previewPolicy(_selectedAccountId, values);
  }

  Future<Map<String, dynamic>> _runPolicyTests() {
    return _client().runPolicyTests(_selectedAccountId);
  }

  Future<void> _savePolicy(Map<String, Object?> values) async {
    await _mutate((api) => api.savePolicy(_selectedAccountId, values));
  }

  Future<void> _updateDns(Map<String, Object?> values) async {
    await _mutate((api) => api.updateDns(_selectedAccountId, values));
  }

  Future<void> _upsertNameserver(String id, Map<String, Object?> values) async {
    await _mutate(
      (api) => api.upsertNameserver(_selectedAccountId, id, values),
    );
  }

  Future<void> _deleteNameserver(String id) async {
    await _mutate((api) => api.deleteNameserver(_selectedAccountId, id));
  }

  Future<void> _upsertSearchDomain(
    String id,
    Map<String, Object?> values,
  ) async {
    await _mutate(
      (api) => api.upsertSearchDomain(_selectedAccountId, id, values),
    );
  }

  Future<void> _deleteSearchDomain(String id) async {
    await _mutate((api) => api.deleteSearchDomain(_selectedAccountId, id));
  }

  Future<void> _updateFlowSettings(Map<String, Object?> values) async {
    await _mutate(
      (api) => api.updateFlowLogSettings(_selectedAccountId, values),
    );
  }

  Future<void> _saveLogStream(String id, Map<String, Object?> values) async {
    await _mutate((api) => api.upsertLogStream(_selectedAccountId, id, values));
  }

  Future<void> _deleteLogStream(String id) async {
    await _mutate((api) => api.deleteLogStream(_selectedAccountId, id));
  }

  void _setSettingsDetail(String detail) {
    setState(() => _settingsDetail = detail);
    runtime.pushAdminPath([AdminSection.settings.slug, detail]);
  }

  Future<void> _changePlan(String planId, String billingPeriod) async {
    if (planId.trim().toLowerCase() == 'community') {
      await _mutate(
        (api) => api.changeBillingPlan(
          accountId: _selectedAccountId,
          planId: planId,
          billingPeriod: billingPeriod,
        ),
      );
      return;
    }

    try {
      final checkout = await _client().createBillingCheckout(
        accountId: _selectedAccountId,
        planId: planId,
        billingPeriod: billingPeriod,
      );
      runtime.writeStoredCheckoutID(checkout.id);
      if (checkout.confirmationUrl.trim().isNotEmpty) {
        runtime.redirectTo(checkout.confirmationUrl.trim());
        return;
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _alert =
            'Checkout ${checkout.id} создан. Ожидается подтверждение оплаты.';
      });
      await _loadAll();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _alert = 'Не удалось создать checkout: $error');
    }
  }

  Future<void> _saveTrustCredential(
    String id,
    Map<String, Object?> values,
  ) async {
    await _mutate((api) async {
      if (id.isEmpty) {
        await api.createTrustCredential(_selectedAccountId, values);
      } else {
        await api.updateTrustCredential(_selectedAccountId, id, values);
      }
    });
  }

  Future<void> _deleteTrustCredential(String id) async {
    await _mutate((api) => api.deleteTrustCredential(_selectedAccountId, id));
  }

  Future<void> _saveWebhook(String id, Map<String, Object?> values) async {
    await _mutate((api) async {
      if (id.isEmpty) {
        await api.createWebhook(_selectedAccountId, values);
      } else {
        await api.updateWebhook(_selectedAccountId, id, values);
      }
    });
  }

  Future<void> _deleteWebhook(String id) async {
    await _mutate((api) => api.deleteWebhook(_selectedAccountId, id));
  }

  Future<void> _testWebhook(String id) async {
    await _mutate((api) => api.testWebhook(_selectedAccountId, id));
  }

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      section: _section,
      accounts: _accounts,
      selectedAccountId: _selectedAccountId,
      user: _me,
      planLabel: _planLabel,
      onSectionSelected: _setSection,
      onAccountSelected: _setAccount,
      onPersonalSettings: _openPersonalSettings,
      onLogout: _logout,
      themeMode: widget.themeMode,
      onThemeModeChanged: widget.onThemeModeChanged,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_loading) const LinearProgressIndicator(minHeight: 2),
          if (_alert != null) _AlertBanner(message: _alert!),
          Expanded(child: _buildSection()),
        ],
      ),
    );
  }

  Widget _buildSection() {
    return switch (_section) {
      AdminSection.machines => MachinesScreen(
        machines: _machines,
        machinesLoaded: _machinesLoaded,
        isLoading: _loading,
        networks: _networks,
        apiBaseUrl: _apiBase,
        canMutate: _canMutate,
        selectedMachineId: _selectedMachineId,
        onMachineSelected: _selectMachine,
        onRefresh: _refreshMachines,
        onCreateJoinToken: _createJoinToken,
        onCreateNetwork: _createNetwork,
        onUpdateMachine: _updateMachine,
        onDeleteMachine: _deleteMachine,
      ),
      AdminSection.apps => AppsScreen(
        apps: _apps,
        canMutate: _canMutate,
        onSave: _saveApp,
        onDelete: _deleteApp,
      ),
      AdminSection.services => ServicesScreen(
        services: _services,
        canMutate: _canMutate,
        onSave: _saveService,
        onDelete: _deleteService,
      ),
      AdminSection.users => UsersScreen(
        members: _members,
        canMutate: _canMutate,
        onInvite: _inviteMember,
        onUpdate: _updateMember,
        onRemove: _removeMember,
      ),
      AdminSection.accessControls => AccessControlsScreen(
        policy: _policy,
        canMutate: _canMutate,
        onValidate: _validatePolicy,
        onPreview: _previewPolicy,
        onRunTests: _runPolicyTests,
        onSave: _savePolicy,
      ),
      AdminSection.logs => LogsScreen(
        auditEvents: _auditEvents,
        logStreams: _logStreams,
        canMutate: _canMutate,
        onUpdateFlowSettings: _updateFlowSettings,
        onSaveLogStream: _saveLogStream,
        onDeleteLogStream: _deleteLogStream,
      ),
      AdminSection.dns => DnsScreen(
        settings: _dnsSettings,
        canMutate: _canMutate,
        onUpdateSettings: _updateDns,
        onUpsertNameserver: _upsertNameserver,
        onDeleteNameserver: _deleteNameserver,
        onUpsertSearchDomain: _upsertSearchDomain,
        onDeleteSearchDomain: _deleteSearchDomain,
      ),
      AdminSection.settings => SettingsScreen(
        user: _me,
        account: _selectedAccount,
        subscription: _subscription,
        usage: _usage,
        invoices: _invoices,
        license: _license,
        billingPlans: _billingPlans,
        trustCredentials: _trustCredentials,
        webhooks: _webhooks,
        detail: _settingsDetail,
        canMutate: _canMutate,
        onDetailSelected: _setSettingsDetail,
        onUpdateAccount: _updateAccount,
        onChangePlan: _changePlan,
        onSaveTrustCredential: _saveTrustCredential,
        onDeleteTrustCredential: _deleteTrustCredential,
        onSaveWebhook: _saveWebhook,
        onDeleteWebhook: _deleteWebhook,
        onTestWebhook: _testWebhook,
      ),
      AdminSection.resourceHub => ResourceHubScreen(
        account: _selectedAccount,
        networks: _networks,
        apiBaseUrl: _apiBase,
        canMutate: _canMutate,
        onCreateJoinToken: (mode, networkId, networkName) =>
            _createJoinTokenPayload(mode, networkId, networkName),
        onRevokeJoinToken: _revokeJoinToken,
      ),
    };
  }
}

class _AlertBanner extends StatelessWidget {
  const _AlertBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = context.adminColors;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.danger.withValues(alpha: .08),
        border: Border.all(color: colors.danger.withValues(alpha: .34)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline_rounded, color: colors.danger),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message, style: TextStyle(color: colors.danger)),
          ),
        ],
      ),
    );
  }
}
