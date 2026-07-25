import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/constants/enums.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/loan.dart';
import '../providers/app_controller.dart';
import '../widgets/common.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  LoanType? _type;
  String? _clientId;
  DateTimeRange? _range;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appProvider);

    var loans = state.loans;
    if (_type != null) loans = loans.where((l) => l.type == _type).toList();
    if (_clientId != null) {
      loans = loans.where((l) => l.clientId == _clientId).toList();
    }
    if (_range != null) {
      loans = loans
          .where((l) =>
              !l.startDate.isBefore(_range!.start) &&
              !l.startDate.isAfter(_range!.end.add(const Duration(days: 1))))
          .toList();
    }

    double lent = 0, received = 0, interest = 0, outstanding = 0;
    for (final l in loans) {
      lent += l.amountLent;
      received += l.amountReceived;
      interest += l.interestReceived;
      outstanding += l.amountOutstanding;
    }

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SectionTitle('Filtros'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Todas modalidades'),
                selected: _type == null,
                onSelected: (_) => setState(() => _type = null),
              ),
              ...LoanType.values.map((t) => ChoiceChip(
                    label: Text(t.label),
                    selected: _type == t,
                    onSelected: (s) => setState(() => _type = s ? t : null),
                  )),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String?>(
            value: _clientId,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Cliente'),
            items: [
              const DropdownMenuItem(value: null, child: Text('Todos os clientes')),
              ...state.clients
                  .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))),
            ],
            onChanged: (v) => setState(() => _clientId = v),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () async {
              final r = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
                initialDateRange: _range,
              );
              if (r != null) setState(() => _range = r);
            },
            icon: const Icon(Icons.date_range),
            label: Text(_range == null
                ? 'Selecionar período'
                : '${Formatters.date(_range!.start)} — ${Formatters.date(_range!.end)}'),
          ),
          if (_range != null)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                  onPressed: () => setState(() => _range = null),
                  child: const Text('Limpar período')),
            ),
          const SizedBox(height: 16),
          const SectionTitle('Resumo'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _row('Empréstimos', '${loans.length}'),
                  _row('Total emprestado', Formatters.money(lent)),
                  _row('Total recebido', Formatters.money(received)),
                  _row('Juros recebidos', Formatters.money(interest)),
                  _row('Em aberto', Formatters.money(outstanding)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => _share(loans, lent, received, interest, outstanding),
            icon: const Icon(Icons.share),
            label: const Text('Compartilhar relatório'),
          ),
          const SizedBox(height: 16),
          const SectionTitle('Detalhamento'),
          if (loans.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: Text('Nenhum empréstimo no filtro.')),
            )
          else
            ...loans.map((l) {
              final client = state.clientById(l.clientId);
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text('${client?.name ?? ''} • ${l.type.label}'),
                  subtitle: Text(
                      'Emprestado ${Formatters.money(l.amountLent)} • Recebido ${Formatters.money(l.amountReceived)}'),
                  trailing: StatusChip(label: l.status.label, dense: true),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _row(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            Text(k),
            const Spacer(),
            Text(v, style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      );

  void _share(List<Loan> loans, double lent, double received, double interest,
      double outstanding) {
    final b = StringBuffer()
      ..writeln('RELATÓRIO — EmprestaFácil')
      ..writeln('Gerado em ${Formatters.dateTime(DateTime.now())}')
      ..writeln('')
      ..writeln('Empréstimos: ${loans.length}')
      ..writeln('Total emprestado: ${Formatters.money(lent)}')
      ..writeln('Total recebido: ${Formatters.money(received)}')
      ..writeln('Juros recebidos: ${Formatters.money(interest)}')
      ..writeln('Em aberto: ${Formatters.money(outstanding)}');
    Share.share(b.toString());
  }
}
