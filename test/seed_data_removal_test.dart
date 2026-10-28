import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:termius_app/models/group_model.dart';
import 'package:termius_app/models/host_model.dart';
import 'package:termius_app/models/ssh_key_model.dart';
import 'package:termius_app/models/snippet_model.dart';
import 'package:termius_app/models/port_forward_model.dart';
import 'package:termius_app/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Seed Data Removal & Sanitization Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('createDefaultData has zero seed data in all collections', () {
      final bundle = StorageService.createDefaultData();
      expect(bundle.hosts, isEmpty, reason: 'Default hosts must be empty');
      expect(bundle.groups, isEmpty, reason: 'Default groups must be empty');
      expect(bundle.keys, isEmpty, reason: 'Default keys must be empty');
      expect(bundle.snippets, isEmpty, reason: 'Default snippets must be empty');
      expect(bundle.portForwards, isEmpty, reason: 'Default port forwards must be empty');
      expect(bundle.settings['fontFamily'], 'JetBrains Mono');
    });

    test('sanitize() purges legacy sample data while preserving custom user data', () {
      final sampleBundle = StorageDataBundle(
        hosts: [
          HostModel(
            id: 'host_ubuntu_demo',
            alias: 'Ubuntu Production VPS',
            hostname: '198.51.100.24',
            createdAt: DateTime.now(),
          ),
          HostModel(
            id: 'user_custom_host_1',
            alias: 'My Custom Server',
            hostname: '192.168.1.50',
            createdAt: DateTime.now(),
          ),
        ],
        groups: [
          GroupModel(id: 'group_cloud', name: 'Cloud Production'),
          GroupModel(id: 'user_group_1', name: 'My Group'),
        ],
        keys: [
          SSHKeyModel(
            id: 'key_prod',
            name: 'id_ed25519_production',
            keyType: 'Ed25519',
            publicKey: 'pub',
            privateKey: 'priv',
            createdAt: DateTime.now(),
          ),
          SSHKeyModel(
            id: 'user_key_1',
            name: 'my_id_rsa',
            keyType: 'RSA',
            publicKey: 'pub',
            privateKey: 'priv',
            createdAt: DateTime.now(),
          ),
        ],
        snippets: [
          SnippetModel(
            id: 'snip_docker_ps',
            title: 'Docker Containers Status',
            command: 'docker ps',
            category: 'Docker',
          ),
          SnippetModel(
            id: 'user_snippet_1',
            title: 'Deploy App',
            command: './deploy.sh',
            category: 'Custom',
          ),
        ],
        portForwards: [
          PortForwardModel(
            id: 'pf_postgres',
            name: 'Secure Remote Postgres Tunnel',
            hostId: 'host_postgres',
            localPort: 5433,
            remotePort: 5432,
          ),
          PortForwardModel(
            id: 'user_pf_1',
            name: 'Custom Tunnel',
            hostId: 'user_custom_host_1',
            localPort: 8080,
            remotePort: 80,
          ),
        ],
        settings: {},
        lastModified: DateTime.now(),
      );

      final cleaned = StorageService.sanitize(sampleBundle);
      expect(cleaned, isNotNull);
      // All sample items purged
      expect(cleaned!.hosts.map((h) => h.id), ['user_custom_host_1']);
      expect(cleaned.groups.map((g) => g.id), ['user_group_1']);
      expect(cleaned.keys.map((k) => k.id), ['user_key_1']);
      expect(cleaned.snippets.map((s) => s.id), ['user_snippet_1']);
      expect(cleaned.portForwards.map((pf) => pf.id), ['user_pf_1']);

      // Running sanitize on already clean bundle returns null (no changes)
      final cleanResult = StorageService.sanitize(cleaned);
      expect(cleanResult, isNull);
    });
  });
}
