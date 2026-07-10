import 'package:flutter/material.dart';

import '../../components.dart';
import '../../models.dart';
import '../../theme.dart';

class DnsScreen extends StatelessWidget {
  const DnsScreen({
    super.key,
    required this.settings,
    required this.canMutate,
    required this.onUpdateSettings,
    required this.onUpsertNameserver,
    required this.onDeleteNameserver,
    required this.onUpsertSearchDomain,
    required this.onDeleteSearchDomain,
  });

  final DnsSettingsModel? settings;
  final bool canMutate;
  final Future<void> Function(Map<String, Object?> values) onUpdateSettings;
  final Future<void> Function(String id, Map<String, Object?> values)
  onUpsertNameserver;
  final Future<void> Function(String id) onDeleteNameserver;
  final Future<void> Function(String id, Map<String, Object?> values)
  onUpsertSearchDomain;
  final Future<void> Function(String id) onDeleteSearchDomain;

  @override
  Widget build(BuildContext context) {
    final dns = settings;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        SectionHeader(
          title: 'DNS',
          subtitle:
              'Суффикс tailnet, DNS-серверы, split DNS, поисковые домены, MagicDNS и управление HTTPS-сертификатами.',
          actions: [
            if (canMutate)
              FilledButton.icon(
                onPressed: () => _editSettings(context, dns),
                icon: const Icon(Icons.edit_rounded),
                label: const Text('Изменить DNS'),
              ),
            if (canMutate)
              OutlinedButton.icon(
                onPressed: () => _editNameserver(context),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Добавить DNS-сервер'),
              ),
          ],
        ),
        const SizedBox(height: 16),
        SurfacePanel(
          child: Wrap(
            spacing: 24,
            runSpacing: 18,
            children: [
              _Metric(label: 'DNS-суффикс', value: dns?.suffix ?? '-'),
              _Metric(
                label: 'MagicDNS',
                value: boolLabel(dns?.magicDnsEnabled == true),
              ),
              _Metric(
                label: 'HTTPS-сертификаты',
                value: boolLabel(dns?.httpsCertsEnabled == true),
              ),
              _Metric(
                label: 'DNS-серверы',
                value: (dns?.nameservers.length ?? 0).toString(),
              ),
              _Metric(
                label: 'Поисковые домены',
                value: (dns?.searchDomains.length ?? 0).toString(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SurfacePanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'DNS-серверы',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  if (canMutate)
                    TextButton.icon(
                      onPressed: () => _editNameserver(context),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Добавить'),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              if (dns == null || dns.nameservers.isEmpty)
                const Text('DNS-серверы не настроены')
              else
                for (final nameserver in dns.nameservers)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(nameserver.address),
                    subtitle: Text(
                      [
                        nameserver.scope.isEmpty ? 'global' : nameserver.scope,
                        'приоритет ${nameserver.priority}',
                        boolLabel(nameserver.enabled),
                        if (nameserver.splitDomains.isNotEmpty)
                          nameserver.splitDomains.join(', '),
                      ].join(' / '),
                    ),
                    trailing: canMutate
                        ? Wrap(
                            spacing: 4,
                            children: [
                              IconButton(
                                tooltip: 'Изменить DNS-сервер',
                                onPressed: () =>
                                    _editNameserver(context, nameserver),
                                icon: const Icon(Icons.edit_rounded),
                              ),
                              IconButton(
                                tooltip: 'Удалить DNS-сервер',
                                onPressed: () =>
                                    _deleteNameserver(context, nameserver),
                                icon: const Icon(Icons.delete_outline_rounded),
                              ),
                            ],
                          )
                        : null,
                  ),
              const Divider(height: 28),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Поисковые домены',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  if (canMutate)
                    TextButton.icon(
                      onPressed: () => _editSearchDomain(context),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Добавить'),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              if (dns == null || dns.searchDomains.isEmpty)
                const Text('Поисковые домены не настроены')
              else
                for (final domain in dns.searchDomains)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(domain.domain),
                    trailing: canMutate
                        ? Wrap(
                            spacing: 4,
                            children: [
                              IconButton(
                                tooltip: 'Изменить поисковый домен',
                                onPressed: () =>
                                    _editSearchDomain(context, domain),
                                icon: const Icon(Icons.edit_rounded),
                              ),
                              IconButton(
                                tooltip: 'Удалить поисковый домен',
                                onPressed: () =>
                                    _deleteSearchDomain(context, domain),
                                icon: const Icon(Icons.delete_outline_rounded),
                              ),
                            ],
                          )
                        : null,
                  ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _editSettings(
    BuildContext context,
    DnsSettingsModel? dns,
  ) async {
    final suffix = TextEditingController(text: dns?.suffix ?? '');
    var magicDns = dns?.magicDnsEnabled ?? true;
    var https = dns?.httpsCertsEnabled ?? false;
    final saved = await showDialog<Map<String, Object?>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Изменить настройки DNS'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: suffix,
                  decoration: const InputDecoration(labelText: 'DNS-суффикс'),
                ),
                SwitchListTile(
                  value: magicDns,
                  onChanged: (value) => setState(() => magicDns = value),
                  title: const Text('MagicDNS'),
                ),
                SwitchListTile(
                  value: https,
                  onChanged: (value) => setState(() => https = value),
                  title: const Text('HTTPS-сертификаты'),
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
                'suffix': suffix.text.trim(),
                'magicdns_enabled': magicDns,
                'https_certs_enabled': https,
              }),
              child: const Text('Сохранить'),
            ),
          ],
        ),
      ),
    );
    suffix.dispose();
    if (saved != null) {
      await onUpdateSettings(saved);
    }
  }

