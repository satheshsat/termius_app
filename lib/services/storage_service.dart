import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'file_io.dart';

import '../models/host_model.dart';
import '../models/group_model.dart';
import '../models/ssh_key_model.dart';
import '../models/snippet_model.dart';
import '../models/port_forward_model.dart';

class StorageDataBundle {
  final List<HostModel> hosts;
  final List<GroupModel> groups;
  final List<SSHKeyModel> keys;
  final List<SnippetModel> snippets;
  final List<PortForwardModel> portForwards;
  final Map<String, dynamic> settings;
  final DateTime lastModified;

  StorageDataBundle({
    required this.hosts,
    required this.groups,
    required this.keys,
    required this.snippets,
    required this.portForwards,
    required this.settings,
    required this.lastModified,
  });

  Map<String, dynamic> toJson() {
    return {
      'version': '1.0.0',
      'appName': 'Termius Cross-Platform SSH Clone',
      'lastModified': lastModified.toIso8601String(),
      'settings': settings,
      'groups': groups.map((g) => g.toJson()).toList(),
      'hosts': hosts.map((h) => h.toJson()).toList(),
      'keys': keys.map((k) => k.toJson()).toList(),
      'snippets': snippets.map((s) => s.toJson()).toList(),
      'portForwards': portForwards.map((p) => p.toJson()).toList(),
    };
  }

