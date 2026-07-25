import 'package:flutter/material.dart';

import '../screens/clients_screen.dart';
import '../screens/collections_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/history_screen.dart';
import '../screens/loans_screen.dart';
import '../screens/map_screen.dart';
import '../screens/new_loan_screen.dart';
import '../screens/reports_screen.dart';
import '../screens/settings_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  final _pages = const [
    DashboardScreen(),
    ClientsScreen(),
    NewLoanScreen(),
    CollectionsScreen(),
    ReportsScreen(),
  ];

  final _titles = const [
    'Dashboard',
    'Clientes',
    'Novo empréstimo',
    'Cobranças do dia',
    'Relatórios',
  ];

  void _select(int i) {
    setState(() => _index = i);
  }

  void _openRoute(Widget page) {
    Navigator.of(context).pop(); // fecha o drawer
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_titles[_index])),
      drawer: _buildDrawer(context),
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _select,
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: 'Início'),
          NavigationDestination(
              icon: Icon(Icons.people_alt_outlined),
              selectedIcon: Icon(Icons.people_alt),
              label: 'Clientes'),
          NavigationDestination(
              icon: Icon(Icons.add_circle_outline),
              selectedIcon: Icon(Icons.add_circle),
              label: 'Novo'),
          NavigationDestination(
              icon: Icon(Icons.request_quote_outlined),
              selectedIcon: Icon(Icons.request_quote),
              label: 'Cobranças'),
          NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined),
              selectedIcon: Icon(Icons.bar_chart),
              label: 'Relatórios'),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget item(IconData icon, String label, VoidCallback onTap) => ListTile(
          leading: Icon(icon),
          title: Text(label),
          onTap: onTap,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        );

    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 20, 12, 12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: scheme.primaryContainer,
                    child: Icon(Icons.account_balance_wallet,
                        color: scheme.onPrimaryContainer),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('EmprestaFácil',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800)),
                      Text('Gestão de empréstimos',
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(),
            item(Icons.dashboard, 'Dashboard', () {
              Navigator.pop(context);
              _select(0);
            }),
            item(Icons.people_alt, 'Clientes', () {
              Navigator.pop(context);
              _select(1);
            }),
            item(Icons.request_quote, 'Empréstimos',
                () => _openRoute(const LoansScreen())),
            item(Icons.today, 'Cobranças do dia', () {
              Navigator.pop(context);
              _select(3);
            }),
            item(Icons.map, 'Mapa', () => _openRoute(const MapScreen())),
            item(Icons.history, 'Histórico',
                () => _openRoute(const HistoryScreen())),
            item(Icons.bar_chart, 'Relatórios', () {
              Navigator.pop(context);
              _select(4);
            }),
            const Divider(),
            item(Icons.settings, 'Configurações',
                () => _openRoute(const SettingsScreen())),
          ],
        ),
      ),
    );
  }
}
