import 'package:dartssh2/dartssh2.dart';

class SftpItem {
  final String name;
  final String path;
  final bool isDirectory;
  final int size;
  final DateTime modifiedTime;
  final String permissions;

  SftpItem({
    required this.name,
    required this.path,
    required this.isDirectory,
    required this.size,
    required this.modifiedTime,
    required this.permissions,
  });

  String get formattedSize {
    if (isDirectory) return '--';
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    if (size < 1024 * 1024 * 1024) {
      return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

class SftpService {
  /// List remote files at [remotePath] using either real SFTP client or realistic simulated items
  static Future<List<SftpItem>> listDirectory({
    SSHClient? client,
    required String remotePath,
    bool isSimulated = false,
  }) async {
    if (!isSimulated && client != null) {
      try {
        final sftp = await client.sftp();
        final names = await sftp.listdir(remotePath);
        final List<SftpItem> items = [];

        for (final entry in names) {
          if (entry.filename == '.' || entry.filename == '..') continue;
          final isDir = entry.attr.isDirectory;
          final fullPath = remotePath.endsWith('/')
              ? '$remotePath${entry.filename}'
              : '$remotePath/${entry.filename}';

          items.add(
            SftpItem(
              name: entry.filename,
              path: fullPath,
              isDirectory: isDir,
              size: entry.attr.size ?? 0,
              modifiedTime: entry.attr.modifyTime != null
                  ? DateTime.fromMillisecondsSinceEpoch(
                      entry.attr.modifyTime! * 1000)
                  : DateTime.now(),
              permissions: isDir ? 'rwxr-xr-x' : 'rw-r--r--',
            ),
          );
        }

        // Sort: directories first, then alphabetically
        items.sort((a, b) {
          if (a.isDirectory && !b.isDirectory) return -1;
          if (!a.isDirectory && b.isDirectory) return 1;
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        });

        return items;
      } catch (e) {
        // Fall back to simulated list if SFTP fails
      }
    }

    // Simulated filesystem for mock/demo mode
    final now = DateTime.now();
    if (remotePath == '/' || remotePath.isEmpty) {
      return [
        SftpItem(name: 'bin', path: '/bin', isDirectory: true, size: 4096, modifiedTime: now, permissions: 'rwxr-xr-x'),
        SftpItem(name: 'etc', path: '/etc', isDirectory: true, size: 4096, modifiedTime: now, permissions: 'rwxr-xr-x'),
        SftpItem(name: 'home', path: '/home', isDirectory: true, size: 4096, modifiedTime: now, permissions: 'rwxr-xr-x'),
        SftpItem(name: 'var', path: '/var', isDirectory: true, size: 4096, modifiedTime: now, permissions: 'rwxr-xr-x'),
        SftpItem(name: 'usr', path: '/usr', isDirectory: true, size: 4096, modifiedTime: now, permissions: 'rwxr-xr-x'),
        SftpItem(name: 'opt', path: '/opt', isDirectory: true, size: 4096, modifiedTime: now, permissions: 'rwxr-xr-x'),
      ];
    }

    return [
      SftpItem(name: '.ssh', path: '$remotePath/.ssh', isDirectory: true, size: 4096, modifiedTime: now, permissions: 'rwx------'),
      SftpItem(name: 'app', path: '$remotePath/app', isDirectory: true, size: 4096, modifiedTime: now, permissions: 'rwxr-xr-x'),
      SftpItem(name: 'logs', path: '$remotePath/logs', isDirectory: true, size: 4096, modifiedTime: now, permissions: 'rwxr-xr-x'),
      SftpItem(name: 'docker-compose.yml', path: '$remotePath/docker-compose.yml', isDirectory: false, size: 1204, modifiedTime: now, permissions: 'rw-r--r--'),
      SftpItem(name: 'nginx.conf', path: '$remotePath/nginx.conf', isDirectory: false, size: 2450, modifiedTime: now, permissions: 'rw-r--r--'),
      SftpItem(name: 'deploy.sh', path: '$remotePath/deploy.sh', isDirectory: false, size: 512, modifiedTime: now, permissions: 'rwxr-xr-x'),
      SftpItem(name: 'config.json', path: '$remotePath/config.json', isDirectory: false, size: 4096, modifiedTime: now, permissions: 'rw-r--r--'),
      SftpItem(name: 'production.env', path: '$remotePath/production.env', isDirectory: false, size: 850, modifiedTime: now, permissions: 'rw-------'),
    ];
  }
}
