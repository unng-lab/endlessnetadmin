import 'package:flutter/material.dart';

import 'models.dart';
import 'runtime.dart' as runtime;
import 'theme.dart';

enum AdminSection {
  machines,
  apps,
  services,
  users,
  accessControls,
  logs,
  dns,
  settings,
  resourceHub,
}

extension AdminSectionMeta on AdminSection {
  String get label {
    return switch (this) {
      AdminSection.machines => 'Устройства',
      AdminSection.apps => 'Приложения',
      AdminSection.services => 'Сервисы',
      AdminSection.users => 'Пользователи',
      AdminSection.accessControls => 'Доступ',
      AdminSection.logs => 'Журналы',
      AdminSection.dns => 'DNS',
      AdminSection.settings => 'Настройки',
      AdminSection.resourceHub => 'Ресурсы',
    };
  }

  String get slug {
    return switch (this) {
      AdminSection.machines => 'machines',
      AdminSection.apps => 'apps',
      AdminSection.services => 'services',
      AdminSection.users => 'users',
      AdminSection.accessControls => 'access-controls',
      AdminSection.logs => 'logs',
      AdminSection.dns => 'dns',
      AdminSection.settings => 'settings',
      AdminSection.resourceHub => 'resource-hub',
    };
  }

  IconData get icon {
    return switch (this) {
      AdminSection.machines => Icons.dns_rounded,
      AdminSection.apps => Icons.apps_rounded,
      AdminSection.services => Icons.router_rounded,
      AdminSection.users => Icons.people_alt_rounded,
      AdminSection.accessControls => Icons.policy_rounded,
      AdminSection.logs => Icons.receipt_long_rounded,
      AdminSection.dns => Icons.public_rounded,
      AdminSection.settings => Icons.settings_rounded,
      AdminSection.resourceHub => Icons.menu_book_rounded,
    };
  }
}

AdminSection sectionFromSlug(String slug) {
  final normalized = slug.trim().toLowerCase();
  for (final section in AdminSection.values) {
    if (section.slug == normalized) {
      return section;
    }
  }
  return AdminSection.machines;
}

class AdminShell extends StatelessWidget {
  const AdminShell({
    super.key,
    required this.section,
    required this.accounts,
    required this.selectedAccountId,
    required this.user,
    required this.planLabel,
    required this.onSectionSelected,
    required this.onAccountSelected,
    required this.onPersonalSettings,
    required this.onLogout,
    required this.themeMode,
    required this.onThemeModeChanged,
    required this.child,
  });

