import 'package:endlessnet_admin/admin_routing.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('machine selection is read only from the query parameter', () {
    expect(
      machineIdFromAdminLocation(
        Uri.parse('https://admin.example.test/machines/?machine=node%2F1'),
      ),
      'node/1',
    );
    expect(
      machineIdFromAdminLocation(
        Uri.parse('https://admin.example.test/machines/legacy-id/'),
      ),
      isEmpty,
    );
  });

  test('machine selection stays on the static machines route', () {
    expect(
      adminMachineSelectionLocation('/admin/', 'node/id + 1'),
      '/admin/machines/?machine=node%2Fid+%2B+1',
    );
    expect(adminMachineSelectionLocation('/admin/', ''), '/admin/machines/');
  });
}
