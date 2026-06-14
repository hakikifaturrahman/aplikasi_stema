import 'dart:io';

void main() {
  final files = [
    'd:/apk_pui/frontend/lib/screens/riwayat_match_screen.dart',
    'd:/apk_pui/frontend/lib/screens/rule_engine_screen.dart',
    'd:/apk_pui/frontend/lib/screens/laporan_screen.dart',
  ];

  for (var path in files) {
    if (!File(path).existsSync()) continue;
    var f = File(path);
    var content = f.readAsStringSync();
    
    if (!content.contains("import '../theme/app_theme.dart';")) {
      content = content.replaceFirst("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\nimport '../theme/app_theme.dart';");
    }

    // Remove consts that will become dynamic
    content = content.replaceAll('const Scaffold', 'Scaffold');
    content = content.replaceAll('const AppBar', 'AppBar');
    content = content.replaceAll('const Container', 'Container');
    content = content.replaceAll('const Padding', 'Padding');
    content = content.replaceAll('const Row', 'Row');
    content = content.replaceAll('const Column', 'Column');
    content = content.replaceAll('const Text', 'Text');
    content = content.replaceAll('const Icon', 'Icon');
    content = content.replaceAll('const TextField', 'TextField');
    content = content.replaceAll('const TextStyle', 'TextStyle');
    content = content.replaceAll('const BoxDecoration', 'BoxDecoration');
    content = content.replaceAll('const InputDecoration', 'InputDecoration');
    content = content.replaceAll('const _HeaderCell', '_HeaderCell');
    content = content.replaceAll('const SizedBox', 'SizedBox'); // sometimes nested but let's be safe
    content = content.replaceAll('const Spacer', 'Spacer'); 
    
    // Replace hardcoded background colors
    content = content.replaceAll('const Color(0xFF1B1A12)', 'context.bgColor');
    content = content.replaceAll('Color(0xFF1B1A12)', 'context.bgColor');
    
    content = content.replaceAll('const Color(0xFF242217)', 'context.cardColor');
    content = content.replaceAll('Color(0xFF242217)', 'context.cardColor');
    
    content = content.replaceAll('const Color(0xFF2C2B1E)', 'context.cardAltColor');
    content = content.replaceAll('Color(0xFF2C2B1E)', 'context.cardAltColor');
    
    content = content.replaceAll('const Color(0xFF404040)', 'context.borderColor');
    content = content.replaceAll('Colors.white.withValues(alpha: 0.05)', 'context.borderColor');
    content = content.replaceAll('Colors.white.withValues(alpha: 0.07)', 'context.borderColor');
    content = content.replaceAll('Colors.white.withValues(alpha: 0.1)', 'context.borderColor');
    content = content.replaceAll('Colors.white.withValues(alpha: 0.03)', 'context.borderColor');
    
    // Replace text and icon colors
    content = content.replaceAll('color: Colors.white', 'color: context.textPrimary');
    content = content.replaceAll('color: Colors.white70', 'color: context.textSecondary');
    content = content.replaceAll('color: Colors.grey', 'color: context.textSecondary');
    content = content.replaceAll('color: Colors.white.withValues(alpha: 0.1)', 'color: context.borderColor');
    content = content.replaceAll('color: Colors.white.withValues(alpha: 0.03)', 'color: context.borderColor');

    f.writeAsStringSync(content);
  }
}
