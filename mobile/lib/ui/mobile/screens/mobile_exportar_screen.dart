import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../repositories/lancamento_repository.dart';
import '../../../services/sync_service.dart';

class MobileExportarScreen extends StatefulWidget {
  const MobileExportarScreen({super.key});

  @override
  State<MobileExportarScreen> createState() => _MobileExportarScreenState();
}

class _MobileExportarScreenState extends State<MobileExportarScreen> {
  final _repo = LancamentoRepository();
  bool _exportando = false;
  String? _mensagemStatus;

  Future<void> _exportarCsv() async {
    setState(() => _exportando = true);
    try {
      final itens = await _repo.getCompletos();
      final file = await SyncService.exportToCsv(itens);
      setState(() {
        _exportando = false;
        _mensagemStatus = 'Planilha .CSV exportada com sucesso:\n${file.path}';
      });
    } catch (e) {
      setState(() {
        _exportando = false;
        _mensagemStatus = 'Erro ao exportar CSV: $e';
      });
    }
  }

  Future<void> _exportarDb() async {
    setState(() => _exportando = true);
    try {
      final file = await SyncService.exportDatabaseCopy();
      setState(() {
        _exportando = false;
        _mensagemStatus = 'Backup .DB (SQLite) exportado com sucesso:\n${file.path}';
      });
    } catch (e) {
      setState(() {
        _exportando = false;
        _mensagemStatus = 'Erro ao exportar DB: $e';
      });
    }
  }

  Future<void> _exportarZipCompleto() async {
    setState(() => _exportando = true);
    try {
      final itens = await _repo.getCompletos();
      final zip = await SyncService.exportFullZipPackage(itens);
      setState(() {
        _exportando = false;
        _mensagemStatus = 'Pacote Completo (.ZIP com Fotos e Dados) gerado:\n${zip.path}';
      });
    } catch (e) {
      setState(() {
        _exportando = false;
        _mensagemStatus = 'Erro ao gerar ZIP: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exportação de Dados'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Selecione o formato para exportar os dados catalogados:', style: TextStyle(color: BalancoColors.textSecondary)),
          const SizedBox(height: 16),

          // 1. Pacote ZIP Completo com Fotos (Recomendado)
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: BalancoColors.secondary, width: 1.5),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: BalancoColors.secondary.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.folder_zip, color: BalancoColors.secondary, size: 28),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Pacote Completo (.ZIP com Fotos)', style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold, fontSize: 16)),
                            Text('Recomendado para o Desktop Balanço', style: TextStyle(color: BalancoColors.secondary, fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text('Gera um arquivo compacto contendo o banco SQLite, a planilha tabular e todas as fotos originais tiradas em campo.', style: TextStyle(color: BalancoColors.textSecondary, fontSize: 13)),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: BalancoColors.secondary),
                      onPressed: _exportando ? null : _exportarZipCompleto,
                      icon: const Icon(Icons.archive),
                      label: const Text('Exportar Pacote .ZIP Completo'),
                    ),
                  )
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // 2. Banco SQLite (.db)
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.all(14),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: BalancoColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.storage, color: BalancoColors.primary, size: 26),
              ),
              title: const Text('Snapshot SQLite (.db)', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Base relacional íntegra com tabelas e integridade ACID.'),
              trailing: OutlinedButton(
                onPressed: _exportando ? null : _exportarDb,
                child: const Text('Exportar .db'),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // 3. Planilha CSV (.csv)
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.all(14),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: BalancoColors.success.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.table_chart, color: BalancoColors.success, size: 26),
              ),
              title: const Text('Planilha Tabular (.csv)', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Colunas padronizadas com plaqueta, setor, produto e caminhos.'),
              trailing: OutlinedButton(
                onPressed: _exportando ? null : _exportarCsv,
                child: const Text('Exportar .csv'),
              ),
            ),
          ),
          const SizedBox(height: 24),

          if (_exportando)
            const Center(child: CircularProgressIndicator())
          else if (_mensagemStatus != null)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: BalancoColors.containerLow,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: BalancoColors.border),
              ),
              child: Text(
                _mensagemStatus!,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: BalancoColors.primary),
              ),
            ),
        ],
      ),
    );
  }
}
