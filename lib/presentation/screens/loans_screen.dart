import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/enums.dart';
import '../../core/utils/formatters.dart';
import '../providers/app_controller.dart';
import '../widgets/common.dart';
import 'loan_detail_screen.dart';

class LoansScreen extends ConsumerStatefulWidget {
  const LoansScreen({super.key});

  @override
  ConsumerState<LoansScreen> createState() => _LoansScreenState();
}

class _LoansScreenState extends ConsumerState<LoansScreen> {
  LoanType? _type;
  LoanStatus? _status;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appProvider);
    var loans = state.loans;
    if (_type != null) loans = loans.where((l) => l.type == _type).toList();
    if (_status != null) {
      loans = loans.where((l) => l.status == _status).toList();
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Empréstimos')),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('Todos'),
                  selected: _type == null && _status == null,
                  onSelected: (_) =>
                      setState(() {
                    _type = null;
                    _status = null;
                  }),
                ),
                const SizedBox(width: 8),
                ...LoanType.values.map((t) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(t.label),
                        selected: _type == t,
                        onSelected: (s) =>
                            setState(() => _type = s ? t : null),
                      ),
                    )),
                ...LoanStatus.values.map((s) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(s.label),
                        selected: _status == s,
                        onSelected: (sel) =>
                            setState(() => _status = sel ? s : null),
                      ),
                    )),
              ],
            ),
          ),
          Expanded(
            child: loans.isEmpty
                ? const EmptyState(
                    icon: Icons.request_quote_outlined,
                    title: 'Nenhum empréstimo',
                    message: 'Ajuste os filtros ou crie um novo empréstimo.')
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: loans.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final loan = loans[i];
                      final client = state.clientById(loan.clientId);
                      return Card(
                        child: ListTile(
                          title: Text(client?.name ?? 'Cliente'),
                          subtitle: Text(
                              '${loan.type.label} • ${Formatters.money(loan.capital)} • aberto ${Formatters.money(loan.amountOutstanding)}'),
                          trailing:
                              StatusChip(label: loan.status.label, dense: true),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    LoanDetailScreen(loanId: loan.id)),
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
}
