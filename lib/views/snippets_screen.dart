import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../models/snippet_model.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';

class SnippetsScreen extends StatefulWidget {
  const SnippetsScreen({super.key});

  @override
  State<SnippetsScreen> createState() => _SnippetsScreenState();
}

class _SnippetsScreenState extends State<SnippetsScreen> {
  String _selectedCategory = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final allSnippets = provider.snippets;

    // Categories extraction
    final categories = ['All', ...{...allSnippets.map((s) => s.category)}];

    final filtered = allSnippets.where((s) {
      if (_selectedCategory != 'All' && s.category != _selectedCategory) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        return s.title.toLowerCase().contains(q) ||
            s.command.toLowerCase().contains(q) ||
            s.description.toLowerCase().contains(q);
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Header Bar
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
                    const FaIcon(FontAwesomeIcons.code, color: AppColors.amber, size: 20),
                    const SizedBox(width: 10),
                    const Text(
                      'Snippets & Automation',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: () => _showAddSnippetDialog(context),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('New Snippet'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.amber,
                        foregroundColor: Colors.black,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Search bar
                TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val),
                  style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    hintText: 'Search snippets by title, command or description...',
                    prefixIcon: Icon(Icons.search, size: 18, color: AppColors.textSecondary),
                    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                  ),
                ),
                const SizedBox(height: 10),
                // Category chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: categories.map((cat) {
                      final isSelected = _selectedCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(cat),
                          selected: isSelected,
                          onSelected: (_) => setState(() => _selectedCategory = cat),
                          selectedColor: AppColors.amber.withValues(alpha: 0.2),
                          backgroundColor: AppColors.card,
                          side: BorderSide(
                            color: isSelected ? AppColors.amber : AppColors.border,
                          ),
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? AppColors.amber : AppColors.textSecondary,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Snippets List
          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: Text('No snippets found', style: TextStyle(color: AppColors.textMuted)),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final snip = filtered[index];
                      return _buildSnippetCard(context, snip, provider);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSnippetCard(BuildContext context, SnippetModel snippet, AppProvider provider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    snippet.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    snippet.category,
                    style: const TextStyle(fontSize: 11, color: AppColors.amber),
                  ),
                ),
                const SizedBox(width: 6),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 18, color: AppColors.textSecondary),
                  color: AppColors.surface,
                  onSelected: (val) {
                    if (val == 'edit') {
                      _showEditSnippetDialog(context, snippet);
                    } else if (val == 'delete') {
                      provider.deleteSnippet(snippet.id);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete', style: TextStyle(color: AppColors.rose)),
                    ),
                  ],
                ),
              ],
            ),
            if (snippet.description.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                snippet.description,
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
            const SizedBox(height: 12),

            // Command Box with Monospace font and background
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF090D13),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
              ),
              child: SelectableText(
                snippet.command,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12.5,
                  color: AppColors.cyan,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Action row
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Copy button
                OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: snippet.command));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Command copied to clipboard!'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy, size: 14),
                  label: const Text('Copy'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
                const SizedBox(width: 8),
                // Run in Terminal button
                ElevatedButton.icon(
                  onPressed: () {
                    if (provider.activeSession == null) {
                      provider.createNewLocalTab();
                    }
                    provider.runSnippetInActiveSession(snippet);
                  },
                  icon: const Icon(Icons.play_arrow, size: 16),
                  label: const Text('Run in Terminal'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.cyan,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddSnippetDialog(BuildContext context) {
    _showSnippetFormDialog(context, null);
  }

  void _showEditSnippetDialog(BuildContext context, SnippetModel snippet) {
    _showSnippetFormDialog(context, snippet);
  }

  void _showSnippetFormDialog(BuildContext context, SnippetModel? existing) {
    final provider = Provider.of<AppProvider>(context, listen: false);
    final isEditing = existing != null;

    final titleController = TextEditingController(text: existing?.title ?? '');
    final catController = TextEditingController(text: existing?.category ?? 'General');
    final cmdController = TextEditingController(text: existing?.command ?? '');
    final descController = TextEditingController(text: existing?.description ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEditing ? 'Edit Snippet' : 'New Shell Snippet'),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Title *'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: catController,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    hintText: 'Docker, System, Network, Logs, etc.',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: cmdController,
                  maxLines: 4,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                  decoration: const InputDecoration(
                    labelText: 'Command / Script *',
                    hintText: 'docker ps -a || systemctl status nginx',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Description (Optional)',
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final title = titleController.text.trim();
              final command = cmdController.text.trim();
              if (title.isEmpty || command.isEmpty) return;

              if (isEditing) {
                final updated = existing.copyWith(
                  title: title,
                  category: catController.text.trim(),
                  command: command,
                  description: descController.text.trim(),
                );
                provider.updateSnippet(updated);
              } else {
                final newSnippet = SnippetModel(
                  id: 'snip_${DateTime.now().millisecondsSinceEpoch}',
                  title: title,
                  category: catController.text.trim().isNotEmpty ? catController.text.trim() : 'General',
                  command: command,
                  description: descController.text.trim(),
                );
                provider.addSnippet(newSnippet);
              }
              Navigator.pop(ctx);
            },
            child: Text(isEditing ? 'Save' : 'Create'),
          ),
        ],
      ),
    );
  }
}
