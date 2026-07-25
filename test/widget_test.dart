import 'package:emprestafacil/core/utils/formatters.dart';
import 'package:emprestafacil/presentation/widgets/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('StatCard renderiza rótulo e valor', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatCard(
            label: 'Total emprestado',
            value: Formatters.money(1000),
            icon: Icons.outbond,
          ),
        ),
      ),
    );

    expect(find.text('Total emprestado'), findsOneWidget);
    expect(find.byIcon(Icons.outbond), findsOneWidget);
  });

  testWidgets('StatusChip mostra o status', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: StatusChip(label: 'Ativo'))),
      ),
    );
    expect(find.text('Ativo'), findsOneWidget);
  });
}
