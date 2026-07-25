import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../providers/derived.dart';
import '../widgets/common.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final m = ref.watch(dashboardProvider);
    final width = MediaQuery.of(context).size.width;
    final columns = width >= 900 ? 4 : (width >= 600 ? 3 : 2);

    final cards = [
      StatCard(
          label: 'Total emprestado',
          value: Formatters.money(m.totalLent),
          icon: Icons.outbond,
          color: AppTheme.info),
      StatCard(
          label: 'Total recebido',
          value: Formatters.money(m.totalReceived),
          icon: Icons.savings,
          color: AppTheme.positive),
      StatCard(
          label: 'Em aberto',
          value: Formatters.money(m.totalOutstanding),
          icon: Icons.hourglass_bottom,
          color: AppTheme.warning),
      StatCard(
          label: 'Juros recebidos',
          value: Formatters.money(m.interestReceived),
          icon: Icons.trending_up,
          color: AppTheme.positive),
      StatCard(
          label: 'Clientes ativos',
          value: '${m.activeClients}',
          icon: Icons.people,
          color: AppTheme.info),
      StatCard(
          label: 'Clientes atrasados',
          value: '${m.overdueClients}',
          icon: Icons.report_gmailerrorred,
          color: AppTheme.negative),
      StatCard(
          label: 'Empréstimos ativos',
          value: '${m.activeLoans}',
          icon: Icons.play_circle,
          color: AppTheme.info),
      StatCard(
          label: 'Encerrados',
          value: '${m.closedLoans}',
          icon: Icons.check_circle,
          color: AppTheme.positive),
    ];

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(dashboardProvider),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GridView.count(
            crossAxisCount: columns,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.15,
            children: cards,
          ),
          const SizedBox(height: 20),
          const SectionTitle('Recebimentos mensais'),
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 20, 16, 12),
              child: SizedBox(
                height: 220,
                child: _MonthlyChart(data: m.monthlyReceipts),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const SectionTitle('Situação da carteira'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: _PortfolioBars(
                active: m.activeLoans,
                overdue: m.overdueClients,
                closed: m.closedLoans,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthlyChart extends StatelessWidget {
  const _MonthlyChart({required this.data});
  final List<MapEntry<String, double>> data;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (data.every((e) => e.value == 0)) {
      return const Center(child: Text('Sem recebimentos ainda.'));
    }
    final maxV = data.map((e) => e.value).reduce((a, b) => a > b ? a : b);

    String monthLabel(String key) {
      final parts = key.split('-');
      const months = [
        'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
        'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'
      ];
      return months[int.parse(parts[1]) - 1];
    }

    return BarChart(
      BarChartData(
        maxY: maxV * 1.25,
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          drawVerticalLine: false,
          getDrawingHorizontalLine: (v) =>
              FlLine(color: scheme.outlineVariant.withOpacity(.4), strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 42,
              getTitlesWidget: (v, _) => Text(
                Formatters.moneyCompact(v),
                style: const TextStyle(fontSize: 9),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < 0 || i >= data.length) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(monthLabel(data[i].key),
                      style: const TextStyle(fontSize: 11)),
                );
              },
            ),
          ),
        ),
        barGroups: [
          for (int i = 0; i < data.length; i++)
            BarChartGroupData(x: i, barRods: [
              BarChartRodData(
                toY: data[i].value,
                color: scheme.primary,
                width: 16,
                borderRadius: BorderRadius.circular(6),
              )
            ]),
        ],
      ),
    );
  }
}

class _PortfolioBars extends StatelessWidget {
  const _PortfolioBars({
    required this.active,
    required this.overdue,
    required this.closed,
  });
  final int active;
  final int overdue;
  final int closed;

  @override
  Widget build(BuildContext context) {
    final total = (active + overdue + closed).clamp(1, 1 << 30);
    Widget bar(String label, int value, Color color) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(label),
                const Spacer(),
                Text('$value',
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: value / total,
                minHeight: 8,
                backgroundColor: color.withOpacity(.15),
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        bar('Ativos', active, AppTheme.info),
        bar('Em atraso', overdue, AppTheme.negative),
        bar('Encerrados', closed, AppTheme.positive),
      ],
    );
  }
}
