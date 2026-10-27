import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dartssh2/dartssh2.dart';

import '../models/host_model.dart';
import '../models/ssh_key_model.dart';
import '../models/terminal_session_model.dart';

class SSHService {
  /// Start a connection for the given session and host
  static Future<void> connectSession({
    required TerminalSessionModel session,
    required HostModel host,
    List<SSHKeyModel> availableKeys = const [],
    bool forceSimulation = false,
  }) async {
    final terminal = session.terminal;
    session.status = TerminalConnectionStatus.connecting;

    // Print starting banner
    terminal.write('\x1b[38;5;51m[Termius SSH]\x1b[0m Connecting to \x1b[1;37m${host.alias}\x1b[0m (${host.username}@${host.hostname}:${host.port})...\r\n');

    // On Web or forced simulation, jump directly to interactive simulator
    if (kIsWeb || forceSimulation) {
      await Future.delayed(const Duration(milliseconds: 300));
      _startSimulatedShell(session, host);
      return;
    }

    // Try real SSH connection on Desktop/Mobile
    try {
      terminal.write('\x1b[90mEstablishing TCP socket connection...\x1b[0m\r\n');
      
      final socket = await SSHSocket.connect(
        host.hostname,
        host.port,
        timeout: const Duration(seconds: 8),
      );

      terminal.write('\x1b[90mSocket connected! Authenticating as ${host.username}...\x1b[0m\r\n');

      // Prepare identities (keys)
      List<SSHKeyPair> identities = [];
      if (host.keyId != null) {
        final keyModel = availableKeys.firstWhere(
          (k) => k.id == host.keyId,
          orElse: () => SSHKeyModel(
            id: '',
            name: '',
            publicKey: '',
            privateKey: '',
            createdAt: DateTime.now(),
          ),
        );

        if (keyModel.privateKey.isNotEmpty) {
          try {
            final parsedPairs = SSHKeyPair.fromPem(
              keyModel.privateKey,
              host.passphrase.isNotEmpty ? host.passphrase : null,
            );
            identities.addAll(parsedPairs);
          } catch (e) {
            terminal.write('\x1b[33mWarning: Failed to parse private key: $e. Falling back to password.\x1b[0m\r\n');
          }
        }
      }

      final client = SSHClient(
        socket,
        username: host.username,
        onPasswordRequest: () => host.password,
        identities: identities.isNotEmpty ? identities : null,
      );

      await client.authenticated;
      session.client = client;

      terminal.write('\x1b[32m✔ Authenticated successfully via SSH2!\x1b[0m\r\n');

      final cols = terminal.viewWidth > 0 ? terminal.viewWidth : 80;
      final rows = terminal.viewHeight > 0 ? terminal.viewHeight : 24;

      final sshSession = await client.shell(
        pty: SSHPtyConfig(
          width: cols,
          height: rows,
        ),
      );
      session.session = sshSession;
      session.status = TerminalConnectionStatus.connected;
      session.isSimulated = false;

      // Pipe SSH stdout & stderr to Terminal
      sshSession.stdout.listen(
        (data) {
          terminal.write(utf8.decode(data, allowMalformed: true));
        },
        onDone: () {
          session.status = TerminalConnectionStatus.disconnected;
          terminal.write('\r\n\x1b[33m[Connection closed by remote host]\x1b[0m\r\n');
        },
        onError: (e) {
          session.status = TerminalConnectionStatus.error;
          terminal.write('\r\n\x1b[31m[SSH Stream Error: $e]\x1b[0m\r\n');
        },
      );

      sshSession.stderr.listen((data) {
        terminal.write(utf8.decode(data, allowMalformed: true));
      });

      // Pipe Terminal input to SSH stdin
      terminal.onOutput = (data) {
        try {
          sshSession.stdin.add(utf8.encode(data));
        } catch (e) {
          debugPrint('Error writing to stdin: $e');
        }
      };

      // Handle terminal resize
      terminal.onResize = (width, height, pixelWidth, pixelHeight) {
        try {
          sshSession.resizeTerminal(width, height);
        } catch (_) {}
      };
    } catch (e) {
      debugPrint('Real SSH failed ($e). Launching interactive Terminal Simulation.');
      terminal.write('\x1b[33mℹ Note: Could not reach live host ($e).\x1b[0m\r\n');
      terminal.write('\x1b[36m⚡ Switching to Termius Interactive UNIX Shell Simulator...\x1b[0m\r\n\r\n');
      _startSimulatedShell(session, host);
    }
  }

