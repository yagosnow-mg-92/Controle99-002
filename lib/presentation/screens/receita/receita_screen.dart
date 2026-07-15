import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/receita.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/receita_provider.dart';

class ReceitaScreen extends StatefulWidget {
  const ReceitaScreen({super.key});

  @override
  State<ReceitaScreen> createState() => _ReceitaScreenState();
}

class _ReceitaScreenState extends State<ReceitaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _kmController = TextEditingController();
  final _valorController = TextEditingController();
  final _observacaoController = TextEditingController();
  final _kmFocusNode = FocusNode();

  DateTime _dataSelecionada = DateTime.now();
  double _valorPorKmPreview = 0;
  String _buscaTexto = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReceitaProvider>().carregar();
    });
    _kmController.addListener(_atualizarPreview);
    _valorController.addListener(_atualizarPreview);
  }

  @override
  void dispose() {
    _kmController.dispose();
    _valorController.dispose();
    _observacaoController.dispose();
    _kmFocusNode.dispose();
    super.dispose();
  }

  void _atualizarPreview() {
    final km = double.tryParse(_kmController.text.replaceAll(',', '.')) ?? 0;
    final valor = double.tryParse(_valorController.text.replaceAll(',', '.')) ?? 0;
    setState(() {
      _valorPorKmPreview = km > 0 ? valor / km : 0;
    });
  }

  Future<void> _selecionarData() async {
    final hoje = DateTime.now();
    final resultado = await showDatePicker(
      context: context,
      initialDate: _dataSelecionada,
      firstDate: DateTime(2020),
      lastDate: DateTime(hoje.year, hoje.month, hoje.day),
      locale: const Locale('pt', 'BR'),
    );
    if (resultado != null) {
      setState(() => _dataSelecionada = resultado);
    }
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    final km = double.parse(_kmController.text.replaceAll(',', '.'));
    final valor = double.parse(_valorController.text.replaceAll(',', '.'));

    await context.read<ReceitaProvider>().salvar(
          data: _dataSelecionada,
          kmRodados: km,
          valorRecebido: valor,
          observacao: _observacaoController.text,
        );

    // Mantém os providers em sincronia: assim que uma receita é salva,
    // o Dashboard recalcula seus indicadores automaticamente.
    if (mounted) {
      await context.read<DashboardProvider>().carregar();
    }

    if (!mounted) return;

    _kmController.clear();
    _valorController.clear();
    _observacaoController.clear();
    setState(() => _valorPorKmPreview = 0);
    // A data NÃO é resetada de propósito: ao lançar vários dias
    // retroativos seguidos, o usuário espera continuar no mesmo dia
    // até trocar manualmente. O foco volta para o primeiro campo (Km),
    // agilizando o próximo lançamento.
    FocusScope.of(context).requestFocus(_kmFocusNode);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Receita lançada com sucesso'),
        backgroundColor: AppColors.receita,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lançar receita')),
      body: SafeArea(
        child: Consumer<ReceitaProvider>(
          builder: (context, provider, _) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                _formulario(provider),
                const SizedBox(height: 28),
                const Text(
                  'Lançamentos recentes',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                _campoBusca(),
                const SizedBox(height: 12),
                _listaLancamentos(provider),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _formulario(ReceitaProvider provider) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _campoData(),
            const SizedBox(height: 14),
            TextFormField(
              controller: _kmController,
              focusNode: _kmFocusNode,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Quilômetros rodados',
                labelStyle: TextStyle(color: AppColors.textSecondary),
                suffixText: 'km',
              ),
              validator: (valor) {
                final numero = double.tryParse((valor ?? '').replaceAll(',', '.'));
                if (numero == null || numero <= 0) return 'Informe um valor de km válido';
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _valorController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Valor recebido',
                labelStyle: TextStyle(color: AppColors.textSecondary),
                prefixText: 'R\$ ',
              ),
              validator: (valor) {
                final numero = double.tryParse((valor ?? '').replaceAll(',', '.'));
                if (numero == null || numero <= 0) return 'Informe um valor recebido válido';
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _observacaoController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Observação (opcional)',
                labelStyle: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(height: 16),
            _previewValorPorKm(),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: provider.salvando ? null : _salvar,
                child: provider.salvando
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Salvar receita'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _campoData() {
    return InkWell(
      onTap: _selecionarData,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.textSecondary),
            const SizedBox(width: 12),
            Text(
              Formatters.data(_dataSelecionada),
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }

  Widget _previewValorPorKm() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.receitaSoft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Valor por Km',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          Text(
            Formatters.moeda(_valorPorKmPreview),
            style: const TextStyle(
              color: AppColors.receita,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _confirmarExclusao(Receita receita) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Excluir lançamento?',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          'Receita de ${Formatters.moeda(receita.valorRecebido)} do dia ${Formatters.data(receita.data)} será excluída permanentemente.',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Excluir', style: TextStyle(color: AppColors.despesa)),
          ),
        ],
      ),
    );
    return confirmado ?? false;
  }

  Widget _campoBusca() {
    return TextField(
      onChanged: (texto) => setState(() => _buscaTexto = texto),
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: const InputDecoration(
        hintText: 'Buscar por valor, km ou observação...',
        hintStyle: TextStyle(color: AppColors.textDisabled),
        prefixIcon: Icon(Icons.search_rounded, color: AppColors.textSecondary),
      ),
    );
  }

  Widget _listaLancamentos(ReceitaProvider provider) {
    if (provider.carregando) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    final busca = _buscaTexto.trim().toLowerCase();
    final lancamentosFiltrados = busca.isEmpty
        ? provider.lancamentos
        : provider.lancamentos.where((r) {
            return r.valorRecebido.toString().contains(busca) ||
                r.kmRodados.toString().contains(busca) ||
                (r.observacao ?? '').toLowerCase().contains(busca);
          }).toList();

    if (lancamentosFiltrados.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          busca.isEmpty ? 'Nenhuma receita lançada ainda' : 'Nenhum resultado para "$_buscaTexto"',
          style: const TextStyle(color: AppColors.textSecondary),
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
        children: lancamentosFiltrados.map((r) {
          return Dismissible(
            key: ValueKey(r.id),
            direction: DismissDirection.endToStart,
            confirmDismiss: (_) => _confirmarExclusao(r),
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              decoration: BoxDecoration(
                color: AppColors.despesa.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.delete_outline_rounded, color: AppColors.despesa),
            ),
            onDismissed: (_) async {
              await context.read<ReceitaProvider>().excluir(r.id);
              if (context.mounted) {
                await context.read<DashboardProvider>().carregar();
              }
            },
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppColors.receitaSoft,
                child: Icon(Icons.arrow_upward_rounded, color: AppColors.receita, size: 18),
              ),
              title: Text(
                Formatters.moeda(r.valorRecebido),
                style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                '${Formatters.data(r.data)} · ${Formatters.km(r.kmRodados)} · ${Formatters.moeda(r.valorPorKm)}/km',
                style: const TextStyle(color: AppColors.textDisabled, fontSize: 12),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
