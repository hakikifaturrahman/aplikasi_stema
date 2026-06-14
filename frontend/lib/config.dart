// ==========================================================================
// STEMA (Smart Team Estimation and Match Analysis) - Config
// File: frontend/lib/config.dart
// Deskripsi: Konfigurasi URL API & Socket Backend pada Flutter.
//            Mendukung override URL saat build menggunakan --dart-define.
// ==========================================================================

import 'package:flutter/foundation.dart';

class AppConfig {
  // Fallback default alamat IP local/localhost untuk keperluan development
  static const String _defaultUrl = kIsWeb 
      ? 'http://127.0.0.1:3000' 
      : 'http://192.168.100.231:3000';

  // Membaca target URL backend dari environment variable '--dart-define=BACKEND_URL=...' saat compile.
  // Jika tidak didefinisikan, otomatis menggunakan fallback _defaultUrl di atas.
  static const String backendUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: _defaultUrl,
  );
}
