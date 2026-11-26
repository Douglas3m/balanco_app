import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/entidade.dart';
import '../../../models/produto.dart';
import '../../../models/setor.dart';
import '../../../repositories/entidade_repository.dart';
import '../../../repositories/produto_repository.dart';
import '../../../repositories/setor_repository.dart';

class DesktopEntidadesSetoresScreen extends StatefulWidget {
  const DesktopEntidadesSetoresScreen({super.key});

  @override
  State<DesktopEntidadesSetoresScreen> createState() => _DesktopEntidadesSetoresScreenState();
}

class _DesktopEntidadesSetoresScreenState extends State<DesktopEntidadesSetoresScreen> {
  final _entidadeRepo = EntidadeRepository();
  final _setorRepo = SetorRepository();
  final _produtoRepo = ProdutoRepository();

  List<Entidade> _entidades = [];
  List<Setor> _setores = [];
  List<Produto> _produtos = [];

  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    final e = await _entidadeRepo.getAll();
    final s = await _setorRepo.getAll();
    final p = await _produtoRepo.getAll();
    if (mounted) {
      setState(() {
        _entidades = e;
        _setores = s;
        _produtos = p;
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
            const Text('Gestão de Entidades, Setores & Catálogo de Ativos', style: TextStyle(fontFamily: 'Outfit', fontSize: 22, fontWeight: FontWeight.bold, color: BalancoColors.primary)),
            const Text('Cadastros padronizados para seleção rápida e auditoria fiscal.', style: TextStyle(color: BalancoColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 20),

            // Tabs Desktop
            Row(
              children: [
                _tabBtn(0, 'Entidades & Órgãos (${_entidades.length})', Icons.domain),
                const SizedBox(width: 8),
                _tabBtn(1, 'Setores & Salas (${_setores.length})', Icons.meeting_room),
                const SizedBox(width: 8),
                _tabBtn(2, 'Catálogo de Produtos (${_produtos.length})', Icons.inventory_2),
              ],
            ),
            const SizedBox(height: 16),

            Expanded(
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: BalancoColors.border)),
                child: _tabIndex == 0 ? _buildEntidadesTable() : _tabIndex == 1 ? _buildSetoresTable() : _buildProdutosTable(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tabBtn(int idx, String label, IconData icon) {
    final active = _tabIndex == idx;
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: active ? BalancoColors.primary : Colors.white,
        foregroundColor: active ? Colors.white : BalancoColors.textMain,
        side: const BorderSide(color: BalancoColors.border),
      ),
      onPressed: () => setState(() => _tabIndex = idx),
      icon: Icon(icon, size: 18),
      label: Text(label),
    );
  }

  Widget _buildEntidadesTable() {
    return SingleChildScrollView(
      child: DataTable(
        columns: const [
          DataColumn(label: Text('ID', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('NOME DA ENTIDADE', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('CNPJ / CÓDIGO', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('REGIME JURÍDICO', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('OBSERVAÇÕES', style: TextStyle(fontWeight: FontWeight.bold))),
        ],
        rows: _entidades.map((e) => DataRow(cells: [
          DataCell(Text('${e.id}')),
          DataCell(Text(e.nome, style: const TextStyle(fontWeight: FontWeight.bold))),
          DataCell(Text(e.cnpjCodigo)),
          DataCell(Text(e.regime)),
          DataCell(Text(e.observacao)),
        ])).toList(),
      ),
    );
  }

  Widget _buildSetoresTable() {
    return SingleChildScrollView(
      child: DataTable(
        columns: const [
          DataColumn(label: Text('ID', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('SETOR / SALA', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('ENTIDADE VINCULADA', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('ANDAR / BLOCO', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('RESPONSÁVEL', style: TextStyle(fontWeight: FontWeight.bold))),
        ],
        rows: _setores.map((s) => DataRow(cells: [
          DataCell(Text('${s.id}')),
          DataCell(Text(s.nome, style: const TextStyle(fontWeight: FontWeight.bold))),
          DataCell(Text(s.entidadeNome ?? '-')),
          DataCell(Text(s.andarBloco)),
          DataCell(Text(s.responsavel)),
        ])).toList(),
      ),
    );
  }

  Widget _buildProdutosTable() {
    return SingleChildScrollView(
      child: DataTable(
        columns: const [
          DataColumn(label: Text('ID', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('NOME DO PRODUTO / ATIVO', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('CATEGORIA', style: TextStyle(fontWeight: FontWeight.bold))),
        ],
        rows: _produtos.map((p) => DataRow(cells: [
          DataCell(Text('${p.id}')),
          DataCell(Text(p.nome, style: const TextStyle(fontWeight: FontWeight.bold))),
          DataCell(Text(p.categoria)),
        ])).toList(),
      ),
    );
  }
}
