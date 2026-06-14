/// Halaman Pengelolaan Data Roster Pemain STEMA
/// 
/// Halaman ini menampilkan daftar lengkap pemain (roster) sepak bola tim kita.
/// Pengguna dapat mencari pemain, melihat detail lengkap atribut/statistik fisik,
/// mengedit data pemain, menambahkan pemain baru, serta menghapus pemain.
/// Data disinkronkan secara real-time via Socket.IO.

import 'package:flutter/material.dart';
import 'dart:convert';
import '../main.dart';
import '../services/socket_service.dart';
import 'tambah_pemain_screen.dart';

/// Widget Halaman Roster Pemain: DataPemainScreen
class DataPemainScreen extends StatefulWidget {
  const DataPemainScreen({super.key});

  @override
  State<DataPemainScreen> createState() => _DataPemainScreenState();
}

class _DataPemainScreenState extends State<DataPemainScreen> {
  // ── State Roster Pemain ──
  List<Map<String, dynamic>> _roster = []; // Menyimpan daftar data pemain dari database backend
  bool _isLoading = true;                  // Penanda status loading saat mengambil data dari server
  String _searchQuery = '';                // Menyimpan kata kunci pencarian nama atau posisi pemain

  @override
  void initState() {
    super.initState();
    // 1. Memulai/menggunakan kembali koneksi Socket.IO global
    SocketService().connect();
    
    // Mengirim permintaan sinkronisasi awal ('request_sync') ke server backend
    SocketService().socket.emit('request_sync');

    // 2. Mendengarkan event 'stamina_sync' untuk memperbarui data roster pemain secara real-time
    SocketService().socket.off('stamina_sync');
    SocketService().socket.on('stamina_sync', (data) {
      if (mounted && data != null) {
        setState(() {
          // Melakukan parsing data list dinamis dari socket ke tipe list local
          _roster = List<Map<String, dynamic>>.from(
              data.map((item) => Map<String, dynamic>.from(item)));
          _isLoading = false; // Mematikan status loading
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            MainLayout.goToHome(context);
          },
        ),
        title: const Text('Data Pemain'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              _showInfoDialog(context);
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF000),
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                icon: const Icon(Icons.person_add, color: Colors.black),
                onPressed: () {
                  Navigator.pushNamed(context, '/tambah_pemain');
                },
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          children: [
            _buildSearchBar(),
            const SizedBox(height: 24),
            if (_isLoading)
               const Center(child: CircularProgressIndicator())
            else if (_roster.isEmpty)
               const Center(child: Text('Belum ada pemain yang ditambahkan.', style: TextStyle(color: Colors.grey)))
            else if (_roster.where((player) => 
               (player['nama'] ?? '').toString().toLowerCase().contains(_searchQuery) || 
               (player['pos'] ?? '').toString().toLowerCase().contains(_searchQuery)).isEmpty)
               const Center(child: Padding(padding: EdgeInsets.only(top: 40), child: Text('Tidak ada pemain yang cocok dengan pencarian.', style: TextStyle(color: Colors.grey))))
            else
               ..._roster.where((player) => 
                 (player['nama'] ?? '').toString().toLowerCase().contains(_searchQuery) || 
                 (player['pos'] ?? '').toString().toLowerCase().contains(_searchQuery)
               ).map((player) {
                  final String status = player['status'] ?? 'Main';
                  final Color sc = (status == 'Main' || status == 'Pemanasan') ? Colors.greenAccent : ((status.startsWith('Cedera') || status == 'Tidak Hadir') ? Colors.redAccent : Colors.orangeAccent);
                  final int st = (player['stamina'] is int) ? player['stamina'] : int.tryParse(player['stamina'].toString()) ?? 100;
                  final Color stc = st > 60 ? Colors.greenAccent : (st > 40 ? Colors.orangeAccent : Colors.redAccent);
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildPlayerCard(
                      name: player['nama'] ?? 'Unknown',
                      pos: player['pos'] ?? 'MF',
                      status: status,
                      statusColor: sc,
                      stamina: st,
                      staminaColor: stc,
                      imageBase64: player['foto'], // Mengambil foto dari DB berbentuk string base64
                      onEdit: () {
                        // Mengarahkan ke TambahPemainScreen dengan melemparkan data player yang ingin diedit
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TambahPemainScreen(playerData: player),
                          ),
                        );
                      },
                      onDelete: () {
                         // Menampilkan dialog konfirmasi penghapusan data pemain
                         showDialog(
                           context: context,
                           builder: (ctx) => AlertDialog(
                             backgroundColor: context.cardColor,
                             title: Text("Hapus Pemain", style: TextStyle(color: context.textPrimary)),
                             content: Text("Yakin ingin menghapus ${player['nama']}?", style: TextStyle(color: context.textSecondary)),
                             actions: [
                               TextButton(onPressed: () => Navigator.pop(ctx), child: Text("Batal", style: TextStyle(color: context.textSecondary))),
                               TextButton(
                                 onPressed: () {
                                    // Mengirimkan event 'delete_player' ke backend Node.js beserta argumen nama pemain
                                    SocketService().socket.emit('delete_player', player['nama']);
                                    Navigator.pop(ctx);
                                 }, 
                                 child: const Text("Hapus", style: TextStyle(color: Colors.redAccent))
                               )
                             ]
                           )
                         );
                      },
                      onInfo: () {
                        _showPlayerDetailDialog(context, player);
                      }
                    ),
                  );
               }).toList(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.info_outline, color: context.textPrimary),
            const SizedBox(width: 8),
            Text("Informasi Data Pemain", style: TextStyle(color: context.textPrimary, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Halaman ini digunakan untuk mengelola daftar (roster) pemain. Semua perubahan data (tambah, edit, hapus) di sini akan langsung disinkronkan secara real-time ke fitur Monitoring Stamina dan dropdown pemilihan pemain saat pertandingan.",
              style: TextStyle(color: context.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 16),
            Text(
              "Indikator Warna (Status / Stamina):",
              style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Row(children: [const Icon(Icons.circle, color: Colors.greenAccent, size: 12), const SizedBox(width: 8), Text("Siap Main / Prima (>60%)", style: TextStyle(color: context.textSecondary, fontSize: 13))]),
            const SizedBox(height: 4),
            Row(children: [const Icon(Icons.circle, color: Colors.orangeAccent, size: 12), const SizedBox(width: 8), Text("Rawan / Pemulihan (41-60%)", style: TextStyle(color: context.textSecondary, fontSize: 13))]),
            const SizedBox(height: 4),
            Row(children: [const Icon(Icons.circle, color: Colors.redAccent, size: 12), const SizedBox(width: 8), Text("Cedera / Kritis (<40%)", style: TextStyle(color: context.textSecondary, fontSize: 13))]),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('💡 '),
                  Expanded(
                    child: Text(
                      'Tips: Selalu pastikan daftar pemain Anda up-to-date sebelum memulai pertandingan agar perhitungan statistik dan Rule Engine berjalan akurat.',
                      style: TextStyle(color: context.textPrimary, fontStyle: FontStyle.italic, fontSize: 13, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Mengerti", style: TextStyle(color: context.textPrimary)),
          ),
        ],
      ),
    );
  }

  /// Menampilkan dialog popup yang berisi informasi rinci profil fisik, posisi alternatif,
  /// tanggal lahir, serta grafik batang sederhana untuk atribut skill teknis pemain.
  void _showPlayerDetailDialog(BuildContext context, Map<String, dynamic> player) {
    // Mengekstrak informasi biodata pemain dengan nilai default jika kosong
    final String name = player['nama'] ?? 'Unknown';
    final String pos = player['pos'] ?? '-';
    final String altPos = player['posisiAlternatif'] ?? 'None';
    final int no = (player['no'] is int) ? player['no'] : (int.tryParse(player['no'].toString()) ?? 0);
    final int tinggi = (player['tinggi'] is int) ? player['tinggi'] : (int.tryParse(player['tinggi'].toString()) ?? 0);
    final int berat = (player['berat'] is int) ? player['berat'] : (int.tryParse(player['berat'].toString()) ?? 0);
    final String tipe = player['tipe'] ?? 'Balanced';
    final String tglLahirStr = player['tgllahir'] ?? '';
    final String status = player['status'] ?? 'Main';
    final String? imageBase64 = player['foto'];

    // Menghitung kesesuaian warna penanda status
    final Color sc = (status == 'Main' || status == 'Pemanasan') ? Colors.greenAccent : ((status.startsWith('Cedera') || status == 'Tidak Hadir') ? Colors.redAccent : Colors.orangeAccent);
    final int stamina = (player['stamina'] is int) ? player['stamina'] : int.tryParse(player['stamina'].toString()) ?? 100;
    final Color stc = stamina > 60 ? Colors.greenAccent : (stamina > 40 ? Colors.orangeAccent : Colors.redAccent);

    // Mengambil dan memparsing atribut statistik kemampuan teknis pemain
    final attributes = player['attributes'] ?? {};
    final int speed = (attributes['speed'] is int) ? attributes['speed'] : int.tryParse(attributes['speed'].toString()) ?? 70;
    final int shooting = (attributes['shooting'] is int) ? attributes['shooting'] : int.tryParse(attributes['shooting'].toString()) ?? 70;
    final int passing = (attributes['passing'] is int) ? attributes['passing'] : int.tryParse(attributes['passing'].toString()) ?? 70;
    final int defensive = (attributes['defensive'] is int) ? attributes['defensive'] : int.tryParse(attributes['defensive'].toString()) ?? 70;
    final int vision = (attributes['vision'] is int) ? attributes['vision'] : int.tryParse(attributes['vision'].toString()) ?? 70;
    final int dribbling = (attributes['dribbling'] is int) ? attributes['dribbling'] : int.tryParse(attributes['dribbling'].toString()) ?? 70;

    String formattedDate = '-';
    if (tglLahirStr.isNotEmpty) {
      try {
        DateTime dt = DateTime.parse(tglLahirStr);
        formattedDate = '${dt.day}/${dt.month}/${dt.year}';
      } catch (e) {}
    }

    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: ctx.cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFFFF000).withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 70, height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFFFF000), width: 2),
                          color: ctx.cardAltColor,
                        ),
                        child: CircleAvatar(
                          backgroundColor: Colors.transparent,
                          backgroundImage: imageBase64 != null 
                              ? MemoryImage(base64Decode(imageBase64)) as ImageProvider
                              : null,
                          child: imageBase64 == null 
                              ? Icon(Icons.person, color: ctx.iconMuted, size: 40)
                              : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name, style: TextStyle(color: ctx.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(color: ctx.posBadgeBg, borderRadius: BorderRadius.circular(4)),
                                  child: Text(pos, style: TextStyle(color: ctx.posBadgeText, fontSize: 12, fontWeight: FontWeight.bold)),
                                ),
                                const SizedBox(width: 8),
                                Text('No. $no', style: TextStyle(color: ctx.textSecondary, fontSize: 14)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        color: ctx.iconMuted,
                        onPressed: () => Navigator.pop(ctx),
                      )
                    ],
                  ),
                  const Divider(height: 32, color: Colors.white24),
                  
                  Row(
                    children: [
                      Expanded(child: _buildInfoItem(ctx, 'Status', status, valueColor: sc)),
                      Expanded(child: _buildInfoItem(ctx, 'Stamina', '$stamina%', valueColor: stc)),
                    ]
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildInfoItem(ctx, 'Tinggi/Berat', '${tinggi > 0 ? tinggi : "-"} cm / ${berat > 0 ? berat : "-"} kg')),
                      Expanded(child: _buildInfoItem(ctx, 'Tgl Lahir', formattedDate)),
                    ]
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildInfoItem(ctx, 'Tipe Bermain', tipe)),
                      Expanded(child: _buildInfoItem(ctx, 'Pos Alternatif', altPos == 'None' ? '-' : altPos)),
                    ]
                  ),
                  const Divider(height: 32, color: Colors.white24),

                  Text('Statistik Atribut (0-100)', style: TextStyle(color: ctx.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _buildStatBar(ctx, 'Speed', speed),
                  _buildStatBar(ctx, 'Shooting', shooting),
                  _buildStatBar(ctx, 'Passing', passing),
                  _buildStatBar(ctx, 'Dribbling', dribbling),
                  _buildStatBar(ctx, 'Defensive', defensive),
                  _buildStatBar(ctx, 'Vision', vision),
                ],
              ),
            ),
          ),
        );
      }
    );
  }

  Widget _buildInfoItem(BuildContext context, String label, String value, {Color? valueColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: context.textSecondary, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: valueColor ?? context.textPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildStatBar(BuildContext context, String label, int value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text(label, style: TextStyle(color: context.textSecondary, fontSize: 13))),
          Expanded(
            child: Container(
              height: 8,
              decoration: BoxDecoration(color: context.isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: (value / 100).clamp(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: value >= 80 ? Colors.greenAccent : (value >= 60 ? const Color(0xFFFFF000) : Colors.orangeAccent),
                    borderRadius: BorderRadius.circular(4)
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: 40, child: Text(value.toString(), textAlign: TextAlign.right, style: TextStyle(color: context.textPrimary, fontSize: 13, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Builder(builder: (context) {
      return TextField(
        onChanged: (value) {
          setState(() {
            _searchQuery = value.toLowerCase();
          });
        },
        style: TextStyle(color: context.textPrimary),
        decoration: InputDecoration(
          hintText: 'Cari nama atau posisi pemain...',
          hintStyle: TextStyle(color: context.textSecondary),
          prefixIcon: Icon(Icons.search, color: context.iconMuted),
          filled: true,
          fillColor: context.searchFill,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      );
    });
  }

  Widget _buildPlayerCard({
    required String name,
    required String pos,
    required String status,
    required Color statusColor,
    required int stamina,
    required Color staminaColor,
    required String? imageBase64,
    bool isYellowBorder = false,
    VoidCallback? onEdit,
    VoidCallback? onDelete,
    VoidCallback? onInfo,
  }) {
    return Builder(builder: (context) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: context.isDark
                ? Colors.white.withValues(alpha: 0.05)
                : context.borderColor.withValues(alpha: 0.5),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: isYellowBorder
                        ? Border.all(color: const Color(0xFFFFF000), width: 3)
                        : Border.all(
                            color: Colors.grey.withValues(alpha: 0.3),
                            width: 2,
                          ),
                  ),
                  child: CircleAvatar(
                    backgroundColor: context.cardAltColor,
                    backgroundImage: imageBase64 != null 
                        ? MemoryImage(base64Decode(imageBase64)) as ImageProvider 
                        : null,
                    child: imageBase64 == null
                        ? Icon(Icons.person, color: context.iconMuted, size: 36)
                        : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          color: context.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: context.posBadgeBg,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              pos,
                              style: TextStyle(
                                color: context.posBadgeText,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '• Status: $status',
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 12,
                                height: 1.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: onEdit ?? () {},
                          icon: Icon(
                            Icons.edit,
                            color: context.iconMuted,
                            size: 20,
                          ),
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(),
                          splashRadius: 20,
                        ),
                        IconButton(
                          onPressed: onDelete ?? () {},
                          icon: Icon(
                            Icons.delete,
                            color: context.iconMuted,
                            size: 20,
                          ),
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(),
                          splashRadius: 20,
                        ),
                        IconButton(
                          onPressed: onInfo ?? () {},
                          icon: Icon(
                            Icons.info,
                            color: context.iconMuted,
                            size: 20,
                          ),
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(),
                          splashRadius: 20,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'STAMINA',
                  style: TextStyle(
                    color: context.textSecondary,
                    fontSize: 11,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '$stamina%',
                  style: TextStyle(
                    color: staminaColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              height: 8,
              width: double.infinity,
              decoration: BoxDecoration(
                color: context.isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(4),
              ),
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: stamina / 100.0,
                child: Container(
                  decoration: BoxDecoration(
                    color: staminaColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}
