import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Widget Screen: PrivacyPolicyScreen
/// Halaman statis yang menampilkan Kebijakan Privasi aplikasi STEMA/APK PUI.
/// Menggunakan StatelessWidget karena kontennya bersifat informatif dan statis.
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor, // Latar belakang adaptif dari tema
      appBar: AppBar(
        backgroundColor: context.bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.textPrimary),
          onPressed: () => Navigator.pop(context), // Kembali ke halaman sebelumnya
        ),
        title: Text(
          'Kebijakan Privasi',
          style: TextStyle(
            color: context.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              context,
              'Pendahuluan',
              'APK PUI ("Kami", "Aplikasi", atau "Layanan") berkomitmen untuk melindungi privasi Anda. Kebijakan Privasi ini menjelaskan bagaimana kami mengumpulkan, menggunakan, mengungkapkan, dan melindungi informasi Anda.',
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              '1. Informasi yang Kami Kumpulkan',
              '• Informasi Akun: Nama, email, nomor telepon, dan informasi profil lainnya\n• Data Pertandingan: Statistik pemain, hasil pertandingan, dan analisis performa\n• Data Teknis: Alamat IP, jenis perangkat, sistem operasi, dan data penggunaan aplikasi\n• Cookie dan Teknologi Pelacakan: Untuk meningkatkan pengalaman pengguna',
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              '2. Penggunaan Informasi',
              '• Menyediakan dan meningkatkan layanan aplikasi\n• Personalisasi pengalaman pengguna\n• Mengirim notifikasi dan pembaruan\n• Melakukan analisis dan riset\n• Mematuhi kewajiban hukum\n• Mencegah penipuan dan keamanan',
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              '3. Perlindungan Data',
              'Kami menerapkan langkah-langkah keamanan teknis dan organisasi yang sesuai untuk melindungi data pribadi Anda dari akses tidak sah, perubahan, pengungkapan, atau penghapusan. Namun, tidak ada metode transmisi melalui Internet yang 100% aman.',
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              '4. Berbagi Informasi',
              'Kami tidak menjual, memindahkan, atau mengungkapkan informasi pribadi Anda kepada pihak ketiga tanpa persetujuan eksplisit Anda, kecuali diwajibkan oleh hukum atau untuk melindungi hak-hak kami.',
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              '5. Hak Pengguna',
              '• Hak akses ke data pribadi Anda\n• Hak untuk memperbaiki data yang tidak akurat\n• Hak untuk menghapus akun dan data terkait\n• Hak untuk membatasi pemrosesan\n• Hak untuk keberatan atas pemrosesan',
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              '6. Penyimpanan Data',
              'Kami menyimpan data pribadi Anda selama diperlukan untuk menyediakan layanan atau sesuai dengan persyaratan hukum yang berlaku. Anda dapat meminta penghapusan data kapan saja melalui pengaturan akun.',
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              '7. Kontak Kami',
              'Jika Anda memiliki pertanyaan tentang Kebijakan Privasi ini atau praktik privasi kami, silakan hubungi kami:\n\nEmail: privacy@apkpui.com\nTelepon: +62 812 3456 7890',
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              '8. Perubahan Kebijakan',
              'Kami dapat memperbarui Kebijakan Privasi ini dari waktu ke waktu. Kami akan memberitahu Anda tentang perubahan apa pun dengan memposting Kebijakan Privasi yang baru di halaman ini dan memperbarui tanggal "Terakhir Diperbarui".',
            ),
            const SizedBox(height: 32),
            
            // Footer Info Tanggal Update
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.cardAltColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: context.borderColor),
              ),
              child: Text(
                'Terakhir diperbarui: 13 Maret 2026',
                style: TextStyle(
                  color: context.textSecondary,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  /// Widget Helper: Membuat section teks kebijakan
  /// Memformat [title] tebal dan [content] dengan tinggi baris yang nyaman dibaca.
  Widget _buildSection(BuildContext context, String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: context.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: TextStyle(
            color: context.textSecondary,
            fontSize: 13,
            height: 1.6,
          ),
        ),
      ],
    );
  }
}