  factory StorageDataBundle.fromJson(Map<String, dynamic> json) {
    return StorageDataBundle(
      hosts: (json['hosts'] as List<dynamic>?)
              ?.map((item) => HostModel.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      groups: (json['groups'] as List<dynamic>?)
              ?.map((item) => GroupModel.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      keys: (json['keys'] as List<dynamic>?)
              ?.map((item) => SSHKeyModel.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      snippets: (json['snippets'] as List<dynamic>?)
              ?.map((item) => SnippetModel.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      portForwards: (json['portForwards'] as List<dynamic>?)
              ?.map((item) =>
                  PortForwardModel.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      settings: (json['settings'] as Map<String, dynamic>?) ?? {},
      lastModified: json['lastModified'] != null
          ? DateTime.tryParse(json['lastModified'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class StorageService {
  static const String _prefKey = 'termius_data_json_backup';
  static const String fileName = 'termius_data.json';

  String? _cachedFilePath;

  String? get currentFilePath => _cachedFilePath;

  /// Returns the absolute path where termius_data.json is stored (executable directory on desktop)
  Future<String> getJsonFilePath() async {
    if (_cachedFilePath != null) return _cachedFilePath!;

    if (kIsWeb) {
      _cachedFilePath = 'Browser LocalStorage ($fileName)';
      return _cachedFilePath!;
    }

    try {
      _cachedFilePath = await getExecutableStoragePath(fileName);
      return _cachedFilePath!;
    } catch (e) {
      debugPrint('Error getting executable directory: $e');
      _cachedFilePath = fileName;
      return fileName;
    }
  }

  /// Load data from termius_data.json or fallback/seed
  Future<StorageDataBundle> loadData() async {
    try {
      String? jsonString;

      if (!kIsWeb) {
        final filePath = await getJsonFilePath();
        jsonString = await readTextFile(filePath);

        // If file not yet present in executable path, check if it was previously saved in Documents
        if (jsonString == null || jsonString.isEmpty) {
          try {
            final docsDir = await getApplicationDocumentsDirectory();
            final legacyPath = '${docsDir.path}/$fileName';
            jsonString = await readTextFile(legacyPath);
            if (jsonString != null && jsonString.isNotEmpty) {
              debugPrint('Migrating Termius data from Documents to executable path: $filePath');
              await writeTextFile(filePath, jsonString);
            }
          } catch (_) {}
        }

        if (jsonString != null && jsonString.isNotEmpty) {
          debugPrint('Loaded Termius data from JSON file: $filePath');
        }
      }

      // Check SharedPreferences if not on disk or on web
      if (jsonString == null || jsonString.isEmpty) {
        final prefs = await SharedPreferences.getInstance();
        jsonString = prefs.getString(_prefKey);
      }

      if (jsonString != null && jsonString.isNotEmpty) {
        final decoded = json.decode(jsonString) as Map<String, dynamic>;
        final bundle = StorageDataBundle.fromJson(decoded);
        return bundle;
      }
    } catch (e, stack) {
      debugPrint('Error loading JSON data: $e\n$stack');
    }

    // If nothing found or error, create default seed data and save to file immediately
    final defaultBundle = createDefaultData();
    await saveData(defaultBundle);
    return defaultBundle;
  }

  /// Save data to termius_data.json and sync to preferences
  Future<bool> saveData(StorageDataBundle bundle) async {
    try {
      final encoder = const JsonEncoder.withIndent('  ');
      final jsonString = encoder.convert(bundle.toJson());

      // Save to SharedPreferences as backup & for Web
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, jsonString);

      // Save to physical JSON file on native platforms (Linux, macOS, Windows, Android, iOS)
      if (!kIsWeb) {
        final filePath = await getJsonFilePath();
        await writeTextFile(filePath, jsonString);
        debugPrint('Successfully saved data to JSON file: $filePath');
      }

      return true;
    } catch (e, stack) {
      debugPrint('Error saving JSON data: $e\n$stack');
      return false;
    }
  }

  /// Get the raw formatted JSON string for export or viewing
  Future<String> exportRawJson(StorageDataBundle bundle) async {
    final encoder = const JsonEncoder.withIndent('  ');
    return encoder.convert(bundle.toJson());
  }

  /// Import from a raw JSON string
  Future<StorageDataBundle?> importFromJsonString(String rawJson) async {
    try {
      final decoded = json.decode(rawJson) as Map<String, dynamic>;
      final bundle = StorageDataBundle.fromJson(decoded);
      await saveData(bundle);
      return bundle;
    } catch (e) {
      debugPrint('Import error: $e');
      return null;
    }
  }

  /// Default seed data with realistic servers, snippets, keys, groups
  static StorageDataBundle createDefaultData() {
    final now = DateTime.now();

    final groups = [
      GroupModel(
        id: 'group_cloud',
        name: 'Cloud Production',
        colorHex: '#00D2FF',
        iconName: 'cloud',
        description: 'Production cloud instances and API clusters',
      ),
      GroupModel(
        id: 'group_aws',
        name: 'AWS Staging',
        colorHex: '#8B5CF6',
        iconName: 'server',
        description: 'Staging environment and load balancers',
      ),
      GroupModel(
        id: 'group_homelab',
        name: 'Home Lab & IoT',
        colorHex: '#10B981',
        iconName: 'microchip',
        description: 'Local Raspberry Pi, NAS, and development boxes',
      ),
      GroupModel(
        id: 'group_db',
        name: 'Databases',
        colorHex: '#F59E0B',
        iconName: 'database',
        description: 'PostgreSQL, Redis, and MySQL clusters',
      ),
    ];

    final keys = [
      SSHKeyModel(
        id: 'key_prod',
        name: 'id_ed25519_production',
        keyType: 'Ed25519',
        publicKey:
            'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGe9mQ0sR3d0K1Y2e5e4n5m6termius-demo-key dev@termius.app',
        privateKey:
            '-----BEGIN OPENSSH PRIVATE KEY-----\nb3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAAAMwAAAAtzc2gtZW\nQyNTUxOQAAACAAg5+7+c+32+TermiusKeyDemoMockProductionPrivate123456789==\n-----END OPENSSH PRIVATE KEY-----',
        fingerprint: 'SHA256:dZ81kx99wLa8U/J7Q3r5pL4m3b+K1Y9vE3m2q',
        createdAt: now.subtract(const Duration(days: 30)),
      ),
      SSHKeyModel(
        id: 'key_homelab',
        name: 'id_rsa_homelab',
        keyType: 'RSA',
        publicKey:
            'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC8+SampleTermiusLabKeyRsa2048BitLengthSecureKey pi@raspberrypi',
        privateKey:
            '-----BEGIN RSA PRIVATE KEY-----\nMIIEowIBAAKCAQEAvsampleRsaKeyDataHereTermiusAppPrivateFile12345\n-----END RSA PRIVATE KEY-----',
        fingerprint: 'SHA256:yT42b99wLa1U/M3Q8r5pL0m3b+K1Y2vE8m1q',
        createdAt: now.subtract(const Duration(days: 60)),
      ),
    ];

    final hosts = [
      HostModel(
        id: 'host_ubuntu_demo',
        alias: 'Ubuntu Production VPS',
        hostname: '198.51.100.24',
        port: 22,
        username: 'root',
        password: '',
        keyId: 'key_prod',
        group: 'Cloud Production',
        colorHex: '#00D2FF',
        tags: ['prod', 'nginx', 'fastapi', 'ubuntu'],
        notes: 'Main Nginx reverse proxy and API cluster entrypoint.',
        createdAt: now.subtract(const Duration(days: 14)),
        lastConnectedAt: now.subtract(const Duration(hours: 3)),
        status: 'online',
        isFavorite: true,
      ),
      HostModel(
        id: 'host_aws_ec2',
        alias: 'AWS EC2 Microservices',
        hostname: 'ec2-54-210-14-88.compute-1.amazonaws.com',
        port: 22,
        username: 'ubuntu',
        password: '',
        keyId: 'key_prod',
        group: 'AWS Staging',
        colorHex: '#8B5CF6',
        tags: ['aws', 'staging', 'docker', 'k8s'],
        notes: 'Docker Swarm worker node in us-east-1.',
        createdAt: now.subtract(const Duration(days: 20)),
        lastConnectedAt: now.subtract(const Duration(days: 1)),
        status: 'online',
        isFavorite: true,
      ),
      HostModel(
        id: 'host_rpi5',
        alias: 'Raspberry Pi 5 Lab',
        hostname: '192.168.1.150',
        port: 22,
        username: 'pi',
        password: 'raspberrypi',
        keyId: 'key_homelab',
        group: 'Home Lab & IoT',
        colorHex: '#10B981',
        tags: ['homelab', 'arm64', 'pihole', 'wireguard'],
        notes: 'Home gateway running Pi-hole DNS and WireGuard VPN.',
        createdAt: now.subtract(const Duration(days: 45)),
        lastConnectedAt: now.subtract(const Duration(minutes: 42)),
        status: 'online',
        isFavorite: true,
      ),
      HostModel(
        id: 'host_postgres',
        alias: 'PostgreSQL Primary DB',
        hostname: '10.0.4.12',
        port: 2222,
        username: 'postgres',
        password: '',
        keyId: 'key_prod',
        group: 'Databases',
        colorHex: '#F59E0B',
        tags: ['database', 'postgres', 'replication', 'nvme'],
        notes: 'Primary database node with WAL archiving and streaming replication.',
        createdAt: now.subtract(const Duration(days: 60)),
        lastConnectedAt: now.subtract(const Duration(days: 3)),
        status: 'online',
        isFavorite: false,
      ),
      HostModel(
        id: 'host_local_dev',
        alias: 'Localhost SSH / Dev Shell',
        hostname: '127.0.0.1',
        port: 22,
        username: 'sathesh',
        password: '',
        group: 'Home Lab & IoT',
        colorHex: '#EC4899',
        tags: ['local', 'mint', 'dev'],
        notes: 'Local workstation terminal session.',
        createdAt: now.subtract(const Duration(days: 5)),
        lastConnectedAt: now.subtract(const Duration(minutes: 5)),
        status: 'online',
        isFavorite: true,
      ),
    ];

    final snippets = [
      SnippetModel(
        id: 'snip_docker_ps',
        title: 'Docker Containers Status',
        command:
            'docker ps -a --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"',
        category: 'Docker',
        description: 'Displays a clean table of active and stopped containers.',
      ),
      SnippetModel(
        id: 'snip_htop',
        title: 'Interactive System Monitor',
        command: 'htop || top',
        category: 'Monitoring',
        description: 'Launches real-time process manager and system metrics.',
      ),
      SnippetModel(
        id: 'snip_disk_usage',
        title: 'Disk Space Overview (Clean)',
        command: 'df -h --exclude-type=tmpfs --exclude-type=devtmpfs',
        category: 'System',
        description: 'Clean breakdown of storage usage across physical disks.',
      ),
      SnippetModel(
        id: 'snip_listening_ports',
        title: 'Listening TCP/UDP Ports',
        command: 'ss -tulpn | grep LISTEN',
        category: 'Network',
        description: 'Lists all processes with open ports and sockets.',
      ),
      SnippetModel(
        id: 'snip_nginx_reload',
        title: 'Nginx Config Test & Reload',
        command: 'sudo nginx -t && sudo systemctl reload nginx',
        category: 'Web Server',
        description: 'Verifies Nginx syntax then applies changes with zero downtime.',
      ),
      SnippetModel(
        id: 'snip_tail_logs',
        title: 'Follow System Journal Logs',
        command: 'journalctl -f -n 100',
        category: 'Logs',
        description: 'Streams live output of the latest 100 systemd log entries.',
      ),
      SnippetModel(
        id: 'snip_sys_info',
        title: 'Fast System Diagnostic',
        command:
            'echo "=== HOSTNAME & KERNEL ===" && uname -a && echo -e "\n=== UPTIME & LOAD ===" && uptime && echo -e "\n=== MEMORY ===" && free -h',
        category: 'System',
        description: 'Prints kernel, uptime, load average, and RAM usage in one glance.',
      ),
    ];

    final portForwards = [
      PortForwardModel(
        id: 'pf_postgres',
        name: 'Secure Remote Postgres Tunnel',
        hostId: 'host_postgres',
        forwardType: 'Local',
        localPort: 5433,
        remoteHost: '127.0.0.1',
        remotePort: 5432,
        isActive: false,
      ),
      PortForwardModel(
        id: 'pf_redis',
        name: 'Redis Cache Port 6379',
        hostId: 'host_ubuntu_demo',
        forwardType: 'Local',
        localPort: 6380,
        remoteHost: '127.0.0.1',
        remotePort: 6379,
        isActive: false,
      ),
    ];

    final settings = {
      'theme': 'Termius Obsidian Dark',
      'fontFamily': 'JetBrains Mono',
      'fontSize': 14.0,
      'cursorBlink': true,
      'cursorStyle': 'block', // 'block', 'underline', 'bar'
      'soundBell': false,
      'autoSave': true,
    };

    return StorageDataBundle(
      hosts: hosts,
      groups: groups,
      keys: keys,
      snippets: snippets,
      portForwards: portForwards,
      settings: settings,
      lastModified: now,
    );
  }
}
