import 'dart:async';

import 'package:flutter/material.dart';

import '../../components.dart';
import '../../models.dart';
import '../../theme.dart';
import '../resource_hub/windows_enrollment.dart';

const machinesRefreshInterval = Duration(seconds: 10);

class MachinesScreen extends StatefulWidget {
  const MachinesScreen({
    super.key,
    required this.machines,
    required this.machinesLoaded,
    required this.isLoading,
    required this.networks,
    required this.apiBaseUrl,
    required this.canMutate,
    required this.selectedMachineId,
    required this.onMachineSelected,
    required this.onRefresh,
    required this.onCreateJoinToken,
    required this.onCreateNetwork,
    required this.onUpdateMachine,
    required this.onDeleteMachine,
    this.refreshInterval = machinesRefreshInterval,
  }) : assert(refreshInterval > Duration.zero);

  final List<MachineModel> machines;
  final bool machinesLoaded;
  final bool isLoading;
  final List<NetworkModel> networks;
  final String apiBaseUrl;
  final bool canMutate;
  final String selectedMachineId;
  final ValueChanged<String> onMachineSelected;
  final Future<void> Function() onRefresh;
  final Future<String?> Function() onCreateJoinToken;
  final Future<void> Function(Map<String, Object?> values) onCreateNetwork;
  final Future<void> Function(String id, Map<String, Object?> values)
  onUpdateMachine;
  final Future<void> Function(String id) onDeleteMachine;
  final Duration refreshInterval;

  @override
  State<MachinesScreen> createState() => _MachinesScreenState();
}

class _MachinesScreenState extends State<MachinesScreen> {
  final _filter = TextEditingController();
  String _query = '';
  String? _lastJoinToken;
  Timer? _refreshTimer;
  bool _refreshInFlight = false;

  @override
  void initState() {
    super.initState();
    _startRefreshTimer();
  }

  @override
  void didUpdateWidget(covariant MachinesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshInterval != widget.refreshInterval) {
      _startRefreshTimer();
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _filter.dispose();
    super.dispose();
  }

