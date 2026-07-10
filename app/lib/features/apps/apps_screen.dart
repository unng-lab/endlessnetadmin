import 'package:flutter/material.dart';

import '../../components.dart';
import '../../models.dart';

class AppsScreen extends StatelessWidget {
  const AppsScreen({
    super.key,
    required this.apps,
    required this.canMutate,
    required this.onSave,
    required this.onDelete,
  });

  final List<AppModel> apps;
  final bool canMutate;
  final Future<void> Function(String id, Map<String, Object?> values) onSave;
  final Future<void> Function(String id) onDelete;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        SectionHeader(
          title: 'Приложения',
          subtitle:
              'Сторонние SaaS и приватные приложения, доступные через одобренные коннекторы.',
          actions: [
            if (canMutate)
              FilledButton.icon(
                onPressed: () => _editApp(context),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Добавить приложение'),
              ),
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.download_rounded),
              label: const Text('Экспорт'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (apps.isEmpty)
          const EmptyState(
            icon: Icons.apps_rounded,
            title: 'Приложения не настроены',
            detail:
                'Добавьте домен, CIDR или origin и привяжите узлы-коннекторы либо ACL-теги.',
          )
        else
          SurfacePanel(
            padding: EdgeInsets.zero,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Приложение')),
                  DataColumn(label: Text('Цель')),
                  DataColumn(label: Text('Коннекторы')),
                  DataColumn(label: Text('Политика')),
                  DataColumn(label: Text('Состояние')),
                  DataColumn(label: Text('Действия')),
                ],
                rows: [
                  for (final app in apps)
                    DataRow(
                      cells: [
                        DataCell(Text(app.name)),
                        DataCell(Text('${app.targetType}: ${app.target}')),
                        DataCell(
                          Text(
                            [
                              ...app.connectorNodes,
                              ...app.connectorTags,
                            ].join(', '),
                          ),
                        ),
                        DataCell(
                          StatusPill(
                            label: app.policyStatus.isEmpty
                                ? 'черновик'
                                : statusLabel(app.policyStatus),
                            tone: app.policyStatus == 'active'
                                ? StatusTone.good
                                : StatusTone.warn,
                          ),
                        ),
                        DataCell(
                          StatusPill(
                            label: app.health.isEmpty
                                ? 'неизвестно'
                                : statusLabel(app.health),
                            tone: app.health == 'healthy'
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
                                      tooltip: 'Изменить приложение',
                                      onPressed: () => _editApp(context, app),
                                      icon: const Icon(Icons.edit_rounded),
                                    ),
                                    IconButton(
                                      tooltip: 'Удалить приложение',
                                      onPressed: () => _deleteApp(context, app),
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

  Future<void> _editApp(BuildContext context, [AppModel? app]) async {
    final name = TextEditingController(text: app?.name ?? '');
    final targetType = TextEditingController(text: app?.targetType ?? 'domain');
    final target = TextEditingController(text: app?.target ?? '');
    final connectorTags = TextEditingController(
      text: app?.connectorTags.join(', ') ?? '',
    );
    final connectorNodes = TextEditingController(
      text: app?.connectorNodes.join(', ') ?? '',
    );
    final saved = await showDialog<Map<String, Object?>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          app == null ? 'Добавить приложение' : 'Изменить приложение',
        ),
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
                controller: targetType,
                decoration: const InputDecoration(
                  labelText: 'Тип цели',
                  hintText: 'domain, cidr, url',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: target,
                decoration: const InputDecoration(labelText: 'Цель'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: connectorTags,
                decoration: const InputDecoration(
                  labelText: 'Теги коннекторов',
                  hintText: 'tag:prod, tag:connector',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: connectorNodes,
                decoration: const InputDecoration(labelText: 'Узлы-коннекторы'),
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
              'target_type': targetType.text.trim(),
              'target': target.text.trim(),
              'connector_tags': _csv(connectorTags.text),
              'connector_nodes': _csv(connectorNodes.text),
              'dns_enabled': true,
              'policy_status': app?.policyStatus ?? 'draft',
              'health': app?.health ?? 'unknown',
            }),
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
    name.dispose();
    targetType.dispose();
    target.dispose();
    connectorTags.dispose();
    connectorNodes.dispose();
    if (saved != null) {
      await onSave(app?.id ?? '', saved);
    }
  }

  Future<void> _deleteApp(BuildContext context, AppModel app) async {
    final ok = await confirmDestructive(
      context,
      title: 'Удалить приложение',
      message: 'Удалить ${app.name} и привязки коннекторов?',
    );
    if (ok) {
      await onDelete(app.id);
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
