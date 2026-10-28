import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';

import '../providers/app_provider.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page Header
            const Row(
              children: [
                Icon(Icons.settings, color: AppColors.cyan, size: 24),
                SizedBox(width: 10),
                Text(
                  'Settings & Storage Manager',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Manage application preferences, JSON file persistence, backup, and terminal themes',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),

            // PRIMARY SECTION: JSON File Storage Hub
            _buildJsonStorageSection(context, provider),

            const SizedBox(height: 24),

            // SECONDARY SECTION: Terminal Appearance Preferences
            _buildTerminalPreferencesSection(context, provider),

            const SizedBox(height: 24),

            // TERTIARY SECTION: About & Platform Details
            _buildAboutSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildJsonStorageSection(BuildContext context, AppProvider provider) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.cyan.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const FaIcon(FontAwesomeIcons.fileCode, color: AppColors.cyan, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'JSON File Storage Engine',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.emerald.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: AppColors.emerald.withValues(alpha: 0.5)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle, size: 12, color: AppColors.emerald),
                              SizedBox(width: 4),
                              Text(
                                'Active & Persistent',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.emerald,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'All hosts, groups, SSH keys, snippets, and tunnels are serialized to termius_data.json',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // File Path Box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF090D13),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    FaIcon(FontAwesomeIcons.hardDrive, size: 13, color: AppColors.textMuted),
                    SizedBox(width: 8),
                    Text(
                      'STORAGE FILE LOCATION ON DISK',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: SelectableText(
                        provider.jsonFilePath.isNotEmpty
                            ? provider.jsonFilePath
                            : 'Loading file path...',
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12.5,
                          color: AppColors.cyan,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: provider.jsonFilePath));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('File path copied to clipboard!')),
                        );
                      },
                      icon: const Icon(Icons.copy, size: 13),
                      label: const Text('Copy Path'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      ),
                    ),
                  ],
                ),
                if (provider.lastSaved != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Last auto-saved: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(provider.lastSaved!)}',
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Data Counter Pills
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _buildStatChip(FontAwesomeIcons.server, '${provider.hosts.length} Hosts', AppColors.cyan),
              _buildStatChip(FontAwesomeIcons.code, '${provider.snippets.length} Snippets', AppColors.amber),
              _buildStatChip(FontAwesomeIcons.key, '${provider.keys.length} SSH Keys', AppColors.purple),
              _buildStatChip(FontAwesomeIcons.networkWired, '${provider.portForwards.length} Tunnels', AppColors.emerald),
              _buildStatChip(FontAwesomeIcons.layerGroup, '${provider.groups.length} Groups', AppColors.rose),
            ],
          ),
          const SizedBox(height: 20),

          const Divider(),
          const SizedBox(height: 16),

          // JSON Action Buttons
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: [
              // View & Edit Raw JSON Button
              ElevatedButton.icon(
                onPressed: () => _showRawJsonViewerDialog(context, provider),
                icon: const FaIcon(FontAwesomeIcons.codeBranch, size: 15),
                label: const Text('View / Edit Raw JSON'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.cyan,
                  foregroundColor: Colors.black,
                ),
              ),

              // Export JSON to File
              ElevatedButton.icon(
                onPressed: () => _exportJsonFile(context, provider),
                icon: const Icon(Icons.download, size: 16),
                label: const Text('Export JSON File'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.surfaceElevated,
                  foregroundColor: AppColors.textPrimary,
                  side: const BorderSide(color: AppColors.cyan),
                ),
              ),

              // Import JSON from File
              ElevatedButton.icon(
                onPressed: () => _importJsonFile(context, provider),
                icon: const Icon(Icons.upload, size: 16),
                label: const Text('Import JSON File'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.surfaceElevated,
                  foregroundColor: AppColors.textPrimary,
                  side: const BorderSide(color: AppColors.border),
                ),
              ),

              // Reset to clean fresh state
              OutlinedButton.icon(
                onPressed: () => _confirmReset(context, provider),
                icon: const Icon(Icons.refresh, size: 16, color: AppColors.amber),
                label: const Text('Reset All Data'),
                style: OutlinedButton.styleFrom(foregroundColor: AppColors.amber),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(FaIconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FaIcon(icon, size: 13, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTerminalPreferencesSection(BuildContext context, AppProvider provider) {
    final currentTheme = provider.settings['theme'] as String? ?? 'Termius Obsidian Dark';
    final fontSize = (provider.settings['fontSize'] as num?)?.toDouble() ?? 14.0;
    final cursorBlink = provider.settings['cursorBlink'] as bool? ?? true;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              FaIcon(FontAwesomeIcons.terminal, color: AppColors.purple, size: 18),
              SizedBox(width: 10),
              Text(
                'Terminal Appearance & Themes',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Terminal Theme Selector
          Row(
            children: [
              const Expanded(
                flex: 2,
                child: Text('Default Terminal Theme', style: TextStyle(fontSize: 14)),
              ),
              Expanded(
                flex: 3,
                child: DropdownButtonFormField<String>(
                  initialValue: currentTheme,
                  dropdownColor: AppColors.surface,
                  items: [
                    'Termius Obsidian Dark',
                    'Dracula',
                    'Nord',
                    'Monokai Pro',
                    'Default',
                  ].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                  onChanged: (val) {
                    if (val != null) provider.updateSetting('theme', val);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Font Size Slider
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Terminal Font Size', style: TextStyle(fontSize: 14)),
                    Text('${fontSize.toStringAsFixed(1)} pt', style: const TextStyle(fontSize: 12, color: AppColors.cyan)),
                  ],
                ),
              ),
              Expanded(
                flex: 3,
                child: Slider(
                  value: fontSize,
                  min: 11.0,
                  max: 22.0,
                  divisions: 11,
                  activeColor: AppColors.cyan,
                  onChanged: (val) {
                    provider.updateSetting('fontSize', val);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Cursor Blink Toggle
          Material(
            color: Colors.transparent,
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Blinking Cursor in Terminal', style: TextStyle(fontSize: 14)),
              subtitle: const Text('Emulates native VT100/xterm cursor blink', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
              value: cursorBlink,
              activeThumbColor: AppColors.cyan,
              onChanged: (val) {
                provider.updateSetting('cursorBlink', val);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.textSecondary, size: 20),
              SizedBox(width: 10),
              Text(
                'About term App',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Built with Flutter, dartssh2, and xterm for seamless cross-platform performance across Linux, macOS, Windows, Android, iOS, and Web. All data is securely stored in a portable JSON file format.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildBadge('Platform: Linux / Desktop / Web'),
              const SizedBox(width: 8),
              _buildBadge('Version: 1.0.0'),
              const SizedBox(width: 8),
              _buildBadge('Storage: JSON File (termius_data.json)'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(text, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
    );
  }

  // ==================== Dialogs & File Operations ====================

  void _showRawJsonViewerDialog(BuildContext context, AppProvider provider) async {
    final rawJson = await provider.exportJsonString();
    final jsonController = TextEditingController(text: rawJson);

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const FaIcon(FontAwesomeIcons.fileCode, color: AppColors.cyan, size: 18),
            const SizedBox(width: 10),
            const Text('termius_data.json Live Editor'),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.copy, size: 18),
              tooltip: 'Copy all JSON',
              onPressed: () {
                Clipboard.setData(ClipboardData(text: jsonController.text));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Raw JSON copied to clipboard!')),
                );
              },
            ),
          ],
        ),
        content: SizedBox(
          width: 700,
          height: 480,
          child: Column(
            children: [
              const Text(
                'You can view or directly edit the JSON content below and click "Save & Apply".',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF090D13),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: TextField(
                    controller: jsonController,
                    maxLines: null,
                    expands: true,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: AppColors.cyan,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final editedJson = jsonController.text.trim();
              try {
                // Verify valid JSON
                json.decode(editedJson);
                final success = await provider.importJsonString(editedJson);
                if (success) {
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Saved & applied new JSON file successfully!')),
                    );
                  }
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Invalid JSON syntax: $e')),
                  );
                }
              }
            },
            child: const Text('Save & Apply JSON'),
          ),
        ],
      ),
    );
  }

  void _exportJsonFile(BuildContext context, AppProvider provider) async {
    try {
      final jsonStr = await provider.exportJsonString();

      // On Native desktop/mobile, allow user to pick directory or save to documents
        final Uri? outputUri = await FilePicker.saveFile(
          dialogTitle: 'Save termius_data.json backup',
          fileName: 'termius_data.json',
          bytes: Uint8List.fromList(utf8.encode(jsonStr)),
          mimeType: 'application/json',
        );

        if (outputUri != null) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Exported JSON to: ${outputUri.path}')),
            );
          }
        } else {
        // Fallback or Web
        Clipboard.setData(ClipboardData(text: jsonStr));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('JSON data exported & copied to clipboard!')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export error: $e')),
        );
      }
    }
  }

  void _importJsonFile(BuildContext context, AppProvider provider) async {
    try {
      final List<PlatformFile> files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (files.isNotEmpty) {
        final picked = files.first;
        final rawContent = await picked.xFile.readAsString();

        if (rawContent.isNotEmpty) {
          final success = await provider.importJsonString(rawContent);
          if (success && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Successfully imported and restored from ${picked.name}!')),
            );
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import error: $e')),
        );
      }
    }
  }

  void _confirmReset(BuildContext context, AppProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Application Data'),
        content: const Text(
          'This will reset your data to a clean fresh state (empty hosts, groups, snippets, and keys in termius_data.json). Continue?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.amber, foregroundColor: Colors.black),
            onPressed: () async {
              await provider.resetToDefaults();
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Reset data to clean fresh state!')),
                );
              }
            },
            child: const Text('Reset Now'),
          ),
        ],
      ),
    );
  }
}
