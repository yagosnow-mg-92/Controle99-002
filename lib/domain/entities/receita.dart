class Receita {
  final String id;
  final DateTime data;
  final double kmRodados;
  final double valorRecebido;
  final String? observacao;
  final DateTime criadoEm;

  const Receita({
    required this.id,
    required this.data,
    required this.kmRodados,
    required this.valorRecebido,
    this.observacao,
    required this.criadoEm,
  });

  /// Valor recebido por quilômetro rodado. Regra de negócio central do app.
  double get valorPorKm => kmRodados > 0 ? valorRecebido / kmRodados : 0;

  Receita copyWith({
    String? id,
    DateTime? data,
    double? kmRodados,
    double? valorRecebido,
    String? observacao,
    DateTime? criadoEm,
  }) {
    return Receita(
      id: id ?? this.id,
      data: data ?? this.data,
      kmRodados: kmRodados ?? this.kmRodados,
      valorRecebido: valorRecebido ?? this.valorRecebido,
      observacao: observacao ?? this.observacao,
      criadoEm: criadoEm ?? this.criadoEm,
    );
  }
}
