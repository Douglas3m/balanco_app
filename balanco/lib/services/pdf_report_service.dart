import 'dart:io';
import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/lancamento_item.dart';

class PdfReportService {
  static Future<Uint8List> generateA4Report({
    required String titulo,
    required String entidadeNome,
    required List<LancamentoItem> items,
  }) async {
    final pdf = pw.Document();
    final totalQtd = items.fold<int>(0, (sum, i) => sum + i.quantidade);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(15 * PdfPageFormat.mm),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Row(
                  children: [
                    pw.Container(
                      width: 28,
                      height: 28,
                      decoration: const pw.BoxDecoration(
                        color: PdfColor.fromInt(0xFF1E3A8A),
                        borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
                      ),
                      child: pw.Center(
                        child: pw.Text('B', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                    pw.SizedBox(width: 8),
                    pw.Text('BALANÇO', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFF1E3A8A))),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(entidadeNome, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                    pw.Text('Emissão: ${DateFormat('dd/MM/yyyy às HH:mm').format(DateTime.now())}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 6),
            pw.Container(height: 2, color: const PdfColor.fromInt(0xFF1E3A8A)),
            pw.SizedBox(height: 8),
            pw.Center(
              child: pw.Text(titulo.toUpperCase(), style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
            ),
            pw.SizedBox(height: 10),
          ],
        ),
        footer: (context) => pw.Column(
          children: [
            pw.Divider(color: PdfColors.grey400),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Total de Itens: ${items.length} | Volume Físico Somado: $totalQtd un', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                pw.Text('Página ${context.pageNumber} de ${context.pagesCount}', style: const pw.TextStyle(fontSize: 9)),
              ],
            ),
          ],
        ),
        build: (context) => [
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            columnWidths: {
              0: const pw.FixedColumnWidth(40), // Foto 1:1
              1: const pw.FixedColumnWidth(65), // Plaqueta #PAT
              2: const pw.FlexColumnWidth(3),   // Descrição
              3: const pw.FlexColumnWidth(2),   // Setor
              4: const pw.FixedColumnWidth(40), // Qtd
              5: const pw.FixedColumnWidth(55), // Data
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF1E3A8A)),
                children: [
                  _headerCell('FOTO'),
                  _headerCell('PLAQUETA'),
                  _headerCell('PRODUTO / ESPECIFICAÇÃO'),
                  _headerCell('SETOR'),
                  _headerCell('QTD'),
                  _headerCell('DATA'),
                ],
              ),
              ...items.asMap().entries.map((entry) {
                final idx = entry.key;
                final item = entry.value;
                final isZebra = idx % 2 == 1;

                return pw.TableRow(
                  decoration: pw.BoxDecoration(
                    color: isZebra ? const PdfColor.fromInt(0xFFF8FAFC) : PdfColors.white,
                  ),
                  children: [
                    pw.Container(
                      height: 32,
                      padding: const pw.EdgeInsets.all(2),
                      alignment: pw.Alignment.center,
                      child: (item.fotoPath.isNotEmpty && File(item.fotoPath).existsSync())
                          ? pw.Image(pw.MemoryImage(File(item.fotoPath).readAsBytesSync()), fit: pw.BoxFit.cover)
                          : pw.Container(
                              width: 28,
                              height: 28,
                              color: PdfColors.grey200,
                              child: pw.Center(child: pw.Text('SEM FOTO', style: const pw.TextStyle(fontSize: 5))),
                            ),
                    ),
                    _bodyCell(item.plaquetaCodigo, bold: true),
                    _bodyCell(item.produtoNome ?? '-'),
                    _bodyCell(item.setorNome ?? '-'),
                    _bodyCell('${item.quantidade} un', align: pw.TextAlign.center, bold: true),
                    _bodyCell(item.dataLancamento.split(' ').first, align: pw.TextAlign.center),
                  ],
                );
              }),
            ],
          ),
        ],
      ),
    );

    return pdf.save();
  }

  static pw.Widget _headerCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: pw.Text(
        text,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(color: PdfColors.white, fontSize: 8, fontWeight: pw.FontWeight.bold),
      ),
    );
  }

  static pw.Widget _bodyCell(String text, {bool bold = false, pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(fontSize: 8, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal),
      ),
    );
  }
}
