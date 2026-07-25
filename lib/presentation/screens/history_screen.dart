import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/formatters.dart';
import '../providers/app_controller.dart';
import '../widgets/common.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  IconData _iconFor(String category) => switch (category) {
        'cliente' => Icons.person,
        'emprestimo' => Icons.request_quote,
        'pagamento' => Icons.payments,
        'sistema' => Icons.settings,
        _ => Icons.circle_notifications,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(appProvider).events;
    return Scaffold(
      appBar: AppBar(title: const Text('Histórico')),
      body: events.isEmpty
          ? const EmptyState(
              icon: Icons.history,
              title: 'Sem registros',
              message: 'As ações do sistema aparecerão aqui.')
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: events.length,
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (context, i) {
                final e = events[i];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(child: Icon(_iconFor(e.category))),
                    title: Text(e.title),
                    subtitle: Text(e.detail.isEmpty
                        ? Formatters.dateTime(e.at)
                        : '${e.detail}\n${Formatters.dateTime(e.at)}'),
                    isThreeLine: e.detail.isNotEmpty,
                  ),
                );
              },
            ),
    );
  }
}
