import 'package:flutter/material.dart';
import '../services/socket_service.dart';

/// Widget Screen: RegisterScreen
/// Halaman untuk melakukan pendaftaran akun baru pada sistem STEMA.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Controller untuk mengontrol masukan teks pada kolom formulir pendaftaran
  final _namaController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  String _selectedRole = 'Asisten Pelatih'; // Role default pengguna baru
  bool _isLoading = false;                   // Melacak status loading pendaftaran
  bool _obscureText = true;                  // Kontrol visibilitas password

  @override
  void initState() {
    super.initState();
    // Mendengarkan respon pendaftaran 'register_response' dari server
    SocketService().socket.on('register_response', (data) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      
      // Tampilkan SnackBar notifikasi hasil pendaftaran
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(data['message'] ?? ''),
          backgroundColor: data['success'] ? Colors.green : Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Jika pendaftaran sukses, tutup halaman registrasi dan kembali ke LoginScreen
      if (data['success']) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  void dispose() {
    // Mematikan listener socket untuk menghindari kebocoran memori (memory leak)
    SocketService().socket.off('register_response');
    
    // Membersihkan controller
    _namaController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Fungsi memicu pendaftaran akun baru ke server backend
  void _register() {
    // Validasi kelengkapan semua kolom formulir
    if (_namaController.text.trim().isEmpty || 
        _emailController.text.trim().isEmpty || 
        _passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Semua kolom wajib diisi!'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Mengirim payload event 'register' ke server backend
    SocketService().socket.emit('register', {
      'nama': _namaController.text.trim(),
      'email': _emailController.text.trim(),
      'password': _passwordController.text.trim(),
      'role': _selectedRole
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buat Akun Baru'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
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
                    // Icon pendaftaran
                    Icon(
                      Icons.person_add,
                      size: 60,
                      color: isDark ? const Color(0xFFFFF000) : Colors.blue.shade800,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Daftar STEMA',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // Input Nama Lengkap
                    TextField(
                      controller: _namaController,
                      decoration: InputDecoration(
                        labelText: 'Nama Lengkap',
                        prefixIcon: const Icon(Icons.person),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
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
                    const SizedBox(height: 16),
                    
                    // Dropdown Pilihan Role
                    DropdownButtonFormField<String>(
                      value: _selectedRole,
                      decoration: InputDecoration(
                        labelText: 'Role (Jabatan)',
                        prefixIcon: const Icon(Icons.work),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Pelatih Utama', child: Text('Pelatih Utama')),
                        DropdownMenuItem(value: 'Asisten Pelatih', child: Text('Asisten Pelatih')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedRole = val);
                        }
                      },
                    ),
                    const SizedBox(height: 24),
                    
                    // Tombol Aksi Daftar
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
                        onPressed: _isLoading ? null : _register,
                        child: _isLoading 
                            ? const CircularProgressIndicator()
                            : const Text('DAFTAR', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
