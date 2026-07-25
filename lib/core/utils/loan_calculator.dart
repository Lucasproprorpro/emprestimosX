import '../constants/enums.dart';
import '../../data/models/installment.dart';
import 'date_utils.dart';

/// Regras de cálculo das três modalidades de empréstimo.
///
/// Todas as funções são PURAS (sem efeitos colaterais) para facilitar testes.
/// As premissas de cada modalidade estão documentadas abaixo e podem ser
/// ajustadas em um único lugar sem afetar o restante do app.
class LoanCalculator {
  /// Arredonda para 2 casas decimais.
  static double round2(double v) => (v * 100).roundToDouble() / 100;

  // -------------------------------------------------------------- PENHOR

  /// Penhor: o cliente paga apenas os juros sobre o capital.
  /// Ex.: capital 1000, taxa 10%  ->  juros 100 por período.
  static double pledgeInterest(double capital, double ratePercent) =>
      round2(capital * ratePercent / 100);

  // -------------------------------------------------------------- DIÁRIO

  /// Diário: gera uma agenda com [termDays] dias.
  ///
  /// Premissa: a taxa informada é o percentual TOTAL de juros sobre o período.
  /// total a receber = capital * (1 + taxa/100); dividido igualmente pelos
  /// dias, com o último dia absorvendo eventual diferença de arredondamento.
  /// O primeiro vencimento é no dia seguinte ao [startDate].
  static List<LoanInstallment> dailySchedule({
    required double capital,
    required double ratePercent,
    required int termDays,
    required DateTime startDate,
  }) {
    assert(termDays > 0);
    final total = round2(capital * (1 + ratePercent / 100));
    final base = round2(total / termDays);
    final start = DateOnly.of(startDate);

    final items = <LoanInstallment>[];
    double accumulated = 0;
    for (int day = 1; day <= termDays; day++) {
      final isLast = day == termDays;
      final amount = isLast ? round2(total - accumulated) : base;
      accumulated = round2(accumulated + amount);
      items.add(LoanInstallment(
        number: day,
        dueDate: start.add(Duration(days: day)),
        amount: amount,
        status: PaymentStatus.future,
      ));
    }
    return items;
  }

  // ------------------------------------------------------------ PARCELADO

  /// Parcelado: calcula juros sobre o capital, divide o capital e acrescenta os
  /// juros em cada parcela (método "flat" descrito na especificação).
  ///
  /// juros total = capital * taxa/100
  /// total       = capital + juros
  /// parcela      = total / n  (a última parcela absorve o arredondamento)
  /// Vencimentos mensais a partir de um mês após o [startDate].
  static List<LoanInstallment> installmentSchedule({
    required double capital,
    required double ratePercent,
    required int count,
    required DateTime startDate,
  }) {
    assert(count > 0);
    final interest = round2(capital * ratePercent / 100);
    final total = round2(capital + interest);
    final base = round2(total / count);
    final start = DateOnly.of(startDate);

    final items = <LoanInstallment>[];
    double accumulated = 0;
    for (int i = 1; i <= count; i++) {
      final isLast = i == count;
      final amount = isLast ? round2(total - accumulated) : base;
      accumulated = round2(accumulated + amount);
      items.add(LoanInstallment(
        number: i,
        dueDate: DateOnly.addMonths(start, i),
        amount: amount,
        status: PaymentStatus.future,
      ));
    }
    return items;
  }

  // ------------------------------------------------------------- helpers

  /// Total a receber de uma agenda gerada.
  static double scheduleTotal(List<LoanInstallment> schedule) =>
      round2(schedule.fold(0.0, (s, i) => s + i.amount));

  /// Juros embutidos na agenda (total - capital).
  static double scheduleInterest(
          List<LoanInstallment> schedule, double capital) =>
      round2(scheduleTotal(schedule) - capital);
}