  final AdminSection section;
  final List<AccountModel> accounts;
  final String selectedAccountId;
  final AdminUser? user;
  final String planLabel;
  final ValueChanged<AdminSection> onSectionSelected;
  final ValueChanged<String> onAccountSelected;
  final VoidCallback onPersonalSettings;
  final VoidCallback onLogout;
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.adminColors;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 860;
        if (compact) {
          return Scaffold(
            appBar: AppBar(
              title: const _BrandHeader(compact: true),
              backgroundColor: colors.surface,
              actions: [
                _AccountMenu(
                  accounts: accounts,
                  selectedAccountId: selectedAccountId,
                  onChanged: onAccountSelected,
                ),
                _ThemeModeSwitch(
                  themeMode: themeMode,
                  onChanged: onThemeModeChanged,
                  compact: true,
                ),
              ],
            ),
            drawer: Drawer(
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(18, 18, 18, 12),
                      child: _BrandHeader(),
                    ),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        children: [
                          for (final item in AdminSection.values)
                            _NavItem(
                              item: item,
                              selected: item == section,
                              onTap: () {
                                Navigator.pop(context);
                                onSectionSelected(item);
                              },
                            ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _ThemeModeSwitch(
                            themeMode: themeMode,
                            onChanged: onThemeModeChanged,
                          ),
                          const SizedBox(height: 8),
                          _UserCard(user: user),
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            onPressed: onLogout,
                            icon: const Icon(Icons.logout_rounded),
                            label: const Text('Выйти'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            body: child,
          );
        }
        return Scaffold(
          body: DecoratedBox(
            decoration: _shellBackgroundDecoration(context),
            child: Row(
              children: [
                Container(
                  width: 284,
                  decoration: BoxDecoration(
                    color: dark ? null : colors.surface,
                    gradient: dark
                        ? LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              colors.surface.withValues(alpha: .88),
                              colors.background.withValues(alpha: .96),
                            ],
                          )
                        : null,
                    border: Border(
                      right: BorderSide(
                        color: colors.line.withValues(alpha: .68),
                      ),
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const _BrandHeader(),
                          const SizedBox(height: 26),
                          Expanded(
                            child: ListView(
                              padding: EdgeInsets.zero,
                              children: [
                                for (final item in AdminSection.values)
                                  _NavItem(
                                    item: item,
                                    selected: item == section,
                                    onTap: () => onSectionSelected(item),
                                  ),
                              ],
                            ),
                          ),
                          _UserCard(user: user),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: onLogout,
                            icon: const Icon(Icons.logout_rounded),
                            label: const Text('Выйти'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      _TopBar(
                        accounts: accounts,
                        selectedAccountId: selectedAccountId,
                        planLabel: planLabel,
                        user: user,
                        onAccountSelected: onAccountSelected,
                        onPersonalSettings: onPersonalSettings,
                        onLogout: onLogout,
                        themeMode: themeMode,
                        onThemeModeChanged: onThemeModeChanged,
                      ),
                      Expanded(child: child),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

BoxDecoration _shellBackgroundDecoration(BuildContext context) {
  final colors = context.adminColors;
  final dark = Theme.of(context).brightness == Brightness.dark;
  if (dark) {
    return BoxDecoration(
      gradient: RadialGradient(
        center: const Alignment(-.72, -1.16),
        radius: 1.2,
        colors: [
          colors.blue.withValues(alpha: .16),
          colors.background.withValues(alpha: 0),
        ],
        stops: const [0, 1],
      ),
      color: colors.background,
    );
  }
  return BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [colors.surface, colors.background],
    ),
  );
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = context.adminColors;
    final dark = Theme.of(context).brightness == Brightness.dark;
    if (dark) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Image.asset(
          'assets/brand-logo.png',
          width: compact ? 168 : 204,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => Text(
            'EndlessNet',
            style: TextStyle(
              color: colors.text,
              fontSize: compact ? 18 : 22,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/brand-mark.png',
          width: compact ? 28 : 38,
          height: compact ? 28 : 38,
          errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
        ),
        const SizedBox(width: 10),
        Text(
          'EndlessNet',
          style: TextStyle(
            color: colors.text,
            fontSize: compact ? 18 : 22,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final AdminSection item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.adminColors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.5),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            height: 54,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              gradient: selected
                  ? LinearGradient(
                      colors: [
                        colors.blue.withValues(alpha: .15),
                        colors.blue.withValues(alpha: .04),
                      ],
                    )
                  : null,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 140),
                  width: 3,
                  height: selected ? 28 : 0,
                  decoration: BoxDecoration(
                    color: colors.blue,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(width: 13),
                Icon(
                  item.icon,
                  size: 21,
                  color: selected ? colors.blue : colors.muted,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    item.label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selected ? colors.blue : colors.text,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.accounts,
    required this.selectedAccountId,
    required this.planLabel,
    required this.user,
    required this.onAccountSelected,
    required this.onPersonalSettings,
    required this.onLogout,
    required this.themeMode,
    required this.onThemeModeChanged,
  });

  final List<AccountModel> accounts;
  final String selectedAccountId;
  final String planLabel;
  final AdminUser? user;
  final ValueChanged<String> onAccountSelected;
  final VoidCallback onPersonalSettings;
  final VoidCallback onLogout;
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.adminColors;
    return LayoutBuilder(
      builder: (context, constraints) {
        final condensed = constraints.maxWidth < 1040;
        return Container(
          height: 76,
          padding: EdgeInsets.symmetric(horizontal: condensed ? 18 : 34),
          decoration: BoxDecoration(
            color: colors.background.withValues(alpha: .74),
            border: Border(
              bottom: BorderSide(color: colors.line.withValues(alpha: .68)),
            ),
          ),
          child: Row(
            children: [
              if (!condensed) ...[
                Text(
                  'Рабочая область',
                  style: TextStyle(
                    color: colors.muted,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 12),
              ],
              _AccountMenu(
                accounts: accounts,
                selectedAccountId: selectedAccountId,
                onChanged: onAccountSelected,
              ),
              const SizedBox(width: 14),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: colors.blue.withValues(alpha: .11),
                  border: Border.all(color: colors.blue.withValues(alpha: .2)),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  planLabel.isEmpty ? 'План недоступен' : planLabel,
                  style: TextStyle(
                    color: colors.blue,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Spacer(),
              _ThemeModeSwitch(
                themeMode: themeMode,
                onChanged: onThemeModeChanged,
              ),
              const SizedBox(width: 12),
              _RoundPopupButton(
                tooltip: 'Справка',
                icon: Icons.help_outline_rounded,
                onSelected: _openHelpTarget,
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'docs', child: Text('Документация')),
                  PopupMenuItem(value: 'guides', child: Text('Сценарии')),
                  PopupMenuItem(value: 'support', child: Text('Поддержка')),
                  PopupMenuItem(value: 'download', child: Text('Скачать')),
                  PopupMenuItem(
                    value: 'feedback',
                    child: Text('Обратная связь'),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              _RoundPopupButton(
                tooltip: 'Меню пользователя',
                icon: Icons.account_circle_rounded,
                onSelected: (value) {
                  if (value == 'settings') {
                    onPersonalSettings();
                  } else if (value == 'logout') {
                    onLogout();
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    enabled: false,
                    child: Text(_userMenuLabel(user)),
                  ),
                  const PopupMenuItem(
                    value: 'settings',
                    child: Text('Личные настройки'),
                  ),
                  const PopupMenuItem(value: 'logout', child: Text('Выйти')),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RoundPopupButton extends StatelessWidget {
  const _RoundPopupButton({
    required this.tooltip,
    required this.icon,
    required this.onSelected,
    required this.itemBuilder,
  });

  final String tooltip;
  final IconData icon;
  final ValueChanged<String> onSelected;
  final PopupMenuItemBuilder<String> itemBuilder;

  @override
  Widget build(BuildContext context) {
    final colors = context.adminColors;
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: .58),
        border: Border.all(color: colors.line.withValues(alpha: .72)),
        shape: BoxShape.circle,
      ),
      child: PopupMenuButton<String>(
        tooltip: tooltip,
        icon: Icon(icon, size: 20),
        iconColor: colors.muted,
        padding: EdgeInsets.zero,
        color: colors.surface,
        onSelected: onSelected,
        itemBuilder: itemBuilder,
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({required this.user});

  final AdminUser? user;

  @override
  Widget build(BuildContext context) {
    final colors = context.adminColors;
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: colors.surfaceAlt.withValues(alpha: .72),
        border: Border.all(color: colors.line.withValues(alpha: .68)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: colors.text.withValues(alpha: .08),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              _userInitials(user),
              style: TextStyle(
                color: colors.text,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _userPrimaryLabel(user),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.text,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _userSecondaryLabel(user),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: colors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

void _openHelpTarget(String value) {
  final url = adminHelpMenuUrl(value, runtime.siteRoot());
  if (url.isNotEmpty) {
    runtime.openExternal(url);
  }
}

String adminHelpMenuUrl(String value, String siteRoot) {
  final root = Uri.parse(siteRoot);
  return switch (value) {
    'docs' => root.resolve('docs/').toString(),
    'guides' => root.resolve('#cases').toString(),
    'download' => root.resolve('docs/#install').toString(),
    'support' => Uri(
      scheme: 'mailto',
      path: 'support@endlessnet.ru',
      queryParameters: {'subject': 'EndlessNet support'},
    ).toString(),
    'feedback' => Uri(
      scheme: 'mailto',
      path: 'support@endlessnet.ru',
      queryParameters: {'subject': 'EndlessNet feedback'},
    ).toString(),
    _ => '',
  };
}

String _userMenuLabel(AdminUser? user) {
  if (user == null) {
    return 'Профиль не загружен';
  }
  final email = user.email.trim();
  if (email.isNotEmpty) {
    return email;
  }
  final name = user.name.trim();
  if (name.isNotEmpty) {
    return name;
  }
  final userId = user.userId.trim();
  if (userId.isNotEmpty) {
    return userId;
  }
  return 'Профиль без имени';
}

String _userPrimaryLabel(AdminUser? user) {
  if (user == null) {
    return 'Администратор';
  }
  final name = user.name.trim();
  if (name.isNotEmpty) {
    return name;
  }
  final email = user.email.trim();
  if (email.isNotEmpty) {
    return email;
  }
  return _userMenuLabel(user);
}

String _userSecondaryLabel(AdminUser? user) {
  if (user == null) {
    return 'Сессия не загружена';
  }
  final email = user.email.trim();
  if (email.isNotEmpty && email != _userPrimaryLabel(user)) {
    return email;
  }
  final userId = user.userId.trim();
  if (userId.isNotEmpty) {
    return userId;
  }
  return 'Профиль без имени';
}

String _userInitials(AdminUser? user) {
  final source = _userPrimaryLabel(
    user,
  ).replaceAll(RegExp(r'[^A-Za-zА-Яа-я0-9@._ -]'), '').trim();
  if (source.isEmpty || source == 'Администратор') {
    return 'AA';
  }
  final parts = source
      .split(RegExp(r'[\s@._-]+'))
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.length >= 2) {
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }
  return (source.length <= 2 ? source : source.substring(0, 2)).toUpperCase();
}

class _ThemeModeSwitch extends StatelessWidget {
  const _ThemeModeSwitch({
    required this.themeMode,
    required this.onChanged,
    this.compact = false,
  });

  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onChanged;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = context.adminColors;
    return Semantics(
      label: 'Тема интерфейса',
      child: SegmentedButton<ThemeMode>(
        showSelectedIcon: false,
        selected: {themeMode},
        segments: [
          ButtonSegment<ThemeMode>(
            value: ThemeMode.light,
            label: _ThemeModeSegment(
              icon: Icons.light_mode_rounded,
              label: 'Светлая',
              compact: compact,
            ),
          ),
          ButtonSegment<ThemeMode>(
            value: ThemeMode.dark,
            label: _ThemeModeSegment(
              icon: Icons.dark_mode_rounded,
              label: 'Темная',
              compact: compact,
            ),
          ),
        ],
        onSelectionChanged: (selection) {
          if (selection.isNotEmpty) {
            onChanged(selection.first);
          }
        },
        style: ButtonStyle(
          visualDensity: VisualDensity.compact,
          padding: WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: compact ? 9 : 12),
          ),
          side: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return BorderSide(color: selected ? colors.blue : colors.line);
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return selected ? colors.blue : colors.text;
          }),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return selected
                ? colors.blue.withValues(alpha: .12)
                : colors.surface;
          }),
        ),
      ),
    );
  }
}

class _ThemeModeSegment extends StatelessWidget {
  const _ThemeModeSegment({
    required this.icon,
    required this.label,
    required this.compact,
  });

  final IconData icon;
  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18),
        if (!compact) ...[const SizedBox(width: 6), Text(label)],
      ],
    );
    if (!compact) {
      return content;
    }
    return Tooltip(message: label, child: content);
  }
}

class _AccountMenu extends StatelessWidget {
  const _AccountMenu({
    required this.accounts,
    required this.selectedAccountId,
    required this.onChanged,
  });

  final List<AccountModel> accounts;
  final String selectedAccountId;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.adminColors;
    if (accounts.isEmpty) {
      return Text(
        'Нет аккаунта',
        style: TextStyle(color: colors.text, fontWeight: FontWeight.w800),
      );
    }
    return DropdownButton<String>(
      value: accounts.any((account) => account.id == selectedAccountId)
          ? selectedAccountId
          : accounts.first.id,
      underline: const SizedBox.shrink(),
      dropdownColor: colors.surface,
      iconEnabledColor: colors.blue,
      style: TextStyle(color: colors.text, fontWeight: FontWeight.w800),
      items: [
        for (final account in accounts)
          DropdownMenuItem(
            value: account.id,
            child: Text(
              account.name.isEmpty ? account.slug : account.name,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
      onChanged: (value) {
        if (value != null) {
          onChanged(value);
        }
      },
    );
  }
}
