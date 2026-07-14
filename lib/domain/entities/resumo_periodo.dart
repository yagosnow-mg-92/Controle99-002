/// Agrega todos os indicadores financeiros calculados para um período
/// (dia, semana, mês, etc). É o resultado da "inteligência" do app:
/// sempre recalculado a partir dos lançamentos brutos, nunca persistido.
class ResumoPeriodo {
  final double receitaTotal;
  final double despesaTotal;
  final double lucroLiquido;
  final double kmRodados;
  final int quantidadeReceitas;
  final int quantidadeDespesas;
  final double maiorReceitaDiaria;
  final double maiorDespesa;
  final DateTime? melhorDia;
  final DateTime? piorDia;
  final Map<String, double> despesasPorCategoria;

  const ResumoPeriodo({
    this.receitaTotal = 0,
    this.despesaTotal = 0,
    this.lucroLiquido = 0,
    this.kmRodados = 0,
    this.quantidadeReceitas = 0,
    this.quantidadeDespesas = 0,
    this.maiorReceitaDiaria = 0,
    this.maiorDespesa = 0,
    this.melhorDia,
    this.piorDia,
    this.despesasPorCategoria = const {},
  });

  double get receitaPorKm => kmRodados > 0 ? receitaTotal / kmRodados : 0;
  double get lucroPorKm => kmRodados > 0 ? lucroLiquido / kmRodados : 0;
  double get despesaPorKm => kmRodados > 0 ? despesaTotal / kmRodados : 0;
  double get percentualLucro =>
      receitaTotal > 0 ? (lucroLiquido / receitaTotal) * 100 : 0;
  double get percentualDespesa =>
      receitaTotal > 0 ? (despesaTotal / receitaTotal) * 100 : 0;
}
