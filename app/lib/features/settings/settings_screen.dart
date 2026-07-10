import 'package:flutter/material.dart';

import '../../components.dart';
import '../../models.dart';
import '../../theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    required this.user,
    required this.account,
    required this.subscription,
    required this.usage,
    required this.invoices,
    required this.license,
    required this.billingPlans,
    required this.trustCredentials,
    required this.webhooks,
    required this.detail,
    required this.canMutate,
    required this.onDetailSelected,
    required this.onUpdateAccount,
    required this.onChangePlan,
    required this.onSaveTrustCredential,
    required this.onDeleteTrustCredential,
    required this.onSaveWebhook,
    required this.onDeleteWebhook,
    required this.onTestWebhook,
  });

  final AdminUser? user;
  final AccountModel? account;
  final SubscriptionModel? subscription;
  final UsageSnapshotModel? usage;
  final List<InvoiceModel> invoices;
  final Map<String, dynamic> license;
  final List<BillingPlanModel> billingPlans;
  final List<Map<String, dynamic>> trustCredentials;
  final List<Map<String, dynamic>> webhooks;
  final String detail;
  final bool canMutate;
  final ValueChanged<String> onDetailSelected;
  final Future<void> Function(Map<String, Object?> values) onUpdateAccount;
  final Future<void> Function(String planId, String billingPeriod) onChangePlan;
  final Future<void> Function(String id, Map<String, Object?> values)
  onSaveTrustCredential;
  final Future<void> Function(String id) onDeleteTrustCredential;
  final Future<void> Function(String id, Map<String, Object?> values)
  onSaveWebhook;
  final Future<void> Function(String id) onDeleteWebhook;
  final Future<void> Function(String id) onTestWebhook;

  @override
  Widget build(BuildContext context) {
    final selected = detail.isEmpty ? 'general' : detail;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        SectionHeader(
          title: 'Настройки',
          subtitle:
              'Общие настройки аккаунта, пользователи, устройства, политики, учетные данные, вебхуки, контакты, биллинг и ключи.',
          actions: [
            if (canMutate && selected == 'general')
              FilledButton.icon(
                onPressed: () => _editAccount(context),
                icon: const Icon(Icons.edit_rounded),
                label: const Text('Изменить аккаунт'),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final item in _sections)
              ChoiceChip(
                label: Text(_label(item)),
                selected: selected == item,
                onSelected: (_) => onDetailSelected(item),
              ),
          ],
        ),
        const SizedBox(height: 16),
        switch (selected) {
          'personal' => _PersonalSettingsPanel(user: user),
          'billing' => _BillingPanel(
            subscription: subscription,
            usage: usage,
            invoices: invoices,
            license: license,
            plans: billingPlans,
            canMutate: canMutate,
            onChangePlan: onChangePlan,
          ),
          'trust-credentials' => _TrustCredentialsPanel(
            credentials: trustCredentials,
            canMutate: canMutate,
            onSave: onSaveTrustCredential,
            onDelete: onDeleteTrustCredential,
          ),
          'webhooks' => _WebhooksPanel(
            webhooks: webhooks,
            canMutate: canMutate,
            onSave: onSaveWebhook,
            onDelete: onDeleteWebhook,
            onTest: onTestWebhook,
          ),
          'keys' => _JsonPanel(
            title: 'Ключи',
            values: {
              'Статус лицензии': statusLabel(
                license['status']?.toString() ?? 'missing',
              ),
              'Только публичные ключи': 'да',
            },
          ),
          'contact-preferences' => const _JsonPanel(
            title: 'Контактные предпочтения',
            values: {
              'Безопасность': 'управляется сервером',
              'Биллинг': 'управляется сервером',
            },
          ),
          _ => _SettingsPanel(account: account, section: selected),
        },
      ],
    );
  }

  Future<void> _editAccount(BuildContext context) async {
    final current = account;
    if (current == null) {
      return;
    }
    final name = TextEditingController(text: current.name);
    final country = TextEditingController(text: current.billingCountry);
    final currency = TextEditingController(text: current.currency);
    final values = await showDialog<Map<String, Object?>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Изменить аккаунт'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                decoration: const InputDecoration(
                  labelText: 'Отображаемое имя',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: country,
                decoration: const InputDecoration(labelText: 'Страна биллинга'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: currency,
                decoration: const InputDecoration(labelText: 'Валюта'),
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
              'billing_country': country.text.trim(),
              'currency': currency.text.trim(),
            }),
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
    name.dispose();
    country.dispose();
    currency.dispose();
    if (values != null) {
      await onUpdateAccount(values);
    }
  }
}

