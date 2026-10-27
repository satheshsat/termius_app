import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

import '../models/host_model.dart';
import '../models/terminal_session_model.dart';
import '../providers/app_provider.dart';
import '../services/sftp_service.dart';
import '../theme/app_theme.dart';

class SftpScreen extends StatefulWidget {
  const SftpScreen({super.key});

  @override
  State<SftpScreen> createState() => _SftpScreenState();
}

class _SftpScreenState extends State<SftpScreen> {
  String _currentPath = '/home/user';
  HostModel? _selectedHost;
  List<SftpItem> _items = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<AppProvider>(context, listen: false);
      if (provider.hosts.isNotEmpty) {
        setState(() {
          _selectedHost = provider.hosts.first;
          _currentPath = '/home/${_selectedHost!.username}';
        });
        _loadDirectory();
      }
    });
  }

  Future<void> _loadDirectory() async {
    if (_selectedHost == null) return;
    setState(() => _loading = true);

    try {
      final provider = Provider.of<AppProvider>(context, listen: false);
      TerminalSessionModel? activeSession;
      for (final s in provider.sessions) {
        if (s.host?.id == _selectedHost?.id) {
          activeSession = s;
          break;
        }
      }
      if (activeSession == null && provider.sessions.isNotEmpty) {
        activeSession = provider.sessions.first;
      }

      final items = await SftpService.listDirectory(
        client: activeSession?.client,
        remotePath: _currentPath,
        isSimulated: activeSession?.isSimulated ?? true,
      );

      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  void _navigateTo(String path) {
    setState(() => _currentPath = path);
    _loadDirectory();
  }

  void _navigateUp() {
    if (_currentPath == '/' || _currentPath.isEmpty) return;
    final lastSlash = _currentPath.lastIndexOf('/');
    if (lastSlash <= 0) {
      _navigateTo('/');
    } else {
      _navigateTo(_currentPath.substring(0, lastSlash));
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final hosts = provider.hosts;

    if (_selectedHost == null && hosts.isNotEmpty) {
      _selectedHost = hosts.first;
      _currentPath = '/home/${_selectedHost!.username}';
      _loadDirectory();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Header Bar with Host Selector
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                const FaIcon(FontAwesomeIcons.folderOpen, color: AppColors.purple, size: 20),
                const SizedBox(width: 10),
                const Text(
                  'SFTP File Manager',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 20),
                // Host selector
                Container(
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedHost?.id,
                      dropdownColor: AppColors.surface,
                      hint: const Text('Select Host'),
                      items: hosts.map((h) {
                        return DropdownMenuItem(
                          value: h.id,
                          child: Text('${h.alias} (${h.hostname})'),
                        );
                      }).toList(),
                      onChanged: (hostId) {
                        final found = hosts.firstWhere((h) => h.id == hostId);
                        setState(() {
                          _selectedHost = found;
                          _currentPath = '/home/${found.username}';
                        });
                        _loadDirectory();
                      },
                    ),
                  ),
                ),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Upload feature ready. Drag & drop or select file to transfer via SFTP.')),
                    );
                  },
                  icon: const Icon(Icons.upload_file, size: 16),
                  label: const Text('Upload'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _loadDirectory,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Refresh'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.cyan, foregroundColor: Colors.black),
                ),
              ],
            ),
          ),

          // Path breadcrumbs bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: AppColors.sidebar,
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Go to Parent Directory',
                  icon: const Icon(Icons.arrow_upward, size: 18, color: AppColors.cyan),
                  onPressed: _currentPath == '/' ? null : _navigateUp,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const FaIcon(FontAwesomeIcons.folder, size: 13, color: AppColors.amber),
                        const SizedBox(width: 8),
                        Text(
                          _currentPath,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 13,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // File List
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _items.isEmpty
                    ? const Center(child: Text('Folder is empty', style: TextStyle(color: AppColors.textMuted)))
                    : ListView.separated(
                        itemCount: _items.length,
                        separatorBuilder: (ctx, i) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final item = _items[index];
                          return ListTile(
                            leading: FaIcon(
                              item.isDirectory
                                  ? FontAwesomeIcons.solidFolder
                                  : FontAwesomeIcons.solidFileLines,
                              color: item.isDirectory ? AppColors.amber : AppColors.cyan,
                              size: 18,
                            ),
                            title: Text(
                              item.name,
                              style: TextStyle(
                                fontWeight: item.isDirectory ? FontWeight.bold : FontWeight.normal,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            subtitle: Text(
                              '${item.permissions} · ${DateFormat('MMM d, HH:mm').format(item.modifiedTime)}',
                              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  item.formattedSize,
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                if (!item.isDirectory)
                                  IconButton(
                                    icon: const Icon(Icons.download, size: 16, color: AppColors.cyan),
                                    onPressed: () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Downloading "${item.name}"...')),
                                      );
                                    },
                                  ),
                              ],
                            ),
                            onTap: () {
                              if (item.isDirectory) {
                                _navigateTo(item.path);
                              }
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
