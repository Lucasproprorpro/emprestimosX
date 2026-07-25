import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/enums.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/loan_calculator.dart';
import '../providers/app_controller.dart';
import '../widgets/common.dart';
import 'client_form_screen.dart';
import 'loan_detail_screen.dart';

class NewLoanScreen extends ConsumerStatefulWidget {
  const NewLoanScreen({super.key, this.preselectedClientId});
  final String? preselectedClientId;

  @override
  ConsumerState<NewLoanScreen> createState() => _NewLoanScreenState();
}

class _NewLoanScreenState extends ConsumerState<NewLoanScreen> {
  final _formKey = GlobalKey<FormState>();
  LoanType _type = LoanType.pledge;
  String? _clientId;
  DateTime _start = DateTime.now();

  final _capital = TextEditingController();
  final _rate = TextEditingController();
  final _term = TextEditingController(text: '20');
  final _count = TextEditingController(text: '4');
  final _notes = TextEditingController();

  @override
  void initState() {
    super.initState();
    _clientId = widget.preselectedClientId;
  }

  @override
  void dispose() {
    for (final c in [_capital, _rate, _term, _count, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  double get _capitalV => double.tryParse(_capital.text.replaceAll(',', '.')) ?? 0;
  double get _rateV => double.tryParse(_rate.text.replaceAll(',', '.')) ?? 0;
  int get _termV => int.tryParse(_term.text) ?? 0;
  int get _countV => int.tryParse(_count.text) ?? 0;

  @override
  Widget build(BuildContext context) {
    final clients = ref.watch(appProvider).clients;

    return Scaffold(
      appBar: widget.preselectedClientId != null
          ? AppBar(title: const Text('Novo empréstimo'))
          : null,
      body: clients.isEmpty
          ? EmptyState(
              icon: Icons.person_add_alt,
              title: 'Cadastre um cliente',
              message: 'Você precisa de ao menos um cliente para criar um empréstimo.',
              action: FilledButton.icon(
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const ClientFormScreen())),
                icon: const Icon(Icons.person_add),
                label: const Text('Novo cliente'),
              ),
            )
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const SectionTitle('Modalidade'),
                  _ModalitySelector(
                    selected: _type,
                    onChanged: (t) => setState(() => _type = t),
                  ),
                  const SizedBox(height: 8),
                  Text(_type.description,
                      style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _clientId,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Cliente *'),
                    items: clients
                        .map((c) => DropdownMenuItem(
                            value: c.id, child: Text(c.name)))
                        .toList(),
                    validator: (v) => v == null ? 'Selecione o cliente' : null,
                    onChanged: (v) => setState(() => _clientId = v),
                  ),
                  const SizedBox(height: 12),
                  _moneyField(_capital, 'Capital (R\$) *'),
                  _numberField(_rate, 'Taxa de juros (%) *', decimal: true),
                  if (_type == LoanType.daily)
                    _numberField(_term, 'Prazo (dias) *'),
                  if (_type == LoanType.installment)
                    _numberField(_count, 'Número de parcelas *'),
                  const SizedBox(height: 4),
                  _DateField(
                    label: 'Data inicial',
                    value: _start,
                    onChanged: (d) => setState(() => _start = d),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _notes,
                    maxLines: 2,
                    decoration:
                        const InputDecoration(labelText: 'Observações'),
                  ),
                  const SizedBox(height: 20),
                  _PreviewCard(
                    type: _type,
                    capital: _capitalV,
                    rate: _rateV,
                    term: _termV,
                    count: _countV,
                    start: _start,
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: _create,
                    icon: const Icon(Icons.check),
                    label: const Text('Criar empréstimo'),
                  ),
                ],
              ),
            ),
    );
  }

  Future<void> _create() async {
    if (!_formKey.currentState!.validate()) return;
    if (_capitalV <= 0) {
      _snack('Informe um capital válido.');
      return;
    }
    if (_type == LoanType.daily && _termV <= 0) {
      _snack('Informe um prazo válido.');
      return;
    }
    if (_type == LoanType.installment && _countV <= 0) {
      _snack('Informe o número de parcelas.');
      return;
    }
    final loan = await ref.read(appProvider.notifier).createLoan(
          clientId: _clientId!,
          type: _type,
          capital: _capitalV,
          interestRate: _rateV,
          startDate: _start,
          termDays: _type == LoanType.daily ? _termV : null,
          installmentsCount: _type == LoanType.installment ? _countV : null,
          notes: _notes.text.trim(),
        );
    if (!mounted) return;
    // limpa para permitir novo cadastro se estiver na aba
    _capital.clear();
    _rate.clear();
    _notes.clear();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => LoanDetailScreen(loanId: loan.id)),
    );
  }

  void _snack(String m) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(m)));

  Widget _moneyField(TextEditingController c, String label) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          controller: c,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))
          ],
          decoration: InputDecoration(labelText: label),
          onChanged: (_) => setState(() {}),
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
        ),
      );

  Widget _numberField(TextEditingController c, String label,
          {bool decimal = false}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          controller: c,
          keyboardType: TextInputType.numberWithOptions(decimal: decimal),
          inputFormatters: [
            FilteringTextInputFormatter.allow(
                RegExp(decimal ? r'[0-9.,]' : r'[0-9]'))
          ],
          decoration: InputDecoration(labelText: label),
          onChanged: (_) => setState(() {}),
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
        ),
      );
}

