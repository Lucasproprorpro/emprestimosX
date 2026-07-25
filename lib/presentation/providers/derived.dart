import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/enums.dart';
import '../../core/utils/date_utils.dart';
import '../../data/models/client.dart';
import '../../data/models/installment.dart';
import '../../data/models/loan.dart';
import 'app_controller.dart';

// --------------------------------------------------------------- dashboard

class DashboardMetrics {
  const DashboardMetrics({
    required this.totalLent,
    required this.totalReceived,
    required this.totalOutstanding,
    required this.interestReceived,
    required this.activeClients,
    required this.overdueClients,
    required this.closedLoans,
    required this.activeLoans,
    required this.monthlyReceipts,
  });

  final double totalLent;
  final double totalReceived;
  final double totalOutstanding;
  final double interestReceived;
  final int activeClients;
  final int overdueClients;
  final int closedLoans;
  final int activeLoans;

  /// Últimos 6 meses: label -> valor recebido.
  final List<MapEntry<String, double>> monthlyReceipts;
}

final dashboardProvider = Provider<DashboardMetrics>((ref) {
  final state = ref.watch(appProvider);
  final loans = state.loans;

  double totalLent = 0, received = 0, outstanding = 0, interest = 0;
  final activeClientIds = <String>{};
  final overdueClientIds = <String>{};
  int closed = 0, active = 0;

  for (final l in loans) {
    totalLent += l.amountLent;
    received += l.amountReceived;
    outstanding += l.amountOutstanding;
    interest += l.interestReceived;
    if (l.status == LoanStatus.closed) {
      closed++;
    } else {
      active++;
      activeClientIds.add(l.clientId);
      if (l.status == LoanStatus.overdue) overdueClientIds.add(l.clientId);
    }
  }

  // Recebimentos dos últimos 6 meses.
  final now = DateTime.now();
  final buckets = <String, double>{};
  final order = <String>[];
  for (int i = 5; i >= 0; i--) {
    final d = DateOnly.addMonths(DateTime(now.year, now.month, 1), -i);
    final key = '${d.year}-${d.month.toString().padLeft(2, '0')}';
    buckets[key] = 0;
    order.add(key);
  }
  String keyOf(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}';

  for (final l in loans) {
    for (final i in l.schedule.where((e) => e.isPaid && e.paidAt != null)) {
      final k = keyOf(i.paidAt!);
      if (buckets.containsKey(k)) buckets[k] = buckets[k]! + i.amount;
    }
    for (final p in l.interestPayments) {
      final k = keyOf(p.paidAt);
      if (buckets.containsKey(k)) buckets[k] = buckets[k]! + p.amount;
    }
  }
  final monthly = order.map((k) => MapEntry(k, buckets[k]!)).toList();

  return DashboardMetrics(
    totalLent: totalLent,
    totalReceived: received,
    totalOutstanding: outstanding,
    interestReceived: interest,
    activeClients: activeClientIds.length,
    overdueClients: overdueClientIds.length,
    closedLoans: closed,
    activeLoans: active,
    monthlyReceipts: monthly,
  );
});

// --------------------------------------------------------- collections today

class CollectionItem {
  const CollectionItem({
    required this.client,
    required this.loan,
    required this.installment,
    required this.overdue,
  });

  final Client client;
  final Loan loan;
  final LoanInstallment installment;
  final bool overdue;
}

/// Cobranças do dia: parcelas com vencimento até hoje que ainda não foram pagas.
final todayCollectionsProvider = Provider<List<CollectionItem>>((ref) {
  final state = ref.watch(appProvider);
  final today = DateOnly.today();
  final items = <CollectionItem>[];

  for (final loan in state.loans) {
    if (loan.status == LoanStatus.closed) continue;
    final client = state.clientById(loan.clientId);
    if (client == null) continue;
    for (final inst in loan.schedule) {
      if (inst.isPaid) continue;
      final due = DateOnly.of(inst.dueDate);
      if (!due.isAfter(today)) {
        items.add(CollectionItem(
          client: client,
          loan: loan,
          installment: inst,
          overdue: due.isBefore(today),
        ));
      }
    }
  }
  items.sort((a, b) {
    if (a.overdue != b.overdue) return a.overdue ? -1 : 1;
    return a.installment.dueDate.compareTo(b.installment.dueDate);
  });
  return items;
});

/// Clientes que possuem coordenadas (para o mapa).
final clientsWithLocationProvider = Provider<List<Client>>((ref) {
  final state = ref.watch(appProvider);
  return state.clients.where((c) => c.hasLocation).toList();
});

// -------------------------------------------------------------- client stats

class ClientStats {
  const ClientStats({
    required this.loanCount,
    required this.totalPaid,
    required this.totalPending,
    required this.punctuality,
    required this.recentPayments,
  });

  final int loanCount;
  final double totalPaid;
  final double totalPending;
  final double punctuality; // 0..1
  final List<MapEntry<DateTime, double>> recentPayments;
}

final clientStatsProvider =
    Provider.family<ClientStats, String>((ref, clientId) {
  final state = ref.watch(appProvider);
  final loans = state.loansOfClient(clientId);

  double paid = 0, pending = 0;
  int onTime = 0, totalSettled = 0;
  final payments = <MapEntry<DateTime, double>>[];

  for (final l in loans) {
    paid += l.amountReceived;
    pending += l.amountOutstanding;
    for (final i in l.schedule.where((e) => e.isPaid && e.paidAt != null)) {
      totalSettled++;
      if (!DateOnly.of(i.paidAt!).isAfter(DateOnly.of(i.dueDate))) onTime++;
      payments.add(MapEntry(i.paidAt!, i.amount));
    }
    for (final p in l.interestPayments) {
      payments.add(MapEntry(p.paidAt, p.amount));
    }
  }
  payments.sort((a, b) => b.key.compareTo(a.key));

  return ClientStats(
    loanCount: loans.length,
    totalPaid: paid,
    totalPending: pending,
    punctuality: totalSettled == 0 ? 1 : onTime / totalSettled,
    recentPayments: payments.take(8).toList(),
  );
});
