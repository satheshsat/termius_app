import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

import '../models/ssh_key_model.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';

class KeysScreen extends StatefulWidget {
  const KeysScreen({super.key});

  @override
  State<KeysScreen> createState() => _KeysScreenState();
}

class _KeysScreenState extends State<KeysScreen> {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final keys = provider.keys;

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
            child: Row(
              children: [
                const FaIcon(FontAwesomeIcons.key, color: AppColors.purple, size: 20),
                const SizedBox(width: 10),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SSH Key Vault',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Cryptographic credentials and identities stored securely in termius_data.json',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: () => _showImportKeyDialog(context),
                  icon: const Icon(Icons.download, size: 16),
                  label: const Text('Import Key'),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: () => _showGenerateKeyDialog(context),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Generate Key Pair'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.purple,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // Key list
          Expanded(
            child: keys.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const FaIcon(FontAwesomeIcons.key, size: 36, color: AppColors.purple),
                        const SizedBox(height: 12),
                        const Text(
                          'No SSH Keys in Vault',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => _showGenerateKeyDialog(context),
                          child: const Text('Generate Key Pair Now'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: keys.length,
                    itemBuilder: (context, index) {
                      final key = keys[index];
                      return _buildKeyCard(context, key, provider);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyCard(BuildContext context, SSHKeyModel key, AppProvider provider) {
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
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.purple.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.purple.withValues(alpha: 0.4)),
                  ),
                  child: const FaIcon(FontAwesomeIcons.key, size: 16, color: AppColors.purple),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            key.name,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceElevated,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Text(
                              key.keyType,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.cyan,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Created: ${DateFormat('MMM d, yyyy').format(key.createdAt)} · Fingerprint: ${key.fingerprint.isNotEmpty ? key.fingerprint : "SHA256:generated"}',
                        style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Delete Key',
                  icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.rose),
                  onPressed: () => _confirmDeleteKey(context, key, provider),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Public key snippet
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF090D13),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
              ),
              child: SelectableText(
                key.publicKey.isNotEmpty ? key.publicKey : '[Private Key Stored]',
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
                maxLines: 2,
              ),
            ),
            const SizedBox(height: 10),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _showViewPrivateKey(context, key),
                  icon: const Icon(Icons.visibility_outlined, size: 14),
                  label: const Text('View Private Key'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: key.publicKey));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Public key copied! Ready for ~/.ssh/authorized_keys'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy, size: 14),
                  label: const Text('Copy Public Key'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.cyan,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showGenerateKeyDialog(BuildContext context) {
    final provider = Provider.of<AppProvider>(context, listen: false);
    final nameController = TextEditingController(text: 'id_ed25519_${DateTime.now().millisecondsSinceEpoch % 1000}');
    String selectedType = 'Ed25519';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: const Row(
              children: [
                FaIcon(FontAwesomeIcons.shieldHalved, color: AppColors.purple, size: 18),
                SizedBox(width: 10),
                Text('Generate SSH Key Pair'),
              ],
            ),
            content: SizedBox(
              width: 440,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Key Name / Label *',
                      hintText: 'e.g. id_ed25519_deploy',
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text('Key Algorithm', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(height: 6),
                  Row(
                    children: ['Ed25519', 'RSA'].map((type) {
                      final isSelected = selectedType == type;
                      return Expanded(
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          child: InkWell(
                            onTap: () => setDialogState(() => selectedType = type),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.purple.withValues(alpha: 0.2) : AppColors.card,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected ? AppColors.purple : AppColors.border,
                                  width: isSelected ? 1.5 : 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    type,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isSelected ? AppColors.purple : AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    type == 'Ed25519' ? 'Fast & Modern' : '2048-bit Classic',
                                    style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () {
                  final name = nameController.text.trim();
                  if (name.isEmpty) return;
                  provider.generateNewKey(name: name, keyType: selectedType);
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Generated $selectedType key pair "$name"!')),
                  );
                },
                child: const Text('Generate Now'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showImportKeyDialog(BuildContext context) {
    final provider = Provider.of<AppProvider>(context, listen: false);
    final nameController = TextEditingController();
    final privController = TextEditingController();
    final pubController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Import Existing SSH Key'),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Key Name *'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: privController,
                  maxLines: 4,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                  decoration: const InputDecoration(
                    labelText: 'Private Key (PEM / OpenSSH format)',
                    hintText: '-----BEGIN OPENSSH PRIVATE KEY-----\n...',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: pubController,
                  maxLines: 2,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                  decoration: const InputDecoration(
                    labelText: 'Public Key',
                    hintText: 'ssh-ed25519 AAAAC3... user@host',
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isEmpty) return;

              final key = SSHKeyModel(
                id: 'key_${DateTime.now().millisecondsSinceEpoch}',
                name: name,
                keyType: privController.text.contains('RSA') ? 'RSA' : 'Ed25519',
                publicKey: pubController.text.trim(),
                privateKey: privController.text.trim(),
                createdAt: DateTime.now(),
              );
              provider.addKey(key);
              Navigator.pop(ctx);
            },
            child: const Text('Import'),
          ),
        ],
      ),
    );
  }

  void _showViewPrivateKey(BuildContext context, SSHKeyModel key) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.lock, color: AppColors.amber, size: 20),
            const SizedBox(width: 8),
            Text('Private Key: ${key.name}'),
          ],
        ),
        content: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF090D13),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(
                  key.privateKey.isNotEmpty ? key.privateKey : '[No private key stored]',
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: AppColors.cyan),
                ),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteKey(BuildContext context, SSHKeyModel key, AppProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete SSH Key'),
        content: Text('Are you sure you want to delete "${key.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.rose),
            onPressed: () {
              provider.deleteKey(key.id);
              Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
