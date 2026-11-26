import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../repositories/lancamento_repository.dart';
import '../../../services/sync_service.dart';

class DesktopExportarScreen extends StatefulWidget {
  const DesktopExportarScreen({super.key});

  @override
  State<DesktopExportarScreen> createState() => _DesktopExportarScreenState();
}

class _DesktopExportarScreenState extends State<DesktopExportarScreen> {
  final _repo = LancamentoRepository();
  bool _exportando = false;
  String? _status;

  Future<void> _exportar(String tipo) async {
    setState(() {
      _exportando = true;
      _status = null;
    });

    try {
      final itens = await _repo.getCompletos();
      String path = '';
      if (tipo == 'zip') {
        final f = await SyncService.exportFullZipPackage(itens);
        path = f.path;
      } else if (tipo == 'csv') {
        final f = await SyncService.exportToCsv(itens);
        path = f.path;
      } else if (tipo == 'db') {
        final f = await SyncService.exportDatabaseCopy();
        path = f.path;
      }

      setState(() {
        _exportando = false;
        _status = 'Exportação concluída com sucesso em:\n$path';
      });
    } catch (e) {
      setState(() {
        _exportando = false;
        _status = 'Erro na exportação: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BalancoColors.background,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Exportação e Backup do Sistema Desktop', style: TextStyle(fontFamily: 'Outfit', fontSize: 22, fontWeight: FontWeight.bold, color: BalancoColors.primary)),
            const Text('Gere backups relacionais em SQLite ou planilhas auditáveis para envio fiscal.', style: TextStyle(color: BalancoColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 24),

            Row(
              children: [
                _cardExport('Pacote .ZIP com Fotos', 'Gera arquivo compactado com fotos e dados.', Icons.folder_zip, BalancoColors.secondary, () => _exportar('zip')),
                const SizedBox(width: 16),
                _cardExport('Planilha .CSV', 'Planilha tabular RFC 4180 compatível com Excel.', Icons.table_chart, BalancoColors.success, () => _exportar('csv')),
                const SizedBox(width: 16),
                _cardExport('Backup SQLite (.DB)', 'Cópia física do arquivo de banco de dados.', Icons.storage, BalancoColors.primary, () => _exportar('db')),
              ],
            ),
            const SizedBox(height: 24),

            if (_exportando)
              const Center(child: CircularProgressIndicator())
            else if (_status != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: BalancoColors.containerLow,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: BalancoColors.border),
                ),
                child: Text(_status!, style: const TextStyle(fontWeight: FontWeight.bold, color: BalancoColors.primary)),
              )
          ],
        ),
      ),
    );
  }

  Widget _cardExport(String title, String desc, IconData icon, Color color, VoidCallback onTap) {
    return Expanded(
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: BalancoColors.border)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 14),
              Text(title, style: const TextStyle(fontFamily: 'Outfit', fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text(desc, style: const TextStyle(color: BalancoColors.textSecondary, fontSize: 12)),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: color),
                  onPressed: onTap,
                  child: const Text('Exportar'),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
