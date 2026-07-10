import 'package:flutter/material.dart';

import '../../components.dart';
import '../../models.dart';
import '../../runtime.dart' as runtime;
import '../../theme.dart';
import 'windows_enrollment.dart';

class ResourceHubScreen extends StatefulWidget {
  const ResourceHubScreen({
    super.key,
    required this.account,
    required this.networks,
    required this.apiBaseUrl,
    required this.canMutate,
    required this.onCreateJoinToken,
    required this.onRevokeJoinToken,
    this.openExternal,
    this.launchEnrollmentLink,
  });

  final AccountModel? account;
  final List<NetworkModel> networks;
  final String apiBaseUrl;
  final bool canMutate;
  final Future<Map<String, dynamic>?> Function(
    String mode,
    String networkId,
    String networkName,
  )
  onCreateJoinToken;
  final Future<void> Function(String tokenId) onRevokeJoinToken;
  final void Function(String url)? openExternal;
  final void Function(String url)? launchEnrollmentLink;

  @override
  State<ResourceHubScreen> createState() => _ResourceHubScreenState();
}

class _ResourceHubScreenState extends State<ResourceHubScreen> {
  String _mode = 'workstation';
  String _networkId = '';
  Map<String, dynamic>? _token;
  bool _creating = false;
  bool _revoking = false;
  String? _error;

  Future<Map<String, dynamic>?> _createWindowsToken() async {
    final network = _selectedNetwork;
    setState(() {
      _creating = true;
      _error = null;
    });
    try {
      final token = await widget.onCreateJoinToken(
        _mode,
        network?.id ?? '',
        network?.name ?? 'default',
      );
      if (!mounted) {
        return token;
      }
      setState(() => _token = token);
      return token;
    } catch (error) {
      if (!mounted) {
        return null;
      }
      setState(() => _error = '$error');
      return null;
    } finally {
      if (mounted) {
        setState(() => _creating = false);
      }
    }
  }

  void _downloadWindowsInstaller() {
    (widget.openExternal ?? runtime.openExternal)(windowsInstallerURL);
  }

  Future<void> _connectWindowsDevice() async {
    final token = _token ?? await _createWindowsToken();
    if (!mounted || token == null) {
      return;
    }
    final enrollToken = stringValue(token['token']).trim();
    if (enrollToken.isEmpty) {
      setState(() => _error = 'Не удалось получить ссылку подключения.');
      return;
    }
    final link = windowsEnrollmentLink(
      serverUrl: widget.apiBaseUrl,
      enrollToken: enrollToken,
      mode: _mode,
    );
    (widget.launchEnrollmentLink ?? runtime.redirectTo)(link);
  }

  Future<void> _revokeWindowsToken() async {
    final id = stringValue(_token?['id']).trim();
    if (id.isEmpty) {
      return;
    }
    setState(() {
      _revoking = true;
      _error = null;
    });
    try {
      await widget.onRevokeJoinToken(id);
      if (!mounted) {
        return;
      }
      setState(() => _token = null);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _error = '$error');
    } finally {
      if (mounted) {
        setState(() => _revoking = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final windowsLink = _windowsEnrollmentLink;
    final selectedNetwork = _selectedNetwork;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SectionHeader(
          title: 'Ресурсы',
          subtitle:
              'Загрузки, команды установки, API-справка, ссылки поддержки и идентификаторы аккаунта.',
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _WindowsEnrollmentPanel(
              account: widget.account,
              networks: widget.networks,
              apiBaseUrl: widget.apiBaseUrl,
              canMutate: widget.canMutate,
              mode: _mode,
              selectedNetworkId: selectedNetwork?.id ?? '',
              token: _token,
              enrollmentLink: windowsLink,
              error: _error,
              creating: _creating,
              revoking: _revoking,
              onModeChanged: (value) => setState(() {
                _mode = value;
                _token = null;
              }),
              onNetworkChanged: (value) => setState(() {
                _networkId = value;
                _token = null;
              }),
              onDownload: _downloadWindowsInstaller,
              onConnect: _connectWindowsDevice,
              onRevoke: _revokeWindowsToken,
            ),
            const _ResourcePanel(
              title: 'Debian/Ubuntu (APT)',
              icon: Icons.developer_board_rounded,
              command: 'curl -fsSL https://endlessnet.ru/install.sh | sudo sh',
            ),
            const _ResourcePanel(
              title: 'Linux/macOS (install.sh)',
              icon: Icons.terminal_rounded,
              command: 'curl -fsSL https://endlessnet.ru/install.sh | sh',
            ),
            const _ResourcePanel(
              title: 'Android/iOS (WireGuard)',
              icon: Icons.phone_iphone_rounded,
              command:
                  'Используйте сгенерированный WireGuard-совместимый профиль с одобренного устройства.',
            ),
            const _ResourcePanel(
              title: 'API и MCP',
              icon: Icons.api_rounded,
              command: 'go run ./cmd/endlessnet-mcp',
            ),
            _ResourcePanel(
              title: 'Контекст аккаунта',
              icon: Icons.badge_rounded,
              command: [
                'account=${widget.account?.id ?? '-'}',
                'networks=${widget.networks.length}',
              ].join('\n'),
            ),
          ],
        ),
      ],
    );
  }

  String get _windowsEnrollmentLink {
    final token = stringValue(_token?['token']).trim();
    if (token.isEmpty) {
      return '';
    }
    return windowsEnrollmentLink(
      serverUrl: widget.apiBaseUrl,
      enrollToken: token,
      mode: _mode,
    );
  }

  NetworkModel? get _selectedNetwork {
    if (widget.networks.isEmpty) {
      return null;
    }
    for (final network in widget.networks) {
      if (network.id == _networkId) {
        return network;
      }
    }
    return widget.networks.first;
  }
}

