import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Placeholder — implementado na próxima etapa do desenvolvimento.
class IndicadoresScreen extends StatelessWidget {
  const IndicadoresScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Indicadores')),
      body: const Center(
        child: Text(
          'Tela de Indicadores — em construção',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      ),
    );
  }
}
