import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Placeholder — implementado na próxima etapa do desenvolvimento.
class ConfiguracoesScreen extends StatelessWidget {
  const ConfiguracoesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: const Center(
        child: Text(
          'Tela de Configurações — em construção',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      ),
    );
  }
}
