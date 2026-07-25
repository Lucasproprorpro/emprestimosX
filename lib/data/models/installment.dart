import 'package:hive/hive.dart';

import '../../core/constants/enums.dart';

/// Uma parcela (modalidade Parcelado) ou um dia da agenda (modalidade Diário).
class LoanInstallment {
  LoanInstallment({
    required this.number,
    required this.dueDate,
    required this.amount,
    this.status = PaymentStatus.future,
    this.paidAt,
    this.note = '',
  });

  final int number;
  DateTime dueDate;
  double amount;
  PaymentStatus status;
  DateTime? paidAt;
  String note;

  bool get isPaid => status == PaymentStatus.paid;

  Map<String, dynamic> toJson() => {
        'number': number,
        'dueDate': dueDate.toIso8601String(),
        'amount': amount,
        'status': status.index,
        'paidAt': paidAt?.toIso8601String(),
        'note': note,
      };

  factory LoanInstallment.fromJson(Map<String, dynamic> j) => LoanInstallment(
        number: j['number'] as int,
        dueDate: DateTime.parse(j['dueDate'] as String),
        amount: (j['amount'] as num).toDouble(),
        status: PaymentStatus.values[j['status'] as int],
        paidAt: j['paidAt'] == null ? null : DateTime.parse(j['paidAt'] as String),
        note: (j['note'] ?? '') as String,
      );
}

class LoanInstallmentAdapter extends TypeAdapter<LoanInstallment> {
  @override
  final int typeId = 3;

  @override
  LoanInstallment read(BinaryReader reader) {
    final n = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < n; i++) reader.readByte(): reader.read(),
    };
    return LoanInstallment(
      number: fields[0] as int,
      dueDate: fields[1] as DateTime,
      amount: fields[2] as double,
      status: PaymentStatus.values[fields[3] as int],
      paidAt: fields[4] as DateTime?,
      note: (fields[5] ?? '') as String,
    );
  }

  @override
  void write(BinaryWriter writer, LoanInstallment obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.number)
      ..writeByte(1)
      ..write(obj.dueDate)
      ..writeByte(2)
      ..write(obj.amount)
      ..writeByte(3)
      ..write(obj.status.index)
      ..writeByte(4)
      ..write(obj.paidAt)
      ..writeByte(5)
      ..write(obj.note);
  }
}

/// Pagamento de juros (modalidade Penhor). O capital permanece em aberto.
class InterestPayment {
  InterestPayment({
    required this.amount,
    required this.paidAt,
    this.note = '',
  });

  final double amount;
  final DateTime paidAt;
  final String note;

  Map<String, dynamic> toJson() => {
        'amount': amount,
        'paidAt': paidAt.toIso8601String(),
        'note': note,
      };

  factory InterestPayment.fromJson(Map<String, dynamic> j) => InterestPayment(
        amount: (j['amount'] as num).toDouble(),
        paidAt: DateTime.parse(j['paidAt'] as String),
        note: (j['note'] ?? '') as String,
      );
}

class InterestPaymentAdapter extends TypeAdapter<InterestPayment> {
  @override
  final int typeId = 4;

  @override
  InterestPayment read(BinaryReader reader) {
    final n = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < n; i++) reader.readByte(): reader.read(),
    };
    return InterestPayment(
      amount: fields[0] as double,
      paidAt: fields[1] as DateTime,
      note: (fields[2] ?? '') as String,
    );
  }

  @override
  void write(BinaryWriter writer, InterestPayment obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.amount)
      ..writeByte(1)
      ..write(obj.paidAt)
      ..writeByte(2)
      ..write(obj.note);
  }
}