  Future<void> _editNameserver([
    BuildContext? context,
    DnsNameserverModel? nameserver,
  ]) async {
    final dialogContext = context;
    if (dialogContext == null) {
      return;
    }
    final address = TextEditingController(text: nameserver?.address ?? '');
    final scope = TextEditingController(text: nameserver?.scope ?? 'global');
    final split = TextEditingController(
      text: nameserver?.splitDomains.join(', ') ?? '',
    );
    final priority = TextEditingController(
      text: (nameserver?.priority ?? 100).toString(),
    );
    var enabled = nameserver?.enabled ?? true;
    final saved = await showDialog<Map<String, Object?>>(
      context: dialogContext,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(
            nameserver == null ? 'Добавить DNS-сервер' : 'Изменить DNS-сервер',
          ),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: address,
                  decoration: const InputDecoration(labelText: 'Адрес'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: scope,
                  decoration: const InputDecoration(labelText: 'Область'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: split,
                  decoration: const InputDecoration(
                    labelText: 'Split-домены',
                    hintText: 'corp.example, svc.internal',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: priority,
                  decoration: const InputDecoration(labelText: 'Приоритет'),
                  keyboardType: TextInputType.number,
                ),
                SwitchListTile(
                  value: enabled,
                  onChanged: (value) => setState(() => enabled = value),
                  title: const Text('Включено'),
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
              onPressed: () {
                if (address.text.trim().isEmpty) {
                  return;
                }
                Navigator.pop(context, {
                  'address': address.text.trim(),
                  'scope': scope.text.trim(),
                  'split_domains': _csv(split.text),
                  'priority': int.tryParse(priority.text.trim()) ?? 100,
                  'enabled': enabled,
                });
              },
              child: const Text('Сохранить'),
            ),
          ],
        ),
      ),
    );
    address.dispose();
    scope.dispose();
    split.dispose();
    priority.dispose();
    if (saved != null) {
      await onUpsertNameserver(nameserver?.id ?? '', saved);
    }
  }

  Future<void> _deleteNameserver(
    BuildContext context,
    DnsNameserverModel nameserver,
  ) async {
    final ok = await confirmDestructive(
      context,
      title: 'Удалить DNS-сервер',
      message: 'Удалить ${nameserver.address} из настроек DNS?',
    );
    if (ok) {
      await onDeleteNameserver(nameserver.id);
    }
  }

  Future<void> _editSearchDomain([
    BuildContext? context,
    DnsSearchDomainModel? domain,
  ]) async {
    final dialogContext = context;
    if (dialogContext == null) {
      return;
    }
    final controller = TextEditingController(text: domain?.domain ?? '');
    final saved = await showDialog<String>(
      context: dialogContext,
      builder: (context) => AlertDialog(
        title: Text(
          domain == null
              ? 'Добавить поисковый домен'
              : 'Изменить поисковый домен',
        ),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Домен'),
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
    if (saved != null && saved.isNotEmpty) {
      await onUpsertSearchDomain(domain?.id ?? '', {'domain': saved});
    }
  }

  Future<void> _deleteSearchDomain(
    BuildContext context,
    DnsSearchDomainModel domain,
  ) async {
    final ok = await confirmDestructive(
      context,
      title: 'Удалить поисковый домен',
      message: 'Удалить ${domain.domain} из поисковых доменов DNS?',
    );
    if (ok) {
      await onDeleteSearchDomain(domain.id);
    }
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

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
            style: TextStyle(color: colors.muted, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}

List<String> _csv(String value) {
  return value
      .split(',')
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
}
