import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        backgroundColor: context.bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Syarat & Ketentuan',
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
              'Selamat datang di APK PUI. Dengan menggunakan aplikasi ini, Anda menyetujui dan terikat oleh Syarat & Ketentuan berikut. Jika Anda tidak setuju dengan salah satu kondisi, mohon berhenti menggunakan aplikasi ini.',
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              '1. Penggunaan Lisensi',
              'APK PUI memberikan kepada Anda lisensi terbatas, non-eksklusif, dan tidak dapat dialihkan untuk menggunakan aplikasi ini untuk tujuan pribadi dan profesional. Anda tidak boleh menyalin, memodifikasi, mendistribusikan, menjual, atau melisensikan kembali aplikasi atau bagian mana pun darinya.',
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              '2. Tanggung Jawab Pengguna',
              '• Anda bertanggung jawab untuk mempertahankan kerahasiaan akun dan kata sandi Anda\n• Anda setuju untuk tidak menggunakan aplikasi untuk tujuan ilegal atau berbahaya\n• Anda setuju untuk tidak mengakses atau mencoba mengakses area yang tidak diizinkan\n• Anda berkomitmen untuk menggunakan data dengan etika dan sesuai regulasi\n• Anda tidak akan melakukan reverse engineering atau dekompilasi aplikasi',
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              '3. Data dan Konten',
              '• Data pertandingan dan statistik pemain adalah milik pengguna yang membuat entri\n• Kami berhak menggunakan data agregat untuk analisis dan peningkatan layanan\n• Anda memberikan izin kepada kami untuk menyimpan, memproses, dan mengakses data Anda\n• Anda bertanggung jawab atas akurasi data yang Anda masukkan',
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              '4. Batasan Tanggung Jawab',
              'APLIKASI DISEDIAKAN ATAS DASAR "SEBAGAIMANA ADANYA" TANPA JAMINAN APAPUN. KAMI TIDAK BERTANGGUNG JAWAB ATAS KERUSAKAN LANGSUNG, TIDAK LANGSUNG, INSIDENTIL, KHUSUS, ATAU KONSEKUENSIAL YANG TIMBUL DARI PENGGUNAAN ATAU KETIDAKMAMPUAN MENGGUNAKAN APLIKASI.',
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              '5. Pembatasan Hukum',
              'Beberapa yurisdiksi tidak mengizinkan pengecualian tanggung jawab tertentu. Jika batasan tersebut tidak berlaku, tanggung jawab kami dibatasi pada jumlah yang Anda bayarkan kepada kami (jika ada) dalam tiga belas bulan terakhir.',
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              '6. Penghentian Layanan',
              'Kami berhak untuk menangguhkan atau menghentikan akun Anda kapan saja tanpa pemberitahuan sebelumnya jika kami percaya Anda telah melanggar ketentuan ini atau melakukan aktivitas ilegal. Anda dapat menutup akun Anda kapan saja melalui pengaturan.',
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              '7. Harga dan Pembayaran',
              'Layanan APK PUI saat ini gratis. Jika di masa depan kami mengenakan biaya, kami akan memberi tahu Anda terlebih dahulu dan Anda dapat memilih untuk terus menggunakan layanan gratis atau berlangganan versi premium.',
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              '8. Hak Kekayaan Intelektual',
              'Semua konten di aplikasi ini, termasuk teks, grafik, logo, dan kode, dilindungi oleh hak cipta dan hak kekayaan intelektual lainnya. Anda tidak boleh memproduksi ulang, mendistribusikan, atau mengirimkan konten tanpa izin tertulis dari kami.',
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              '9. Tautan Pihak Ketiga',
              'Aplikasi kami dapat berisi tautan ke situs web pihak ketiga. Kami tidak bertanggung jawab atas konten, keakuratan, atau praktik situs tersebut. Akses ke situs pihak ketiga berada di risiko Anda sendiri.',
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              '10. Modifikasi Ketentuan',
              'Kami berhak untuk memodifikasi Syarat & Ketentuan ini kapan saja. Perubahan akan berlaku segera setelah diposting. Penggunaan aplikasi Anda yang berkelanjutan setelah perubahan berarti Anda menerima syarat yang dimodifikasi.',
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              '11. Hukum yang Berlaku',
              'Syarat & Ketentuan ini diatur oleh dan ditafsirkan sesuai dengan hukum Republik Indonesia, tanpa mempertimbangkan konflik tata letak hukumnya. Anda setuju untuk tunduk pada yurisdiksi eksklusif pengadilan di Indonesia.',
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              '12. Kontak untuk Pertanyaan',
              'Jika Anda memiliki pertanyaan tentang Syarat & Ketentuan ini, silakan hubungi kami:\n\nEmail: support@apkpui.com\nTelepon: +62 812 3456 7890',
            ),
            const SizedBox(height: 32),
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
