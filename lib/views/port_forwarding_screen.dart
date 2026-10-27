import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../models/port_forward_model.dart';
import '../models/host_model.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';

class PortForwardingScreen extends StatelessWidget {
  const PortForwardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final forwards = provider.portForwards;

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
                const FaIcon(FontAwesomeIcons.arrowsSplitUpAndLeft, color: AppColors.emerald, size: 20),
                const SizedBox(width: 10),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Port Forwarding & Tunnels',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'SSH Tunnels for databases, web ports, and SOCKS5 proxies',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () => _showAddTunnelDialog(context),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('New Tunnel'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.emerald,
                    foregroundColor: Colors.black,
                  ),
                ),
              ],
            ),
          ),

          // Tunnels List
          Expanded(
            child: forwards.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const FaIcon(FontAwesomeIcons.networkWired, size: 36, color: AppColors.emerald),
                        const SizedBox(height: 12),
                        const Text(
                          'No Active Tunnels Configured',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => _showAddTunnelDialog(context),
                          child: const Text('Add Port Forwarding Rule'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: forwards.length,
                    itemBuilder: (context, index) {
                      final pf = forwards[index];
                      HostModel? host;
                      for (final h in provider.hosts) {
                        if (h.id == pf.hostId) {
                          host = h;
                          break;
                        }
                      }
                      if (host == null && provider.hosts.isNotEmpty) {
                        host = provider.hosts.first;
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: pf.isActive ? AppColors.emerald.withValues(alpha: 0.6) : AppColors.border,
                            width: pf.isActive ? 1.5 : 1,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: (pf.isActive ? AppColors.emerald : AppColors.textMuted).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: FaIcon(
                                  FontAwesomeIcons.networkWired,
                                  color: pf.isActive ? AppColors.emerald : AppColors.textMuted,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          pf.name,
                                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                                            pf.forwardType.toUpperCase(),
                                            style: const TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.cyan,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Text(
                                          '127.0.0.1:${pf.localPort}',
                                          style: const TextStyle(
                                            fontFamily: 'monospace',
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        const Icon(Icons.arrow_forward, size: 14, color: AppColors.emerald),
                                        const SizedBox(width: 8),
                                        Text(
                                          '${pf.remoteHost}:${pf.remotePort}',
                                          style: const TextStyle(
                                            fontFamily: 'monospace',
                                            fontSize: 13,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                        if (host != null) ...[
                                          const SizedBox(width: 12),
                                          Text(
                                            'via ${host.alias}',
                                            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              // Active switch
                              Switch(
                                value: pf.isActive,
                                activeThumbColor: AppColors.emerald,
                                onChanged: (_) {
                                  provider.togglePortForward(pf.id);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        pf.isActive ? 'Tunnel stopped' : 'Tunnel started on port ${pf.localPort}',
                                      ),
                                      duration: const Duration(seconds: 1),
                                    ),
                                  );
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.rose),
                                onPressed: () => provider.deletePortForward(pf.id),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showAddTunnelDialog(BuildContext context) {
    final provider = Provider.of<AppProvider>(context, listen: false);
    final nameController = TextEditingController(text: 'Web Tunnel');
    final localPortController = TextEditingController(text: '8080');
    final remoteHostController = TextEditingController(text: '127.0.0.1');
    final remotePortController = TextEditingController(text: '80');
    String selectedType = 'Local';
    String? selectedHostId = provider.hosts.isNotEmpty ? provider.hosts.first.id : null;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: const Text('Add Port Forwarding Tunnel'),
            content: SizedBox(
              width: 480,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Tunnel Name *'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selectedHostId,
                      decoration: const InputDecoration(labelText: 'Forward Via Server *'),
                      dropdownColor: AppColors.surface,
                      items: provider.hosts.map((h) {
                        return DropdownMenuItem(value: h.id, child: Text(h.alias));
                      }).toList(),
                      onChanged: (val) => setDialogState(() => selectedHostId = val),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: selectedType,
                            decoration: const InputDecoration(labelText: 'Type'),
                            dropdownColor: AppColors.surface,
                            items: ['Local', 'Remote', 'Dynamic'].map((t) {
                              return DropdownMenuItem(value: t, child: Text(t));
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setDialogState(() => selectedType = val);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: localPortController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Local Port *'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: remoteHostController,
                            decoration: const InputDecoration(labelText: 'Destination Host'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 1,
                          child: TextField(
                            controller: remotePortController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Destination Port'),
                          ),
                        ),
                      ],
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
                  final lPort = int.tryParse(localPortController.text.trim()) ?? 8080;
                  final rPort = int.tryParse(remotePortController.text.trim()) ?? 80;
                  if (name.isEmpty || selectedHostId == null) return;

                  final pf = PortForwardModel(
                    id: 'pf_${DateTime.now().millisecondsSinceEpoch}',
                    name: name,
                    hostId: selectedHostId!,
                    forwardType: selectedType,
                    localPort: lPort,
                    remoteHost: remoteHostController.text.trim(),
                    remotePort: rPort,
                    isActive: false,
                  );
                  provider.addPortForward(pf);
                  Navigator.pop(ctx);
                },
                child: const Text('Create Tunnel'),
              ),
            ],
          );
        },
      ),
    );
  }
}