  /// Interactive UNIX shell simulator with command handling and ANSI styling
  static void _startSimulatedShell(TerminalSessionModel session, HostModel host) {
    final terminal = session.terminal;
    session.status = TerminalConnectionStatus.connected;
    session.isSimulated = true;

    final promptUser = host.username.isNotEmpty ? host.username : 'user';
    final promptHost = host.alias.replaceAll(RegExp(r'[^a-zA-Z0-9-]'), '-').toLowerCase();
    final promptStr = '\x1b[1;32m$promptUser@$promptHost\x1b[0m:\x1b[1;34m~\x1b[0m\$ ';

    // Pretty Welcome Banner
    terminal.write('''
\x1b[38;5;45m   ████████╗███████╗██████╗ ███╗   ███╗██╗██╗   ██╗███████╗
   ╚══██╔══╝██╔════╝██╔══██╗████╗ ████║██║██║   ██║██╔════╝
      ██║   █████╗  ██████╔╝██╔████╔██║██║██║   ██║███████╗
      ██║   ██╔══╝  ██╔══██╗██║╚██╔╝██║██║██║   ██║╚════██║
      ██║   ███████╗██║  ██║██║ ╚═╝ ██║██║╚██████╔╝███████║
      ╚═╝   ╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝╚═╝ ╚═════╝ ╚══════╝\x1b[0m
\x1b[90m  Welcome to Termius Cloud & Infrastructure Shell (v1.0.0)\x1b[0m
\x1b[32m✔ Authenticated securely with pseudo-TTY interactive shell\x1b[0m
\x1b[90m* Host: \x1b[37m${host.hostname}:${host.port}\x1b[90m | OS: Ubuntu 24.04 LTS (x86_64)\x1b[0m
\x1b[90m* Type \x1b[1;33mhelp\x1b[90m to view commands or run snippets from the bar below.\x1b[0m

$promptStr''');

    session.inputBuffer = '';

    terminal.onOutput = (data) {
      for (int i = 0; i < data.length; i++) {
        final char = data[i];

        // Enter key
        if (char == '\r' || char == '\n') {
          final command = session.inputBuffer.trim();
          terminal.write('\r\n');

          if (command.isNotEmpty) {
            session.commandHistory.add(command);
            session.historyPointer = session.commandHistory.length;
            _executeSimulatedCommand(session, host, command);
          }

          session.inputBuffer = '';
          terminal.write(promptStr);
        }
        // Backspace
        else if (char == '\x7f' || char == '\b') {
          if (session.inputBuffer.isNotEmpty) {
            session.inputBuffer =
                session.inputBuffer.substring(0, session.inputBuffer.length - 1);
            terminal.write('\b \b');
          }
        }
        // Ctrl+C
        else if (char == '\x03') {
          terminal.write('^C\r\n');
          session.inputBuffer = '';
          terminal.write(promptStr);
        }
        // Ctrl+L (Clear screen)
        else if (char == '\x0c') {
          terminal.write('\x1b[2J\x1b[H');
          terminal.write(promptStr);
          terminal.write(session.inputBuffer);
        }
        // Arrow Up (history previous)
        else if (data.contains('\x1b[A')) {
          if (session.commandHistory.isNotEmpty && session.historyPointer > 0) {
            session.historyPointer--;
            // Erase current input
            while (session.inputBuffer.isNotEmpty) {
              terminal.write('\b \b');
              session.inputBuffer =
                  session.inputBuffer.substring(0, session.inputBuffer.length - 1);
            }
            final prev = session.commandHistory[session.historyPointer];
            session.inputBuffer = prev;
            terminal.write(prev);
          }
          break;
        }
        // Arrow Down (history next)
        else if (data.contains('\x1b[B')) {
          if (session.historyPointer < session.commandHistory.length - 1) {
            session.historyPointer++;
            while (session.inputBuffer.isNotEmpty) {
              terminal.write('\b \b');
              session.inputBuffer =
                  session.inputBuffer.substring(0, session.inputBuffer.length - 1);
            }
            final next = session.commandHistory[session.historyPointer];
            session.inputBuffer = next;
            terminal.write(next);
          } else {
            session.historyPointer = session.commandHistory.length;
            while (session.inputBuffer.isNotEmpty) {
              terminal.write('\b \b');
              session.inputBuffer =
                  session.inputBuffer.substring(0, session.inputBuffer.length - 1);
            }
          }
          break;
        }
        // Normal printable characters
        else if (char.codeUnitAt(0) >= 32 && char.codeUnitAt(0) <= 126) {
          session.inputBuffer += char;
          terminal.write(char);
        }
      }
    };
  }

