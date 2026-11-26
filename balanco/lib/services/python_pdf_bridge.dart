import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/lancamento_item.dart';

/// Ponte de integração entre o Flutter Desktop e o Motor Python de PDF
class PythonPdfBridge {
  static const String localServerUrl = 'http://127.0.0.1:8000';

  /// Gera o PDF do relatório A4 acionando o Motor Python
  /// Tenta primeiro via CLI subprocess e, como fallback, via servidor HTTP FastAPI local
  static Future<File> generateReportPdf({
    required String titulo,
    required String entidadeNome,
    required String cnpj,
    required List<LancamentoItem> items,
    String? outputFilePath,
  }) async {
    final payload = {
      'titulo': titulo,
      'entidade_nome': entidadeNome,
      'cnpj': cnpj,
      'data_emissao': DateTime.now().toIso8601String(),
      'itens': items.map((i) => {
        'id': i.id,
        'plaqueta': i.plaquetaCodigo,
        'produto': i.produtoNome ?? 'Item #${i.id}',
        'setor': i.setorNome ?? '-',
        'entidade': i.entidadeNome ?? entidadeNome,
        'quantidade': i.quantidade,
        'conservacao': i.estadoConservacao,
        'observacao': i.observacao,
        'data': i.dataLancamento,
        'foto_path': i.fotoPath,
      }).toList(),
    };

    final docDir = await getApplicationDocumentsDirectory();
    final jsonFile = File(p.join(docDir.path, 'report_payload_${DateTime.now().millisecondsSinceEpoch}.json'));
    await jsonFile.writeAsString(jsonEncode(payload));

    final targetPdfPath = outputFilePath ??
        p.join(docDir.path, 'relatorio_balanco_${DateTime.now().millisecondsSinceEpoch}.pdf');

    // 1. Tenta acionar via subprocesso CLI (método mais simples e sem dependência de porta)
    try {
      final cliResult = await Process.run(
        'python',
        [
          '-m',
          'PC.pdf_engine.generate_pdf',
          '--input',
          jsonFile.path,
          '--output',
          targetPdfPath,
        ],
        workingDirectory: 'D:/app_balanco',
      );

      if (cliResult.exitCode == 0 && File(targetPdfPath).existsSync()) {
        return File(targetPdfPath);
      }
    } catch (_) {}

    // 2. Fallback: Tenta acionar o servidor HTTP FastAPI local
    try {
      final response = await http.post(
        Uri.parse('$localServerUrl/generate-pdf'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final pdfFile = File(targetPdfPath);
        await pdfFile.writeAsBytes(response.bodyBytes);
        return pdfFile;
      }
    } catch (_) {}

    // 3. Fallback adicional de execução direta do script generate_pdf.py
    final directScript = 'D:/app_balanco/PC/pdf_engine/generate_pdf.py';
    final fallbackRun = await Process.run(
      'python',
      [directScript, '--input', jsonFile.path, '--output', targetPdfPath],
    );

    if (File(targetPdfPath).existsSync()) {
      return File(targetPdfPath);
    }

    throw Exception('Falha ao acionar o motor Python de PDF: ${fallbackRun.stderr}');
  }
}
