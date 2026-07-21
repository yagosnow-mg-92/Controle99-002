import 'package:flutter/foundation.dart';

import '../../domain/entities/receita.dart';
import '../../domain/repositories/receita_repository.dart';

/// Estado da tela de Receita: lista de lançamentos recentes e operações
/// de salvar/excluir. Quem quiser reagir a mudanças de receita (ex: o
/// Dashboard) deve chamar seu próprio `carregar()` depois de um `salvar()`
/// bem-sucedido aqui — mantendo cada provider responsável só pelo seu escopo.
class ReceitaProvider extends ChangeNotifier {
  final ReceitaRepository _repository;

  ReceitaProvider({required ReceitaRepository repository}) : _repository = repository;

  bool carregando = true;
  bool salvando = false;
  List<Receita> lancamentos = [];

  Future<void> carregar() async {
    carregando = true;
    notifyListeners();

    lancamentos = await _repository.listar();

    carregando = false;
    notifyListeners();
  }

  Future<void> salvar({
    required DateTime data,
    required double kmRodados,
    required double valorRecebido,
    String? observacao,
    String? localEmbarque,
    String? localDestino,
  }) async {
    salvando = true;
    notifyListeners();

    final receita = Receita(
      id: '',
      data: data,
      kmRodados: kmRodados,
      valorRecebido: valorRecebido,
      observacao: (observacao == null || observacao.trim().isEmpty) ? null : observacao.trim(),
      criadoEm: DateTime.now(),
      localEmbarque: (localEmbarque == null || localEmbarque.trim().isEmpty)
          ? null
          : localEmbarque.trim(),
      localDestino: (localDestino == null || localDestino.trim().isEmpty)
          ? null
          : localDestino.trim(),
    );

    await _repository.salvar(receita);
    await carregar();

    salvando = false;
    notifyListeners();
  }

  Future<void> excluir(String id) async {
    await _repository.excluir(id);
    await carregar();
  }
}
