import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/enums.dart';
import '../../core/utils/loan_calculator.dart';
import '../../data/local/hive_service.dart';
import '../../data/models/app_event.dart';
import '../../data/models/client.dart';
import '../../data/models/installment.dart';
import '../../data/models/loan.dart';

const _uuid = Uuid();

class AppState {
  const AppState({
    this.clients = const [],
    this.loans = const [],
    this.events = const [],
  });

  final List<Client> clients;
  final List<Loan> loans;
  final List<AppEvent> events;

  AppState copyWith({
    List<Client>? clients,
    List<Loan>? loans,
    List<AppEvent>? events,
  }) =>
      AppState(
        clients: clients ?? this.clients,
        loans: loans ?? this.loans,
        events: events ?? this.events,
      );

  Client? clientById(String id) =>
      clients.where((c) => c.id == id).firstOrNull;

  List<Loan> loansOfClient(String clientId) =>
      loans.where((l) => l.clientId == clientId).toList();
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}

class AppController extends Notifier<AppState> {
  @override
  AppState build() => _reload(refreshStatuses: true);

  // --------------------------------------------------------------- loading

  AppState _reload({bool refreshStatuses = false}) {
    final loans = HiveService.loans.values.toList();
    if (refreshStatuses) {
      for (final l in loans) {
        final before = l.status;
        l.refreshStatuses();
        if (l.status != before) l.save();
      }
    }
    final clients = HiveService.clients.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    loans.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final events = HiveService.events.values.toList()
      ..sort((a, b) => b.at.compareTo(a.at));
    return AppState(clients: clients, loans: loans, events: events);
  }

  void _persistAndRefresh() => state = _reload();

  Future<void> _log(String title, {String detail = '', String category = 'geral'}) async {
    final e = AppEvent(id: _uuid.v4(), title: title, detail: detail, category: category);
    await HiveService.events.put(e.id, e);
  }

  // --------------------------------------------------------------- clients

  Future<Client> saveClient(Client client) async {
    await HiveService.clients.put(client.id, client);
    await _log('Cliente salvo', detail: client.name, category: 'cliente');
    _persistAndRefresh();
    return client;
  }

  Future<Client> createClient({
    required String name,
    String document = '',
    String? cpf,
    String phone = '',
    String address = '',
    String? photoPath,
    double? latitude,
    double? longitude,
    String notes = '',
    String? businessName,
    BusinessType? businessType,
  }) {
    final client = Client(
      id: _uuid.v4(),
      name: name,
      document: document,
      cpf: cpf,
      phone: phone,
      address: address,
      photoPath: photoPath,
      latitude: latitude,
      longitude: longitude,
      notes: notes,
      businessName: businessName,
      businessType: businessType,
    );
    return saveClient(client);
  }

  Future<void> deleteClient(String id) async {
    final client = state.clientById(id);
    for (final l in state.loansOfClient(id)) {
      await HiveService.loans.delete(l.id);
    }
    await HiveService.clients.delete(id);
    await _log('Cliente excluído',
        detail: client?.name ?? id, category: 'cliente');
    _persistAndRefresh();
  }

  // ----------------------------------------------------------------- loans

  Future<Loan> createLoan({
    required String clientId,
    required LoanType type,
    required double capital,
    required double interestRate,
    required DateTime startDate,
    int? termDays,
    int? installmentsCount,
    String notes = '',
  }) async {
    List<LoanInstallment> schedule = [];
    switch (type) {
      case LoanType.pledge:
        schedule = [];
        break;
      case LoanType.daily:
        schedule = LoanCalculator.dailySchedule(
          capital: capital,
          ratePercent: interestRate,
          termDays: termDays ?? 1,
          startDate: startDate,
        );
        break;
      case LoanType.installment:
        schedule = LoanCalculator.installmentSchedule(
          capital: capital,
          ratePercent: interestRate,
          count: installmentsCount ?? 1,
          startDate: startDate,
        );
        break;
    }

    final loan = Loan(
      id: _uuid.v4(),
      clientId: clientId,
      type: type,
      capital: capital,
      interestRate: interestRate,
      startDate: startDate,
      termDays: termDays,
      installmentsCount: installmentsCount,
      notes: notes,
      schedule: schedule,
    );
    loan.refreshStatuses();

    await HiveService.loans.put(loan.id, loan);
    final client = state.clientById(clientId);
    await _log('Empréstimo criado (${type.label})',
        detail: '${client?.name ?? ''} • capital ${capital.toStringAsFixed(2)}',
        category: 'emprestimo');
    _persistAndRefresh();
    return loan;
  }

