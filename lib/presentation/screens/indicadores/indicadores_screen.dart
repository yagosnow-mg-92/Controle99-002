import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/periodo_filtro.dart';
import '../../../domain/entities/resumo_periodo.dart';
import '../../providers/indicadores_provider.dart';
import '../../widgets/indicador_card.dart';

class IndicadoresScreen extends StatefulWidget {
  const IndicadoresScreen({super.key});

  @override
  State<IndicadoresScreen> createState() => _IndicadoresScreenState();
}

class _IndicadoresScreenState extends State<IndicadoresScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<IndicadoresProvider>().carregar();
    });
  }

  Future<void> _selecionarPeriodoPersonalizado() async {
    final provider = context.read<IndicadoresProvider>();
    final resultado = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: provider.periodoPersonalizadoInicio,
        end: provider.periodoPersonalizadoFim,
      ),
      locale: const Locale('pt', 'BR'),
    );
    if (resultado != null) {
      await provider.definirPeriodoPersonalizado(resultado.start, resultado.end);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Indicadores')),
      body: SafeArea(
        child: Consumer<IndicadoresProvider>(
          builder: (context, provider, _) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                _filtrosPeriodo(provider),
                const SizedBox(height: 20),
                if (provider.carregando)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                  )
                else ...[
                  _resumoPrincipal(provider.resumo),
                  const SizedBox(height: 24),
                  const _TituloSecao('Evolução do lucro acumulado'),
                  const SizedBox(height: 12),
                  _graficoEvolucao(provider.serieDiaria),
                  const SizedBox(height: 24),
                  const _TituloSecao('Histórico mensal'),
                  const SizedBox(height: 12),
                  _graficoHistoricoMensal(provider.historicoMensal),
                  const SizedBox(height: 24),
                  const _TituloSecao('Receita x Despesa'),
                  const SizedBox(height: 12),
                  _graficoBarras(provider.resumo),
                  const SizedBox(height: 24),
                  const _TituloSecao('Despesas por categoria'),
                  const SizedBox(height: 12),
                  _graficoPizza(provider.resumo),
                  const SizedBox(height: 24),
                  const _TituloSecao('Todos os indicadores'),
                  const SizedBox(height: 12),
                  _gradeIndicadores(provider.resumo),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _filtrosPeriodo(IndicadoresProvider provider) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: PeriodoFiltro.values.map((periodo) {
          final selecionado = provider.filtro == periodo;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(periodo.label),
              selected: selecionado,
              onSelected: (_) async {
                if (periodo == PeriodoFiltro.personalizado) {
                  await _selecionarPeriodoPersonalizado();
                } else {
                  await provider.mudarFiltro(periodo);
                }
              },
              backgroundColor: AppColors.surface,
              selectedColor: AppColors.primary.withOpacity(0.25),
              side: BorderSide(
                color: selecionado ? AppColors.primary : AppColors.border,
              ),
              labelStyle: TextStyle(
                color: selecionado ? AppColors.textPrimary : AppColors.textSecondary,
                fontWeight: selecionado ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _resumoPrincipal(ResumoPeriodo resumo) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary.withOpacity(0.18), AppColors.surface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Lucro líquido do período',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 6),
          Text(
            Formatters.moeda(resumo.lucroLiquido),
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 30,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${Formatters.percentual(resumo.percentualLucro)} de margem',
            style: const TextStyle(
              color: AppColors.lucro,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _graficoEvolucao(List<({DateTime dia, double lucro})> serie) {
    if (serie.isEmpty) {
      return _placeholderGrafico('Sem dados suficientes no período');
    }

    // Transforma o lucro diário em lucro acumulado (soma progressiva) —
    // é isso que mostra visualmente a tendência de crescimento/queda.
    double acumulado = 0;
    final pontos = <FlSpot>[];
    for (int i = 0; i < serie.length; i++) {
      acumulado += serie[i].lucro;
      pontos.add(FlSpot(i.toDouble(), acumulado));
    }

    final valores = pontos.map((p) => p.y);
    final minY = valores.reduce((a, b) => a < b ? a : b);
    final maxY = valores.reduce((a, b) => a > b ? a : b);
    final corLinha = acumulado >= 0 ? AppColors.lucro : AppColors.despesa;

    return Container(
      height: 200,
      padding: const EdgeInsets.fromLTRB(12, 20, 20, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: LineChart(
        LineChartData(
          minY: minY == maxY ? minY - 10 : minY - (maxY - minY) * 0.1,
          maxY: minY == maxY ? maxY + 10 : maxY + (maxY - minY) * 0.1,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: const FlTitlesData(
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: pontos,
              isCurved: true,
              color: corLinha,
              barWidth: 3,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(show: true, color: corLinha.withOpacity(0.1)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _graficoHistoricoMensal(List<({String mes, double lucro})> historico) {
    if (historico.isEmpty) {
      return _placeholderGrafico('Sem dados suficientes');
    }

    final maiorAbsoluto = historico
        .map((h) => h.lucro.abs())
        .fold<double>(0, (a, b) => a > b ? a : b);

    return Container(
      height: 200,
      padding: const EdgeInsets.fromLTRB(12, 20, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: BarChart(
        BarChartData(
          minY: maiorAbsoluto == 0 ? -10 : -maiorAbsoluto * 1.2,
          maxY: maiorAbsoluto == 0 ? 10 : maiorAbsoluto * 1.2,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final indice = value.toInt();
                  if (indice < 0 || indice >= historico.length) return const SizedBox();
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      historico[indice].mes,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: [
            for (int i = 0; i < historico.length; i++)
              BarChartGroupData(x: i, barRods: [
                BarChartRodData(
                  toY: historico[i].lucro,
                  color: historico[i].lucro >= 0 ? AppColors.lucro : AppColors.despesa,
                  width: 22,
                  borderRadius: BorderRadius.circular(6),
                ),
              ]),
          ],
        ),
      ),
    );
  }

  Widget _placeholderGrafico(String mensagem) {
    return Container(
      height: 140,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(mensagem, style: const TextStyle(color: AppColors.textSecondary)),
    );
  }

  Widget _graficoBarras(ResumoPeriodo resumo) {
    final maxY = [resumo.receitaTotal, resumo.despesaTotal].reduce((a, b) => a > b ? a : b);

    return Container(
      height: 200,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: BarChart(
        BarChartData(
          maxY: maxY == 0 ? 10 : maxY * 1.2,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final texto = value == 0 ? 'Receita' : 'Despesa';
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      texto,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: [
            BarChartGroupData(x: 0, barRods: [
              BarChartRodData(
                toY: resumo.receitaTotal,
                color: AppColors.receita,
                width: 42,
                borderRadius: BorderRadius.circular(8),
              ),
            ]),
            BarChartGroupData(x: 1, barRods: [
              BarChartRodData(
                toY: resumo.despesaTotal,
                color: AppColors.despesa,
                width: 42,
                borderRadius: BorderRadius.circular(8),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _graficoPizza(ResumoPeriodo resumo) {
    if (resumo.despesasPorCategoria.isEmpty) {
      return Container(
        height: 140,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: const Text(
          'Nenhuma despesa no período',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    final categorias = resumo.despesasPorCategoria.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = resumo.despesaTotal;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 180,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 42,
                sections: [
                  for (int i = 0; i < categorias.length; i++)
                    PieChartSectionData(
                      value: categorias[i].value,
                      color: AppColors.pieCategoryColors[i % AppColors.pieCategoryColors.length],
                      title: total > 0
                          ? '${(categorias[i].value / total * 100).toStringAsFixed(0)}%'
                          : '',
                      titleStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                      radius: 54,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(categorias.length, (i) {
            final entry = categorias[i];
            final cor = AppColors.pieCategoryColors[i % AppColors.pieCategoryColors.length];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(color: cor, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      entry.key,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                    ),
                  ),
                  Text(
                    Formatters.moeda(entry.value),
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _gradeIndicadores(ResumoPeriodo resumo) {
    final indicadores = <({String titulo, String valor, IconData icone, Color cor, Color fundo})>[
      (
        titulo: 'Receita total',
        valor: Formatters.moeda(resumo.receitaTotal),
        icone: Icons.trending_up_rounded,
        cor: AppColors.receita,
        fundo: AppColors.receitaSoft,
      ),
      (
        titulo: 'Despesa total',
        valor: Formatters.moeda(resumo.despesaTotal),
        icone: Icons.trending_down_rounded,
        cor: AppColors.despesa,
        fundo: AppColors.despesaSoft,
      ),
      (
        titulo: 'Lucro líquido',
        valor: Formatters.moeda(resumo.lucroLiquido),
        icone: Icons.savings_rounded,
        cor: AppColors.lucro,
        fundo: AppColors.lucroSoft,
      ),
      (
        titulo: 'Km rodados',
        valor: Formatters.km(resumo.kmRodados),
        icone: Icons.route_rounded,
        cor: AppColors.alerta,
        fundo: AppColors.surfaceElevated,
      ),
      (
        titulo: 'Receita por Km',
        valor: Formatters.moeda(resumo.receitaPorKm),
        icone: Icons.speed_rounded,
        cor: AppColors.receita,
        fundo: AppColors.receitaSoft,
      ),
      (
        titulo: 'Lucro por Km',
        valor: Formatters.moeda(resumo.lucroPorKm),
        icone: Icons.bolt_rounded,
        cor: AppColors.lucro,
        fundo: AppColors.lucroSoft,
      ),
      (
        titulo: 'Despesa por Km',
        valor: Formatters.moeda(resumo.despesaPorKm),
        icone: Icons.local_gas_station_rounded,
        cor: AppColors.despesa,
        fundo: AppColors.despesaSoft,
      ),
      (
        titulo: 'Custo operacional',
        valor: Formatters.moeda(resumo.despesaTotal),
        icone: Icons.build_circle_rounded,
        cor: AppColors.despesa,
        fundo: AppColors.despesaSoft,
      ),
      (
        titulo: '% de lucro',
        valor: Formatters.percentual(resumo.percentualLucro),
        icone: Icons.percent_rounded,
        cor: AppColors.lucro,
        fundo: AppColors.lucroSoft,
      ),
      (
        titulo: '% de despesa',
        valor: Formatters.percentual(resumo.percentualDespesa),
        icone: Icons.percent_rounded,
        cor: AppColors.despesa,
        fundo: AppColors.despesaSoft,
      ),
      (
        titulo: 'Qtd. de receitas',
        valor: '${resumo.quantidadeReceitas}',
        icone: Icons.receipt_rounded,
        cor: AppColors.receita,
        fundo: AppColors.receitaSoft,
      ),
      (
        titulo: 'Qtd. de despesas',
        valor: '${resumo.quantidadeDespesas}',
        icone: Icons.receipt_long_rounded,
        cor: AppColors.despesa,
        fundo: AppColors.despesaSoft,
      ),
      (
        titulo: 'Maior receita diária',
        valor: Formatters.moeda(resumo.maiorReceitaDiaria),
        icone: Icons.emoji_events_rounded,
        cor: AppColors.receita,
        fundo: AppColors.receitaSoft,
      ),
      (
        titulo: 'Maior despesa',
        valor: Formatters.moeda(resumo.maiorDespesa),
        icone: Icons.priority_high_rounded,
        cor: AppColors.despesa,
        fundo: AppColors.despesaSoft,
      ),
      (
        titulo: 'Melhor dia',
        valor: resumo.melhorDia != null ? Formatters.data(resumo.melhorDia!) : '—',
        icone: Icons.star_rounded,
        cor: AppColors.receita,
        fundo: AppColors.receitaSoft,
      ),
      (
        titulo: 'Pior dia',
        valor: resumo.piorDia != null ? Formatters.data(resumo.piorDia!) : '—',
        icone: Icons.trending_down_rounded,
        cor: AppColors.despesa,
        fundo: AppColors.despesaSoft,
      ),
      (
        titulo: 'Média diária de lucro',
        valor: Formatters.moeda(resumo.mediaDiariaLucro),
        icone: Icons.calendar_view_day_rounded,
        cor: AppColors.lucro,
        fundo: AppColors.lucroSoft,
      ),
      (
        titulo: 'Média semanal de lucro',
        valor: Formatters.moeda(resumo.mediaSemanalLucro),
        icone: Icons.calendar_view_week_rounded,
        cor: AppColors.lucro,
        fundo: AppColors.lucroSoft,
      ),
      (
        titulo: 'Média mensal de lucro',
        valor: Formatters.moeda(resumo.mediaMensalLucro),
        icone: Icons.calendar_month_rounded,
        cor: AppColors.lucro,
        fundo: AppColors.lucroSoft,
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.35,
      children: indicadores.map((item) {
        return IndicadorCard(
          titulo: item.titulo,
          valor: item.valor,
          icone: item.icone,
          cor: item.cor,
          corFundo: item.fundo,
        );
      }).toList(),
    );
  }
}

class _TituloSecao extends StatelessWidget {
  final String texto;
  const _TituloSecao(this.texto);

  @override
  Widget build(BuildContext context) {
    return Text(
      texto,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
