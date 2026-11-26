import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/lancamento_item.dart';
import '../../../repositories/lancamento_repository.dart';

class DesktopCatalogacaoScreen extends StatefulWidget {
  const DesktopCatalogacaoScreen({super.key});

  @override
  State<DesktopCatalogacaoScreen> createState() => _DesktopCatalogacaoScreenState();
}

class _DesktopCatalogacaoScreenState extends State<DesktopCatalogacaoScreen> {
  final _repo = LancamentoRepository();
  List<LancamentoItem> _itens = [];
  bool _loading = true;
  String _filtroTexto = '';

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _loading = true);
    final res = await _repo.getCompletos(query: _filtroTexto);
    if (mounted) {
      setState(() {
        _itens = res;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalQtd = _itens.fold<int>(0, (sum, i) => sum + i.quantidade);

    return Scaffold(
      backgroundColor: BalancoColors.background,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Base de Catalogação e Lançamentos', style: TextStyle(fontFamily: 'Outfit', fontSize: 22, fontWeight: FontWeight.bold, color: BalancoColors.primary)),
                    Text('Visão consolidada de todos os ativos registrados localmente.', style: TextStyle(color: BalancoColors.textSecondary, fontSize: 13)),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: _carregar,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Atualizar'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Cartão de Resumo Superior
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: BalancoColors.border),
              ),
              child: Row(
                children: [
                  _statItem('Total de Registros', '${_itens.length}', Icons.folder_open),
                  const VerticalDivider(),
                  _statItem('Unidades Físicas Somadas', '$totalQtd un', Icons.tag),
                  const VerticalDivider(),
                  _statItem('Integridade do Banco', '100% ACID', Icons.verified_user),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Tabela de Dados
            Expanded(
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: BalancoColors.border),
                ),
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _itens.isEmpty
                        ? const Center(child: Text('Nenhum bem patrimonial encontrado.'))
                        : SingleChildScrollView(
                            child: SizedBox(
                              width: double.infinity,
                              child: DataTable(
                                headingRowColor: MaterialStateProperty.all(BalancoColors.containerLow),
                                columns: const [
                                  DataColumn(label: Text('FOTO', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('PLAQUETA', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('PRODUTO / ATIVO', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('SETOR', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('ENTIDADE', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('QTD', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('CONSERVAÇÃO', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('DATA', style: TextStyle(fontWeight: FontWeight.bold))),
                                ],
                                rows: _itens.map((item) {
                                  return DataRow(
                                    cells: [
                                      DataCell(
                                        Container(
                                          width: 38,
                                          height: 38,
                                          decoration: BoxDecoration(
                                            color: BalancoColors.containerLow,
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: BalancoColors.border),
                                          ),
                                          child: (item.fotoPath.isNotEmpty && File(item.fotoPath).existsSync())
                                              ? ClipRRect(
                                                  borderRadius: BorderRadius.circular(5),
                                                  child: Image.file(File(item.fotoPath), fit: BoxFit.cover),
                                                )
                                              : const Icon(Icons.photo, size: 20, color: BalancoColors.textMuted),
                                        ),
                                      ),
                                      DataCell(Text(item.plaquetaCodigo, style: const TextStyle(fontFamily: 'JetBrains Mono', fontWeight: FontWeight.bold, color: BalancoColors.primary))),
                                      DataCell(Text(item.produtoNome ?? '-', style: const TextStyle(fontWeight: FontWeight.w600))),
                                      DataCell(Text(item.setorNome ?? '-')),
                                      DataCell(Text(item.entidadeNome ?? '-')),
                                      DataCell(Text('${item.quantidade} un', style: const TextStyle(fontWeight: FontWeight.bold))),
                                      DataCell(
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: item.estadoConservacao == 'Danificado'
                                                ? BalancoColors.dangerBg
                                                : BalancoColors.successBg,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            item.estadoConservacao,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: item.estadoConservacao == 'Danificado'
                                                  ? BalancoColors.danger
                                                  : BalancoColors.success,
                                            ),
                                          ),
                                        ),
                                      ),
                                      DataCell(Text(item.dataLancamento.split(' ').first)),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statItem(String label, String value, IconData icon) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, color: BalancoColors.primary, size: 24),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Outfit')),
              Text(label, style: const TextStyle(color: BalancoColors.textSecondary, fontSize: 12)),
            ],
          )
        ],
      ),
    );
  }
}
