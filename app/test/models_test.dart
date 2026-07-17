import 'dart:convert';
import 'dart:io';

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

  group('published device endpoints', () {
    late Map<String, dynamic> fixture;

    setUpAll(() {
      fixture =
          jsonDecode(
                File('test/fixtures/device_endpoints.json').readAsStringSync(),
              )
              as Map<String, dynamic>;
    });

    test('keeps the primary designation while de-duplicating candidates', () {
      final machine = MachineModel.fromJson(
        (fixture['machines'] as List).first as Map<String, dynamic>,
      );

      expect(machine.endpointGeneration, 12);
      expect(machine.endpointExpiresAt, DateTime.utc(2099, 7, 17, 12));
      expect(machine.publishedEndpoints.map((item) => item.value), [
        '203.0.113.10:41641',
        '192.0.2.10:41641',
        '[2001:db8::10]:41641',
      ]);
      expect(machine.publishedEndpoints.map((item) => item.isPrimary), [
        true,
        false,
        false,
      ]);
      expect(
        machine.endpointPublicationIsExpiredAt(DateTime.utc(2026, 7, 17)),
        isFalse,
      );
    });

    test('handles empty and expired endpoint publications', () {
      final machines = (fixture['machines'] as List)
          .cast<Map<String, dynamic>>()
          .map(MachineModel.fromJson)
          .toList(growable: false);
      final empty = machines[1];
      final expired = machines[2];

      expect(empty.publishedEndpoints, isEmpty);
      expect(
        empty.endpointPublicationIsExpiredAt(DateTime.utc(2026, 7, 17)),
        isFalse,
      );
      expect(
        expired.endpointPublicationIsExpiredAt(DateTime.utc(2026, 7, 17)),
        isTrue,
      );
    });

    test('reads endpoint publication fields from node DTOs', () {
      final node = NodeModel.fromJson(
        (fixture['nodes'] as List).first as Map<String, dynamic>,
      );

      expect(node.endpoint, '[2001:db8:2::13]:51820');
      expect(node.endpointGeneration, 7);
      expect(node.publishedEndpoints.map((item) => item.value), [
        '[2001:db8:2::13]:51820',
        '203.0.113.13:51820',
      ]);
      expect(node.publishedEndpoints.first.isPrimary, isTrue);
    });
  });
}
