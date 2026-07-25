import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_controller.dart';
import '../providers/derived.dart';
import '../widgets/common.dart';
import 'client_detail_screen.dart';
import 'client_form_screen.dart';

class ClientsScreen extends ConsumerStatefulWidget {
  const ClientsScreen({super.key});

  @override
  ConsumerState<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends ConsumerState<ClientsScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final clients = ref.watch(appProvider).clients;
    final filtered = clients
        .where((c) =>
            c.name.toLowerCase().contains(_query.toLowerCase()) ||
            c.phone.contains(_query) ||
            (c.businessName ?? '').toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Buscar cliente...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? EmptyState(
                    icon: Icons.people_outline,
                    title: 'Nenhum cliente',
                    message: 'Cadastre seu primeiro cliente para começar.',
                    action: FilledButton.icon(
                      onPressed: _addClient,
                      icon: const Icon(Icons.add),
                      label: const Text('Novo cliente'),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final c = filtered[i];
                      final stats = ref.watch(clientStatsProvider(c.id));
                      return Card(
                        child: ListTile(
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          leading:
                              ClientAvatar(name: c.name, photoPath: c.photoPath),
                          title: Text(c.name,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(c.businessName?.isNotEmpty == true
                              ? c.businessName!
                              : (c.phone.isNotEmpty ? c.phone : 'Sem telefone')),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('${stats.loanCount} empr.',
                                  style: Theme.of(context).textTheme.bodySmall),
                              const SizedBox(height: 2),
                              Icon(Icons.chevron_right,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant),
                            ],
                          ),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => ClientDetailScreen(clientId: c.id)),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addClient,
        icon: const Icon(Icons.person_add),
        label: const Text('Cliente'),
      ),
    );
  }

  void _addClient() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ClientFormScreen()),
    );
  }
}
