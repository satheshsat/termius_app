import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:xterm/xterm.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/terminal_session_model.dart';
import '../providers/app_provider.dart';
import '../services/ssh_service.dart';
import '../theme/app_theme.dart';

class TerminalScreen extends StatefulWidget {
  const TerminalScreen({super.key});

  @override
  State<TerminalScreen> createState() => _TerminalScreenState();
}

class _TerminalScreenState extends State<TerminalScreen> {
  double _fontSize = 13.5;
  String _currentThemeName = 'Termius Obsidian Dark';

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final sessions = provider.sessions;
    final activeSession = provider.activeSession;

    if (sessions.isEmpty) {
      return _buildNoActiveSessions(context, provider);
    }

    final terminalTheme = AppTheme.getTerminalTheme(_currentThemeName);

    return Scaffold(
      backgroundColor: terminalTheme.background,
      body: Column(
        children: [
          // Sessions Tab Bar & Terminal Toolbar
          Container(
            height: 44,
            decoration: const BoxDecoration(
              color: AppColors.sidebar,
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                // Horizontal list of tabs
                Expanded(
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: sessions.length,
                    itemBuilder: (context, index) {
                      final s = sessions[index];
                      final isActive = index == provider.activeSessionIndex;
                      return _buildSessionTab(context, s, index, isActive, provider);
                    },
                  ),
                ),

                // "+" button to add new tab
                IconButton(
                  tooltip: 'New Terminal Tab',
                  icon: const Icon(Icons.add, size: 20, color: AppColors.cyan),
                  onPressed: () => _showNewTabMenu(context, provider),
                ),

                const VerticalDivider(width: 1, indent: 8, endIndent: 8),

                // Quick Snippets Drawer button
                IconButton(
                  tooltip: 'Snippets Quick Runner',
                  icon: const FaIcon(FontAwesomeIcons.code, size: 14, color: AppColors.amber),
                  onPressed: () => _showSnippetsSheet(context, provider, activeSession),
                ),

                // Font size controls
                IconButton(
                  tooltip: 'Decrease Font',
                  icon: const Icon(Icons.text_decrease, size: 18, color: AppColors.textSecondary),
                  onPressed: () {
                    if (_fontSize > 10) setState(() => _fontSize -= 1.0);
                  },
                ),
                IconButton(
                  tooltip: 'Increase Font',
                  icon: const Icon(Icons.text_increase, size: 18, color: AppColors.textSecondary),
                  onPressed: () {
                    if (_fontSize < 24) setState(() => _fontSize += 1.0);
                  },
                ),

                // Theme switcher popup
                PopupMenuButton<String>(
                  tooltip: 'Terminal Theme',
                  icon: const Icon(Icons.palette_outlined, size: 18, color: AppColors.purple),
                  color: AppColors.surface,
                  onSelected: (val) {
                    if (val.isNotEmpty) setState(() => _currentThemeName = val);
                  },
                  itemBuilder: (context) => [
                    'Termius Obsidian Dark',
                    'Dracula',
                    'Nord',
                    'Monokai Pro',
                    'Default',
                  ].map((themeName) {
                    return PopupMenuItem(
                      value: themeName,
                      child: Row(
                        children: [
                          if (_currentThemeName == themeName)
                            const Icon(Icons.check, size: 16, color: AppColors.cyan)
                          else
                            const SizedBox(width: 16),
                          const SizedBox(width: 8),
                          Text(themeName),
                        ],
                      ),
                    );
                  }).toList(),
                ),

                // Clear screen
                IconButton(
                  tooltip: 'Clear Screen (Ctrl+L)',
                  icon: const Icon(Icons.cleaning_services_outlined, size: 18, color: AppColors.textSecondary),
                  onPressed: () {
                    if (activeSession != null) {
                      activeSession.terminal.write('\x1b[2J\x1b[H');
                    }
                  },
                ),
              ],
            ),
          ),

          // Main Terminal Display
          Expanded(
            child: activeSession == null
                ? const SizedBox.shrink()
                : Container(
                    color: terminalTheme.background,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: TerminalView(
                      activeSession.terminal,
                      controller: activeSession.controller,
                      theme: terminalTheme,
                      textStyle: TerminalStyle(
                        fontSize: _fontSize,
                        fontFamily: GoogleFonts.jetBrainsMono().fontFamily ?? 'monospace',
                      ),
                      autofocus: true,
                    ),
                  ),
          ),

          // Accessory Keyboard Helper Bar (for Mobile & Desktop convenience)
          if (activeSession != null)
            _buildKeyboardHelperBar(context, activeSession),
        ],
      ),
    );
  }

  Widget _buildSessionTab(
    BuildContext context,
    TerminalSessionModel session,
    int index,
    bool isActive,
    AppProvider provider,
  ) {
    Color statusColor;
    switch (session.status) {
      case TerminalConnectionStatus.connected:
        statusColor = AppColors.emerald;
        break;
      case TerminalConnectionStatus.connecting:
        statusColor = AppColors.cyan;
        break;
      case TerminalConnectionStatus.error:
        statusColor = AppColors.rose;
        break;
      case TerminalConnectionStatus.disconnected:
        statusColor = AppColors.amber;
        break;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? AppColors.surfaceElevated : AppColors.card,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isActive ? AppColors.cyan.withValues(alpha: 0.8) : AppColors.border,
          width: isActive ? 1.5 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: () => provider.selectSession(index),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: statusColor,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  session.title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                    color: isActive ? AppColors.textPrimary : AppColors.textSecondary,
                  ),
                ),
                if (session.isSimulated) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppColors.purple.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: const Text(
                      'SIM',
                      style: TextStyle(fontSize: 9, color: AppColors.purple, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => provider.closeSession(session.id),
                  borderRadius: BorderRadius.circular(10),
                  child: const Padding(
                    padding: EdgeInsets.all(2),
                    child: Icon(Icons.close, size: 14, color: AppColors.textMuted),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKeyboardHelperBar(BuildContext context, TerminalSessionModel session) {
    final keys = [
      {'label': 'ESC', 'code': '\x1b'},
      {'label': 'TAB', 'code': '\t'},
      {'label': 'Ctrl+C', 'code': '\x03'},
      {'label': 'Ctrl+D', 'code': '\x04'},
      {'label': 'Ctrl+Z', 'code': '\x1a'},
      {'label': 'Ctrl+L', 'code': '\x0c'},
      {'label': '↑', 'code': '\x1b[A'},
      {'label': '↓', 'code': '\x1b[B'},
      {'label': '←', 'code': '\x1b[D'},
      {'label': '→', 'code': '\x1b[C'},
      {'label': '|', 'code': '|'},
      {'label': '~', 'code': '~'},
      {'label': '/', 'code': '/'},
      {'label': '\\', 'code': '\\'},
      {'label': 'ENTER', 'code': '\r'},
    ];

    return Container(
      height: 38,
      decoration: const BoxDecoration(
        color: AppColors.sidebar,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        itemCount: keys.length,
        itemBuilder: (context, i) {
          final item = keys[i];
          return Container(
            margin: const EdgeInsets.only(right: 6),
            child: OutlinedButton(
              onPressed: () {
                final code = item['code']!;
                if (session.isSimulated) {
                  // Direct to terminal simulation
                  session.terminal.onOutput?.call(code);
                } else {
                  SSHService.sendInput(session, code);
                }
              },
              style: OutlinedButton.styleFrom(
                backgroundColor: AppColors.surface,
                foregroundColor: AppColors.textPrimary,
                side: const BorderSide(color: AppColors.border),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                minimumSize: const Size(36, 30),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
              child: Text(
                item['label']!,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showNewTabMenu(BuildContext context, AppProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Open New Terminal Session',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const FaIcon(FontAwesomeIcons.terminal, color: AppColors.cyan),
                title: const Text('New Local Interactive Shell'),
                subtitle: const Text('Fast local UNIX simulator with full command support'),
                onTap: () {
                  Navigator.pop(ctx);
                  provider.createNewLocalTab();
                },
              ),
              const Divider(),
              const Text(
                'Connect to Saved Host:',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 6),
              ...provider.hosts.take(5).map((h) {
                return ListTile(
                  dense: true,
                  leading: const FaIcon(FontAwesomeIcons.server, size: 16, color: AppColors.textSecondary),
                  title: Text(h.alias),
                  subtitle: Text('${h.username}@${h.hostname}:${h.port}'),
                  onTap: () {
                    Navigator.pop(ctx);
                    provider.connectToHost(h);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  void _showSnippetsSheet(BuildContext context, AppProvider provider, TerminalSessionModel? session) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(16),
          height: 380,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      FaIcon(FontAwesomeIcons.code, color: AppColors.amber, size: 18),
                      SizedBox(width: 10),
                      Text(
                        'Insert & Run Snippet',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: provider.snippets.length,
                  itemBuilder: (context, index) {
                    final snip = provider.snippets[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: ListTile(
                        dense: true,
                        title: Text(snip.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(
                          snip.command,
                          style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: AppColors.cyan),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(ctx);
                            if (session != null) {
                              SSHService.sendInput(session, snip.command);
                            }
                          },
                          icon: const Icon(Icons.play_arrow, size: 16),
                          label: const Text('Execute'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.amber,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNoActiveSessions(BuildContext context, AppProvider provider) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surface,
              border: Border.all(color: AppColors.border),
            ),
            child: const Center(
              child: FaIcon(
                FontAwesomeIcons.terminal,
                size: 36,
                color: AppColors.cyan,
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'No Active Terminal Sessions',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Select a server from the Hosts screen or launch a local shell session.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                onPressed: () => provider.createNewLocalTab(),
                icon: const Icon(Icons.play_arrow),
                label: const Text('Launch Local Shell'),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () => provider.setNavIndex(0), // Jump to Hosts
                icon: const FaIcon(FontAwesomeIcons.server, size: 14),
                label: const Text('Browse Hosts'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
