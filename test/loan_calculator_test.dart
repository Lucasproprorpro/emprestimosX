import 'package:emprestafacil/core/utils/loan_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Penhor', () {
    test('juros = capital * taxa/100', () {
      expect(LoanCalculator.pledgeInterest(1000, 10), 100.0);
      expect(LoanCalculator.pledgeInterest(2500, 8), 200.0);
    });
  });

  group('Diário', () {
    test('gera agenda com o número de dias correto', () {
      final s = LoanCalculator.dailySchedule(
        capital: 1000,
        ratePercent: 6,
        termDays: 20,
        startDate: DateTime(2025, 1, 1),
      );
      expect(s.length, 20);
      // total = 1000 * 1.06 = 1060
      expect(LoanCalculator.scheduleTotal(s), closeTo(1060, 0.001));
      // primeiro vencimento no dia seguinte
      expect(s.first.dueDate, DateTime(2025, 1, 2));
      expect(s.last.dueDate, DateTime(2025, 1, 21));
    });

    test('soma das parcelas fecha exatamente com o total', () {
      final s = LoanCalculator.dailySchedule(
        capital: 777,
        ratePercent: 13,
        termDays: 7,
        startDate: DateTime(2025, 3, 10),
      );
      final total = LoanCalculator.scheduleTotal(s);
      expect(total, closeTo(777 * 1.13, 0.001));
    });
  });

  group('Parcelado', () {
    test('juros somados ao capital e divididos em parcelas', () {
      final s = LoanCalculator.installmentSchedule(
        capital: 1000,
        ratePercent: 20,
        count: 4,
        startDate: DateTime(2025, 1, 15),
      );
      expect(s.length, 4);
      // total = 1000 + 200 = 1200; parcela = 300
      expect(LoanCalculator.scheduleTotal(s), closeTo(1200, 0.001));
      expect(s.first.amount, 300.0);
      // vencimentos mensais
      expect(s[0].dueDate, DateTime(2025, 2, 15));
      expect(s[3].dueDate, DateTime(2025, 5, 15));
    });

    test('última parcela absorve arredondamento', () {
      final s = LoanCalculator.installmentSchedule(
        capital: 1000,
        ratePercent: 10,
        count: 3,
        startDate: DateTime(2025, 1, 31),
      );
      // total = 1100; 1100/3 = 366.67; última ajusta
      final total = LoanCalculator.scheduleTotal(s);
      expect(total, closeTo(1100, 0.001));
      // fevereiro não tem dia 31 -> ajusta para 28
      expect(s[0].dueDate, DateTime(2025, 2, 28));
    });
  });
}
