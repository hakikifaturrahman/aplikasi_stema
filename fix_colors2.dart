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
    
    // Fix `textPrimary70` mapping
    content = content.replaceAll('context.textPrimary70', 'context.textSecondary');
    
    // Fix any `const` related to Text if color is no longer constant
    // but the script removed `const Text` already, but maybe left `const` before `TextStyle`
    // Actually `const TextStyle(color: context.textPrimary` is invalid const. We removed `const TextStyle` earlier though.
    // Let's check for `const TextStyle(` that was missed if it didn't match exactly.
    // Let's replace `const TextStyle(` with `TextStyle(` globally just in case.
    content = content.replaceAll('const TextStyle(', 'TextStyle(');
    content = content.replaceAll('const BoxDecoration(', 'BoxDecoration(');
    content = content.replaceAll('const InputDecoration(', 'InputDecoration(');
    content = content.replaceAll('const OutlineInputBorder(', 'OutlineInputBorder(');
    content = content.replaceAll('const BorderSide(', 'BorderSide(');
    content = content.replaceAll('const IconData(', 'IconData(');

    f.writeAsStringSync(content);
  }
}
