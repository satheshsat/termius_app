import 'package:dartssh2/dartssh2.dart';
import 'package:xterm/xterm.dart';
import 'host_model.dart';

enum TerminalConnectionStatus {
  connecting,
  connected,
  disconnected,
  error,
}

class TerminalSessionModel {
  final String id;
  String title;
  final HostModel? host;
  final Terminal terminal;
  final TerminalController controller;
  SSHClient? client;
  SSHSession? session;
  TerminalConnectionStatus status;
  String? errorMessage;
  bool isSimulated;
  DateTime startedAt;

  // For simulation shell state
  String inputBuffer = '';
  final List<String> commandHistory = [];
  int historyPointer = -1;

  TerminalSessionModel({
    required this.id,
    required this.title,
    this.host,
    required this.terminal,
    required this.controller,
    this.client,
    this.session,
    this.status = TerminalConnectionStatus.connecting,
    this.errorMessage,
    this.isSimulated = false,
    DateTime? startedAt,
  }) : startedAt = startedAt ?? DateTime.now();

  void dispose() {
    try {
      session?.close();
    } catch (_) {}
    try {
      client?.close();
    } catch (_) {}
  }
}
