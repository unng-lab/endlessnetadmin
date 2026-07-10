import 'package:flutter/material.dart';

import '../../components.dart';
import '../../models.dart';

class ServicesScreen extends StatelessWidget {
  const ServicesScreen({
    super.key,
    required this.services,
    required this.canMutate,
    required this.onSave,
    required this.onDelete,
  });

  final List<ServiceModel> services;
  final bool canMutate;
  final Future<void> Function(String id, Map<String, Object?> values) onSave;
  final Future<void> Function(String id) onDelete;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        SectionHeader(
          title: 'Сервисы',
          subtitle:
              'Объявленные сервисы и обнаруженные эндпоинты внутри сетей EndlessNet.',
          actions: [
            if (canMutate)
              FilledButton.icon(
                onPressed: () => _editService(context),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Описать сервис'),
              ),
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.sensors_rounded),
              label: const Text('Сбор эндпоинтов'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (services.isEmpty)
          const EmptyState(
            icon: Icons.router_rounded,
            title: 'Нет объявленных сервисов',
            detail:
                'Задайте порты, DNS-имена, теги и правила одобрения хостов для внутреннего сервиса.',
          )
        else
          SurfacePanel(
            padding: EdgeInsets.zero,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Сервис')),
                  DataColumn(label: Text('DNS-имя')),
                  DataColumn(label: Text('Порты')),
                  DataColumn(label: Text('Теги')),
                  DataColumn(label: Text('Хосты')),
                  DataColumn(label: Text('Одобрение')),
                  DataColumn(label: Text('Состояние')),
                  DataColumn(label: Text('Действия')),
                ],
                rows: [
                  for (final service in services)
                    DataRow(
                      cells: [
                        DataCell(Text(service.name)),
                        DataCell(Text(service.dnsName)),
                        DataCell(Text(service.ports.join(', '))),
                        DataCell(Text(service.tags.join(', '))),
                        DataCell(Text(service.hostCount.toString())),
                        DataCell(
                          StatusPill(
                            label: service.approvalStatus.isEmpty
                                ? 'ожидает'
                                : statusLabel(service.approvalStatus),
                            tone: service.approvalStatus == 'approved'
                                ? StatusTone.good
                                : StatusTone.warn,
                          ),
                        ),
                        DataCell(
                          StatusPill(
                            label: service.health.isEmpty
                                ? 'неизвестно'
                                : statusLabel(service.health),
                            tone: service.health == 'healthy'
                                ? StatusTone.good
                                : StatusTone.neutral,
                          ),
                        ),
                        DataCell(
                          canMutate
                              ? Wrap(
                                  spacing: 4,
                                  children: [
                                    IconButton(
                                      tooltip: 'Изменить сервис',
                                      onPressed: () =>
                                          _editService(context, service),
                                      icon: const Icon(Icons.edit_rounded),
                                    ),
                                    IconButton(
                                      tooltip: 'Удалить сервис',
                                      onPressed: () =>
                                          _deleteService(context, service),
                                      icon: const Icon(
                                        Icons.delete_outline_rounded,
                                      ),
                                    ),
                                  ],
                                )
                              : const Text('-'),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _editService(
    BuildContext context, [
    ServiceModel? service,
  ]) async {
    final name = TextEditingController(text: service?.name ?? '');
    final dns = TextEditingController(text: service?.dnsName ?? '');
    final ports = TextEditingController(text: service?.ports.join(', ') ?? '');
    final tags = TextEditingController(text: service?.tags.join(', ') ?? '');
    final saved = await showDialog<Map<String, Object?>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(service == null ? 'Описать сервис' : 'Изменить сервис'),
        content: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Название'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: dns,
                decoration: const InputDecoration(labelText: 'DNS-имя'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: ports,
                decoration: const InputDecoration(
                  labelText: 'Порты',
                  hintText: 'tcp:443, udp:53',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: tags,
                decoration: const InputDecoration(labelText: 'Теги'),
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
              'dns_name': dns.text.trim(),
              'ports': _ports(ports.text),
              'tags': _csv(tags.text),
              'approval_mode': service?.approvalStatus ?? 'manual',
              'health': service?.health ?? 'unknown',
            }),
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
    name.dispose();
    dns.dispose();
    ports.dispose();
    tags.dispose();
    if (saved != null) {
      await onSave(service?.id ?? '', saved);
    }
  }

  Future<void> _deleteService(
    BuildContext context,
    ServiceModel service,
  ) async {
    final ok = await confirmDestructive(
      context,
      title: 'Удалить сервис',
      message: 'Удалить ${service.name} и одобрения хостов?',
    );
    if (ok) {
      await onDelete(service.id);
    }
  }
}

List<String> _csv(String value) {
  return value
      .split(',')
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
}

List<Map<String, String>> _ports(String value) {
  return _csv(value)
      .map((item) {
        final parts = item.split(':');
        if (parts.length == 2) {
          return {'protocol': parts[0].trim(), 'port': parts[1].trim()};
        }
        return {'protocol': 'tcp', 'port': item.trim()};
      })
      .toList(growable: false);
}
