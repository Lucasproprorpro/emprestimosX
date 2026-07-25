import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/enums.dart';
import '../../core/utils/formatters.dart';
import '../providers/app_controller.dart';
import '../providers/derived.dart';
import '../widgets/common.dart';
import 'client_form_screen.dart';
import 'loan_detail_screen.dart';
import 'new_loan_screen.dart';

class ClientDetailScreen extends ConsumerWidget {
  const ClientDetailScreen({super.key, required this.clientId});
  final String clientId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appProvider);
    final client = state.clientById(clientId);
    if (client == null) {
      return const Scaffold(body: Center(child: Text('Cliente removido.')));
    }
    final loans = state.loansOfClient(clientId);
    final stats = ref.watch(clientStatsProvider(clientId));
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cliente'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => ClientFormScreen(existing: client)),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              final ok = await _confirm(context,
                  'Excluir cliente?', 'Todos os empréstimos deste cliente serão removidos.');
              if (ok) {
                await ref.read(appProvider.notifier).deleteClient(clientId);
                if (context.mounted) Navigator.pop(context);
              }
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => NewLoanScreen(preselectedClientId: clientId)),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Empréstimo'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              ClientAvatar(
                  name: client.name, photoPath: client.photoPath, radius: 32),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(client.name,
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w800)),
                    if (client.businessName?.isNotEmpty == true)
                      Text(
                          '${client.businessName}'
                          '${client.businessType != null ? ' • ${client.businessType!.label}' : ''}',
                          style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (client.phone.isNotEmpty)
                _ActionButton(
                    icon: Icons.call,
                    label: 'Ligar',
                    onTap: () => _launch('tel:${client.phone}')),
              if (client.phone.isNotEmpty)
                _ActionButton(
                    icon: Icons.chat,
                    label: 'WhatsApp',
                    onTap: () => _launch(
                        'https://wa.me/${client.phone.replaceAll(RegExp(r'[^0-9]'), '')}')),
              if (client.hasLocation)
                _ActionButton(
                    icon: Icons.map,
                    label: 'Rota',
                    onTap: () => _launch(
                        'https://www.google.com/maps/dir/?api=1&destination=${client.latitude},${client.longitude}')),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      _MiniStat(
                          label: 'Empréstimos',
                          value: '${stats.loanCount}'),
                      _MiniStat(
                          label: 'Pago',
                          value: Formatters.moneyCompact(stats.totalPaid)),
                      _MiniStat(
                          label: 'Pendente',
                          value: Formatters.moneyCompact(stats.totalPending)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text('Pontualidade',
                          style: Theme.of(context).textTheme.bodyMedium),
                      const Spacer(),
                      Text('${(stats.punctuality * 100).round()}%',
                          style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: stats.punctuality >= .8
                                  ? scheme.primary
                                  : scheme.error)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: stats.punctuality,
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (client.address.isNotEmpty || client.document.isNotEmpty) ...[
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (client.document.isNotEmpty)
                      _infoRow(Icons.badge, 'Documento', client.document),
                    if (client.cpf?.isNotEmpty == true)
                      _infoRow(Icons.pin, 'CPF', client.cpf!),
                    if (client.address.isNotEmpty)
                      _infoRow(Icons.home, 'Endereço', client.address),
                    if (client.notes.isNotEmpty)
                      _infoRow(Icons.note, 'Observações', client.notes),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          const SectionTitle('Empréstimos'),
          if (loans.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: Text('Nenhum empréstimo cadastrado.')),
            )
          else
            ...loans.map((loan) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            scheme.secondaryContainer,
                        child: Icon(_iconFor(loan.type),
                            color: scheme.onSecondaryContainer),
                      ),
                      title: Text(
                          '${loan.type.label} • ${Formatters.money(loan.capital)}'),
                      subtitle: Text(
                          'Em aberto: ${Formatters.money(loan.amountOutstanding)}'),
                      trailing: StatusChip(label: loan.status.label, dense: true),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => LoanDetailScreen(loanId: loan.id)),
                      ),
                    ),
                  ),
                )),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  static IconData _iconFor(LoanType t) => switch (t) {
        LoanType.pledge => Icons.diamond,
        LoanType.daily => Icons.today,
        LoanType.installment => Icons.event_repeat,
      };

  static Widget _infoRow(IconData icon, String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 10),
            Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w600)),
            Expanded(child: Text(value)),
          ],
        ),
      );

  static Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  static Future<bool> _confirm(
      BuildContext context, String title, String message) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancelar')),
              FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Confirmar')),
            ],
          ),
        ) ??
        false;
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton(
      {required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 2),
          Text(label,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
