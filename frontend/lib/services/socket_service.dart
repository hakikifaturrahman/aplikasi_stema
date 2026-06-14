import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../config.dart';

/// Kelas Layanan: SocketService
/// Mengelola koneksi WebSocket menggunakan Socket.IO Client.
/// Menggunakan pola Singleton untuk menjamin hanya ada satu instance koneksi aktif di seluruh aplikasi.
class SocketService {
  // Instance internal tunggal (Singleton)
  static final SocketService _instance = SocketService._internal();
  
  // Factory constructor untuk mengembalikan instance tunggal
  factory SocketService() => _instance;
  
  // Private constructor
  SocketService._internal();

  late IO.Socket socket;          // Instance Socket.IO Client
  bool _isInitialized = false;     // Penanda status inisialisasi koneksi

  /// Membuka koneksi WebSocket ke server backend Node.js
  void connect() {
    if (_isInitialized) return; // Mencegah inisialisasi ulang jika sudah aktif

    // Menentukan URL server secara dinamis berdasarkan konfigurasi
    String url = AppConfig.backendUrl;

    socket = IO.io(url, <String, dynamic>{
      'transports': [
        'websocket',
        'polling',
      ], // Mengaktifkan websocket dan fallback polling untuk kompatibilitas yang baik
      'autoConnect': false, // Menunda koneksi otomatis agar bisa dipicu secara manual
    });

    // Melakukan koneksi ke server
    socket.connect();

    // Event Listener: Ketika koneksi berhasil terjalin
    socket.onConnect((_) {
      print('[+] Berhasil koneksi Server WebSockets (Node.js)');
    });

    // Event Listener: Ketika menerima event pembaruan data real-time 'data_updated' dari backend
    socket.on('data_updated', (data) {
      print('🔥 Update Data Real-Time Mendarat: $data');
    });

    // Event Listener: Ketika terputus dari server
    socket.onDisconnect((_) => print('[-] Terputus dari Server WebSockets'));

    _isInitialized = true;
  }

  /// Mengirimkan data dari Flutter ke Server Backend Node.js
  /// Menerima parameter [data] berupa Map (Key-Value)
  void throwData(Map<String, dynamic> data) {
    socket.emit('update_data', data);
  }

  /// Menutup koneksi socket secara aman dan menyetel ulang status inisialisasi
  void disconnect() {
    if (_isInitialized) {
      socket.disconnect();
      _isInitialized = false;
    }
  }
}