  Loan? loanById(String id) => state.loans.where((l) => l.id == id).firstOrNull;

  /// "Baixar pagamento" de uma parcela/dia (Diário ou Parcelado).
  Future<void> settleInstallment(String loanId, int number, {String note = ''}) async {
    final loan = loanById(loanId);
    if (loan == null) return;
    final item = loan.schedule.where((i) => i.number == number).firstOrNull;
    if (item == null || item.isPaid) return;
    item.status = PaymentStatus.paid;
    item.paidAt = DateTime.now();
    item.note = note;
    loan.refreshStatuses();
    await loan.save();
    await _log('Pagamento recebido',
        detail: 'Parcela $number • ${item.amount.toStringAsFixed(2)}',
        category: 'pagamento');
    _persistAndRefresh();
  }

  /// Desfaz a baixa de uma parcela.
  Future<void> undoInstallment(String loanId, int number) async {
    final loan = loanById(loanId);
    if (loan == null) return;
    final item = loan.schedule.where((i) => i.number == number).firstOrNull;
    if (item == null || !item.isPaid) return;
    item.status = PaymentStatus.future;
    item.paidAt = null;
    item.note = '';
    loan.refreshStatuses();
    await loan.save();
    await _log('Pagamento estornado',
        detail: 'Parcela $number', category: 'pagamento');
    _persistAndRefresh();
  }

  /// Registra um pagamento de juros (Penhor).
  Future<void> registerPledgeInterest(String loanId,
      {double? amount, String note = ''}) async {
    final loan = loanById(loanId);
    if (loan == null) return;
    final value = amount ?? loan.interestAmount;
    loan.interestPayments.add(
      InterestPayment(amount: value, paidAt: DateTime.now(), note: note),
    );
    await loan.save();
    await _log('Juros recebidos',
        detail: '${loan.type.label} • ${value.toStringAsFixed(2)}',
        category: 'pagamento');
    _persistAndRefresh();
  }

  /// Encerra um empréstimo (capital devolvido / quitado).
  Future<void> closeLoan(String loanId) async {
    final loan = loanById(loanId);
    if (loan == null) return;
    loan.status = LoanStatus.closed;
    loan.closedAt = DateTime.now();
    await loan.save();
    await _log('Empréstimo encerrado',
        detail: loan.type.label, category: 'emprestimo');
    _persistAndRefresh();
  }

  Future<void> deleteLoan(String loanId) async {
    await HiveService.loans.delete(loanId);
    await _log('Empréstimo excluído', category: 'emprestimo');
    _persistAndRefresh();
  }

  // --------------------------------------------------------------- backup

  String exportBackup() {
    final data = {
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'clients': state.clients.map((e) => e.toJson()).toList(),
      'loans': state.loans.map((e) => e.toJson()).toList(),
      'events': state.events.map((e) => e.toJson()).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  Future<void> importBackup(String jsonStr) async {
    final data = jsonDecode(jsonStr) as Map<String, dynamic>;
    await HiveService.clients.clear();
    await HiveService.loans.clear();
    await HiveService.events.clear();

    for (final c in (data['clients'] as List)) {
      final client = Client.fromJson(Map<String, dynamic>.from(c as Map));
      await HiveService.clients.put(client.id, client);
    }
    for (final l in (data['loans'] as List)) {
      final loan = Loan.fromJson(Map<String, dynamic>.from(l as Map));
      await HiveService.loans.put(loan.id, loan);
    }
    for (final e in (data['events'] as List? ?? [])) {
      final ev = AppEvent.fromJson(Map<String, dynamic>.from(e as Map));
      await HiveService.events.put(ev.id, ev);
    }
    await _log('Backup restaurado', category: 'sistema');
    state = _reload(refreshStatuses: true);
  }
}

final appProvider =
    NotifierProvider<AppController, AppState>(AppController.new);
