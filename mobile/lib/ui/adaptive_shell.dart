import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'mobile/mobile_shell.dart';
import 'desktop/desktop_shell.dart';

class AdaptiveShell extends StatelessWidget {
  const AdaptiveShell({super.key});

  @override
  Widget build(BuildContext context) {
    // Breakpoint: Se a largura for >= 900 ou estiver em Desktop nativo (Windows/macOS/Linux)
    final isDesktopPlatform = !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);
    final isWideScreen = MediaQuery.of(context).size.width >= 900;

    if (isDesktopPlatform || isWideScreen) {
      return const DesktopShell();
    }
    return const MobileShell();
  }
}
