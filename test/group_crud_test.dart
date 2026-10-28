import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:termius_app/models/group_model.dart';
import 'package:termius_app/models/host_model.dart';
import 'package:termius_app/providers/app_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Group CRUD & Cascading Tests in AppProvider', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Create, Update, and Delete Groups cleanly', () async {
      final provider = AppProvider();
      await Future.delayed(const Duration(milliseconds: 100));

      // 1. Initial state should have NO sample groups or hosts
      expect(provider.groups, isEmpty);
      expect(provider.hosts, isEmpty);

      // 2. Add Group
      final group1 = GroupModel(
        id: 'group_prod',
        name: 'Production',
        colorHex: '#00D2FF',
        iconName: 'server',
        description: 'Live servers',
      );
      provider.addGroup(group1);
      expect(provider.groups.length, 1);
      expect(provider.groups.first.name, 'Production');

      // 3. Add Host to this group
      final host1 = HostModel(
        id: 'host_web_1',
        alias: 'Web 1',
        hostname: '10.0.0.1',
        group: 'Production',
        createdAt: DateTime.now(),
      );
      provider.addHost(host1);
      expect(provider.hosts.length, 1);
      expect(provider.getGroupHostCount('Production'), 1);

      // 4. Update Group (rename from Production to Prod-V2)
      final updatedGroup1 = group1.copyWith(name: 'Prod-V2');
      provider.updateGroup(updatedGroup1, oldName: 'Production');
      expect(provider.groups.first.name, 'Prod-V2');
      // Host should automatically cascade to new group name
      expect(provider.hosts.first.group, 'Prod-V2');
      expect(provider.getGroupHostCount('Prod-V2'), 1);

      // 5. Delete Group
      provider.deleteGroup(group1.id);
      expect(provider.groups, isEmpty);
      // Host should be moved to 'Default'
      expect(provider.hosts.first.group, 'Default');
    });
  });
}
