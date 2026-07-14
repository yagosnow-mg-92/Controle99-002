import 'package:collection/collection.dart';

import '../../domain/entities/despesa.dart';
import '../../domain/entities/receita.dart';
import '../../domain/entities/resumo_periodo.dart';

/// Camada de "inteligência" do app: recebe listas cruas de receitas e
/// despesas e calcula todos os indicadores derivados. Fica isolada para
/// que Dashboard e tela de Indicadores reutilizem exatamente a mesma lógica.
class IndicadoresService {
  ResumoPeriodo calcular({
    required List<Receita> receitas,
    required List<Despesa> despesas,
    DateTime? inicio,
    DateTime? fim,
  }) {
    final receitaTotal = receitas.fold<double>(0, (s, r) => s + r.valorRecebido);
    final despesaTotal = despesas.fold<double>(0, (s, d) => s + d.valor);
    final kmRodados = receitas.fold<double>(0, (s, r) => s + r.kmRodados);

    final receitasPorDia = groupBy(receitas, (Receita r) => _apenasData(r.data));
    final totalPorDia = receitasPorDia.map(
      (dia, lista) => MapEntry(dia, lista.fold<double>(0, (s, r) => s + r.valorRecebido)),
    );

    MapEntry<DateTime, double>? melhor;
    MapEntry<DateTime, double>? pior;
    for (final entry in totalPorDia.entries) {
      if (melhor == null || entry.value > melhor.value) melhor = entry;
      if (pior == null || entry.value < pior.value) pior = entry;
    }

    final despesasPorCategoria = <String, double>{};
    for (final d in despesas) {
      despesasPorCategoria[d.categoria] =
          (despesasPorCategoria[d.categoria] ?? 0) + d.valor;
    }

    final maiorDespesa = despesas.isEmpty
        ? 0.0
        : despesas.map((d) => d.valor).reduce((a, b) => a > b ? a : b);

    final numeroDias = (inicio != null && fim != null)
        ? fim.difference(inicio).inDays.clamp(1, 100000)
        : 1;

    return ResumoPeriodo(
      receitaTotal: receitaTotal,
      despesaTotal: despesaTotal,
      lucroLiquido: receitaTotal - despesaTotal,
      kmRodados: kmRodados,
      quantidadeReceitas: receitas.length,
      quantidadeDespesas: despesas.length,
      maiorReceitaDiaria: melhor?.value ?? 0,
      maiorDespesa: maiorDespesa,
      melhorDia: melhor?.key,
      piorDia: pior?.key,
      despesasPorCategoria: despesasPorCategoria,
      numeroDias: numeroDias,
    );
  }

  DateTime _apenasData(DateTime d) => DateTime(d.year, d.month, d.day);
}
