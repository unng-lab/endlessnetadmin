import 'package:endlessnet_admin/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('NodeModel reads status from API payload', () {
    final node = NodeModel.fromJson({
      'id': 'node-1',
      'network_id': 'net-1',
      'user_id': 'user-1',
      'hostname': 'laptop',
      'public_key': 'pub',
      'assigned_ip': '100.64.0.2',
      'status': 'offline',
      'advertised_ips': ['10.0.0.0/24'],
      'tags': ['workstation'],
      'created_at': '2026-06-26T09:00:00Z',
      'updated_at': '2026-06-26T09:05:00Z',
      'last_seen': '2026-06-26T09:10:00Z',
    });

    expect(node.status, 'offline');
    expect(node.hostname, 'laptop');
    expect(node.tags, ['workstation']);
  });
}
