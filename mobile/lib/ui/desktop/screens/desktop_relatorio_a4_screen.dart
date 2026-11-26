import 'dart:io';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/lancamento_item.dart';
import '../../../repositories/lancamento_repository.dart';
import '../../../services/pdf_report_service.dart';
import '../../../services/python_pdf_bridge.dart';

class DesktopRelatorioA4Screen extends StatefulWidget {
  const DesktopRelatorioA4Screen({super.key});

  @override
  State<DesktopRelatorioA4Screen> createState() => _DesktopRelatorioA4ScreenState();
}

class _DesktopRelatorioA4ScreenState extends State<DesktopRelatorioA4Screen> {
  final _repo = LancamentoRepository();
  List<LancamentoItem> _itens = [];
  bool _loading = true;
  bool _gerandoPython = false;
  String? _statusPython;
  String? _caminhoPdfGerado;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _loading = true);
    final res = await _repo.getCompletos();
    if (mounted) {
      setState(() {
        _itens = res;
        _loading = false;
      });
    }
  }

  Future<void> _gerarPdfMotorPython() async {
    setState(() {
      _gerandoPython = true;
      _statusPython = 'Acionando Motor Python (Jinja2 + Playwright/Chromium A4)...';
    });

    try {
      final pdf = await PythonPdfBridge.generateReportPdf(
        titulo: 'RELATÓRIO AUDITADO DE CATALOGAÇÃO E TOMBAMENTO PATRIMONIAL',
        entidadeNome: _itens.isNotEmpty ? (_itens.first.entidadeNome ?? 'Prefeitura Municipal') : 'Prefeitura Municipal',
        cnpj: '14.283.910/0001-44',
        items: _itens,
      );

      setState(() {
        _gerandoPython = false;
        _caminhoPdfGerado = pdf.path;
        _statusPython = 'PDF A4 gerado com sucesso pelo Motor Python em:\n${pdf.path}';
      });

      // Abre o PDF gerado diretamente no visualizador nativo do sistema
      if (Platform.isWindows) {
        Process.run('cmd', ['/c', 'start', '', pdf.path]);
      }
    } catch (e) {
      setState(() {
        _gerandoPython = false;
        _statusPython = 'Erro no Motor Python: $e';
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
            // Cabeçalho da Tela
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Emissão & Impressão de Relatório A4', style: TextStyle(fontFamily: 'Outfit', fontSize: 22, fontWeight: FontWeight.bold, color: BalancoColors.primary)),
                    Text('Layout Pericial A4 em conformidade com Google Stitch e Norma NBR 14653.', style: TextStyle(color: BalancoColors.textSecondary, fontSize: 13)),
                  ],
                ),
                Row(
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: BalancoColors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      ),
                      onPressed: _gerandoPython ? null : _gerarPdfMotorPython,
                      icon: const Icon(Icons.picture_as_pdf),
                      label: Text(_gerandoPython ? 'Gerando no Python...' : 'Gerar PDF (Motor Python)'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Barra de Especificações do Layout A4
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: BalancoColors.border),
              ),
              child: const Row(
                children: [
                  Icon(Icons.aspect_ratio, color: BalancoColors.primary, size: 20),
                  SizedBox(width: 8),
                  Text('Formato: <strong>A4 Retrato (210×297mm)</strong>', style: TextStyle(fontSize: 12)),
                  SizedBox(width: 20),
                  Icon(Icons.margin, color: BalancoColors.textSecondary, size: 20),
                  SizedBox(width: 8),
                  Text('Margens Auditáveis: <strong>15mm Simétricas</strong>', style: TextStyle(fontSize: 12)),
                  SizedBox(width: 20),
                  Icon(Icons.table_rows, color: BalancoColors.secondary, size: 20),
                  SizedBox(width: 8),
                  Text('Linhas: <strong>Zebradas de Alta Legibilidade</strong>', style: TextStyle(fontSize: 12)),
                  Spacer(),
                  Row(
                    children: [
                      Icon(Icons.verified, color: BalancoColors.success, size: 16),
                      SizedBox(width: 6),
                      Text('Tribunal de Contas Ready', style: TextStyle(color: BalancoColors.success, fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            if (_statusPython != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: BalancoColors.containerLow,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: BalancoColors.border),
                ),
                child: Text(_statusPython!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: BalancoColors.primary)),
              ),
              const SizedBox(height: 12),
            ],

            // Pré-visualização Vetorial A4 Realista
            Expanded(
              child: Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: BalancoColors.border)),
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : PdfPreview(
                        build: (format) => PdfReportService.generateA4Report(
                          titulo: 'Relatório Auditado de Catalogação e Tombamento Patrimonial',
                          entidadeNome: _itens.isNotEmpty ? (_itens.first.entidadeNome ?? 'Prefeitura Municipal') : 'Prefeitura Municipal',
                          items: _itens,
                        ),
                        initialPageFormat: PdfPageFormat.a4,
                        canChangePageFormat: false,
                        canChangeOrientation: false,
                        pdfFileName: 'relatorio_patrimonial_balanco_a4.pdf',
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
