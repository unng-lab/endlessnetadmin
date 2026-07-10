import 'package:flutter/material.dart';

import '../../components.dart';
import '../../models.dart';

class LogsScreen extends StatelessWidget {
  const LogsScreen({
    super.key,
    required this.auditEvents,
    required this.logStreams,
    required this.canMutate,
    required this.onUpdateFlowSettings,
    required this.onSaveLogStream,
    required this.onDeleteLogStream,
  });

  final List<AuditEventModel> auditEvents;
  final List<Map<String, dynamic>> logStreams;
  final bool canMutate;
  final Future<void> Function(Map<String, Object?> values) onUpdateFlowSettings;
  final Future<void> Function(String id, Map<String, Object?> values)
  onSaveLogStream;
  final Future<void> Function(String id) onDeleteLogStream;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        SectionHeader(
          title: 'Журналы',
          subtitle:
              'Аудит конфигурации, очищенные метаданные, настройки flow-логов и потоковая отправка в SIEM.',
          actions: [
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.file_download_rounded),
              label: const Text('Экспорт JSON'),
            ),
            if (canMutate)
              FilledButton.icon(
                onPressed: () => _flowSettings(context),
                icon: const Icon(Icons.security_rounded),
                label: const Text('Настройки flow-логов'),
              ),
            if (canMutate)
              OutlinedButton.icon(
                onPressed: () => _editStream(context),
                icon: const Icon(Icons.add_link_rounded),
                label: const Text('Добавить поток'),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (auditEvents.isEmpty)
          const EmptyState(
            icon: Icons.receipt_long_rounded,
            title: 'События аудита не загружены',
            detail:
                'Изменения в консоли, входы и события биллинга записываются с очищенными метаданными.',
          )
        else
          SurfacePanel(
            padding: EdgeInsets.zero,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Время')),
                  DataColumn(label: Text('Действие')),
                  DataColumn(label: Text('Автор')),
                  DataColumn(label: Text('Цель')),
                ],
                rows: [
                  for (final event in auditEvents)
                    DataRow(
                      cells: [
                        DataCell(Text(formatDate(event.createdAt))),
                        DataCell(Text(event.type)),
                        DataCell(
                          Text(
                            event.actorUserId.isEmpty ? '-' : event.actorUserId,
                          ),
                        ),
                        DataCell(Text('${event.targetType}:${event.targetId}')),
                      ],
                    ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 16),
        SurfacePanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Потоки журналов',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              if (logStreams.isEmpty)
                const Text('Потоки SIEM не настроены')
              else
                for (final stream in logStreams)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(stream['url']?.toString() ?? '-'),
                    subtitle: Text(
                      [
                        stream['status']?.toString() ?? 'active',
                        stream['event_types']?.toString() ?? '',
                      ].where((item) => item.isNotEmpty).join(' / '),
                    ),
                    trailing: canMutate
                        ? Wrap(
                            spacing: 4,
                            children: [
                              IconButton(
                                tooltip: 'Изменить поток',
                                onPressed: () => _editStream(context, stream),
                                icon: const Icon(Icons.edit_rounded),
                              ),
                              IconButton(
                                tooltip: 'Удалить поток',
                                onPressed: () => _deleteStream(context, stream),
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

  Future<void> _flowSettings(BuildContext context) async {
    var enabled = true;
    var streamEnabled = true;
    final retention = TextEditingController(text: '30');
    final values = await showDialog<Map<String, Object?>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Настройки flow-логов'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwitchListTile(
                  value: enabled,
                  onChanged: (value) => setState(() => enabled = value),
                  title: const Text('Включить flow-логи'),
                ),
                SwitchListTile(
                  value: streamEnabled,
                  onChanged: (value) => setState(() => streamEnabled = value),
                  title: const Text('Отправлять в SIEM'),
                ),
                TextField(
                  controller: retention,
                  decoration: const InputDecoration(
                    labelText: 'Срок хранения, дней',
                  ),
                  keyboardType: TextInputType.number,
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
                'enabled': enabled,
                'stream_enabled': streamEnabled,
                'retention_days': int.tryParse(retention.text.trim()) ?? 30,
                'privacy_notice_acknowledged': true,
              }),
              child: const Text('Сохранить'),
            ),
          ],
        ),
      ),
    );
    retention.dispose();
    if (values != null) {
      await onUpdateFlowSettings(values);
    }
  }

  Future<void> _editStream(
    BuildContext context, [
    Map<String, dynamic>? stream,
  ]) async {
    final url = TextEditingController(text: stream?['url']?.toString() ?? '');
    final events = TextEditingController(
      text: _listText(stream?['event_types']),
    );
    final values = await showDialog<Map<String, Object?>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          stream == null
              ? 'Добавить поток журналов'
              : 'Изменить поток журналов',
        ),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: url,
                decoration: const InputDecoration(labelText: 'URL'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: events,
                decoration: const InputDecoration(
                  labelText: 'Типы событий',
                  hintText: 'audit.*, flow.*',
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
              'url': url.text.trim(),
              'event_types': _csv(events.text),
              'status': stream?['status']?.toString() ?? 'active',
            }),
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
    url.dispose();
    events.dispose();
    if (values != null) {
      await onSaveLogStream(stream?['id']?.toString() ?? '', values);
    }
  }

  Future<void> _deleteStream(
    BuildContext context,
    Map<String, dynamic> stream,
  ) async {
    final id = stream['id']?.toString() ?? '';
    if (id.isEmpty) {
      return;
    }
    final ok = await confirmDestructive(
      context,
      title: 'Удалить поток журналов',
      message: 'Удалить ${stream['url'] ?? id}?',
    );
    if (ok) {
      await onDeleteLogStream(id);
    }
  }
}

String _listText(Object? value) {
  if (value is List) {
    return value.map((item) => item.toString()).join(', ');
  }
  return value?.toString() ?? '';
}

List<String> _csv(String value) {
  return value
      .split(',')
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
}
