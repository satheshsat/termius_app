import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

Future<String> getExecutableStoragePath(String fileName) async {
  try {
    // If running in test environment or flutter_tester, use project working directory
    if (Platform.environment.containsKey('FLUTTER_TEST') ||
        Platform.resolvedExecutable.contains('flutter_tester')) {
      return '${Directory.current.path}/$fileName';
    }

    // On Desktop (Linux, Windows, macOS), store in the executable's directory
    if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      final execPath = Platform.resolvedExecutable;
      final execDir = File(execPath).parent.path;
      return '$execDir/$fileName';
    }

    // On Mobile (Android, iOS), the executable directory is sandboxed and read-only,
    // so we use the application documents directory
    final appDocDir = await getApplicationDocumentsDirectory();
    return '${appDocDir.path}/$fileName';
  } catch (e) {
    debugPrint('Error getting executable directory: $e');
    return '${Directory.current.path}/$fileName';
  }
}

Future<String?> readTextFile(String path) async {
  try {
    final file = File(path);
    if (await file.exists()) {
      return await file.readAsString();
    }
  } catch (_) {}
  return null;
}

Future<void> writeTextFile(String path, String content) async {
  try {
    final tmpFile = File('$path.tmp');
    await tmpFile.writeAsString(content, flush: true);
    await tmpFile.rename(path);
  } catch (_) {
    try {
      final file = File(path);
      await file.writeAsString(content, flush: true);
    } catch (_) {}
  }
}
