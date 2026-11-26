import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import 'widgets/desktop_sidebar.dart';
import 'widgets/desktop_header.dart';
import 'screens/desktop_catalogacao_screen.dart';
import 'screens/desktop_importar_screen.dart';
import 'screens/desktop_exportar_screen.dart';
import 'screens/desktop_entidades_setores_screen.dart';
import 'screens/desktop_camera_remota_screen.dart';
import 'screens/desktop_relatorio_a4_screen.dart';

class DesktopShell extends StatefulWidget {
  const DesktopShell({super.key});

  @override
  State<DesktopShell> createState() => _DesktopShellState();
}

class _DesktopShellState extends State<DesktopShell> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    DesktopCatalogacaoScreen(),
    DesktopImportarScreen(),
    DesktopExportarScreen(),
    DesktopEntidadesSetoresScreen(),
    DesktopCameraRemotaScreen(),
    DesktopRelatorioA4Screen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Barra Lateral de Navegação
          DesktopSidebar(
            selectedIndex: _selectedIndex,
            onSelect: (idx) => setState(() => _selectedIndex = idx),
          ),

          // Área Central de Trabalho com Cabeçalho Superior
          Expanded(
            child: Column(
              children: [
                DesktopHeader(
                  onSearchChanged: (query) {},
                ),
                Expanded(
                  child: IndexedStack(
                    index: _selectedIndex,
                    children: _screens,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
