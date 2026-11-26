import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/entidade.dart';
import '../../../models/produto.dart';
import '../../../models/setor.dart';
import '../../../repositories/entidade_repository.dart';
import '../../../repositories/produto_repository.dart';
import '../../../repositories/setor_repository.dart';

class MobileCadastrosScreen extends StatefulWidget {
  const MobileCadastrosScreen({super.key});

  @override
  State<MobileCadastrosScreen> createState() => _MobileCadastrosScreenState();
}

class _MobileCadastrosScreenState extends State<MobileCadastrosScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _entidadeRepo = EntidadeRepository();
  final _setorRepo = SetorRepository();
  final _produtoRepo = ProdutoRepository();

  List<Entidade> _entidades = [];
  List<Setor> _setores = [];
  List<Produto> _produtos = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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

  void _novaEntidade() {
    final nomeController = TextEditingController();
    final cnpjController = TextEditingController();
    final obsController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nova Entidade / Instituição'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nomeController, decoration: const InputDecoration(labelText: 'Nome da Entidade*')),
            const SizedBox(height: 10),
            TextField(controller: cnpjController, decoration: const InputDecoration(labelText: 'CNPJ / Código')),
            const SizedBox(height: 10),
            TextField(controller: obsController, decoration: const InputDecoration(labelText: 'Observação')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (nomeController.text.trim().isNotEmpty) {
                await _entidadeRepo.insert(Entidade(
                  nome: nomeController.text.trim(),
                  cnpjCodigo: cnpjController.text.trim(),
                  observacao: obsController.text.trim(),
                ));
                if (ctx.mounted) Navigator.pop(ctx);
                _carregar();
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  void _novoSetor() {
    if (_entidades.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cadastre primeiro uma Entidade!')),
      );
      return;
    }

    final nomeController = TextEditingController();
    final blocoController = TextEditingController();
    final respController = TextEditingController();
    int selectedEntId = _entidades.first.id!;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: const Text('Novo Setor Operacional'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                value: selectedEntId,
                items: _entidades.map((e) => DropdownMenuItem(value: e.id, child: Text(e.nome))).toList(),
                onChanged: (v) => setModalState(() => selectedEntId = v!),
                decoration: const InputDecoration(labelText: 'Entidade Vinculada*'),
              ),
              const SizedBox(height: 10),
              TextField(controller: nomeController, decoration: const InputDecoration(labelText: 'Nome do Setor / Sala*')),
              const SizedBox(height: 10),
              TextField(controller: blocoController, decoration: const InputDecoration(labelText: 'Andar / Bloco')),
              const SizedBox(height: 10),
              TextField(controller: respController, decoration: const InputDecoration(labelText: 'Responsável')),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () async {
                if (nomeController.text.trim().isNotEmpty) {
                  await _setorRepo.insert(Setor(
                    entidadeId: selectedEntId,
                    nome: nomeController.text.trim(),
                    andarBloco: blocoController.text.trim(),
                    responsavel: respController.text.trim(),
                  ));
                  if (ctx.mounted) Navigator.pop(ctx);
                  _carregar();
                }
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }

  void _novoProduto() {
    final nomeController = TextEditingController();
    final catController = TextEditingController(text: 'Geral');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Novo Produto / Ativo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nomeController, decoration: const InputDecoration(labelText: 'Nome do Bem / Produto*')),
            const SizedBox(height: 10),
            TextField(controller: catController, decoration: const InputDecoration(labelText: 'Categoria')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (nomeController.text.trim().isNotEmpty) {
                await _produtoRepo.insert(Produto(
                  nome: nomeController.text.trim(),
                  categoria: catController.text.trim(),
                ));
                if (ctx.mounted) Navigator.pop(ctx);
                _carregar();
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestão de Cadastros'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Entidades'),
            Tab(text: 'Setores'),
            Tab(text: 'Produtos'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: BalancoColors.primary,
        foregroundColor: Colors.white,
        onPressed: () {
          if (_tabController.index == 0) _novaEntidade();
          if (_tabController.index == 1) _novoSetor();
          if (_tabController.index == 2) _novoProduto();
        },
        child: const Icon(Icons.add),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 1. Entidades
          ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: _entidades.length,
            itemBuilder: (ctx, idx) {
              final e = _entidades[idx];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const Icon(Icons.domain, color: BalancoColors.primary),
                  title: Text(e.nome, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(e.cnpjCodigo.isNotEmpty ? 'CNPJ: ${e.cnpjCodigo}' : 'Sem CNPJ informado'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: BalancoColors.danger),
                    onPressed: () async {
                      if (e.id != null) {
                        await _entidadeRepo.delete(e.id!);
                        _carregar();
                      }
                    },
                  ),
                ),
              );
            },
          ),

          // 2. Setores
          ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: _setores.length,
            itemBuilder: (ctx, idx) {
              final s = _setores[idx];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const Icon(Icons.meeting_room, color: BalancoColors.secondary),
                  title: Text(s.nome, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${s.entidadeNome ?? ''} • ${s.andarBloco}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: BalancoColors.danger),
                    onPressed: () async {
                      if (s.id != null) {
                        await _setorRepo.delete(s.id!);
                        _carregar();
                      }
                    },
                  ),
                ),
              );
            },
          ),

          // 3. Produtos
          ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: _produtos.length,
            itemBuilder: (ctx, idx) {
              final p = _produtos[idx];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const Icon(Icons.inventory_2, color: BalancoColors.warning),
                  title: Text(p.nome, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Categoria: ${p.categoria}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: BalancoColors.danger),
                    onPressed: () async {
                      if (p.id != null) {
                        await _produtoRepo.delete(p.id!);
                        _carregar();
                      }
                    },
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