  void _startRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(
      widget.refreshInterval,
      (_) => unawaited(_refresh()),
    );
  }

  Future<void> _refresh() async {
    if (_refreshInFlight) {
      return;
    }
    _refreshInFlight = true;
    try {
      await widget.onRefresh();
    } finally {
      _refreshInFlight = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final machines = widget.machines
        .where((machine) {
          final text = [
            machine.hostname,
            machine.ownerEmail,
            machine.networkName,
            machine.assignedIp,
            machine.assignedIpv6,
            machine.endpoint,
            machine.endpointCandidates.join(' '),
            machine.status,
            machine.os,
            machine.clientVersion,
            machine.tags.join(' '),
          ].join(' ').toLowerCase();
          return _query.isEmpty || text.contains(_query.toLowerCase());
        })
        .toList(growable: false);
    MachineModel? selected;
    for (final machine in widget.machines) {
      if (machine.id == widget.selectedMachineId) {
        selected = machine;
        break;
      }
    }
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        SectionHeader(
          title: 'Устройства',
          subtitle:
              'Узлы, опубликованные эндпоинты, адреса, маршруты, теги, срок действия ключей и состояние подключения.',
          actions: [
            if (widget.canMutate)
              FilledButton.icon(
                onPressed: () async {
                  final token = await widget.onCreateJoinToken();
                  if (!mounted || token == null) {
                    return;
                  }
                  setState(() => _lastJoinToken = token);
                },
                icon: const Icon(Icons.add_rounded),
                label: const Text('Добавить устройство'),
              ),
            if (widget.canMutate)
              OutlinedButton.icon(
                onPressed: () => _createNetwork(context),
                icon: const Icon(Icons.hub_rounded),
                label: const Text('Создать сеть'),
              ),
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.download_rounded),
              label: const Text('Экспорт'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (widget.networks.isNotEmpty) ...[
          SurfacePanel(
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final network in widget.networks)
                  StatusPill(label: '${network.name} ${network.cidr}'),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        FilterBar(
          controller: _filter,
          hint: 'Поиск по имени, владельцу, тегу, IP, версии или сети',
          onChanged: (value) => setState(() => _query = value),
        ),
        const SizedBox(height: 16),
        if (_lastJoinToken != null)
          _AddDevicePanel(
            joinToken: _lastJoinToken!,
            apiBaseUrl: widget.apiBaseUrl,
          ),
        if (_lastJoinToken != null) const SizedBox(height: 16),
        if (!widget.machinesLoaded && widget.isLoading)
          const SurfacePanel(
            child: SizedBox(
              height: 144,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 14),
                    Text('Загрузка устройств…'),
                  ],
                ),
              ),
            ),
          )
        else if (!widget.machinesLoaded)
          const EmptyState(
            icon: Icons.error_outline_rounded,
            title: 'Список устройств не загружен',
            detail:
                'Не удалось получить список устройств. Данные будут запрошены повторно автоматически.',
          )
        else if (machines.isEmpty)
          const EmptyState(
            icon: Icons.dns_rounded,
            title: 'Нет устройств',
            detail:
                'Создайте краткосрочный токен подключения и выполните команду установки на устройстве.',
          )
        else
          SurfacePanel(
            padding: EdgeInsets.zero,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                showCheckboxColumn: true,
                columns: const [
                  DataColumn(label: Text('Устройство')),
                  DataColumn(label: Text('Владелец')),
                  DataColumn(label: Text('Сеть')),
                  DataColumn(label: Text('Адреса')),
                  DataColumn(label: Text('Эндпоинты')),
                  DataColumn(label: Text('Версия')),
                  DataColumn(label: Text('Статус')),
                  DataColumn(label: Text('Последняя активность')),
                  DataColumn(label: Text('Теги')),
                ],
                rows: [
                  for (final machine in machines)
                    DataRow(
                      selected: machine.id == selected?.id,
                      onSelectChanged: (_) =>
                          widget.onMachineSelected(machine.id),
                      cells: [
                        DataCell(
                          Text(
                            machine.hostname.isEmpty
                                ? machine.id
                                : machine.hostname,
                          ),
                        ),
                        DataCell(
                          Text(
                            machine.ownerEmail.isEmpty
                                ? machine.userId
                                : machine.ownerEmail,
                          ),
                        ),
                        DataCell(Text(machine.networkName)),
                        DataCell(
                          Text(
                            [
                              machine.assignedIp,
                              machine.assignedIpv6,
                            ].where((item) => item.isNotEmpty).join('\n'),
                          ),
                        ),
                        DataCell(_EndpointSummary(publication: machine)),
                        DataCell(
                          Text(
                            machine.clientVersion.isEmpty
                                ? '-'
                                : machine.clientVersion,
                          ),
                        ),
                        DataCell(
                          StatusPill(
                            label: machine.status.isEmpty
                                ? 'неизвестно'
                                : statusLabel(machine.status),
                            tone: machine.status == 'online'
                                ? StatusTone.good
                                : StatusTone.neutral,
                          ),
                        ),
                        DataCell(Text(formatDate(machine.lastSeen))),
                        DataCell(
                          Text(
                            machine.tags.isEmpty
                                ? '-'
                                : machine.tags.join(', '),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        if (selected != null) ...[
          const SizedBox(height: 16),
          _MachineDetail(
            machine: selected,
            canMutate: widget.canMutate,
            onUpdate: (values) => widget.onUpdateMachine(selected!.id, values),
            onDelete: () => widget.onDeleteMachine(selected!.id),
          ),
        ],
      ],
    );
  }

  Future<void> _createNetwork(BuildContext context) async {
    final name = TextEditingController();
    final cidr = TextEditingController(text: '100.64.0.0/24');
    final dns = TextEditingController();
    final values = await showDialog<Map<String, Object?>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Создать сеть'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Название'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: cidr,
                decoration: const InputDecoration(labelText: 'IPv4 CIDR'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: dns,
                decoration: const InputDecoration(
                  labelText: 'DNS-резолверы',
                  hintText: '1.1.1.1, 8.8.8.8',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, {
              'name': name.text.trim(),
              'cidr': cidr.text.trim(),
              'dns': _csv(dns.text),
            }),
            child: const Text('Создать'),
          ),
        ],
      ),
    );
    name.dispose();
    cidr.dispose();
    dns.dispose();
    if (values != null) {
      await widget.onCreateNetwork(values);
    }
  }
}

class _MachineDetail extends StatelessWidget {
  const _MachineDetail({
    required this.machine,
    required this.canMutate,
    required this.onUpdate,
    required this.onDelete,
  });

