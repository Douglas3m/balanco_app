import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/entidade.dart';
import '../../../models/lancamento_item.dart';
import '../../../models/produto.dart';
import '../../../models/setor.dart';
import '../../../repositories/entidade_repository.dart';
import '../../../repositories/lancamento_repository.dart';
import '../../../repositories/produto_repository.dart';
import '../../../repositories/setor_repository.dart';

class MobileNovoLancamentoScreen extends StatefulWidget {
  final VoidCallback? onSalvoComSucesso;

  const MobileNovoLancamentoScreen({super.key, this.onSalvoComSucesso});

  @override
  State<MobileNovoLancamentoScreen> createState() => _MobileNovoLancamentoScreenState();
}

class _MobileNovoLancamentoScreenState extends State<MobileNovoLancamentoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _produtoController = TextEditingController();
  final _plaquetaController = TextEditingController();
  final _obsController = TextEditingController();

  final _entidadeRepo = EntidadeRepository();
  final _setorRepo = SetorRepository();
  final _produtoRepo = ProdutoRepository();
  final _lancamentoRepo = LancamentoRepository();

  int _quantidade = 1;
  String _estadoConservacao = 'Ótimo';
  String? _fotoPath;

  int? _selectedEntidadeId;
  int? _selectedSetorId;

  List<Entidade> _entidades = [];
  List<Setor> _setores = [];
  List<Produto> _produtos = [];

  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    _gerarNovaPlaqueta();
    _carregarListas();
  }

  void _gerarNovaPlaqueta() {
    final millis = DateTime.now().millisecondsSinceEpoch.toString();
    _plaquetaController.text = 'PAT-2025-${millis.substring(millis.length - 4)}';
  }

  Future<void> _carregarListas() async {
    final ents = await _entidadeRepo.getAll();
    final prods = await _produtoRepo.getAll();

    if (mounted) {
      setState(() {
        _entidades = ents;
        _produtos = prods;
        if (ents.isNotEmpty && _selectedEntidadeId == null) {
          _selectedEntidadeId = ents.first.id;
          _carregarSetores(ents.first.id!);
        }
      });
    }
  }

  Future<void> _carregarSetores(int entidadeId) async {
    final sets = await _setorRepo.getByEntidade(entidadeId);
    if (mounted) {
      setState(() {
        _setores = sets;
        _selectedSetorId = sets.isNotEmpty ? sets.first.id : null;
      });
    }
  }

  Future<void> _selecionarOrigemFoto() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: BalancoColors.primary),
                title: const Text('Tirar foto com a câmera'),
                onTap: () {
                  Navigator.pop(ctx);
                  _capturarFoto(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: BalancoColors.secondary),
                title: const Text('Escolher da galeria'),
                onTap: () {
                  Navigator.pop(ctx);
                  _capturarFoto(ImageSource.gallery);
                },
              ),
              if (_fotoPath != null)
                ListTile(
                  leading: const Icon(Icons.delete, color: BalancoColors.danger),
                  title: const Text('Remover foto atual'),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() => _fotoPath = null);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _capturarFoto(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: source, imageQuality: 85);
      if (picked != null) {
        setState(() => _fotoPath = picked.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro na captura: $e')));
      }
    }
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedEntidadeId == null || _selectedSetorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione a Entidade e o Setor!')),
      );
      return;
    }

    setState(() => _salvando = true);

    try {
      // 1. Garante ou cria o produto na lista padronizada
      final prodId = await _produtoRepo.getOrCreateByName(_produtoController.text.trim());

      // 2. Cria o lançamento
      final novoLancamento = LancamentoItem(
        plaquetaCodigo: _plaquetaController.text.trim(),
        produtoId: prodId,
        setorId: _selectedSetorId!,
        entidadeId: _selectedEntidadeId!,
        quantidade: _quantidade,
        estadoConservacao: _estadoConservacao,
        fotoPath: _fotoPath ?? '',
        observacao: _obsController.text.trim(),
        dataLancamento: DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now()),
      );

      await _lancamentoRepo.insert(novoLancamento);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: BalancoColors.success,
            content: Text('Lançamento catalogado com sucesso no SQLite!'),
          ),
        );

        // Limpa para o próximo item
        setState(() {
          _produtoController.clear();
          _obsController.clear();
          _fotoPath = null;
          _quantidade = 1;
          _gerarNovaPlaqueta();
          _salvando = false;
        });

        widget.onSalvoComSucesso?.call();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _salvando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: BalancoColors.danger, content: Text('Erro ao salvar: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Novo Lançamento'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Container da Fotografia com Aspecto 1:1 Preservado
            GestureDetector(
              onTap: _selecionarOrigemFoto,
              child: Container(
                height: 190,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: BalancoColors.border, width: 2),
                ),
                child: _fotoPath != null && File(_fotoPath!).existsSync()
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.file(File(_fotoPath!), fit: BoxFit.cover),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                              child: const Icon(Icons.edit, color: Colors.white, size: 18),
                            ),
                          )
                        ],
                      )
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt_outlined, size: 48, color: BalancoColors.primary),
                          SizedBox(height: 8),
                          Text('Tirar Foto do Ativo ou Escolher da Galeria', style: TextStyle(fontWeight: FontWeight.bold)),
                          SizedBox(height: 2),
                          Text('Proporção 1:1 preservada para laudo A4', style: TextStyle(color: BalancoColors.textSecondary, fontSize: 12)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 16),

            // Plaqueta / Tombamento
            TextFormField(
              controller: _plaquetaController,
              decoration: const InputDecoration(
                labelText: 'Plaqueta / Tombamento (#PAT)*',
                prefixIcon: Icon(Icons.tag),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Informe o código do tombamento' : null,
            ),
            const SizedBox(height: 12),

            // Produto / Objeto / Ativo com Autocomplete
            Autocomplete<Produto>(
              optionsBuilder: (textEditingValue) {
                if (textEditingValue.text.isEmpty) return const Iterable<Produto>.empty();
                return _produtos.where((p) => p.nome.toLowerCase().contains(textEditingValue.text.toLowerCase()));
              },
              displayStringForOption: (p) => p.nome,
              onSelected: (p) {
                _produtoController.text = p.nome;
              },
              fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                // Sincroniza com _produtoController
                controller.text = _produtoController.text;
                controller.addListener(() {
                  _produtoController.text = controller.text;
                });
                return TextFormField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: const InputDecoration(
                    labelText: 'Produto / Objeto / Ativo*',
                    hintText: 'Ex: Cadeira Giratória NR-17',
                    prefixIcon: Icon(Icons.inventory_2_outlined),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Informe o nome do bem' : null,
                );
              },
            ),
            const SizedBox(height: 12),

            // Entidade / Instituição
            DropdownButtonFormField<int>(
              value: _selectedEntidadeId,
              items: _entidades.map((e) => DropdownMenuItem(value: e.id, child: Text(e.nome, overflow: TextOverflow.ellipsis))).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedEntidadeId = val);
                  _carregarSetores(val);
                }
              },
              decoration: const InputDecoration(
                labelText: 'Entidade / Instituição*',
                prefixIcon: Icon(Icons.domain_outlined),
              ),
            ),
            const SizedBox(height: 12),

            // Setor / Sala
            DropdownButtonFormField<int>(
              value: _selectedSetorId,
              items: _setores.map((s) => DropdownMenuItem(value: s.id, child: Text(s.nome, overflow: TextOverflow.ellipsis))).toList(),
              onChanged: (val) => setState(() => _selectedSetorId = val),
              decoration: const InputDecoration(
                labelText: 'Setor / Sala Destino*',
                prefixIcon: Icon(Icons.meeting_room_outlined),
              ),
            ),
            const SizedBox(height: 16),

            // Quantidade Física
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: BalancoColors.border)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    const Text('Quantidade Física:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const Spacer(),
                    IconButton.filledTonal(
                      icon: const Icon(Icons.remove),
                      onPressed: () {
                        if (_quantidade > 1) setState(() => _quantidade--);
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text('$_quantidade', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Outfit')),
                    ),
                    IconButton.filledTonal(
                      icon: const Icon(Icons.add),
                      onPressed: () => setState(() => _quantidade++),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Estado de Conservação
            const Text('Estado de Conservação:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: BalancoColors.textSecondary)),
            const SizedBox(height: 6),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'Ótimo', label: Text('Ótimo')),
                ButtonSegment(value: 'Bom', label: Text('Bom')),
                ButtonSegment(value: 'Danificado', label: Text('Danificado')),
              ],
              selected: {_estadoConservacao},
              onSelectionChanged: (val) => setState(() => _estadoConservacao = val.first),
            ),
            const SizedBox(height: 16),

            // Observações
            TextFormField(
              controller: _obsController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Observações de Campo (Opcional)',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 24),

            // Botão Salvar
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _salvando ? null : _salvar,
                icon: _salvando ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.save),
                label: Text(_salvando ? 'Salvando...' : 'Salvar Lançamento no SQLite', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
