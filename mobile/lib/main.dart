import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'ui/adaptive_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BalancoApp());
}

class BalancoApp extends StatelessWidget {
  const BalancoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Balanço - Patrimônio & Auditoria',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const AdaptiveShell(),
    );
  }
}
