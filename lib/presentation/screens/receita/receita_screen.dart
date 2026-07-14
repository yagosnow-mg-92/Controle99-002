import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Placeholder — implementado na próxima etapa do desenvolvimento.
class ReceitaScreen extends StatelessWidget {
  const ReceitaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Receita')),
      body: const Center(
        child: Text(
          'Tela de Receita — em construção',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      ),
    );
  }
}
