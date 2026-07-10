String windowsEnrollmentCommand({
  required String installScriptUrl,
  required String serverUrl,
  required String enrollToken,
  required String mode,
}) {
  final script = _psSingle(installScriptUrl.trim());
  final server = _psSingle(_trimTrailingSlash(serverUrl));
  final token = _psSingle(enrollToken.trim());
  final selectedMode = _psSingle(_windowsMode(mode));
  return [
    'powershell',
    '-ExecutionPolicy Bypass',
    '-NoProfile',
    '-Command',
    _psDouble(
      '\$s=(iwr $script -UseB).Content; & '
      '([scriptblock]::Create(\$s)) -Server $server '
      '-EnrollToken $token -Mode $selectedMode',
    ),
  ].join(' ');
}

const windowsInstallerURL =
    'https://endlessnet.ru/downloads/EndlessNet.Client.msi';

String windowsEnrollmentLink({
  required String serverUrl,
  required String enrollToken,
  required String mode,
}) {
  final query = <String, String>{
    'server': _trimTrailingSlash(serverUrl),
    'token': enrollToken.trim(),
    'mode': _windowsMode(mode),
  }..removeWhere((_, value) => value.trim().isEmpty);
  return Uri(
    scheme: 'endlessnet',
    host: 'enroll',
    queryParameters: query,
  ).toString();
}

String windowsCompatibilityCommand({
  required String serverUrl,
  required String enrollToken,
}) {
  return [
    'endlessnet-client.exe',
    'up',
    '--server',
    _psSingle(_trimTrailingSlash(serverUrl)),
    '--join-token',
    _psSingle(enrollToken.trim()),
  ].join(' ');
}

List<String> windowsEnrollmentTags(String mode) => [
  'platform:windows',
  'mode:${_windowsMode(mode)}',
];

String tokenTTLLabel(DateTime expiresAt, DateTime now) {
  final remaining = expiresAt.toUtc().difference(now.toUtc());
  if (remaining.isNegative) {
    return 'expired';
  }
  final hours = remaining.inHours;
  if (hours >= 1) {
    final minutes = remaining.inMinutes.remainder(60);
    return minutes == 0 ? '${hours}h' : '${hours}h ${minutes}m';
  }
  final minutes = remaining.inMinutes;
  return minutes <= 0 ? '<1m' : '${minutes}m';
}

String _windowsMode(String mode) {
  final normalized = mode.trim().toLowerCase();
  return switch (normalized) {
    'server' => 'server',
    'subnet-router' => 'subnet-router',
    _ => 'workstation',
  };
}

String _trimTrailingSlash(String value) =>
    value.trim().replaceFirst(RegExp(r'/+$'), '');

String _psSingle(String value) => "'${value.replaceAll("'", "''")}'";

String _psDouble(String value) =>
    '"${value.replaceAll('`', '``').replaceAll('"', '`"')}"';
