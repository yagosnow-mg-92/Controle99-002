import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'data/repositories/despesa_repository_impl.dart';
import 'data/repositories/receita_repository_impl.dart';
import 'domain/repositories/despesa_repository.dart';
import 'domain/repositories/receita_repository.dart';
import 'presentation/providers/dashboard_provider.dart';
import 'presentation/screens/home_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR', null);
  runApp(const MotoGestorApp());
}

/// Ponto único de injeção de dependências manual (sem framework externo,
/// mantendo o projeto simples de entender e evoluir). Repositórios são
/// expostos pela interface de domínio, nunca pela implementação concreta,
/// permitindo trocar a fonte de dados (ex.: sincronização em nuvem) no futuro.
class MotoGestorApp extends StatelessWidget {
  const MotoGestorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ReceitaRepository>(create: (_) => ReceitaRepositoryImpl()),
        Provider<DespesaRepository>(create: (_) => DespesaRepositoryImpl()),
        ChangeNotifierProvider<DashboardProvider>(
          create: (context) => DashboardProvider(
            receitaRepository: context.read<ReceitaRepository>(),
            despesaRepository: context.read<DespesaRepository>(),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'Moto Gestor',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.dark,
        home: const HomeShell(),
      ),
    );
  }
}
