import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  // Singleton pattern agar tidak ada duplikasi koneksi
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  late IO.Socket socket;
  bool _isInitialized = false;

  void connect() {
    if (_isInitialized) return;
    
    // URL Ngrok agar bisa diakses dari mana saja menggunakan internet (kuota)
    String url = 'https://backdrop-cabana-jasmine.ngrok-free.dev';

    socket = IO.io(url, <String, dynamic>{
      'transports': ['websocket'], // Wajib diset websocket untuk koneksi yang stabil
      'autoConnect': false,
    });
    
    // Inisialisasi Koneski
    socket.connect();
    
    // Listeners
    socket.onConnect((_) {
      print('[+] Berhasil koneksi Server WebSockets (Node.js)');
    });

    // Menunggu kiriman data ('data_updated' dari Node.js backend)
    socket.on('data_updated', (data) {
      print('🔥 Update Data Real-Time Mendarat: $data');
      // Anda dapat menghubungan ke Provider, GetX, atau setState di sini nanti
    });

    socket.onDisconnect((_) => print('[-] Terputus dari Server WebSockets'));

    _isInitialized = true;
  }
  
  // Ini fungsi untung mengirim data/update secara real-time dari Flutter ke Backend Node.Js
  void throwData(Map<String, dynamic> data) {
    socket.emit('update_data', data);
  }

  // Penting untuk dipanggil saat aplikasi/layer ditutup
  void disconnect() {
    if (_isInitialized) {
      socket.disconnect();
      _isInitialized = false;
    }
  }
}
