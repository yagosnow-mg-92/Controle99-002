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

  /// Lucro dia a dia dentro do período filtrado — usado no gráfico de
  /// evolução (lucro acumulado).
  List<({DateTime dia, double lucro})> serieDiaria = [];

  /// Lucro dos últimos 6 meses (independente do filtro atual) — usado no
  /// gráfico de histórico mensal.
  List<({String mes, double lucro})> historicoMensal = [];

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

    serieDiaria = await _calcularSerieDiaria(intervalo.inicio, intervalo.fim);
    historicoMensal = await _calcularHistoricoMensal();

    carregando = false;
    notifyListeners();
  }

  /// Calcula o lucro de cada dia do período, limitando a 60 pontos para
  /// não pesar o gráfico em períodos muito longos (ex: Ano inteiro) —
  /// nesse caso, agrega por semana.
  Future<List<({DateTime dia, double lucro})>> _calcularSerieDiaria(
    DateTime inicio,
    DateTime fim,
  ) async {
    final totalDias = fim.difference(inicio).inDays;
    final passo = totalDias > 60 ? (totalDias / 60).ceil() : 1;

    final resultado = <({DateTime dia, double lucro})>[];
    for (int i = 0; i < totalDias; i += passo) {
      final diaInicio = inicio.add(Duration(days: i));
      final diaFim = inicio.add(Duration(days: (i + passo).clamp(0, totalDias)));

      final receitas = await _receitaRepository.listar(inicio: diaInicio, fim: diaFim);
      final despesas = await _despesaRepository.listar(inicio: diaInicio, fim: diaFim);

      final receitaTotal = receitas.fold<double>(0, (s, r) => s + r.valorRecebido);
      final despesaTotal = despesas.fold<double>(0, (s, d) => s + d.valor);

      resultado.add((dia: diaInicio, lucro: receitaTotal - despesaTotal));
    }
    return resultado;
  }

  Future<List<({String mes, double lucro})>> _calcularHistoricoMensal() async {
    final hoje = DateTime.now();
    final resultado = <({String mes, double lucro})>[];
    const nomesMeses = [
      'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
      'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez',
    ];

    for (int i = 5; i >= 0; i--) {
      final referencia = DateTime(hoje.year, hoje.month - i, 1);
      final inicioMes = DateTime(referencia.year, referencia.month, 1);
      final inicioProximoMes = DateTime(referencia.year, referencia.month + 1, 1);

      final receitas = await _receitaRepository.listar(inicio: inicioMes, fim: inicioProximoMes);
      final despesas = await _despesaRepository.listar(inicio: inicioMes, fim: inicioProximoMes);

      final receitaTotal = receitas.fold<double>(0, (s, r) => s + r.valorRecebido);
      final despesaTotal = despesas.fold<double>(0, (s, d) => s + d.valor);

      resultado.add((mes: nomesMeses[referencia.month - 1], lucro: receitaTotal - despesaTotal));
    }
    return resultado;
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
