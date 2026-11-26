import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import 'screens/mobile_dashboard_screen.dart';
import 'screens/mobile_lista_lancamentos_screen.dart';
import 'screens/mobile_novo_lancamento_screen.dart';
import 'screens/mobile_cadastros_screen.dart';
import 'screens/mobile_camera_remota_screen.dart';
import 'screens/mobile_exportar_screen.dart';

class MobileShell extends StatefulWidget {
  const MobileShell({super.key});

  @override
  State<MobileShell> createState() => _MobileShellState();
}

class _MobileShellState extends State<MobileShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      MobileDashboardScreen(
        onNovoTap: () => setState(() => _currentIndex = 2),
        onVerTodosTap: () => setState(() => _currentIndex = 1),
      ),
      MobileListaLancamentosScreen(
        onNovoTap: () => setState(() => _currentIndex = 2),
      ),
      MobileNovoLancamentoScreen(
        onSalvoComSucesso: () => setState(() => _currentIndex = 1),
      ),
      const MobileCadastrosScreen(),
      const MobileCameraRemotaScreen(),
      const MobileExportarScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Início',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Itens',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle, color: BalancoColors.primary, size: 32),
            label: 'Novo',
          ),
          NavigationDestination(
            icon: Icon(Icons.domain_outlined),
            selectedIcon: Icon(Icons.domain),
            label: 'Cadastros',
          ),
          NavigationDestination(
            icon: Icon(Icons.videocam_outlined),
            selectedIcon: Icon(Icons.videocam),
            label: 'Câmera',
          ),
          NavigationDestination(
            icon: Icon(Icons.share_outlined),
            selectedIcon: Icon(Icons.share),
            label: 'Exportar',
          ),
        ],
      ),
    );
  }
}
