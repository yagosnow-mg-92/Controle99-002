import 'package:flutter/foundation.dart';

import '../../core/utils/indicadores_service.dart';
import '../../domain/entities/despesa.dart';
import '../../domain/entities/receita.dart';
import '../../domain/entities/resumo_periodo.dart';
import '../../domain/repositories/despesa_repository.dart';
import '../../domain/repositories/receita_repository.dart';

/// Estado da tela Dashboard. Sempre que um lançamento é salvo em qualquer
/// parte do app, `recarregar()` deve ser chamado para que os indicadores
/// sejam recalculados automaticamente — cumprindo o requisito de
/// "inteligência" do aplicativo.
class DashboardProvider extends ChangeNotifier {
  final ReceitaRepository _receitaRepository;
  final DespesaRepository _despesaRepository;
  final IndicadoresService _indicadoresService;

  DashboardProvider({
    required ReceitaRepository receitaRepository,
    required DespesaRepository despesaRepository,
    IndicadoresService? indicadoresService,
  })  : _receitaRepository = receitaRepository,
        _despesaRepository = despesaRepository,
        _indicadoresService = indicadoresService ?? IndicadoresService();

  bool carregando = true;
  ResumoPeriodo resumoHoje = const ResumoPeriodo();
  List<Receita> ultimasReceitas = [];
  List<Despesa> ultimasDespesas = [];
  List<ResumoPeriodo> ultimos7Dias = [];

  Future<void> carregar() async {
    carregando = true;
    notifyListeners();

    final agora = DateTime.now();
    final inicioHoje = DateTime(agora.year, agora.month, agora.day);
    final fimHoje = inicioHoje.add(const Duration(days: 1));

    final receitasHoje = await _receitaRepository.listar(inicio: inicioHoje, fim: fimHoje);
    final despesasHoje = await _despesaRepository.listar(inicio: inicioHoje, fim: fimHoje);

    resumoHoje = _indicadoresService.calcular(
      receitas: receitasHoje,
      despesas: despesasHoje,
    );

    final todasReceitas = await _receitaRepository.listar();
    final todasDespesas = await _despesaRepository.listar();

    ultimasReceitas = todasReceitas.take(5).toList();
    ultimasDespesas = todasDespesas.take(5).toList();

    ultimos7Dias = await _calcularUltimosDias(7);

    carregando = false;
    notifyListeners();
  }

  Future<List<ResumoPeriodo>> _calcularUltimosDias(int dias) async {
    final resultado = <ResumoPeriodo>[];
    final hoje = DateTime.now();

    for (int i = dias - 1; i >= 0; i--) {
      final dia = DateTime(hoje.year, hoje.month, hoje.day).subtract(Duration(days: i));
      final proximoDia = dia.add(const Duration(days: 1));

      final receitas = await _receitaRepository.listar(inicio: dia, fim: proximoDia);
      final despesas = await _despesaRepository.listar(inicio: dia, fim: proximoDia);

      resultado.add(_indicadoresService.calcular(receitas: receitas, despesas: despesas));
    }

    return resultado;
  }
}
