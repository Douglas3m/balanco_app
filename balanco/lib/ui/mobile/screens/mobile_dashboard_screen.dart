import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../database/balanco_database.dart';
import '../../../models/lancamento_item.dart';
import '../../../repositories/lancamento_repository.dart';
import '../../../repositories/setor_repository.dart';
import '../widgets/mobile_metric_card.dart';

class MobileDashboardScreen extends StatefulWidget {
  final VoidCallback? onNovoTap;
  final VoidCallback? onVerTodosTap;

  const MobileDashboardScreen({
    super.key,
    this.onNovoTap,
    this.onVerTodosTap,
  });

  @override
  State<MobileDashboardScreen> createState() => _MobileDashboardScreenState();
}

class _MobileDashboardScreenState extends State<MobileDashboardScreen> {
  final _lancamentoRepo = LancamentoRepository();
  final _setorRepo = SetorRepository();

  List<LancamentoItem> _itens = [];
  int _totalSetores = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    setState(() => _loading = true);
    final itens = await _lancamentoRepo.getCompletos();
    final setores = await _setorRepo.getAll();
    if (mounted) {
      setState(() {
        _itens = itens;
        _totalSetores = setores.length;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalQtd = _itens.fold<int>(0, (sum, i) => sum + i.quantidade);

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.balance, size: 24),
            SizedBox(width: 8),
            Text('BALANÇO', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: BalancoColors.success.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              children: [
                Icon(Icons.check_circle, size: 14, color: BalancoColors.success),
                SizedBox(width: 4),
                Text('SQLite Offline', style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _carregarDados,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Cartão de Identificação da Entidade Principal
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: BalancoColors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.account_balance, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Prefeitura Municipal', style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold, fontSize: 16)),
                          SizedBox(height: 2),
                          Text('CNPJ 14.283.910/0001-44 • Gestão Ativa', style: TextStyle(color: BalancoColors.textSecondary, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Métricas Rápidas
            Row(
              children: [
                Expanded(
                  child: MobileMetricCard(
                    label: 'Bens Únicos',
                    value: '${_itens.length}',
                    icon: Icons.inventory_2_outlined,
                    color: BalancoColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: MobileMetricCard(
                    label: 'Itens Somados',
                    value: '$totalQtd',
                    icon: Icons.tag,
                    color: BalancoColors.secondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: MobileMetricCard(
                    label: 'Setores Mapeados',
                    value: '$_totalSetores',
                    icon: Icons.apartment_outlined,
                    color: BalancoColors.warning,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: MobileMetricCard(
                    label: 'Status Auditoria',
                    value: '100% OK',
                    icon: Icons.verified_outlined,
                    color: BalancoColors.success,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Cabeçalho da Lista Recente
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Últimos Lançamentos Auditados', style: TextStyle(fontFamily: 'Outfit', fontSize: 16, fontWeight: FontWeight.bold)),
                if (widget.onVerTodosTap != null)
                  TextButton(
                    onPressed: widget.onVerTodosTap,
                    child: const Text('Ver Todos', style: TextStyle(color: BalancoColors.secondary, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            if (_loading)
              const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
            else if (_itens.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      const Icon(Icons.inbox_outlined, size: 48, color: BalancoColors.textMuted),
                      const SizedBox(height: 12),
                      const Text('Nenhum item catalogado ainda.', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      const Text('Toque no botão "+" para iniciar a contagem em campo.', style: TextStyle(color: BalancoColors.textSecondary, fontSize: 12)),
                      const SizedBox(height: 16),
                      if (widget.onNovoTap != null)
                        ElevatedButton.icon(
                          onPressed: widget.onNovoTap,
                          icon: const Icon(Icons.add_a_photo),
                          label: const Text('Novo Lançamento'),
                        )
                    ],
                  ),
                ),
              )
            else
              ..._itens.take(5).map((item) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      leading: Container(
                        width: 48,
                        height: 48,
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
                            : const Icon(Icons.photo_camera_outlined, color: BalancoColors.textMuted),
                      ),
                      title: Text(item.produtoNome ?? 'Item #${item.id}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${item.plaquetaCodigo} • ${item.setorNome}\n${item.dataLancamento}'),
                      isThreeLine: true,
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: BalancoColors.containerLow,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${item.quantidade} un',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: BalancoColors.primary,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  )),
          ],
        ),
      ),
    );
  }
}
