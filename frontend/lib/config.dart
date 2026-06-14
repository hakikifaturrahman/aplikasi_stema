// ==========================================================================
// STEMA (Smart Team Estimation and Match Analysis) - Config
// File: frontend/lib/config.dart
// Deskripsi: Konfigurasi URL API & Socket Backend pada Flutter.
//            Mendukung override URL saat build menggunakan --dart-define.
// ==========================================================================

import 'package:flutter/foundation.dart';

class AppConfig {
  // Alamat URL backend Node.js di Railway sebagai default
  static const String _defaultUrl = 'https://aplikasistema-production.up.railway.app';

  // Membaca target URL backend dari environment variable '--dart-define=BACKEND_URL=...' saat compile.
  // Jika tidak didefinisikan, otomatis menggunakan fallback _defaultUrl di atas.
  static const String backendUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: _defaultUrl,
  );
}
