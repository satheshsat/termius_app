import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

import '../models/host_model.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';

class HostsScreen extends StatefulWidget {
  const HostsScreen({super.key});

  @override
  State<HostsScreen> createState() => _HostsScreenState();
}

class _HostsScreenState extends State<HostsScreen> {
  final TextEditingController _quickConnectController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _quickConnectController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final hosts = provider.filteredHosts;
    final groups = provider.groups;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Top Quick Connect & Action Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Quick connect input
                    Expanded(
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: TextField(
                          controller: _quickConnectController,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 13,
                            color: AppColors.textPrimary,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Quick Connect: ssh user@hostname:22 or hostname',
                            hintStyle: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 13,
                              fontFamily: 'monospace',
                            ),
                            prefixIcon: Padding(
                              padding: EdgeInsets.all(12),
                              child: FaIcon(
                                FontAwesomeIcons.terminal,
                                size: 14,
                                color: AppColors.cyan,
                              ),
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 10),
                          ),
                          onSubmitted: (value) {
                            if (value.trim().isNotEmpty) {
                              provider.quickConnect(value);
                              _quickConnectController.clear();
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: () {
                        if (_quickConnectController.text.trim().isNotEmpty) {
                          provider.quickConnect(_quickConnectController.text);
                          _quickConnectController.clear();
                        }
                      },
                      icon: const Icon(Icons.bolt, size: 18),
                      label: const Text('Connect'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.cyan,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: () => _showAddHostDialog(context),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('New Host'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.surfaceElevated,
                        foregroundColor: AppColors.textPrimary,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: const BorderSide(color: AppColors.cyan, width: 1.2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Filter and search controls
                Row(
                  children: [
                    // Search bar
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        height: 38,
                        child: TextField(
                          controller: _searchController,
                          onChanged: (val) => provider.setHostSearchQuery(val),
                          style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                          decoration: InputDecoration(
                            hintText: 'Search hosts by alias, IP, tag, notes...',
                            hintStyle: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                            prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.textSecondary),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 16),
                                    onPressed: () {
                                      _searchController.clear();
                                      provider.setHostSearchQuery('');
                                    },
                                  )
                                : null,
                            contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: AppColors.border),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Group dropdown filter
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
                          value: provider.selectedGroupFilter ?? 'All',
                          dropdownColor: AppColors.surface,
                          style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                          items: [
                            const DropdownMenuItem(value: 'All', child: Text('All Groups')),
                            ...groups.map((g) => DropdownMenuItem(
                                  value: g.name,
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: _parseColor(g.colorHex),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(g.name),
                                    ],
                                  ),
                                )),
                          ],
                          onChanged: (val) {
                            provider.setSelectedGroupFilter(val == 'All' ? null : val);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Host list / grid
          Expanded(
            child: hosts.isEmpty
                ? _buildEmptyState(context)
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: hosts.length,
                    itemBuilder: (context, index) {
                      final host = hosts[index];
                      return _buildHostCard(context, host, provider);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHostCard(BuildContext context, HostModel host, AppProvider provider) {
    final hostColor = _parseColor(host.colorHex);
    final isOnline = host.status == 'online';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => provider.connectToHost(host),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Server avatar badge
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: hostColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: hostColor.withValues(alpha: 0.5)),
                  ),
                  child: Center(
                    child: FaIcon(
                      FontAwesomeIcons.server,
                      color: hostColor,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Host Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              host.alias,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Online badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: (isOnline ? AppColors.emerald : AppColors.amber).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: (isOnline ? AppColors.emerald : AppColors.amber).withValues(alpha: 0.5),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isOnline ? AppColors.emerald : AppColors.amber,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isOnline ? 'Online' : 'Standby',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: isOnline ? AppColors.emerald : AppColors.amber,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Group chip
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceElevated,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Text(
                              host.group,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Connection target: user@hostname:port
                      Row(
                        children: [
                          const Icon(Icons.link, size: 14, color: AppColors.cyan),
                          const SizedBox(width: 4),
                          Text(
                            '${host.username}@${host.hostname}:${host.port}',
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          if (host.keyId != null) ...[
                            const SizedBox(width: 12),
                            const FaIcon(FontAwesomeIcons.key, size: 11, color: AppColors.purple),
                            const SizedBox(width: 4),
                            const Text(
                              'SSH Key',
                              style: TextStyle(fontSize: 11, color: AppColors.purple),
                            ),
                          ],
                        ],
                      ),
                      if (host.tags.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: host.tags.map((t) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Text(
                                '#$t',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.cyan,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                      if (host.lastConnectedAt != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Last connected: ${DateFormat('MMM d, yyyy · HH:mm').format(host.lastConnectedAt!)}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Action buttons
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Favorite toggle
                    IconButton(
                      icon: Icon(
                        host.isFavorite ? Icons.star : Icons.star_border,
                        color: host.isFavorite ? AppColors.amber : AppColors.textMuted,
                        size: 20,
                      ),
                      onPressed: () => provider.toggleFavoriteHost(host.id),
                    ),
                    const SizedBox(width: 4),
                    // Connect button
                    ElevatedButton.icon(
                      onPressed: () => provider.connectToHost(host),
                      icon: const FaIcon(FontAwesomeIcons.terminal, size: 13),
                      label: const Text('SSH'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.cyan,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // SFTP button
                    OutlinedButton.icon(
                      onPressed: () {
                        // Switch to SFTP screen
                        provider.setNavIndex(3);
                      },
                      icon: const FaIcon(FontAwesomeIcons.folderOpen, size: 13),
                      label: const Text('SFTP'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.purple,
                        side: const BorderSide(color: AppColors.purple),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(width: 4),
                    // More options popup menu
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
                      color: AppColors.surface,
                      onSelected: (val) {
                        if (val == 'edit') {
                          _showEditHostDialog(context, host);
                        } else if (val == 'duplicate') {
                          final duplicate = host.copyWith(
                            id: 'host_${DateTime.now().millisecondsSinceEpoch}',
                            alias: '${host.alias} (Copy)',
                            createdAt: DateTime.now(),
                          );
                          provider.addHost(duplicate);
                        } else if (val == 'delete') {
                          _showDeleteConfirm(context, host);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 16, color: AppColors.cyan),
                              SizedBox(width: 10),
                              Text('Edit Host'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'duplicate',
                          child: Row(
                            children: [
                              Icon(Icons.copy, size: 16, color: AppColors.textSecondary),
                              SizedBox(width: 10),
                              Text('Duplicate'),
                            ],
                          ),
                        ),
                        const PopupMenuDivider(),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 16, color: AppColors.rose),
                              SizedBox(width: 10),
                              Text('Delete Host', style: TextStyle(color: AppColors.rose)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surface,
              border: Border.all(color: AppColors.border),
            ),
            child: const Center(
              child: FaIcon(
                FontAwesomeIcons.server,
                size: 32,
                color: AppColors.cyan,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Hosts Found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add your SSH servers to manage and connect with one click.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => _showAddHostDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Add Your First Host'),
          ),
        ],
      ),
    );
  }

  void _showAddHostDialog(BuildContext context) {
    _showHostFormDialog(context, null);
  }

  void _showEditHostDialog(BuildContext context, HostModel host) {
    _showHostFormDialog(context, host);
  }

  void _showHostFormDialog(BuildContext context, HostModel? existingHost) {
    final provider = Provider.of<AppProvider>(context, listen: false);
    final isEditing = existingHost != null;

    final aliasController = TextEditingController(text: existingHost?.alias ?? '');
    final hostController = TextEditingController(text: existingHost?.hostname ?? '');
    final portController = TextEditingController(text: (existingHost?.port ?? 22).toString());
    final userController = TextEditingController(text: existingHost?.username ?? 'root');
    final passController = TextEditingController(text: existingHost?.password ?? '');
    final passphraseController = TextEditingController(text: existingHost?.passphrase ?? '');
    final tagsController = TextEditingController(text: existingHost?.tags.join(', ') ?? '');
    final notesController = TextEditingController(text: existingHost?.notes ?? '');

    String selectedGroup = existingHost?.group ?? (provider.groups.isNotEmpty ? provider.groups.first.name : 'Default');
    String? selectedKeyId = existingHost?.keyId;
    String selectedColor = existingHost?.colorHex ?? '#00D2FF';

    final colorOptions = [
      '#00D2FF', // Cyan
      '#8B5CF6', // Purple
      '#10B981', // Emerald
      '#F59E0B', // Amber
      '#EC4899', // Pink
      '#3B82F6', // Blue
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(
                  isEditing ? Icons.edit : Icons.add_circle,
                  color: AppColors.cyan,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Text(
                  isEditing ? 'Edit SSH Host' : 'Add New SSH Host',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: SizedBox(
              width: 520,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Alias & Group
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: aliasController,
                            decoration: const InputDecoration(
                              labelText: 'Label / Alias *',
                              hintText: 'e.g. Ubuntu Web Server',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: DropdownButtonFormField<String>(
                            initialValue: selectedGroup,
                            decoration: const InputDecoration(labelText: 'Group'),
                            dropdownColor: AppColors.surface,
                            items: provider.groups.map((g) {
                              return DropdownMenuItem(value: g.name, child: Text(g.name));
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setDialogState(() => selectedGroup = val);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Hostname & Port
                    Row(
                      children: [
                        Expanded(
                          flex: 4,
                          child: TextField(
                            controller: hostController,
                            decoration: const InputDecoration(
                              labelText: 'Hostname or IP Address *',
                              hintText: '192.168.1.100 or server.com',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 1,
                          child: TextField(
                            controller: portController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Port *'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Username & Password
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: userController,
                            decoration: const InputDecoration(labelText: 'Username *'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: passController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'Password',
                              hintText: 'Optional if using key',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // SSH Key Vault selector
                    DropdownButtonFormField<String?>(
                      initialValue: selectedKeyId,
                      decoration: const InputDecoration(
                        labelText: 'SSH Key Identity (Optional)',
                        prefixIcon: Padding(
                          padding: EdgeInsets.all(12),
                          child: FaIcon(FontAwesomeIcons.key, size: 14, color: AppColors.purple),
                        ),
                      ),
                      dropdownColor: AppColors.surface,
                      items: [
                        const DropdownMenuItem(value: null, child: Text('None (Use Password)')),
                        ...provider.keys.map((k) {
                          return DropdownMenuItem(
                            value: k.id,
                            child: Text('${k.name} (${k.keyType})'),
                          );
                        }),
                      ],
                      onChanged: (val) {
                        setDialogState(() => selectedKeyId = val);
                      },
                    ),
                    if (selectedKeyId != null) ...[
                      const SizedBox(height: 14),
                      TextField(
                        controller: passphraseController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Key Passphrase (if encrypted)',
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),

                    // Color Badge Picker
                    const Text('Color Badge', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    const SizedBox(height: 8),
                    Row(
                      children: colorOptions.map((c) {
                        final isSelected = selectedColor == c;
                        final color = _parseColor(c);
                        return GestureDetector(
                          onTap: () => setDialogState(() => selectedColor = c),
                          child: Container(
                            margin: const EdgeInsets.only(right: 10),
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: color,
                              border: Border.all(
                                color: isSelected ? Colors.white : Colors.transparent,
                                width: 2.5,
                              ),
                            ),
                            child: isSelected
                                ? const Icon(Icons.check, size: 16, color: Colors.black)
                                : null,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),

                    // Tags
                    TextField(
                      controller: tagsController,
                      decoration: const InputDecoration(
                        labelText: 'Tags (comma separated)',
                        hintText: 'prod, web, nginx, database',
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Notes
                    TextField(
                      controller: notesController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Notes / Server Description',
                        hintText: 'Internal documentation or maintenance schedule',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
              ),
              ElevatedButton(
                onPressed: () {
                  final alias = aliasController.text.trim();
                  final hostname = hostController.text.trim();
                  final port = int.tryParse(portController.text.trim()) ?? 22;
                  final username = userController.text.trim();

                  if (alias.isEmpty || hostname.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter alias and hostname')),
                    );
                    return;
                  }

                  final tagsList = tagsController.text
                      .split(',')
                      .map((t) => t.trim())
                      .where((t) => t.isNotEmpty)
                      .toList();

                  if (isEditing) {
                    final updated = existingHost.copyWith(
                      alias: alias,
                      hostname: hostname,
                      port: port,
                      username: username.isNotEmpty ? username : 'root',
                      password: passController.text,
                      keyId: selectedKeyId,
                      passphrase: passphraseController.text,
                      group: selectedGroup,
                      colorHex: selectedColor,
                      tags: tagsList,
                      notes: notesController.text,
                    );
                    provider.updateHost(updated);
                  } else {
                    final newHost = HostModel(
                      id: 'host_${DateTime.now().millisecondsSinceEpoch}',
                      alias: alias,
                      hostname: hostname,
                      port: port,
                      username: username.isNotEmpty ? username : 'root',
                      password: passController.text,
                      keyId: selectedKeyId,
                      passphrase: passphraseController.text,
                      group: selectedGroup,
                      colorHex: selectedColor,
                      tags: tagsList,
                      notes: notesController.text,
                      createdAt: DateTime.now(),
                      status: 'online',
                    );
                    provider.addHost(newHost);
                  }
                  Navigator.pop(ctx);
                },
                child: Text(isEditing ? 'Save Changes' : 'Create Host'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context, HostModel host) {
    final provider = Provider.of<AppProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Host'),
        content: Text('Are you sure you want to remove "${host.alias}"? This will update termius_data.json immediately.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.rose),
            onPressed: () {
              provider.deleteHost(host.id);
              Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Color _parseColor(String hex) {
    try {
      final buffer = StringBuffer();
      if (hex.length == 6 || hex.length == 7) buffer.write('ff');
      buffer.write(hex.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (_) {
      return AppColors.cyan;
    }
  }
}
