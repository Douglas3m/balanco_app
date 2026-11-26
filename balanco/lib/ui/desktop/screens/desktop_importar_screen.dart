import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../services/sync_service.dart';

class DesktopImportarScreen extends StatefulWidget {
  const DesktopImportarScreen({super.key});

  @override
  State<DesktopImportarScreen> createState() => _DesktopImportarScreenState();
}

class _DesktopImportarScreenState extends State<DesktopImportarScreen> {
  bool _processando = false;
  String? _resultadoStatus;
  bool _sucesso = false;

  Future<void> _selecionarEImportar() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'db', 'zip', 'sqlite'],
    );

    if (result != null && result.files.single.path != null) {
      final path = result.files.single.path!;
      setState(() {
        _processando = true;
        _resultadoStatus = 'Importando e validando transações ACID em: $path...';
      });

      try {
        int count = 0;
        if (path.endsWith('.csv')) {
          count = await SyncService.importFromCsv(path);
          setState(() {
            _sucesso = true;
            _resultadoStatus = 'Sucesso! $count lançamentos importados e sincronizados no SQLite a partir do arquivo CSV.';
          });
        } else if (path.endsWith('.zip')) {
          count = await SyncService.importFromZip(path);
          setState(() {
            _sucesso = true;
            _resultadoStatus = 'Sucesso! Pacote .ZIP importado com sucesso: $count registros e acervo de fotos extraídos!';
          });
        } else {
          setState(() {
            _sucesso = true;
            _resultadoStatus = 'Arquivo SQLite (.db) selecionado. Para substituir a base, utilize a ferramenta de restauração direta.';
          });
        }
      } catch (e) {
        setState(() {
          _sucesso = false;
          _resultadoStatus = 'Erro ao processar importação: $e';
        });
      } finally {
        setState(() => _processando = false);
      }
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
            const Text('Importação de Dados do Inventário Mobile', style: TextStyle(fontFamily: 'Outfit', fontSize: 22, fontWeight: FontWeight.bold, color: BalancoColors.primary)),
            const Text('Selecione arquivos exportados pelo aplicativo móvel (.zip com fotos, .csv ou .db).', style: TextStyle(color: BalancoColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 24),

            // Área de Seleção / Dropzone
            InkWell(
              onTap: _processando ? null : _selecionarEImportar,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                height: 220,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: BalancoColors.secondary, width: 2),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: BalancoColors.secondary.withOpacity(0.1), shape: BoxShape.circle),
                      child: const Icon(Icons.cloud_upload_outlined, size: 48, color: BalancoColors.secondary),
                    ),
                    const SizedBox(height: 14),
                    const Text('Clique para selecionar o arquivo exportado pelo celular', style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    const Text('Formatos aceitos: Pacote .ZIP (com fotos), Planilha .CSV ou Banco .DB', style: TextStyle(color: BalancoColors.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            if (_processando)
              const Center(child: CircularProgressIndicator())
            else if (_resultadoStatus != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _sucesso ? BalancoColors.successBg : BalancoColors.dangerBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _sucesso ? BalancoColors.success : BalancoColors.danger),
                ),
                child: Text(
                  _resultadoStatus!,
                  style: TextStyle(
                    color: _sucesso ? BalancoColors.success : BalancoColors.danger,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
          ],
        ),
      ),
    );
  }
}
