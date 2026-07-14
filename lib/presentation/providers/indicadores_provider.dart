import 'package:flutter/foundation.dart';

import '../../core/utils/indicadores_service.dart';
import '../../domain/entities/periodo_filtro.dart';
import '../../domain/entities/resumo_periodo.dart';
import '../../domain/repositories/despesa_repository.dart';
import '../../domain/repositories/receita_repository.dart';

/// Estado da tela de Indicadores: controla o filtro de período selecionado
/// e recalcula o resumo agregado sempre que o filtro muda.
class IndicadoresProvider extends ChangeNotifier {
  final ReceitaRepository _receitaRepository;
  final DespesaRepository _despesaRepository;
  final IndicadoresService _indicadoresService;

  IndicadoresProvider({
    required ReceitaRepository receitaRepository,
    required DespesaRepository despesaRepository,
    IndicadoresService? indicadoresService,
  })  : _receitaRepository = receitaRepository,
        _despesaRepository = despesaRepository,
        _indicadoresService = indicadoresService ?? IndicadoresService();

  bool carregando = true;
  PeriodoFiltro filtro = PeriodoFiltro.mes;
  DateTime periodoPersonalizadoInicio = DateTime.now().subtract(const Duration(days: 7));
  DateTime periodoPersonalizadoFim = DateTime.now();

  ResumoPeriodo resumo = const ResumoPeriodo();

  ({DateTime inicio, DateTime fim}) get intervaloAtual => _calcularIntervalo();

  Future<void> mudarFiltro(PeriodoFiltro novoFiltro) async {
    filtro = novoFiltro;
    await carregar();
  }

  Future<void> definirPeriodoPersonalizado(DateTime inicio, DateTime fim) async {
    periodoPersonalizadoInicio = inicio;
    periodoPersonalizadoFim = fim;
    filtro = PeriodoFiltro.personalizado;
    await carregar();
  }

  Future<void> carregar() async {
    carregando = true;
    notifyListeners();

    final intervalo = _calcularIntervalo();

    final receitas = await _receitaRepository.listar(
      inicio: intervalo.inicio,
      fim: intervalo.fim,
    );
    final despesas = await _despesaRepository.listar(
      inicio: intervalo.inicio,
      fim: intervalo.fim,
    );

    resumo = _indicadoresService.calcular(
      receitas: receitas,
      despesas: despesas,
      inicio: intervalo.inicio,
      fim: intervalo.fim,
    );

    carregando = false;
    notifyListeners();
  }

  ({DateTime inicio, DateTime fim}) _calcularIntervalo() {
    final agora = DateTime.now();
    final hoje = DateTime(agora.year, agora.month, agora.day);

    switch (filtro) {
      case PeriodoFiltro.dia:
        return (inicio: hoje, fim: hoje.add(const Duration(days: 1)));

      case PeriodoFiltro.semana:
        // Semana começando na segunda-feira.
        final inicioSemana = hoje.subtract(Duration(days: hoje.weekday - 1));
        return (inicio: inicioSemana, fim: inicioSemana.add(const Duration(days: 7)));

      case PeriodoFiltro.mes:
        final inicioMes = DateTime(hoje.year, hoje.month, 1);
        final inicioProximoMes = DateTime(hoje.year, hoje.month + 1, 1);
        return (inicio: inicioMes, fim: inicioProximoMes);

      case PeriodoFiltro.trimestre:
        final trimestreAtual = ((hoje.month - 1) ~/ 3);
        final mesInicioTrimestre = trimestreAtual * 3 + 1;
        final inicioTrimestre = DateTime(hoje.year, mesInicioTrimestre, 1);
        final inicioProximoTrimestre = DateTime(hoje.year, mesInicioTrimestre + 3, 1);
        return (inicio: inicioTrimestre, fim: inicioProximoTrimestre);

      case PeriodoFiltro.ano:
        return (inicio: DateTime(hoje.year, 1, 1), fim: DateTime(hoje.year + 1, 1, 1));

      case PeriodoFiltro.personalizado:
        final fimExclusivo = DateTime(
          periodoPersonalizadoFim.year,
          periodoPersonalizadoFim.month,
          periodoPersonalizadoFim.day,
        ).add(const Duration(days: 1));
        return (
          inicio: DateTime(
            periodoPersonalizadoInicio.year,
            periodoPersonalizadoInicio.month,
            periodoPersonalizadoInicio.day,
          ),
          fim: fimExclusivo,
        );
    }
  }
}
