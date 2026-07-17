import 'package:flutter/material.dart';

import 'corrida/corrida_screen.dart';
import 'dashboard/dashboard_screen.dart';
import 'despesas/despesas_screen.dart';
import 'indicadores/indicadores_screen.dart';
import 'configuracoes/configuracoes_screen.dart';
import 'receita/receita_screen.dart';

/// Casca de navegação principal. Mantém as áreas do app acessíveis
/// por uma barra inferior, seguindo o padrão Material 3.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  final _telas = const [
    DashboardScreen(),
    CorridaScreen(),
    ReceitaScreen(),
    DespesasScreen(),
    IndicadoresScreen(),
    ConfiguracoesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _telas),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_rounded), label: 'Painel'),
          NavigationDestination(icon: Icon(Icons.two_wheeler_rounded), label: 'Corrida'),
          NavigationDestination(icon: Icon(Icons.add_circle_outline_rounded), label: 'Receita'),
          NavigationDestination(icon: Icon(Icons.receipt_long_rounded), label: 'Despesas'),
          NavigationDestination(icon: Icon(Icons.bar_chart_rounded), label: 'Indicadores'),
          NavigationDestination(icon: Icon(Icons.settings_rounded), label: 'Ajustes'),
        ],
      ),
    );
  }
}
