import 'package:hive/hive.dart';

import '../../core/constants/enums.dart';
import '../../core/utils/date_utils.dart';
import 'installment.dart';

/// Empréstimo — raiz de agregação. Guarda a agenda (Diário/Parcelado) e/ou os
/// pagamentos de juros (Penhor).
class Loan extends HiveObject {
  Loan({
    required this.id,
    required this.clientId,
    required this.type,
    required this.capital,
    required this.interestRate,
    required this.startDate,
    this.termDays,
    this.installmentsCount,
    this.status = LoanStatus.active,
    this.notes = '',
    DateTime? createdAt,
    this.closedAt,
    List<LoanInstallment>? schedule,
    List<InterestPayment>? interestPayments,
  })  : createdAt = createdAt ?? DateTime.now(),
        schedule = schedule ?? <LoanInstallment>[],
        interestPayments = interestPayments ?? <InterestPayment>[];

  final String id;
  final String clientId;
  final LoanType type;
  double capital;
  double interestRate;
  DateTime startDate;
  int? termDays; // Diário
  int? installmentsCount; // Parcelado
  LoanStatus status;
  String notes;
  final DateTime createdAt;
  DateTime? closedAt;

  final List<LoanInstallment> schedule; // Diário / Parcelado
  final List<InterestPayment> interestPayments; // Penhor

  // ------------------------------------------------------------------ getters

  /// Valor dos juros calculado sobre o capital (por período, no Penhor).
  double get interestAmount => capital * interestRate / 100;

  double get scheduledTotal =>
      schedule.fold(0.0, (s, i) => s + i.amount);

  double get scheduledPaid =>
      schedule.where((i) => i.isPaid).fold(0.0, (s, i) => s + i.amount);

  double get scheduledOutstanding => scheduledTotal - scheduledPaid;

  double get pledgeInterestPaid =>
      interestPayments.fold(0.0, (s, p) => s + p.amount);

  /// Capital emprestado.
  double get amountLent => capital;

  /// Somente a parcela de JUROS já recebida (para o dashboard).
  double get interestReceived {
    if (type == LoanType.pledge) return pledgeInterestPaid;
    if (scheduledTotal <= 0) return 0;
    final interestTotal = scheduledTotal - capital;
    return scheduledPaid * (interestTotal / scheduledTotal);
  }

  /// Todo o dinheiro efetivamente recebido de volta.
  double get amountReceived {
    if (type == LoanType.pledge) {
      return pledgeInterestPaid + (status == LoanStatus.closed ? capital : 0);
    }
    return scheduledPaid;
  }

  /// Valor ainda em aberto.
  double get amountOutstanding {
    if (type == LoanType.pledge) {
      return status == LoanStatus.closed ? 0 : capital;
    }
    return scheduledOutstanding;
  }

  int get paidCount => schedule.where((i) => i.isPaid).length;
  int get overdueCount =>
      schedule.where((i) => i.status == PaymentStatus.overdue).length;

  /// Próxima parcela/dia em aberto (menor vencimento não pago).
  LoanInstallment? get nextDue {
    final pending = schedule.where((i) => !i.isPaid).toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return pending.isEmpty ? null : pending.first;
  }

  /// Recalcula o status de cada parcela e do empréstimo em relação a hoje.
  void refreshStatuses() {
    if (status == LoanStatus.closed) return;
    final today = DateOnly.today();
    for (final i in schedule) {
      if (i.isPaid) continue;
      i.status = DateOnly.of(i.dueDate).isBefore(today)
          ? PaymentStatus.overdue
          : PaymentStatus.future;
    }
    final hasOverdue = schedule.any((i) => i.status == PaymentStatus.overdue);
    final allPaid = schedule.isNotEmpty && schedule.every((i) => i.isPaid);
    if (allPaid) {
      status = LoanStatus.closed;
      closedAt ??= DateTime.now();
    } else {
      status = hasOverdue ? LoanStatus.overdue : LoanStatus.active;
    }
  }

  // -------------------------------------------------------------------- json

  Map<String, dynamic> toJson() => {
        'id': id,
        'clientId': clientId,
        'type': type.index,
        'capital': capital,
        'interestRate': interestRate,
        'startDate': startDate.toIso8601String(),
        'termDays': termDays,
        'installmentsCount': installmentsCount,
        'status': status.index,
        'notes': notes,
        'createdAt': createdAt.toIso8601String(),
        'closedAt': closedAt?.toIso8601String(),
        'schedule': schedule.map((e) => e.toJson()).toList(),
        'interestPayments': interestPayments.map((e) => e.toJson()).toList(),
      };

  factory Loan.fromJson(Map<String, dynamic> j) => Loan(
        id: j['id'] as String,
        clientId: j['clientId'] as String,
        type: LoanType.values[j['type'] as int],
        capital: (j['capital'] as num).toDouble(),
        interestRate: (j['interestRate'] as num).toDouble(),
        startDate: DateTime.parse(j['startDate'] as String),
        termDays: j['termDays'] as int?,
        installmentsCount: j['installmentsCount'] as int?,
        status: LoanStatus.values[j['status'] as int],
        notes: (j['notes'] ?? '') as String,
        createdAt: DateTime.parse(j['createdAt'] as String),
        closedAt: j['closedAt'] == null ? null : DateTime.parse(j['closedAt'] as String),
        schedule: ((j['schedule'] ?? []) as List)
            .map((e) => LoanInstallment.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        interestPayments: ((j['interestPayments'] ?? []) as List)
            .map((e) => InterestPayment.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );
}

class LoanAdapter extends TypeAdapter<Loan> {
  @override
  final int typeId = 2;

  @override
  Loan read(BinaryReader reader) {
    final n = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < n; i++) reader.readByte(): reader.read(),
    };
    return Loan(
      id: fields[0] as String,
      clientId: fields[1] as String,
      type: LoanType.values[fields[2] as int],
      capital: fields[3] as double,
      interestRate: fields[4] as double,
      startDate: fields[5] as DateTime,
      termDays: fields[6] as int?,
      installmentsCount: fields[7] as int?,
      status: LoanStatus.values[fields[8] as int],
      notes: (fields[9] ?? '') as String,
      createdAt: fields[10] as DateTime,
      closedAt: fields[11] as DateTime?,
      schedule: (fields[12] as List).cast<LoanInstallment>(),
      interestPayments: (fields[13] as List).cast<InterestPayment>(),
    );
  }

  @override
  void write(BinaryWriter writer, Loan obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.clientId)
      ..writeByte(2)
      ..write(obj.type.index)
      ..writeByte(3)
      ..write(obj.capital)
      ..writeByte(4)
      ..write(obj.interestRate)
      ..writeByte(5)
      ..write(obj.startDate)
      ..writeByte(6)
      ..write(obj.termDays)
      ..writeByte(7)
      ..write(obj.installmentsCount)
      ..writeByte(8)
      ..write(obj.status.index)
      ..writeByte(9)
      ..write(obj.notes)
      ..writeByte(10)
      ..write(obj.createdAt)
      ..writeByte(11)
      ..write(obj.closedAt)
      ..writeByte(12)
      ..write(obj.schedule)
      ..writeByte(13)
      ..write(obj.interestPayments);
  }
}