  final MachineModel machine;
  final bool canMutate;
  final Future<void> Function(Map<String, Object?> values) onUpdate;
  final Future<void> Function() onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.adminColors;
    final rows = {
      'ID узла': machine.id,
      'Отпечаток публичного ключа': shortText(machine.publicKey, 30),
      'Ключ идентичности': shortText(machine.identityPublicKey, 30),
      'Назначенный IPv4': machine.assignedIp,
      'Назначенный IPv6': machine.assignedIpv6,
      'Объявленные маршруты': machine.advertisedIps.join(', '),
      'Срок действия ключа': boolLabel(machine.keyExpiryEnabled),
      'Одобрение': machine.approvalState.isEmpty
          ? 'ожидает'
          : statusLabel(machine.approvalState),
      'ОС / платформа': [
        machine.os,
        machine.platform,
      ].where((item) => item.isNotEmpty).join(' / '),
    };
    return SurfacePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  machine.hostname,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              CopyButton(value: machine.id, tooltip: 'Копировать ID узла'),
              if (canMutate)
                PopupMenuButton<String>(
                  onSelected: (value) => _handleAction(context, value),
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'rename',
                      child: Text('Изменить имя устройства'),
                    ),
                    PopupMenuItem(
                      value: 'routes',
                      child: Text('Изменить маршруты'),
                    ),
                    PopupMenuItem(
                      value: 'tags',
                      child: Text('Изменить ACL-теги'),
                    ),
                    PopupMenuItem(
                      value: 'expiry',
                      child: Text('Включить или выключить срок ключа'),
                    ),
                    PopupMenuItem(
                      value: 'remove',
                      child: Text('Удалить устройство'),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 18,
            runSpacing: 12,
            children: [
              for (final entry in rows.entries)
                SizedBox(
                  width: 260,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.key,
                        style: TextStyle(
                          color: colors.muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      SelectableText(entry.value.isEmpty ? '-' : entry.value),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
          _EndpointPublicationDetail(publication: machine),
        ],
      ),
    );
  }

  Future<void> _handleAction(BuildContext context, String value) async {
    switch (value) {
      case 'rename':
        await _editText(
          context,
          'Изменить имя устройства',
          'Имя хоста',
          machine.hostname,
          (text) => onUpdate({'hostname': text}),
        );
      case 'routes':
        await _editText(
          context,
          'Изменить маршруты',
          'Объявленные маршруты',
          machine.advertisedIps.join(', '),
          (text) => onUpdate({'advertised_ips': _csv(text)}),
        );
      case 'tags':
        await _editText(
          context,
          'Изменить ACL-теги',
          'Теги',
          machine.tags.join(', '),
          (text) => onUpdate({'tags': _csv(text)}),
        );
      case 'expiry':
        await onUpdate({'key_expiry_enabled': !machine.keyExpiryEnabled});
      case 'remove':
        final ok = await confirmDestructive(
          context,
          title: 'Удалить устройство',
          message: 'Удалить ${machine.hostname} из этой сети?',
        );
        if (ok) {
          await onDelete();
        }
    }
  }

  Future<void> _editText(
    BuildContext context,
    String title,
    String label,
    String initial,
    Future<void> Function(String value) save,
  ) async {
    final controller = TextEditingController(text: initial);
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(labelText: label),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value != null) {
      await save(value);
    }
  }
}

class _EndpointSummary extends StatelessWidget {
  const _EndpointSummary({required this.publication});

  final EndpointPublicationModel publication;

