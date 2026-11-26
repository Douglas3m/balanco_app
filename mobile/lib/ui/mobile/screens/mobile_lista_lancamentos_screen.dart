import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/lancamento_item.dart';
import '../../../repositories/lancamento_repository.dart';

class MobileListaLancamentosScreen extends StatefulWidget {
  final VoidCallback? onNovoTap;

  const MobileListaLancamentosScreen({super.key, this.onNovoTap});

  @override
  State<MobileListaLancamentosScreen> createState() => _MobileListaLancamentosScreenState();
}

class _MobileListaLancamentosScreenState extends State<MobileListaLancamentosScreen> {
  final _repo = LancamentoRepository();
  final _searchController = TextEditingController();

  List<LancamentoItem> _itens = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _loading = true);
    final res = await _repo.getCompletos(query: _searchController.text);
    if (mounted) {
      setState(() {
        _itens = res;
        _loading = false;
      });
    }
  }

  Future<void> _excluirItem(LancamentoItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: Text('Deseja excluir o lançamento "${item.produtoNome}" (${item.plaquetaCodigo})?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: BalancoColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirm == true && item.id != null) {
      await _repo.delete(item.id!);
      _carregar();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lançamentos Catalogados'),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: BalancoColors.primary,
        foregroundColor: Colors.white,
        onPressed: widget.onNovoTap,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          // Barra de Busca
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => _carregar(),
              decoration: InputDecoration(
                hintText: 'Buscar por bem, plaqueta ou setor...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _carregar();
                        },
                      )
                    : null,
              ),
            ),
          ),

          // Lista de Lançamentos
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _itens.isEmpty
                    ? const Center(child: Text('Nenhum registro encontrado.'))
                    : RefreshIndicator(
                        onRefresh: _carregar,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: _itens.length,
                          itemBuilder: (context, idx) {
                            final item = _itens[idx];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(10),
                                leading: Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    color: BalancoColors.containerLow,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: BalancoColors.border),
                                  ),
                                  child: (item.fotoPath.isNotEmpty && File(item.fotoPath).existsSync())
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(9),
                                          child: Image.file(File(item.fotoPath), fit: BoxFit.cover),
                                        )
                                      : const Icon(Icons.photo, color: BalancoColors.textMuted),
                                ),
                                title: Text(
                                  item.produtoNome ?? 'Item #${item.id}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text('${item.plaquetaCodigo} • ${item.setorNome}'),
                                    Text(item.entidadeNome ?? '', style: const TextStyle(color: BalancoColors.textSecondary, fontSize: 11)),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: item.estadoConservacao == 'Danificado'
                                                ? BalancoColors.dangerBg
                                                : BalancoColors.successBg,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            item.estadoConservacao,
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: item.estadoConservacao == 'Danificado'
                                                  ? BalancoColors.danger
                                                  : BalancoColors.success,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(item.dataLancamento, style: const TextStyle(fontSize: 11, color: BalancoColors.textSecondary)),
                                      ],
                                    ),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: BalancoColors.containerLow,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        '${item.quantidade} un',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: BalancoColors.primary,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: BalancoColors.danger, size: 20),
                                      onPressed: () => _excluirItem(item),
                                    )
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
