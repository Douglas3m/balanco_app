import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class DesktopHeader extends StatelessWidget {
  final ValueChanged<String>? onSearchChanged;

  const DesktopHeader({super.key, this.onSearchChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: BalancoColors.border)),
      ),
      child: Row(
        children: [
          // Campo de Busca Rápida (Ctrl+K)
          Expanded(
            child: Container(
              height: 40,
              constraints: const BoxConstraints(maxWidth: 420),
              child: TextField(
                onChanged: onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Buscar lote, tombamento, produto ou setor...',
                  hintStyle: const TextStyle(fontSize: 13, color: BalancoColors.textSecondary),
                  prefixIcon: const Icon(Icons.search, size: 18),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                  filled: true,
                  fillColor: BalancoColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: BalancoColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: BalancoColors.border),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),

          // Status do SQLite Local
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: BalancoColors.containerLow,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              children: [
                Icon(Icons.check_circle, size: 14, color: BalancoColors.success),
                SizedBox(width: 6),
                Text('SQLite Local: Conectado', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: BalancoColors.primary)),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // Perfil do Auditor
          const CircleAvatar(
            backgroundColor: BalancoColors.primary,
            child: Icon(Icons.person, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Auditor Fiscal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              Text('Operação Desktop', style: TextStyle(color: BalancoColors.textSecondary, fontSize: 11)),
            ],
          )
        ],
      ),
    );
  }
}