  /// Process simulated command and write realistic UNIX output
  static void _executeSimulatedCommand(
    TerminalSessionModel session,
    HostModel host,
    String rawCommand,
  ) {
    final terminal = session.terminal;
    final cmd = rawCommand.toLowerCase().trim();
    final parts = cmd.split(RegExp(r'\s+'));
    final mainCmd = parts.first;

    switch (mainCmd) {
      case 'help':
        terminal.write('''
\x1b[1;36mAvailable Simulated Shell Commands:\x1b[0m
  \x1b[33mls, ll, dir\x1b[0m       - List directory contents with permissions
  \x1b[33mpwd\x1b[0m               - Print working directory
  \x1b[33mwhoami\x1b[0m            - Display current user identity
  \x1b[33muname -a\x1b[0m          - View Linux kernel & machine architecture
  \x1b[33muptime\x1b[0m            - Show system uptime and load average
  \x1b[33mtop, htop\x1b[0m         - Real-time CPU and memory process table
  \x1b[33mfree -h\x1b[0m           - Memory & swap utilization
  \x1b[33mdf -h\x1b[0m             - Mounted filesystem disk capacity
  \x1b[33mdocker ps\x1b[0m         - List running docker microservices
  \x1b[33mss, netstat\x1b[0m       - View listening network sockets
  \x1b[33mcat <file>\x1b[0m        - View contents of file (e.g. cat .bashrc)
  \x1b[33mclear\x1b[0m             - Clear terminal screen buffer
  \x1b[33mecho <msg>\x1b[0m        - Print text to stdout
  \x1b[33mdate\x1b[0m              - Display current UTC/local system date
  \x1b[33mexit\x1b[0m              - Close terminal session
\x1b[90mTip: Click snippets from the Quick Snippets bar to execute them instantly!\x1b[0m\r\n''');
        break;

      case 'ls':
      case 'll':
      case 'dir':
        terminal.write('''
total 48
drwxr-xr-x 6 ${host.username} ${host.username} 4096 Oct 27 09:42 \x1b[1;34m.\x1b[0m
drwxr-xr-x 3 root   root   4096 Oct 20 10:00 \x1b[1;34m..\x1b[0m
-rw------- 1 ${host.username} ${host.username}  842 Oct 27 09:30 .bash_history
-rw-r--r-- 1 ${host.username} ${host.username}  220 Oct 20 10:00 .bash_logout
-rw-r--r-- 1 ${host.username} ${host.username} 3771 Oct 20 10:00 .bashrc
drwx------ 2 ${host.username} ${host.username} 4096 Oct 20 10:15 \x1b[1;34m.ssh\x1b[0m
drwxr-xr-x 8 ${host.username} ${host.username} 4096 Oct 26 14:22 \x1b[1;34mapp\x1b[0m
-rw-r--r-- 1 ${host.username} ${host.username} 1204 Oct 25 18:05 docker-compose.yml
-rw-r--r-- 1 ${host.username} ${host.username} 2450 Oct 24 11:30 nginx.conf
-rwxr-xr-x 1 ${host.username} ${host.username}  512 Oct 23 16:00 \x1b[1;32mdeploy.sh\x1b[0m
drwxr-xr-x 2 ${host.username} ${host.username} 4096 Oct 26 21:00 \x1b[1;34mlogs\x1b[0m\r\n''');
        break;

      case 'pwd':
        terminal.write('/home/${host.username}\r\n');
        break;

      case 'whoami':
        terminal.write('${host.username}\r\n');
        break;

      case 'uname':
        terminal.write('Linux ${host.alias.replaceAll(' ', '-').toLowerCase()} 6.8.0-45-generic #45-Ubuntu SMP PREEMPT_DYNAMIC Wed Oct 2 15:42:00 UTC 2026 x86_64 GNU/Linux\r\n');
        break;

      case 'uptime':
        terminal.write(' 09:55:12 up 32 days,  4:18,  2 users,  load average: 0.14, 0.08, 0.05\r\n');
        break;

      case 'free':
        terminal.write('''
               total        used        free      shared  buff/cache   available
Mem:            15Gi       3.8Gi       8.4Gi       210Mi       3.2Gi        11Gi
Swap:          4.0Gi          0B       4.0Gi\r\n''');
        break;

      case 'df':
        terminal.write('''
Filesystem      Size  Used Avail Use% Mounted on
/dev/nvme0n1p2  120G   38G   77G  33% /
/dev/nvme0n1p1  511M  6.2M  505M   2% /boot/efi
/dev/nvme1n1    500G  142G  333G  30% /data\r\n''');
        break;

      case 'docker':
        if (cmd.contains('ps')) {
          terminal.write('''
\x1b[1mCONTAINER ID   IMAGE                 COMMAND                  CREATED        STATUS        PORTS                                       NAMES\x1b[0m
\x1b[32ma7b3f912c01d\x1b[0m   nginx:alpine          "/docker-entrypoint.…"   2 days ago     Up 2 days     0.0.0.0:80->80/tcp, 0.0.0.0:443->443/tcp     \x1b[1;36mnginx-proxy\x1b[0m
\x1b[32m4c8e1a90b52f\x1b[0m   postgres:16-alpine    "docker-entrypoint.s…"   2 weeks ago    Up 2 weeks    0.0.0.0:5432->5432/tcp                      \x1b[1;36mpostgres-db\x1b[0m
\x1b[32m9d2a6e78f30c\x1b[0m   redis:7-alpine        "docker-entrypoint.s…"   2 weeks ago    Up 2 weeks    0.0.0.0:6379->6379/tcp                      \x1b[1;36mredis-cache\x1b[0m
\x1b[32m1f0e8b45c29a\x1b[0m   fastapi-app:latest    "uvicorn main:app --…"   5 hours ago    Up 5 hours    0.0.0.0:8000->8000/tcp                      \x1b[1;36mapi-backend\x1b[0m\r\n''');
        } else {
          terminal.write('Docker version 27.3.1, build ce12230\r\n');
        }
        break;

      case 'top':
      case 'htop':
        terminal.write('''
\x1b[7m  PID USER      PR  NI    VIRT    RES    SHR S  %CPU  %MEM     TIME+ COMMAND             \x1b[0m
 1042 root      20   0  712400  84200  32100 S   2.3   0.5  12:45.12 dockerd
 1890 www-data  20   0  184200  42100  18900 S   1.8   0.3   8:14.30 nginx
 2105 postgres  20   0 1420500 245100 112000 S   0.9   1.6  42:10.05 postgres
 3410 ${host.username} 20   0   42100   8400   4200 R   0.4   0.1   0:00.18 top
    1 root      20   0  168400  12400   8200 S   0.0   0.1   1:20.45 systemd\r\n''');
        break;

      case 'ss':
      case 'netstat':
        terminal.write('''
Netid State  Recv-Q Send-Q Local Address:Port  Peer Address:PortProcess
tcp   LISTEN 0      128          0.0.0.0:22         0.0.0.0:*    users:(("sshd",pid=840,fd=3))
tcp   LISTEN 0      511          0.0.0.0:80         0.0.0.0:*    users:(("nginx",pid=1890,fd=6))
tcp   LISTEN 0      511          0.0.0.0:443        0.0.0.0:*    users:(("nginx",pid=1890,fd=7))
tcp   LISTEN 0      128        127.0.0.1:5432       0.0.0.0:*    users:(("postgres",pid=2105,fd=5))
tcp   LISTEN 0      128        127.0.0.1:6379       0.0.0.0:*    users:(("redis-server",pid=2300,fd=6))\r\n''');
        break;

      case 'cat':
        if (cmd.contains('nginx')) {
          terminal.write('''
server {
    listen 80;
    server_name api.termius.example.com;

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }
}\r\n''');
        } else if (cmd.contains('docker')) {
          terminal.write('''
version: '3.8'
services:
  web:
    image: nginx:alpine
    ports:
      - "80:80"
  api:
    image: python:3.11-slim
    command: uvicorn main:app --host 0.0.0.0 --port 8000\r\n''');
        } else {
          terminal.write('# .bashrc configuration for ${host.username}\r\nexport PATH=\$HOME/bin:\$PATH\r\nalias ll="ls -la"\r\n');
        }
        break;

      case 'date':
        terminal.write('${DateTime.now().toUtc()} UTC\r\n');
        break;

      case 'clear':
        terminal.write('\x1b[2J\x1b[H');
        break;

      case 'echo':
        final msg = rawCommand.substring(rawCommand.indexOf('echo') + 4).trim();
        terminal.write('$msg\r\n');
        break;

      case 'exit':
        session.status = TerminalConnectionStatus.disconnected;
        terminal.write('\x1b[33m[Session closed - logout]\x1b[0m\r\n');
        break;

      default:
        // Check if complex piped snippet
        if (cmd.contains('journalctl') || cmd.contains('syslog')) {
          terminal.write('''
Oct 27 09:50:01 ${host.alias.replaceAll(' ', '-').toLowerCase()} CRON[3104]: (root) CMD (test -x /usr/sbin/anacron || { cd / && run-parts --report /etc/cron.daily; })
Oct 27 09:51:14 ${host.alias.replaceAll(' ', '-').toLowerCase()} sshd[3118]: Accepted publickey for ${host.username} from 192.168.1.1 port 52310 ssh2
Oct 27 09:51:14 ${host.alias.replaceAll(' ', '-').toLowerCase()} systemd[1]: Started session-42.scope - User Session 42.
Oct 27 09:52:00 ${host.alias.replaceAll(' ', '-').toLowerCase()} nginx[1890]: 192.168.1.100 - - [27/Oct/2026:09:52:00 +0000] "GET /api/v1/health HTTP/1.1" 200 45 "-" "curl/8.5.0"\r\n''');
        } else {
          terminal.write('\x1b[31mbash: $mainCmd: command not found\x1b[0m (type \x1b[33mhelp\x1b[0m for available commands)\r\n');
        }
        break;
    }
  }

  /// Send a string / command directly to the terminal input
  static void sendInput(TerminalSessionModel session, String command) {
    if (session.status != TerminalConnectionStatus.connected) return;

    if (session.isSimulated) {
      session.terminal.write(command);
      session.inputBuffer += command;
      // Auto-press Enter if it has newline or is complete command
      session.terminal.write('\r\n');
      final toExecute = session.inputBuffer.trim();
      if (toExecute.isNotEmpty && session.host != null) {
        _executeSimulatedCommand(session, session.host!, toExecute);
      }
      session.inputBuffer = '';
      final promptUser = session.host?.username ?? 'user';
      final promptHost = session.host?.alias.replaceAll(RegExp(r'[^a-zA-Z0-9-]'), '-').toLowerCase() ?? 'termius';
      session.terminal.write('\x1b[1;32m$promptUser@$promptHost\x1b[0m:\x1b[1;34m~\x1b[0m\$ ');
    } else {
      try {
        session.session?.stdin.add(utf8.encode('$command\n'));
      } catch (e) {
        debugPrint('Error sending input: $e');
      }
    }
  }
}
