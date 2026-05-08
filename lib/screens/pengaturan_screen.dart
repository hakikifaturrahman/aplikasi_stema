import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'dart:convert';
import '../main.dart';
import 'privacy_policy_screen.dart';
import 'terms_conditions_screen.dart';
import '../services/socket_service.dart';

class PengaturanScreen extends StatefulWidget {
  const PengaturanScreen({super.key});

  @override
  State<PengaturanScreen> createState() => _PengaturanScreenState();
}

class _PengaturanScreenState extends State<PengaturanScreen> {
  // Form controllers
  final _namaCtrl = TextEditingController(text: 'Alvaro Arbeloa');
  final _emailCtrl = TextEditingController(text: 'arbeloa@realfootball.com');
  final _telpCtrl = TextEditingController(text: '+62 812 3456 7890');

  String _role = 'Pelatih';
  bool _isEditing = false;

  // Password dialog controllers
  final _oldPassCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  bool _showOldPass = false;
  bool _showNewPass = false;
  bool _showConfirmPass = false;

  Uint8List? _profileBytes;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 50, maxWidth: 300);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _profileBytes = bytes;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _connectSocket();
  }

  void _connectSocket() {
    SocketService().connect();
    SocketService().socket.emit('request_sync');

    SocketService().socket.on('user_sync', (data) {
      if (mounted) {
        setState(() {
          _namaCtrl.text = data['nama'] ?? _namaCtrl.text;
          _emailCtrl.text = data['email'] ?? _emailCtrl.text;
          _telpCtrl.text = data['telp'] ?? _telpCtrl.text;
          
          String newRole = data['role'] ?? _role;
          final legacyRoles = ['Pelatih Kepala', 'Asisten Pelatih', 'Analis Data', 'Pelatih Fisik', 'Admin', 'Pelatih', 'Analis'];
          if (legacyRoles.contains(newRole)) {
            _role = newRole;
          }

          if (data['foto'] != null) {
            try {
              _profileBytes = base64Decode(data['foto']);
            } catch(e) {}
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _namaCtrl.dispose();
    _emailCtrl.dispose();
    _telpCtrl.dispose();
    _oldPassCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF242217),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                'Ubah Password',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildPassField(
                      label: 'Password Lama',
                      controller: _oldPassCtrl,
                      show: _showOldPass,
                      onToggle: () =>
                          setDialogState(() => _showOldPass = !_showOldPass),
                    ),
                    const SizedBox(height: 16),
                    _buildPassField(
                      label: 'Password Baru',
                      controller: _newPassCtrl,
                      show: _showNewPass,
                      onToggle: () =>
                          setDialogState(() => _showNewPass = !_showNewPass),
                    ),
                    const SizedBox(height: 16),
                    _buildPassField(
                      label: 'Konfirmasi Password Baru',
                      controller: _confirmPassCtrl,
                      show: _showConfirmPass,
                      onToggle: () => setDialogState(
                        () => _showConfirmPass = !_showConfirmPass,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    _oldPassCtrl.clear();
                    _newPassCtrl.clear();
                    _confirmPassCtrl.clear();
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Batal',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFF000),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    if (_newPassCtrl.text != _confirmPassCtrl.text) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Password baru tidak cocok!'),
                        ),
                      );
                      return;
                    }
                    _oldPassCtrl.clear();
                    _newPassCtrl.clear();
                    _confirmPassCtrl.clear();
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Password berhasil diubah!'),
                      ),
                    );
                  },
                  child: const Text(
                    'Simpan',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildPassField({
    required String label,
    required TextEditingController controller,
    required bool show,
    required VoidCallback onToggle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: !show,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFF1B1A12),
            suffixIcon: IconButton(
              icon: Icon(
                show ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey,
                size: 20,
              ),
              onPressed: onToggle,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF404040)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF404040)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFFFF000)),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        backgroundColor: context.bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.textPrimary),
          onPressed: () {
            final mainState = context.findAncestorStateOfType<MainLayoutState>();
            if (mainState != null) {
              mainState.setTab(0);
            } else {
              Navigator.of(context).popUntil((route) => route.isFirst);
            }
          },
        ),
        title: Text(
          'Pengaturan',
          style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                if (_isEditing) {
                  SocketService().socket.emit('update_user', {
                    'nama': _namaCtrl.text,
                    'email': _emailCtrl.text,
                    'telp': _telpCtrl.text,
                    'role': _role,
                    'foto': _profileBytes != null ? base64Encode(_profileBytes!) : null,
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Profil berhasil disimpan di Server!')),
                  );
                }
                _isEditing = !_isEditing;
              });
            },
            child: Text(
              _isEditing ? 'Simpan' : 'Edit',
              style: TextStyle(
                color: _isEditing
                    ? const Color(0xFFFFF000)
                    : context.textSecondary,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Foto Profil ──
            Center(
              child: Stack(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFFFF000),
                        width: 3,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: const Color(0xFF242217),
                      backgroundImage: _profileBytes != null
                          ? MemoryImage(_profileBytes!) as ImageProvider
                          : const AssetImage('assets/images/pelatih.jpg'),
                    ),
                  ),
                  if (_isEditing)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Color(0xFFFFF000),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.black,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF3A5F1A),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _role.toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFFFFF000),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // ── Tampilan (Dark / Light Mode) ──
            _buildSectionTitle('Tampilan'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withValues(alpha: isDark ? 0.08 : 0.0),
                ),
                boxShadow: isDark
                    ? []
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Row(
                children: [
                  // Mode gelap icon
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Container(
                      key: ValueKey(isDark),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFFFFF000).withValues(alpha: 0.15)
                            : Colors.orange.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        isDark ? Icons.dark_mode : Icons.light_mode,
                        color: isDark
                            ? const Color(0xFFFFF000)
                            : Colors.orange,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isDark ? 'Mode Gelap' : 'Mode Terang',
                          style: TextStyle(
                            color: context.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isDark
                              ? 'Tampilan saat ini: Gelap'
                              : 'Tampilan saat ini: Terang',
                          style: TextStyle(
                            color: context.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Toggle Switch
                  Switch(
                    value: isDark,
                    onChanged: (val) {
                      themeProvider.toggleTheme();
                    },
                    activeColor: const Color(0xFFFFF000),
                    activeTrackColor:
                        const Color(0xFFFFF000).withValues(alpha: 0.3),
                    inactiveThumbColor: Colors.orange,
                    inactiveTrackColor:
                        Colors.orange.withValues(alpha: 0.25),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Quick toggle row
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      if (!isDark) themeProvider.toggleTheme();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFFFFF000)
                            : context.cardColor,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(10),
                          bottomLeft: Radius.circular(10),
                        ),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFFFFF000)
                              : context.borderColor,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.dark_mode,
                            size: 18,
                            color: isDark
                                ? Colors.black
                                : context.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Gelap',
                            style: TextStyle(
                              color: isDark
                                  ? Colors.black
                                  : context.textSecondary,
                              fontWeight: isDark
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      if (isDark) themeProvider.toggleTheme();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: !isDark
                            ? Colors.orange
                            : context.cardColor,
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(10),
                          bottomRight: Radius.circular(10),
                        ),
                        border: Border.all(
                          color: !isDark
                              ? Colors.orange
                              : context.borderColor,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.light_mode,
                            size: 18,
                            color: !isDark
                                ? Colors.white
                                : context.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Terang',
                            style: TextStyle(
                              color: !isDark
                                  ? Colors.white
                                  : context.textSecondary,
                              fontWeight: !isDark
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // ── Form Profil ──
            _buildSectionTitle('Informasi Profil'),
            const SizedBox(height: 16),
            _buildProfileField(
              label: 'Nama Pengguna',
              controller: _namaCtrl,
              icon: Icons.person_outline,
              enabled: _isEditing,
            ),
            const SizedBox(height: 16),
            _buildProfileField(
              label: 'Email',
              controller: _emailCtrl,
              icon: Icons.email_outlined,
              enabled: _isEditing,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            _buildProfileField(
              label: 'Nomor Telepon',
              controller: _telpCtrl,
              icon: Icons.phone_outlined,
              enabled: _isEditing,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),

            // Role dropdown
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Role Pengguna',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: context.cardColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _isEditing
                          ? const Color(0xFFFFF000).withValues(alpha: 0.5)
                          : context.borderColor,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.badge_outlined,
                        color: Colors.grey,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            dropdownColor: const Color(0xFF242217),
                            value: _role,
                            style: TextStyle(
                              color: _isEditing ? Colors.white : Colors.grey,
                              fontSize: 15,
                            ),
                            icon: Icon(
                              Icons.arrow_drop_down,
                              color: _isEditing
                                  ? const Color(0xFFFFF000)
                                  : Colors.grey,
                            ),
                            items: (() {
                              List<String> rList = ['Pelatih Kepala', 'Asisten Pelatih', 'Analis Data', 'Pelatih Fisik'];
                              if (!rList.contains(_role)) rList.add(_role);
                              return rList;
                            })().map((String item) {
                              return DropdownMenuItem<String>(
                                value: item,
                                child: Text(item),
                              );
                            }).toList(),
                            onChanged: _isEditing
                                ? (v) => setState(() => _role = v!)
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // ── Keamanan Akun ──
            _buildSectionTitle('Keamanan Akun'),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _showChangePasswordDialog,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: isDark ? 0.08 : 0.0),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF000).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.lock_outline,
                        color: Color(0xFFFFF000),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ubah Password',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Perbarui kata sandi akun Anda',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.grey,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // ── Informasi Aplikasi ──
            _buildSectionTitle('Informasi Aplikasi'),
            const SizedBox(height: 16),
            _buildInfoTile(
              icon: Icons.info_outline,
              label: 'Versi Aplikasi',
              value: '1.0.0',
            ),
            _buildInfoTile(
              icon: Icons.shield_outlined,
              label: 'Kebijakan Privasi',
              value: 'Lihat →',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PrivacyPolicyScreen(),
                  ),
                );
              },
            ),
            _buildInfoTile(
              icon: Icons.description_outlined,
              label: 'Syarat & Ketentuan',
              value: 'Lihat →',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TermsConditionsScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),

            // ── Keluar ──
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.logout, color: Colors.redAccent),
                label: const Text(
                  'Keluar dari Akun',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.redAccent),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      backgroundColor: const Color(0xFF242217),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      title: const Text(
                        'Konfirmasi Keluar',
                        style: TextStyle(color: Colors.white),
                      ),
                      content: const Text(
                        'Apakah Anda yakin ingin keluar dari akun?',
                        style: TextStyle(color: Colors.grey),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            'Batal',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            'Keluar',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Builder(builder: (context) {
      final isDark = context.isDark;
      return Row(
        children: [
          Text(
            title,
            style: TextStyle(
              color: isDark ? const Color(0xFFFFF000) : const Color(0xFF8B7A00),
              fontWeight: FontWeight.bold,
              fontSize: 16,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Divider(
              color: (isDark
                      ? const Color(0xFFFFF000)
                      : const Color(0xFF8B7A00))
                  .withValues(alpha: 0.2),
              height: 1,
            ),
          ),
        ],
      );
    });
  }

  Widget _buildProfileField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required bool enabled,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Builder(builder: (context) {
      final isDark = context.isDark;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: context.textSecondary, fontSize: 12)),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            enabled: enabled,
            keyboardType: keyboardType,
            style: TextStyle(
              color: enabled ? context.textPrimary : context.textSecondary,
              fontSize: 15,
            ),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: context.iconMuted, size: 20),
              filled: true,
              fillColor: enabled ? context.cardAltColor : context.cardColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: context.borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: isDark ? const Color(0xFFFFF000) : const Color(0xFF8B7A00),
                  width: 1.2,
                ),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: context.borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: isDark ? const Color(0xFFFFF000) : const Color(0xFF8B7A00),
                  width: 2,
                ),
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
    VoidCallback? onTap,
  }) {
    return Builder(builder: (context) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: context.isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : context.borderColor.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: context.iconMuted, size: 20),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(color: context.textPrimary, fontSize: 14),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    value,
                    style: TextStyle(color: context.textSecondary, fontSize: 13),
                  ),
                  if (onTap != null) ...[
                    const SizedBox(width: 8),
                    Icon(
                      Icons.chevron_right,
                      color: context.textSecondary,
                      size: 18,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      );
    });
  }
}
