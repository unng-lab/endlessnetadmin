import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'theme.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon,
    this.actions = const [],
  });

  final String title;
  final String subtitle;
  final IconData? icon;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final colors = context.adminColors;
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 720;
        final titleBlock = Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (icon != null) ...[
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colors.blue.withValues(alpha: .12),
                  border: Border.all(color: colors.blue.withValues(alpha: .28)),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: colors.blue),
              ),
              const SizedBox(width: 16),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: colors.muted,
                      fontSize: 15,
                      height: 1.42,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              titleBlock,
              if (actions.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(spacing: 8, runSpacing: 8, children: actions),
              ],
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: titleBlock),
            const SizedBox(width: 12),
            Flexible(
              child: Align(
                alignment: Alignment.topRight,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.end,
                  children: actions,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class SurfacePanel extends StatelessWidget {
  const SurfacePanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final colors = context.adminColors;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.line),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? .22 : .06),
            blurRadius: dark ? 44 : 28,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: child,
    );
  }
}

class FilterBar extends StatelessWidget {
  const FilterBar({
    super.key,
    required this.controller,
    required this.hint,
    required this.onChanged,
    this.trailing = const [],
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;
  final List<Widget> trailing;

  @override
  Widget build(BuildContext context) {
    return SurfacePanel(
      padding: const EdgeInsets.all(10),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 320,
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              decoration: InputDecoration(
                hintText: hint,
                prefixIcon: const Icon(Icons.search_rounded),
              ),
            ),
          ),
          ...trailing,
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.detail,
  });

  final IconData icon;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final colors = context.adminColors;
    return SurfacePanel(
      child: SizedBox(
        height: 180,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 34, color: colors.muted),
                const SizedBox(height: 10),
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  detail,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colors.muted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.label,
    this.tone = StatusTone.neutral,
  });

  final String label;
  final StatusTone tone;

  @override
  Widget build(BuildContext context) {
    final colors = context.adminColors;
    final color = switch (tone) {
      StatusTone.good => colors.green,
      StatusTone.warn => colors.amber,
      StatusTone.bad => colors.danger,
      StatusTone.neutral => colors.muted,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .10),
        border: Border.all(color: color.withValues(alpha: .36)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

enum StatusTone { good, warn, bad, neutral }

class CopyButton extends StatelessWidget {
  const CopyButton({
    super.key,
    required this.value,
    this.tooltip = 'Копировать',
  });

  final String value;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: value.isEmpty
          ? null
          : () async {
              await Clipboard.setData(ClipboardData(text: value));
              if (context.mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Скопировано')));
              }
            },
      icon: const Icon(Icons.copy_rounded),
    );
  }
}

Future<bool> confirmDestructive(
  BuildContext context, {
  required String title,
  required String message,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Отмена'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Подтвердить'),
        ),
      ],
    ),
  );
  return result ?? false;
}

String formatDate(DateTime? value) {
  if (value == null || value.year <= 1) {
    return '-';
  }
  final local = value.toLocal();
  String two(int v) => v.toString().padLeft(2, '0');
  return '${local.year}-${two(local.month)}-${two(local.day)} ${two(local.hour)}:${two(local.minute)}';
}

String shortText(String value, [int max = 18]) {
  if (value.length <= max) {
    return value;
  }
  return '${value.substring(0, max - 3)}...';
}

String boolLabel(bool value) => value ? 'включено' : 'выключено';

String statusLabel(String value, {String fallback = 'неизвестно'}) {
  final raw = value.trim();
  if (raw.isEmpty) {
    return fallback;
  }
  return switch (raw.toLowerCase()) {
    'active' => 'активно',
    'approved' => 'одобрено',
    'disabled' => 'выключено',
    'draft' => 'черновик',
    'enabled' => 'включено',
    'failed' => 'ошибка',
    'healthy' => 'исправно',
    'manual' => 'вручную',
    'missing' => 'нет данных',
    'offline' => 'офлайн',
    'online' => 'онлайн',
    'paid' => 'оплачен',
    'pending' => 'ожидает',
    'suspended' => 'приостановлено',
    'unknown' => 'неизвестно',
    _ => raw,
  };
}

String roleLabel(String value) {
  final raw = value.trim();
  return switch (raw.toLowerCase()) {
    'owner' => 'владелец',
    'billing_admin' => 'админ биллинга',
    'security_admin' => 'админ безопасности',
    'network_admin' => 'сетевой админ',
    'developer' => 'разработчик',
    'viewer' => 'наблюдатель',
    'support' => 'поддержка',
    _ when raw.isEmpty => 'роль не задана',
    _ => raw,
  };
}