class _PersonalSettingsPanel extends StatelessWidget {
  const _PersonalSettingsPanel({required this.user});

  final AdminUser? user;

  @override
  Widget build(BuildContext context) {
    return SurfacePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Личные настройки',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _Field(label: 'Email', value: user?.email ?? '-'),
              _Field(label: 'Имя', value: user?.name ?? '-'),
              _Field(label: 'ID пользователя', value: user?.userId ?? '-'),
              _Field(
                label: 'Сессия действительна до',
                value: _formatDate(user?.expiresAt),
              ),
              const _Field(
                label: 'Аутентификация',
                value: 'управляется центром авторизации',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SettingsPanel extends StatelessWidget {
  const _SettingsPanel({required this.account, required this.section});

  final AccountModel? account;
  final String section;

  @override
  Widget build(BuildContext context) {
    return SurfacePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(_label(section), style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _Field(label: 'ID аккаунта', value: account?.id ?? '-'),
              _Field(label: 'Отображаемое имя', value: account?.name ?? '-'),
              _Field(
                label: 'Статус',
                value: statusLabel(account?.status ?? '', fallback: '-'),
              ),
              _Field(label: 'Валюта', value: account?.currency ?? '-'),
              const _Field(
                label: 'Таймаут сессии',
                value: 'настраивается сервером',
              ),
              const _Field(
                label: 'Опасные действия',
                value: 'требуют подтверждения',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BillingPanel extends StatelessWidget {
  const _BillingPanel({
    required this.subscription,
    required this.usage,
    required this.invoices,
    required this.license,
    required this.plans,
    required this.canMutate,
    required this.onChangePlan,
  });

  final SubscriptionModel? subscription;
  final UsageSnapshotModel? usage;
  final List<InvoiceModel> invoices;
  final Map<String, dynamic> license;
  final List<BillingPlanModel> plans;
  final bool canMutate;
  final Future<void> Function(String planId, String billingPeriod) onChangePlan;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SurfacePanel(
          child: Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _Field(label: 'План', value: subscription?.planId ?? '-'),
              _Field(
                label: 'Статус',
                value: statusLabel(subscription?.status ?? '', fallback: '-'),
              ),
              _Field(
                label: 'Пользователи',
                value: usage == null ? '-' : '${usage!.users}',
              ),
              _Field(
                label: 'Узлы',
                value: usage == null ? '-' : '${usage!.nodes}',
              ),
              _Field(
                label: 'Сети',
                value: usage == null ? '-' : '${usage!.networks}',
              ),
              _Field(
                label: 'Лицензия',
                value: statusLabel(license['status']?.toString() ?? 'missing'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SurfacePanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Планы', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 10),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final plan in plans)
                    SizedBox(
                      width: 260,
                      child: SurfacePanel(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              plan.name.isEmpty ? plan.id : plan.name,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(plan.description),
                            const SizedBox(height: 10),
                            if (canMutate)
                              FilledButton(
                                onPressed: () =>
                                    onChangePlan(plan.id, 'monthly'),
                                child: const Text('Перейти на помесячный'),
                              ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SurfacePanel(
          padding: EdgeInsets.zero,
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Счет')),
              DataColumn(label: Text('Статус')),
              DataColumn(label: Text('Провайдер')),
              DataColumn(label: Text('Сумма')),
            ],
            rows: [
              for (final invoice in invoices)
                DataRow(
                  cells: [
                    DataCell(
                      Text(
                        invoice.number.isEmpty ? invoice.id : invoice.number,
                      ),
                    ),
                    DataCell(Text(statusLabel(invoice.status))),
                    DataCell(Text(invoice.provider)),
                    DataCell(Text('${invoice.amount} ${invoice.currency}')),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TrustCredentialsPanel extends StatelessWidget {
  const _TrustCredentialsPanel({
    required this.credentials,
    required this.canMutate,
    required this.onSave,
    required this.onDelete,
  });

  final List<Map<String, dynamic>> credentials;
  final bool canMutate;
  final Future<void> Function(String id, Map<String, Object?> values) onSave;
  final Future<void> Function(String id) onDelete;

  @override
  Widget build(BuildContext context) {
    return SurfacePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Доверенные учетные данные',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              if (canMutate)
                FilledButton.icon(
                  onPressed: () => _edit(context),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Создать учетные данные'),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (credentials.isEmpty)
            const Text('Доверенные учетные данные не настроены')
          else
            for (final credential in credentials)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(credential['issuer']?.toString() ?? '-'),
                subtitle: Text(
                  [
                    credential['description']?.toString() ?? '',
                    statusLabel(
                      credential['status']?.toString() ?? '',
                      fallback: '',
                    ),
                    credential['scopes']?.toString() ?? '',
                  ].where((item) => item.isNotEmpty).join(' / '),
                ),
                trailing: canMutate
                    ? Wrap(
                        spacing: 4,
                        children: [
                          IconButton(
                            tooltip: 'Ротировать секрет',
                            onPressed: () => _edit(context, credential, true),
                            icon: const Icon(Icons.autorenew_rounded),
                          ),
                          IconButton(
                            tooltip: 'Удалить учетные данные',
                            onPressed: () => _delete(context, credential),
                            icon: const Icon(Icons.delete_outline_rounded),
                          ),
                        ],
                      )
                    : null,
              ),
        ],
      ),
    );
  }

  Future<void> _edit(
    BuildContext context, [
    Map<String, dynamic>? credential,
    bool rotate = false,
  ]) async {
    final issuer = TextEditingController(
      text: credential?['issuer']?.toString() ?? '',
    );
    final description = TextEditingController(
      text: credential?['description']?.toString() ?? '',
    );
    final scopes = TextEditingController(
      text: _listText(credential?['scopes']),
    );
    final values = await showDialog<Map<String, Object?>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          credential == null
              ? 'Создать учетные данные'
              : 'Обновить учетные данные',
        ),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: issuer,
                decoration: const InputDecoration(labelText: 'Издатель'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: description,
                decoration: const InputDecoration(labelText: 'Описание'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: scopes,
                decoration: const InputDecoration(labelText: 'Области доступа'),
              ),
              const SizedBox(height: 8),
              Text(
                'Секреты создаются на сервере и не отображаются в консоли.',
                style: TextStyle(color: context.adminColors.muted),
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
              'issuer': issuer.text.trim(),
              'description': description.text.trim(),
              'scopes': _csv(scopes.text),
              'rotate_secret': rotate,
              'status': credential?['status']?.toString() ?? 'active',
            }),
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
    issuer.dispose();
    description.dispose();
    scopes.dispose();
    if (values != null) {
      await onSave(credential?['id']?.toString() ?? '', values);
    }
  }

  Future<void> _delete(
    BuildContext context,
    Map<String, dynamic> credential,
  ) async {
    final id = credential['id']?.toString() ?? '';
    if (id.isEmpty) {
      return;
    }
    final ok = await confirmDestructive(
      context,
      title: 'Удалить учетные данные',
      message: 'Удалить ${credential['issuer'] ?? id}?',
    );
    if (ok) {
      await onDelete(id);
    }
  }
}

class _WebhooksPanel extends StatelessWidget {
  const _WebhooksPanel({
    required this.webhooks,
    required this.canMutate,
    required this.onSave,
    required this.onDelete,
    required this.onTest,
  });

  final List<Map<String, dynamic>> webhooks;
  final bool canMutate;
  final Future<void> Function(String id, Map<String, Object?> values) onSave;
  final Future<void> Function(String id) onDelete;
  final Future<void> Function(String id) onTest;

  @override
  Widget build(BuildContext context) {
    return SurfacePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Вебхуки',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              if (canMutate)
                FilledButton.icon(
                  onPressed: () => _edit(context),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Создать вебхук'),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (webhooks.isEmpty)
            const Text('Вебхуки не настроены')
          else
            for (final webhook in webhooks)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(webhook['url']?.toString() ?? '-'),
                subtitle: Text(
                  [
                    statusLabel(
                      webhook['status']?.toString() ?? '',
                      fallback: '',
                    ),
                    webhook['event_types']?.toString() ?? '',
                    webhook['retry_policy']?.toString() ?? '',
                  ].where((item) => item.isNotEmpty).join(' / '),
                ),
                trailing: canMutate
                    ? Wrap(
                        spacing: 4,
                        children: [
                          IconButton(
                            tooltip: 'Изменить вебхук',
                            onPressed: () => _edit(context, webhook),
                            icon: const Icon(Icons.edit_rounded),
                          ),
                          IconButton(
                            tooltip: 'Проверить вебхук',
                            onPressed: () =>
                                onTest(webhook['id']?.toString() ?? ''),
                            icon: const Icon(Icons.play_arrow_rounded),
                          ),
                          IconButton(
                            tooltip: 'Удалить вебхук',
                            onPressed: () => _delete(context, webhook),
                            icon: const Icon(Icons.delete_outline_rounded),
                          ),
                        ],
                      )
                    : null,
              ),
        ],
      ),
    );
  }

  Future<void> _edit(
    BuildContext context, [
    Map<String, dynamic>? webhook,
  ]) async {
    final url = TextEditingController(text: webhook?['url']?.toString() ?? '');
    final events = TextEditingController(
      text: _listText(webhook?['event_types']),
    );
    final values = await showDialog<Map<String, Object?>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(webhook == null ? 'Создать вебхук' : 'Изменить вебхук'),
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
                  hintText: 'audit.*, billing.*',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Секреты подписи создаются на сервере и не отображаются в консоли.',
                style: TextStyle(color: context.adminColors.muted),
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
              'status': webhook?['status']?.toString() ?? 'active',
              'retry_policy':
                  webhook?['retry_policy']?.toString() ?? 'standard',
            }),
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
    url.dispose();
    events.dispose();
    if (values != null) {
      await onSave(webhook?['id']?.toString() ?? '', values);
    }
  }

  Future<void> _delete(
    BuildContext context,
    Map<String, dynamic> webhook,
  ) async {
    final id = webhook['id']?.toString() ?? '';
    if (id.isEmpty) {
      return;
    }
    final ok = await confirmDestructive(
      context,
      title: 'Удалить вебхук',
      message: 'Удалить ${webhook['url'] ?? id}?',
    );
    if (ok) {
      await onDelete(id);
    }
  }
}

class _JsonPanel extends StatelessWidget {
  const _JsonPanel({required this.title, required this.values});

  final String title;
  final Map<String, Object?> values;

  @override
  Widget build(BuildContext context) {
    return SurfacePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          for (final entry in values.entries)
            _Field(label: entry.key, value: entry.value?.toString() ?? '-'),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.label, required this.value});

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
          SelectableText(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}

String _label(String section) {
  return switch (section) {
    'personal' => 'Личные',
    'general' => 'Общие',
    'user-management' => 'Пользователи',
    'device-management' => 'Устройства',
    'policy-file-management' => 'Файл политики',
    'trust-credentials' => 'Доверенные учетные данные',
    'webhooks' => 'Вебхуки',
    'contact-preferences' => 'Контакты',
    'billing' => 'Биллинг',
    'keys' => 'Ключи',
    _ when section.isEmpty => 'Общие',
    _ => section.substring(0, 1).toUpperCase() + section.substring(1),
  };
}

String _formatDate(DateTime? value) {
  if (value == null) {
    return '-';
  }
  return value.toLocal().toString();
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

const _sections = [
  'personal',
  'general',
  'user-management',
  'device-management',
  'policy-file-management',
  'trust-credentials',
  'webhooks',
  'contact-preferences',
  'billing',
  'keys',
];