  @override
  Widget build(BuildContext context) {
    final colors = context.adminColors;
    final endpoints = publication.publishedEndpoints;
    if (endpoints.isEmpty) {
      return Semantics(
        label: 'Опубликованные эндпоинты отсутствуют',
        child: const Text('-'),
      );
    }

    final expired = publication.endpointPublicationIsExpiredAt(DateTime.now());
    PublishedEndpoint? primary;
    for (final endpoint in endpoints) {
      if (endpoint.isPrimary) {
        primary = endpoint;
        break;
      }
    }
    final candidateCount = endpoints.length - (primary == null ? 0 : 1);
    final status = expired
        ? 'истекли · ${endpoints.length}'
        : primary == null
        ? '$candidateCount кандид.'
        : candidateCount == 0
        ? 'основной'
        : 'основной · +$candidateCount';
    final semanticLabel = _endpointDescription(publication, expired: expired);

    return Tooltip(
      message: semanticLabel,
      child: Semantics(
        container: true,
        label: semanticLabel,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              shortText((primary ?? endpoints.first).value, 30),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontFamily: 'monospace'),
            ),
            const SizedBox(height: 2),
            Text(
              status,
              maxLines: 1,
              style: TextStyle(
                color: expired ? colors.amber : colors.muted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EndpointPublicationDetail extends StatelessWidget {
  const _EndpointPublicationDetail({required this.publication});

  final EndpointPublicationModel publication;

  @override
  Widget build(BuildContext context) {
    final colors = context.adminColors;
    final endpoints = publication.publishedEndpoints;
    final expired = publication.endpointPublicationIsExpiredAt(DateTime.now());
    final statusLabel = endpoints.isEmpty
        ? 'нет данных'
        : expired
        ? 'истекло'
        : 'опубликовано';
    final statusTone = endpoints.isEmpty
        ? StatusTone.neutral
        : expired
        ? StatusTone.warn
        : StatusTone.good;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Divider(color: colors.line),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              'Опубликованные эндпоинты',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            StatusPill(label: statusLabel, tone: statusTone),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Адреса, опубликованные сервером для подключения к устройству. '
          'Кандидаты не означают путь, выбранный клиентом.',
          style: TextStyle(color: colors.muted, height: 1.4),
        ),
        if (expired) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.amber.withValues(alpha: .08),
              border: Border.all(color: colors.amber.withValues(alpha: .32)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'Срок публикации истёк. Адреса ниже показаны только для диагностики и не считаются актуальными.',
              style: TextStyle(
                color: colors.amber,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
        const SizedBox(height: 12),
        if (endpoints.isEmpty)
          Text(
            'Нет опубликованных эндпоинтов.',
            style: TextStyle(color: colors.muted),
          )
        else
          Column(
            children: [
              for (final endpoint in endpoints)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Semantics(
                    container: true,
                    label:
                        '${endpoint.isPrimary ? 'Основной эндпоинт' : 'Кандидат эндпоинта'}: ${endpoint.value}',
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(10, 6, 4, 6),
                      decoration: BoxDecoration(
                        color: colors.surfaceAlt,
                        border: Border.all(color: colors.line),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 86,
                            child: Text(
                              endpoint.isPrimary ? 'Основной' : 'Кандидат',
                              style: TextStyle(
                                color: endpoint.isPrimary
                                    ? colors.blue
                                    : colors.muted,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: SelectableText(
                              endpoint.value,
                              style: const TextStyle(fontFamily: 'monospace'),
                            ),
                          ),
                          CopyButton(
                            value: endpoint.value,
                            tooltip: 'Копировать эндпоинт',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        if (publication.endpointGeneration != null ||
            publication.endpointExpiresAt != null) ...[
          const SizedBox(height: 4),
          Wrap(
            spacing: 24,
            runSpacing: 10,
            children: [
              if (publication.endpointGeneration != null)
                _EndpointDiagnostic(
                  label: 'Поколение публикации',
                  value: '${publication.endpointGeneration}',
                ),
              if (publication.endpointExpiresAt != null)
                _EndpointDiagnostic(
                  label: 'Действительны до',
                  value: formatDate(publication.endpointExpiresAt),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _EndpointDiagnostic extends StatelessWidget {
  const _EndpointDiagnostic({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.adminColors;
    return SizedBox(
      width: 220,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: colors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          SelectableText(value),
        ],
      ),
    );
  }
}

String _endpointDescription(
  EndpointPublicationModel publication, {
  required bool expired,
}) {
  final lines = <String>[
    if (expired) 'Публикация истекла',
    for (final endpoint in publication.publishedEndpoints)
      '${endpoint.isPrimary ? 'Основной' : 'Кандидат'}: ${endpoint.value}',
    if (publication.endpointGeneration != null)
      'Поколение: ${publication.endpointGeneration}',
    if (publication.endpointExpiresAt != null)
      'Действительны до: ${formatDate(publication.endpointExpiresAt)}',
  ];
  return lines.join('\n');
}

class _AddDevicePanel extends StatelessWidget {
  const _AddDevicePanel({required this.joinToken, required this.apiBaseUrl});

  final String joinToken;
  final String apiBaseUrl;

  @override
  Widget build(BuildContext context) {
    final colors = context.adminColors;
    final shellJoinToken = _shellSingle(joinToken);
    final commands = {
      'Linux-сервер':
          'curl -fsSL https://endlessnet.ru/install.sh | sh -s -- --join-token $shellJoinToken',
      'Рабочая станция macOS / Linux':
          'curl -fsSL https://endlessnet.ru/install.sh | sh -s -- --join-token $shellJoinToken',
      'Windows': windowsEnrollmentCommand(
        installScriptUrl: 'https://endlessnet.ru/install.ps1',
        serverUrl: apiBaseUrl,
        enrollToken: joinToken,
        mode: 'workstation',
      ),
      'Docker':
          'docker run --cap-add NET_ADMIN -e ENDLESSNET_JOIN_TOKEN=$joinToken ghcr.io/unlisted/endlessnet-client:latest',
      'Kubernetes':
          'kubectl create secret generic endlessnet-join --from-literal=join-token=$joinToken',
      'WireGuard вручную':
          'Сгенерируйте на целевом устройстве; приватные ключи здесь не хранятся и не показываются.',
    };
    return SurfacePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Добавить устройство',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 6),
          Text(
            'Токен подключения показывается один раз. Команды не содержат токены сессии или приватные ключи.',
            style: TextStyle(color: colors.muted),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final entry in commands.entries)
                SizedBox(
                  width: 360,
                  child: SurfacePanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                entry.key,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            CopyButton(
                              value: entry.value,
                              tooltip: 'Копировать команду',
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SelectableText(
                          entry.value,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

String _shellSingle(String value) => "'${value.replaceAll("'", "'\"'\"'")}'";

List<String> _csv(String value) {
  return value
      .split(',')
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
}
