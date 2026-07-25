import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../providers/app_controller.dart';
import '../providers/derived.dart';
import '../widgets/common.dart';
import 'loan_detail_screen.dart';
import 'map_screen.dart';

class CollectionsScreen extends ConsumerWidget {
  const CollectionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(todayCollectionsProvider);
    final total = items.fold<double>(0, (s, e) => s + e.installment.amount);
    final overdue = items.where((e) => e.overdue).length;

    return Scaffold(
      body: items.isEmpty
          ? const EmptyState(
              icon: Icons.task_alt,
              title: 'Nada para cobrar hoje',
              message: 'Todas as cobranças estão em dia. 🎉')
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Card(
                    color: Theme.of(context)
                        .colorScheme
                        .primaryContainer
                        .withOpacity(.4),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          _summary('A cobrar', '${items.length}'),
                          _summary('Atrasadas', '$overdue'),
                          _summary('Total', Formatters.moneyCompact(total)),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final it = items[i];
                      return Card(
                        child: ListTile(
                          leading: ClientAvatar(
                              name: it.client.name,
                              photoPath: it.client.photoPath),
                          title: Text(it.client.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600)),
                          subtitle: Text(
                              '${it.loan.type.label} • ${Formatters.money(it.installment.amount)}'
                              '${it.overdue ? ' • ATRASADA' : ''}',
                              style: TextStyle(
                                  color: it.overdue
                                      ? AppTheme.negative
                                      : null)),
                          trailing: FilledButton.tonal(
                            onPressed: () async {
                              await ref
                                  .read(appProvider.notifier)
                                  .settleInstallment(
                                      it.loan.id, it.installment.number);
                            },
                            child: const Text('Baixar'),
                          ),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    LoanDetailScreen(loanId: it.loan.id)),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const MapScreen())),
        icon: const Icon(Icons.map),
        label: const Text('Mapa'),
      ),
    );
  }

  Widget _summary(String label, String value) => Expanded(
        child: Column(
          children: [
            Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 18)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      );
}
