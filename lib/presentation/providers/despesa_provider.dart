import 'package:flutter/foundation.dart';

import '../../domain/entities/despesa.dart';
import '../../domain/repositories/despesa_repository.dart';

/// Estado da tela de Despesas: lista de lançamentos, categorias
/// reutilizáveis e operações de salvar/excluir.
class DespesaProvider extends ChangeNotifier {
  final DespesaRepository _repository;

  DespesaProvider({required DespesaRepository repository}) : _repository = repository;

  bool carregando = true;
  bool salvando = false;
  List<Despesa> lancamentos = [];
  List<String> categorias = [];

  Future<void> carregar() async {
    carregando = true;
    notifyListeners();

    lancamentos = await _repository.listar();
    categorias = await _repository.listarCategorias();

    carregando = false;
    notifyListeners();
  }

  Future<void> salvar({
    required DateTime data,
    required String categoria,
    required double valor,
    String? observacao,
  }) async {
    salvando = true;
    notifyListeners();

    final despesa = Despesa(
      id: '',
      data: data,
      categoria: categoria.trim(),
      valor: valor,
      observacao: (observacao == null || observacao.trim().isEmpty) ? null : observacao.trim(),
      criadoEm: DateTime.now(),
    );

    await _repository.salvar(despesa);
    await carregar();

    salvando = false;
    notifyListeners();
  }

  Future<void> excluir(String id) async {
    await _repository.excluir(id);
    await carregar();
  }
}
