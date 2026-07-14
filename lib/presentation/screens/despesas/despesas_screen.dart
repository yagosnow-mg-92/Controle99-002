import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Placeholder — implementado na próxima etapa do desenvolvimento.
class DespesasScreen extends StatelessWidget {
  const DespesasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Despesas')),
      body: const Center(
        child: Text(
          'Tela de Despesas — em construção',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      ),
    );
  }
}