class _WindowsEnrollmentPanel extends StatelessWidget {
  const _WindowsEnrollmentPanel({
    required this.account,
    required this.networks,
    required this.apiBaseUrl,
    required this.canMutate,
    required this.mode,
    required this.selectedNetworkId,
    required this.token,
    required this.enrollmentLink,
    required this.error,
    required this.creating,
    required this.revoking,
    required this.onModeChanged,
    required this.onNetworkChanged,
    required this.onDownload,
    required this.onConnect,
    required this.onRevoke,
  });

  final AccountModel? account;
  final List<NetworkModel> networks;
  final String apiBaseUrl;
  final bool canMutate;
  final String mode;
  final String selectedNetworkId;
  final Map<String, dynamic>? token;
  final String enrollmentLink;
  final String? error;
  final bool creating;
  final bool revoking;
  final ValueChanged<String> onModeChanged;
  final ValueChanged<String> onNetworkChanged;
  final VoidCallback onDownload;
  final VoidCallback onConnect;
  final VoidCallback onRevoke;

  @override
  Widget build(BuildContext context) {
    final colors = context.adminColors;
    final tokenId = stringValue(token?['id']).trim();
    final networkName = stringValue(token?['network_name']).trim();
    final tags = stringList(token?['tags']);
    final expiresAt = DateTime.tryParse(stringValue(token?['expires_at']));
    final reusable = boolValue(token?['reusable']);
    final ttl = expiresAt == null
        ? '-'
        : tokenTTLLabel(expiresAt, DateTime.now());
    final effectiveNetworkId =
        networks.any((network) => network.id == selectedNetworkId)
        ? selectedNetworkId
        : (networks.isEmpty ? '' : networks.first.id);
    return SizedBox(
      width: 760,
      child: SurfacePanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.desktop_windows_rounded),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Подключение Windows',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (enrollmentLink.isNotEmpty)
                  CopyButton(
                    value: enrollmentLink,
                    tooltip: 'Копировать ссылку подключения',
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'workstation',
                      icon: Icon(Icons.laptop_windows_rounded),
                      label: Text('Рабочая станция'),
                    ),
                    ButtonSegment(
                      value: 'server',
                      icon: Icon(Icons.dns_rounded),
                      label: Text('Сервер'),
                    ),
                    ButtonSegment(
                      value: 'subnet-router',
                      icon: Icon(Icons.route_rounded),
                      label: Text('Роутер'),
                    ),
                  ],
                  selected: {mode},
                  onSelectionChanged: creating || revoking
                      ? null
                      : (values) => onModeChanged(values.first),
                ),
                if (networks.isNotEmpty)
                  SizedBox(
                    width: 240,
                    child: DropdownButtonFormField<String>(
                      initialValue: effectiveNetworkId,
                      decoration: const InputDecoration(labelText: 'Network'),
                      items: [
                        for (final network in networks)
                          DropdownMenuItem(
                            value: network.id,
                            child: Text(
                              network.name.isEmpty ? network.id : network.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: creating || revoking
                          ? null
                          : (value) {
                              if (value != null) {
                                onNetworkChanged(value);
                              }
                            },
                    ),
                  ),
                FilledButton.icon(
                  onPressed: onDownload,
                  icon: const Icon(Icons.download_rounded),
                  label: const Text('Скачать установщик'),
                ),
                FilledButton.icon(
                  onPressed: canMutate && !creating ? onConnect : null,
                  icon: creating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.link_rounded),
                  label: const Text('Подключить это устройство'),
                ),
                if (tokenId.isNotEmpty)
                  OutlinedButton.icon(
                    onPressed: revoking ? null : onRevoke,
                    icon: const Icon(Icons.link_off_rounded),
                    label: const Text('Отозвать'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                StatusPill(label: reusable ? 'многоразовый' : 'одноразовый'),
                StatusPill(label: 'ttl $ttl'),
                StatusPill(
                  label: 'tags ${tags.isEmpty ? '-' : tags.join(', ')}',
                ),
                StatusPill(
                  label:
                      'сеть ${networkName.isEmpty ? (networks.isEmpty ? 'default' : networks.first.name) : networkName}',
                ),
                StatusPill(
                  label: 'сервер ${apiBaseUrl.isEmpty ? '-' : apiBaseUrl}',
                ),
              ],
            ),
            if (error != null && error!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(error!, style: TextStyle(color: colors.danger)),
            ],
            const SizedBox(height: 12),
            SelectableText(
              enrollmentLink.isEmpty
                  ? 'Установите приложение и подключите это устройство без командной строки.'
                  : enrollmentLink,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
            if (tokenId.isNotEmpty) ...[
              const SizedBox(height: 10),
              SelectableText(
                'token_id=$tokenId',
                style: TextStyle(color: colors.muted, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ResourcePanel extends StatelessWidget {
  const _ResourcePanel({
    required this.title,
    required this.icon,
    required this.command,
  });

  final String title;
  final IconData icon;
  final String command;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 360,
      child: SurfacePanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                CopyButton(value: command, tooltip: 'Копировать команду'),
              ],
            ),
            const SizedBox(height: 12),
            SelectableText(
              command,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
