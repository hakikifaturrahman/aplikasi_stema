import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/socket_service.dart';
import 'register_screen.dart';
import '../main.dart';
import '../theme/app_theme.dart';

/// Widget Screen: LoginScreen
/// Halaman masuk (login) bagi pengguna untuk autentikasi akun menggunakan Socket.IO.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Controller untuk mengontrol data masukan pada kolom teks
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isLoading = false;      // Menandakan status loading proses login
  bool _obscureText = true;     // Menandakan status sembunyi/tampil karakter password

  @override
  void initState() {
    super.initState();
    // Membuka koneksi socket secara global
    SocketService().connect();
    
    // Mendengarkan event 'login_response' dari server
    SocketService().socket.on('login_response', (data) async {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      
      if (data['success']) {
        // Simpan sesi login lokal jika berhasil masuk
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('userEmail', _emailController.text);
        if (data['user'] != null && data['user']['role'] != null) {
          await prefs.setString('userRole', data['user']['role']);
        }
        
        if (!mounted) return;
        // Pindah ke MainLayout halaman utama dan bersihkan tumpukan rute lama
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainLayout())
        );
      } else {
        // Tampilkan pesan error kegagalan login dari server
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Login Gagal'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    // Mendengarkan kesalahan koneksi server socket
    SocketService().socket.on('connect_error', (err) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Koneksi Server Gagal: $err'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    });

    // Mendengarkan batas waktu habis (timeout) koneksi server
    SocketService().socket.on('connect_timeout', (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Koneksi Server Timeout!'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    });
  }

  @override
  void dispose() {
    // Mematikan listener socket untuk menghindari kebocoran memori (memory leak)
    SocketService().socket.off('login_response');
    SocketService().socket.off('connect_error');
    SocketService().socket.off('connect_timeout');
    
    // Membuang controller teks dari memori
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Fungsi memicu pengiriman event login ke backend
  void _login() {
    // Validasi dasar field kosong
    if (_emailController.text.trim().isEmpty || _passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email dan password tidak boleh kosong!'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Mengirim payload 'login' ke backend dengan parameter email & password
    SocketService().socket.emit('login', {
      'email': _emailController.text.trim(),
      'password': _passwordController.text.trim()
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark 
              ? [const Color(0xFF1A1A2E), const Color(0xFF16213E)] // Gradien warna gelap
              : [Colors.blue.shade800, Colors.blue.shade900],      // Gradien warna terang
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              color: isDark ? const Color(0xFF0F3460) : Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon sepak bola khas STEMA
                    Icon(
                      Icons.sports_soccer,
                      size: 80,
                      color: isDark ? const Color(0xFFFFF000) : Colors.blue.shade800,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'STEMA',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const Text(
                      'Login to Your Account',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 32),
                    
                    // Input Email
                    TextField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        prefixIcon: const Icon(Icons.email),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    
                    // Input Password
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscureText,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(_obscureText ? Icons.visibility : Icons.visibility_off),
                          onPressed: () {
                            setState(() {
                              _obscureText = !_obscureText;
                            });
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Tombol Aksi Login
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark ? const Color(0xFFFFF000) : Colors.blue.shade800,
                          foregroundColor: isDark ? Colors.black : Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _isLoading ? null : _login,
                        child: _isLoading 
                            ? const CircularProgressIndicator()
                            : const Text('LOGIN', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Navigasi ke Layar Pendaftaran Akun (RegisterScreen)
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const RegisterScreen())
                        );
                      },
                      child: Text(
                        'Belum punya akun? Daftar disini',
                        style: TextStyle(color: isDark ? Colors.blue.shade200 : Colors.blue.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
