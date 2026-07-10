import 'package:flutter/material.dart';

import '../../components.dart';
import '../../models.dart';

class UsersScreen extends StatelessWidget {
  const UsersScreen({
    super.key,
    required this.members,
    required this.canMutate,
    required this.onInvite,
    required this.onUpdate,
    required this.onRemove,
  });

  final List<AccountMemberModel> members;
  final bool canMutate;
  final Future<void> Function(Map<String, Object?> values) onInvite;
  final Future<void> Function(String userId, Map<String, Object?> values)
  onUpdate;
  final Future<void> Function(String userId) onRemove;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        SectionHeader(
          title: 'Пользователи',
          subtitle:
              'Участники аккаунта, роли, состояние одобрения, приглашения и владельцы устройств.',
          actions: [
            if (canMutate)
              FilledButton.icon(
                onPressed: () => _invite(context),
                icon: const Icon(Icons.person_add_alt_rounded),
                label: const Text('Пригласить пользователя'),
              ),
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.download_rounded),
              label: const Text('Экспорт'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (members.isEmpty)
          const EmptyState(
            icon: Icons.people_alt_rounded,
            title: 'Участники аккаунта не загружены',
            detail:
                'Участники и приглашения появятся после загрузки выбранного аккаунта.',
          )
        else
          SurfacePanel(
            padding: EdgeInsets.zero,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Пользователь')),
                  DataColumn(label: Text('Роль')),
                  DataColumn(label: Text('Статус')),
                  DataColumn(label: Text('Добавлен')),
                  DataColumn(label: Text('Действия')),
                ],
                rows: [
                  for (final member in members)
                    DataRow(
                      cells: [
                        DataCell(
                          Text(
                            member.email.isEmpty ? member.userId : member.email,
                          ),
                        ),
                        DataCell(Text(roleLabel(member.role))),
                        DataCell(
                          StatusPill(
                            label: statusLabel(member.status),
                            tone: member.status == 'active'
                                ? StatusTone.good
                                : StatusTone.warn,
                          ),
                        ),
                        DataCell(Text(formatDate(member.createdAt))),
                        DataCell(
                          canMutate
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      tooltip: 'Изменить роль',
                                      onPressed: () =>
                                          _changeRole(context, member),
                                      icon: const Icon(Icons.manage_accounts),
                                    ),
                                    IconButton(
                                      tooltip: 'Удалить пользователя',
                                      onPressed: () => _remove(context, member),
                                      icon: const Icon(
                                        Icons.person_remove_alt_1_rounded,
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

  Future<void> _invite(BuildContext context) async {
    final email = TextEditingController();
    final name = TextEditingController();
    var role = 'viewer';
    final values = await showDialog<Map<String, Object?>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Пригласить пользователя'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: email,
                  decoration: const InputDecoration(labelText: 'Эл. почта'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: name,
                  decoration: const InputDecoration(labelText: 'Имя'),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: role,
                  items: _roles
                      .map(
                        (item) => DropdownMenuItem(
                          value: item,
                          child: Text(roleLabel(item)),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) => setState(() => role = value ?? role),
                  decoration: const InputDecoration(labelText: 'Роль'),
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
                'email': email.text.trim(),
                'name': name.text.trim(),
                'role': role,
              }),
              child: const Text('Пригласить'),
            ),
          ],
        ),
      ),
    );
    email.dispose();
    name.dispose();
    if (values != null) {
      await onInvite(values);
    }
  }

  Future<void> _changeRole(
    BuildContext context,
    AccountMemberModel member,
  ) async {
    var role = member.role.isEmpty ? 'viewer' : member.role;
    var status = member.status.isEmpty ? 'active' : member.status;
    final values = await showDialog<Map<String, Object?>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Обновить участника'),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _roles.contains(role) ? role : 'viewer',
                  items: _roles
                      .map(
                        (item) => DropdownMenuItem(
                          value: item,
                          child: Text(roleLabel(item)),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) => setState(() => role = value ?? role),
                  decoration: const InputDecoration(labelText: 'Роль'),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: status,
                  items: const [
                    DropdownMenuItem(value: 'active', child: Text('активно')),
                    DropdownMenuItem(
                      value: 'suspended',
                      child: Text('приостановлено'),
                    ),
                  ],
                  onChanged: (value) =>
                      setState(() => status = value ?? status),
                  decoration: const InputDecoration(labelText: 'Статус'),
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
              onPressed: () =>
                  Navigator.pop(context, {'role': role, 'status': status}),
              child: const Text('Сохранить'),
            ),
          ],
        ),
      ),
    );
    if (values != null) {
      await onUpdate(member.userId, values);
    }
  }

  Future<void> _remove(BuildContext context, AccountMemberModel member) async {
    final ok = await confirmDestructive(
      context,
      title: 'Удалить пользователя',
      message:
          'Удалить ${member.email.isEmpty ? member.userId : member.email}?',
    );
    if (ok) {
      await onRemove(member.userId);
    }
  }
}

const _roles = [
  'owner',
  'billing_admin',
  'security_admin',
  'network_admin',
  'developer',
  'viewer',
  'support',
];