class _ModalitySelector extends StatelessWidget {
  const _ModalitySelector({required this.selected, required this.onChanged});
  final LoanType selected;
  final ValueChanged<LoanType> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: LoanType.values.map((t) {
        final isSel = t == selected;
        final scheme = Theme.of(context).colorScheme;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => onChanged(t),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: isSel
                      ? scheme.primaryContainer
                      : scheme.surfaceContainerHighest.withOpacity(.4),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: isSel ? scheme.primary : Colors.transparent,
                      width: 1.4),
                ),
                child: Column(
                  children: [
                    Icon(
                      switch (t) {
                        LoanType.pledge => Icons.diamond,
                        LoanType.daily => Icons.today,
                        LoanType.installment => Icons.event_repeat,
                      },
                      color: isSel
                          ? scheme.onPrimaryContainer
                          : scheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 6),
                    Text(t.label,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                        )),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField(
      {required this.label, required this.value, required this.onChanged});
  final String label;
  final DateTime value;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () async {
        final d = await showDatePicker(
          context: context,
          initialDate: value,
          firstDate: DateTime(2020),
          lastDate: DateTime(2100),
        );
        if (d != null) onChanged(d);
      },
      child: InputDecorator(
        decoration: InputDecoration(labelText: label),
        child: Row(
          children: [
            Text(Formatters.date(value)),
            const Spacer(),
            const Icon(Icons.calendar_today, size: 18),
          ],
        ),
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({
    required this.type,
    required this.capital,
    required this.rate,
    required this.term,
    required this.count,
    required this.start,
  });

  final LoanType type;
  final double capital;
  final double rate;
  final int term;
  final int count;
  final DateTime start;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final rows = <MapEntry<String, String>>[];

    switch (type) {
      case LoanType.pledge:
        final juros = LoanCalculator.pledgeInterest(capital, rate);
        rows.add(MapEntry('Juros por período', Formatters.money(juros)));
        rows.add(const MapEntry('Capital devolvido ao encerrar', '—'));
        break;
      case LoanType.daily:
        if (term > 0) {
          final sched = LoanCalculator.dailySchedule(
              capital: capital,
              ratePercent: rate,
              termDays: term,
              startDate: start);
          final total = LoanCalculator.scheduleTotal(sched);
          rows.add(MapEntry('Total a receber', Formatters.money(total)));
          rows.add(MapEntry('Juros', Formatters.money(total - capital)));
          rows.add(MapEntry('Valor por dia',
              Formatters.money(sched.isEmpty ? 0 : sched.first.amount)));
          rows.add(MapEntry('Dias', '$term'));
        }
        break;
      case LoanType.installment:
        if (count > 0) {
          final sched = LoanCalculator.installmentSchedule(
              capital: capital,
              ratePercent: rate,
              count: count,
              startDate: start);
          final total = LoanCalculator.scheduleTotal(sched);
          rows.add(MapEntry('Juros total', Formatters.money(total - capital)));
          rows.add(MapEntry('Total a receber', Formatters.money(total)));
          rows.add(MapEntry('Valor da parcela',
              Formatters.money(sched.isEmpty ? 0 : sched.first.amount)));
          rows.add(MapEntry('Parcelas', '$count'));
        }
        break;
    }

    return Card(
      color: scheme.primaryContainer.withOpacity(.35),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calculate, color: scheme.primary),
                const SizedBox(width: 8),
                Text('Simulação',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 12),
            ...rows.map((r) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Text(r.key),
                      const Spacer(),
                      Text(r.value,
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
