import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../providers/configuracoes_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../widgets/indicador_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().carregar();
      context.read<ConfiguracoesProvider>().carregar();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Consumer<DashboardProvider>(
          builder: (context, provider, _) {
            if (provider.carregando) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }

            return RefreshIndicator(
              color: AppColors.primary,
              backgroundColor: AppColors.surface,
              onRefresh: provider.carregar,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  _Cabecalho(),
                  const SizedBox(height: 20),
                  _CardsPrincipais(provider: provider),
                  const SizedBox(height: 16),
                  const _MetaDiaria(),
                  const SizedBox(height: 24),
                  const _TituloSecao('Últimos 7 dias'),
                  const SizedBox(height: 12),
                  _GraficoDesempenho(provider: provider),
                  const SizedBox(height: 24),
                  const _TituloSecao('Últimos lançamentos'),
                  const SizedBox(height: 12),
                  _ListaUltimosLancamentos(provider: provider),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Cabecalho extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final agora = DateTime.now();
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              Formatters.dataExtenso(agora),
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 2),
            const Text(
              'Seu painel de hoje',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: const Icon(Icons.two_wheeler_rounded, color: AppColors.primary),
        ),
      ],
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

class _CardsPrincipais extends StatelessWidget {
  final DashboardProvider provider;
  const _CardsPrincipais({required this.provider});

  @override
  Widget build(BuildContext context) {
    final resumo = provider.resumoHoje;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.35,
      children: [
        IndicadorCard(
          titulo: 'Receita do dia',
          valor: Formatters.moeda(resumo.receitaTotal),
          icone: Icons.trending_up_rounded,
          cor: AppColors.receita,
          corFundo: AppColors.receitaSoft,
        ),
        IndicadorCard(
          titulo: 'Despesa do dia',
          valor: Formatters.moeda(resumo.despesaTotal),
          icone: Icons.trending_down_rounded,
          cor: AppColors.despesa,
          corFundo: AppColors.despesaSoft,
        ),
        IndicadorCard(
          titulo: 'Lucro do dia',
          valor: Formatters.moeda(resumo.lucroLiquido),
          icone: Icons.savings_rounded,
          cor: AppColors.lucro,
          corFundo: AppColors.lucroSoft,
          subtitulo: Formatters.percentual(resumo.percentualLucro),
        ),
        IndicadorCard(
          titulo: 'Km rodados',
          valor: Formatters.km(resumo.kmRodados),
          icone: Icons.route_rounded,
          cor: AppColors.alerta,
          corFundo: AppColors.surfaceElevated,
        ),
        IndicadorCard(
          titulo: 'Ganho por Km',
          valor: Formatters.moeda(resumo.receitaPorKm),
          icone: Icons.speed_rounded,
          cor: AppColors.receita,
          corFundo: AppColors.receitaSoft,
        ),
        IndicadorCard(
          titulo: 'Lucro por Km',
          valor: Formatters.moeda(resumo.lucroPorKm),
          icone: Icons.bolt_rounded,
          cor: AppColors.lucro,
          corFundo: AppColors.lucroSoft,
        ),
      ],
    );
  }
}

class _GraficoDesempenho extends StatelessWidget {
  final DashboardProvider provider;
  const _GraficoDesempenho({required this.provider});

  @override
  Widget build(BuildContext context) {
    final dias = provider.ultimos7Dias;

    if (dias.isEmpty || dias.every((d) => d.receitaTotal == 0 && d.despesaTotal == 0)) {
      return _EstadoVazioGrafico();
    }

    final maxY = dias
        .map((d) => d.receitaTotal > d.despesaTotal ? d.receitaTotal : d.despesaTotal)
        .fold<double>(0, (a, b) => a > b ? a : b);

    return Container(
      height: 220,
      padding: const EdgeInsets.fromLTRB(12, 20, 20, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: maxY == 0 ? 10 : maxY * 1.2,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: const FlTitlesData(
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          lineBarsData: [
            _linha(dias.map((d) => d.receitaTotal).toList(), AppColors.receita),
            _linha(dias.map((d) => d.lucroLiquido).toList(), AppColors.lucro),
          ],
        ),
      ),
    );
  }

  LineChartBarData _linha(List<double> valores, Color cor) {
    return LineChartBarData(
      spots: [
        for (int i = 0; i < valores.length; i++) FlSpot(i.toDouble(), valores[i]),
      ],
      isCurved: true,
      color: cor,
      barWidth: 3,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(show: true, color: cor.withOpacity(0.08)),
    );
  }
}

class _MetaDiaria extends StatelessWidget {
  const _MetaDiaria();

  @override
  Widget build(BuildContext context) {
    return Consumer2<ConfiguracoesProvider, DashboardProvider>(
      builder: (context, configProvider, dashboardProvider, _) {
        final meta = configProvider.configuracoes.metaDiaria;
        if (meta <= 0) return const SizedBox.shrink();

        final receita = dashboardProvider.resumoHoje.receitaTotal;
        final progresso = (receita / meta).clamp(0.0, 1.0);
        final falta = (meta - receita).clamp(0, double.infinity);
        final atingiu = receita >= meta;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Meta diária',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '${Formatters.moeda(receita)} / ${Formatters.moeda(meta)}',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progresso,
                  minHeight: 8,
                  backgroundColor: AppColors.surfaceElevated,
                  color: atingiu ? AppColors.receita : AppColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                atingiu
                    ? 'Meta batida! 🎉'
                    : 'Faltam ${Formatters.moeda(falta.toDouble())} para bater a meta',
                style: TextStyle(
                  color: atingiu ? AppColors.receita : AppColors.textDisabled,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _EstadoVazioGrafico extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: const Text(
        'Registre seus ganhos para ver o gráfico aqui',
        style: TextStyle(color: AppColors.textSecondary),
      ),
    );
  }
}

class _ListaUltimosLancamentos extends StatelessWidget {
  final DashboardProvider provider;
  const _ListaUltimosLancamentos({required this.provider});

  @override
  Widget build(BuildContext context) {
    final itens = [
      ...provider.ultimasReceitas.map((r) => (
            data: r.data,
            titulo: 'Receita',
            valor: r.valorRecebido,
            positivo: true,
          )),
      ...provider.ultimasDespesas.map((d) => (
            data: d.data,
            titulo: d.categoria,
            valor: d.valor,
            positivo: false,
          )),
    ]..sort((a, b) => b.data.compareTo(a.data));

    if (itens.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: const Text(
          'Nenhum lançamento ainda',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: itens.take(6).map((item) {
          return ListTile(
            leading: CircleAvatar(
              backgroundColor:
                  item.positivo ? AppColors.receitaSoft : AppColors.despesaSoft,
              child: Icon(
                item.positivo ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                color: item.positivo ? AppColors.receita : AppColors.despesa,
                size: 18,
              ),
            ),
            title: Text(item.titulo, style: const TextStyle(color: AppColors.textPrimary)),
            subtitle: Text(
              Formatters.data(item.data),
              style: const TextStyle(color: AppColors.textDisabled, fontSize: 12),
            ),
            trailing: Text(
              '${item.positivo ? '+' : '-'} ${Formatters.moeda(item.valor)}',
              style: TextStyle(
                color: item.positivo ? AppColors.receita : AppColors.despesa,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
