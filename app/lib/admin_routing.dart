const adminMachineQueryParameter = 'machine';

String machineIdFromAdminLocation(Uri location) {
  return location.queryParameters[adminMachineQueryParameter]?.trim() ?? '';
}

String adminMachineSelectionLocation(String adminRootPath, String machineId) {
  final root = adminRootPath.endsWith('/') ? adminRootPath : '$adminRootPath/';
  final path = '${root}machines/';
  final selected = machineId.trim();
  if (selected.isEmpty) {
    return path;
  }
  return '$path?$adminMachineQueryParameter=${Uri.encodeQueryComponent(selected)}';
}
