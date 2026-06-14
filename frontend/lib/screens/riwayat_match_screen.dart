/// Halaman Riwayat & Detail Pertandingan STEMA
/// 
/// Halaman ini menyajikan rekaman data riwayat pertandingan sepak bola (menang/seri/kalah)
/// yang disinkronkan dari server Node.js secara real-time. Pelatih dapat memfilter data,
/// melihat statistik tim secara kumulatif, serta mengakses laporan rinci per-pertandingan.

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/socket_service.dart';

// ─────────────────────────────────────────────
// DATA MODEL: MatchRecord
// ─────────────────────────────────────────────
/// Objek Model Data untuk menyimpan satu riwayat pertandingan sepak bola
class MatchRecord {
  final String tanggal;                    // Tanggal diselenggarakannya pertandingan
  final String lawan;                      // Nama tim lawan
  final String ?timKandang;                // Nama tim kandang (default: Real Madrid)
  final String skor;                       // Skor akhir pertandingan (misal: "3 - 1")
  final String hasil;                      // Hasil pertandingan: 'W' (Win/Menang), 'D' (Draw/Seri), 'L' (Loss/Kalah)
  final int totalSubstitusi;               // Jumlah pergantian pemain yang dilakukan
  final List<Map<String, dynamic>> statistikTim; // Statistik kumulatif tim (Possession, Shots, dll)
  final List<String> rekomendasi;          // Riwayat peringatan / rekomendasi dari Rule Engine yang terpicu
  final List<Map<String, dynamic>> performaPemain; // Nilai rating dan statistik performa individual tiap pemain

  const MatchRecord({
    required this.tanggal,
    required this.lawan,
    this.timKandang,
    required this.skor,
    required this.hasil,
    required this.totalSubstitusi,
    required this.statistikTim,
    required this.rekomendasi,
    required this.performaPemain,
  });
}

final List<MatchRecord> dummyMatches = [
  MatchRecord(
    tanggal: '10 Mar 2026',
    lawan: 'Manchester City',
    skor: '3 - 1',
    hasil: 'W',
    totalSubstitusi: 3,
    statistikTim: [
      {'label': 'Ball Possession', 'nilai': '58%'},
      {'label': 'Total Shots', 'nilai': '14'},
      {'label': 'Shots on Target', 'nilai': '8'},
      {'label': 'Passes', 'nilai': '512'},
      {'label': 'Fouls', 'nilai': '9'},
      {'label': 'Yellow Cards', 'nilai': '1'},
    ],
    rekomendasi: [
      '⚠️ Menit ke-62: Stamina Bellingham < 40% → Substitusi disarankan',
      '⚠️ Menit ke-78: Rating Mbappe turun di bawah 6.5 → Ganti formasi',
    ],
    performaPemain: [
      {
        'nama': 'Kylian Mbappe',
        'pos': 'FW',
        'rating': 8.5,
        'sprint': 28,
        'assist': 1,
        'gol': 2,
      },
      {
        'nama': 'Jude Bellingham',
        'pos': 'MF',
        'rating': 7.8,
        'sprint': 35,
        'assist': 2,
        'gol': 1,
      },
      {
        'nama': 'Vinicius Junior',
        'pos': 'FW',
        'rating': 7.2,
        'sprint': 30,
        'assist': 0,
        'gol': 0,
      },
      {
        'nama': 'Fede Valverde',
        'pos': 'MF',
        'rating': 7.5,
        'sprint': 40,
        'assist': 1,
        'gol': 0,
      },
    ],
  ),
  MatchRecord(
    tanggal: '05 Mar 2026',
    lawan: 'Liverpool',
    skor: '1 - 1',
    hasil: 'D',
    totalSubstitusi: 2,
    statistikTim: [
      {'label': 'Ball Possession', 'nilai': '45%'},
      {'label': 'Total Shots', 'nilai': '10'},
      {'label': 'Shots on Target', 'nilai': '4'},
      {'label': 'Passes', 'nilai': '438'},
      {'label': 'Fouls', 'nilai': '13'},
      {'label': 'Yellow Cards', 'nilai': '2'},
    ],
    rekomendasi: [
      '⚠️ Menit ke-55: Total sprint Valverde > 40 → Pertimbangkan istirahat',
      '⚠️ Menit ke-70: Stamina rata-rata tim < 55% → Tingkatkan intensitas pressing',
    ],
    performaPemain: [
      {
        'nama': 'Kylian Mbappe',
        'pos': 'FW',
        'rating': 7.0,
        'sprint': 22,
        'assist': 0,
        'gol': 1,
      },
      {
        'nama': 'Jude Bellingham',
        'pos': 'MF',
        'rating': 6.5,
        'sprint': 28,
        'assist': 1,
        'gol': 0,
      },
      {
        'nama': 'Antonio Rudiger',
        'pos': 'DF',
        'rating': 8.0,
        'sprint': 18,
        'assist': 0,
        'gol': 0,
      },
    ],
  ),
  MatchRecord(
    tanggal: '28 Feb 2026',
    lawan: 'Atletico Madrid',
    skor: '0 - 2',
    hasil: 'L',
    totalSubstitusi: 4,
    statistikTim: [
      {'label': 'Ball Possession', 'nilai': '40%'},
      {'label': 'Total Shots', 'nilai': '7'},
      {'label': 'Shots on Target', 'nilai': '2'},
      {'label': 'Passes', 'nilai': '380'},
      {'label': 'Fouls', 'nilai': '18'},
      {'label': 'Red Cards', 'nilai': '1'},
    ],
    rekomendasi: [
      '⚠️ Menit ke-40: Rating keseluruhan < 6.0 → Ubah taktik serangan',
      '⚠️ Menit ke-65: Pelanggaran > 15 → Waspadai kartu merah',
      '⚠️ Menit ke-80: Status = Kalah AND Stamina < 40% → Ganti 2 pemain',
    ],
    performaPemain: [
      {
        'nama': 'Kylian Mbappe',
        'pos': 'FW',
        'rating': 5.5,
        'sprint': 15,
        'assist': 0,
        'gol': 0,
      },
      {
        'nama': 'Vinicius Junior',
        'pos': 'FW',
        'rating': 5.8,
        'sprint': 12,
        'assist': 0,
        'gol': 0,
      },
      {
        'nama': 'Jude Bellingham',
        'pos': 'MF',
        'rating': 6.0,
        'sprint': 20,
        'assist': 0,
        'gol': 0,
      },
    ],
  ),
  MatchRecord(
    tanggal: '20 Feb 2026',
    lawan: 'Newcastle United',
    skor: '4 - 0',
    hasil: 'W',
    totalSubstitusi: 2,
    statistikTim: [
      {'label': 'Ball Possession', 'nilai': '65%'},
      {'label': 'Total Shots', 'nilai': '18'},
      {'label': 'Shots on Target', 'nilai': '12'},
      {'label': 'Passes', 'nilai': '620'},
      {'label': 'Fouls', 'nilai': '6'},
      {'label': 'Yellow Cards', 'nilai': '0'},
    ],
    rekomendasi: [
      '✅ Tidak ada rule kritis yang terpicu selama pertandingan',
      '⚠️ Menit ke-72: Rotasi pemain disarankan untuk jaga stamina',
    ],
    performaPemain: [
      {
        'nama': 'Kylian Mbappe',
        'pos': 'FW',
        'rating': 9.2,
        'sprint': 32,
        'assist': 2,
        'gol': 2,
      },
      {
        'nama': 'Vinicius Junior',
        'pos': 'FW',
        'rating': 8.8,
        'sprint': 35,
        'assist': 1,
        'gol': 1,
      },
      {
        'nama': 'Jude Bellingham',
        'pos': 'MF',
        'rating': 8.5,
        'sprint': 38,
        'assist': 3,
        'gol': 1,
      },
      {
        'nama': 'Antonio Rudiger',
        'pos': 'DF',
        'rating': 8.0,
        'sprint': 22,
        'assist': 0,
        'gol': 0,
      },
    ],
  ),
  MatchRecord(
    tanggal: '14 Feb 2026',
    lawan: 'Arsenal',
    skor: '2 - 2',
    hasil: 'D',
    totalSubstitusi: 3,
    statistikTim: [
      {'label': 'Ball Possession', 'nilai': '50%'},
      {'label': 'Total Shots', 'nilai': '12'},
      {'label': 'Shots on Target', 'nilai': '6'},
      {'label': 'Passes', 'nilai': '490'},
      {'label': 'Fouls', 'nilai': '11'},
      {'label': 'Yellow Cards', 'nilai': '2'},
    ],
    rekomendasi: [
      '⚠️ Menit ke-58: Stamina Bellingham 38% → Substitusi',
      '⚠️ Menit ke-80: Rating tim rata-rata 6.2 → Pertahankan bola lebih lama',
    ],
    performaPemain: [
      {
        'nama': 'Kylian Mbappe',
        'pos': 'FW',
        'rating': 7.5,
        'sprint': 24,
        'assist': 1,
        'gol': 1,
      },
      {
        'nama': 'Jude Bellingham',
        'pos': 'MF',
        'rating': 6.8,
        'sprint': 30,
        'assist': 1,
        'gol': 1,
      },
    ],
  ),
  MatchRecord(
    tanggal: '07 Feb 2026',
    lawan: 'Chelsea',
    skor: '1 - 0',
    hasil: 'W',
    totalSubstitusi: 1,
    statistikTim: [
      {'label': 'Ball Possession', 'nilai': '53%'},
      {'label': 'Total Shots', 'nilai': '11'},
      {'label': 'Shots on Target', 'nilai': '5'},
      {'label': 'Passes', 'nilai': '470'},
      {'label': 'Fouls', 'nilai': '10'},
      {'label': 'Yellow Cards', 'nilai': '1'},
    ],
    rekomendasi: [
      '✅ Rule stamina tidak terpicu — kondisi fisik tim baik',
      '⚠️ Menit ke-85: Pertahankan skor dan turunkan pressing',
    ],
    performaPemain: [
      {
        'nama': 'Kylian Mbappe',
        'pos': 'FW',
        'rating': 7.8,
        'sprint': 26,
        'assist': 0,
        'gol': 1,
      },
      {
        'nama': 'Fede Valverde',
        'pos': 'MF',
        'rating': 8.1,
        'sprint': 42,
        'assist': 1,
        'gol': 0,
      },
      {
        'nama': 'Antonio Rudiger',
        'pos': 'DF',
        'rating': 8.5,
        'sprint': 20,
        'assist': 0,
        'gol': 0,
      },
    ],
  ),
];

// ─────────────────────────────────────────────
// MAIN LIST SCREEN
// ─────────────────────────────────────────────
/// Widget Halaman Utama Riwayat Pertandingan
class RiwayatMatchScreen extends StatefulWidget {
  const RiwayatMatchScreen({super.key});

  @override
  State<RiwayatMatchScreen> createState() => _RiwayatMatchScreenState();
}

class _RiwayatMatchScreenState extends State<RiwayatMatchScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;        // Controller tab navigasi (Semua, Menang, Kalah/Seri)
  List<MatchRecord> _matches = dummyMatches; // State local daftar pertandingan (diisi dummy awal)

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // 1. Memastikan koneksi socket aktif dan meminta data terbaru
    SocketService().connect();
    SocketService().socket.emit('request_sync');

    // 2. Menerima sinkronisasi data riwayat pertandingan ('riwayat_sync') dari server Node.js
    SocketService().socket.on('riwayat_sync', (data) {
      if (mounted && data != null) {
        setState(() {
          // Melakukan pemetaan list objek dari server ke list model local MatchRecord
          final serverMatches = (data as List).map((item) {
            return MatchRecord(
              tanggal: item['tanggal'] ?? '',
              timKandang: item['timKandang'],
              lawan: item['lawan'] ?? '',
              skor: item['skor'] ?? '',
              hasil: item['hasil'] ?? '',
              totalSubstitusi: item['totalSubstitusi'] ?? 0,
              statistikTim: List<Map<String, dynamic>>.from(item['statistikTim'] ?? []),
              rekomendasi: List<String>.from(item['rekomendasi'] ?? []),
              performaPemain: List<Map<String, dynamic>>.from(item['performaPemain'] ?? []),
            );
          }).toList();

          // Menggabungkan data dari server di urutan teratas (terbaru) dengan data dummy statis
          _matches = [...serverMatches, ...dummyMatches];
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<MatchRecord> _filtered(String filter) {
    if (filter == 'all') return _matches;
    return _matches.where((m) => m.hasil == filter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        backgroundColor: context.bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.textPrimary),
          onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
        ),
        title: Text(
          'Riwayat Match',
          style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFFFF000),
          labelColor: const Color(0xFFFFF000),
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Semua'),
            Tab(text: 'Menang'),
            Tab(text: 'Kalah/Seri'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMatchList(_filtered('all')),
          _buildMatchList(_filtered('W')),
          _buildMatchList(_matches.where((m) => m.hasil != 'W').toList()),
        ],
      ),
    );
  }

  Widget _buildMatchList(List<MatchRecord> matches) {
    final wins = matches.where((m) => m.hasil == 'W').length;
    final draws = matches.where((m) => m.hasil == 'D').length;
    final losses = matches.where((m) => m.hasil == 'L').length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Summary bar
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.borderColor),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryBadge('${matches.length}', 'Total', Colors.white),
                _buildSummaryBadge('$wins', 'Menang', Colors.greenAccent),
                _buildSummaryBadge('$draws', 'Seri', Colors.orangeAccent),
                _buildSummaryBadge('$losses', 'Kalah', Colors.redAccent),
              ],
            ),
          ),
          SizedBox(height: 16),

          // Header row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: context.cardAltColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(flex: 2, child: _HeaderCell('TANGGAL')),
                Expanded(flex: 3, child: _HeaderCell('LAWAN')),
                Expanded(flex: 1, child: _HeaderCell('SKOR')),
                Expanded(flex: 1, child: _HeaderCell('HASIL')),
                Expanded(flex: 1, child: _HeaderCell('SUB')),
                Expanded(flex: 2, child: _HeaderCell('DETAIL')),
              ],
            ),
          ),
          SizedBox(height: 8),

          // Rows
          ...matches.map((m) => _buildMatchRow(m, context)),
        ],
      ),
    );
  }

  Widget _buildSummaryBadge(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        Text(label, style: TextStyle(color: context.textSecondary, fontSize: 11)),
      ],
    );
  }

  Widget _buildMatchRow(MatchRecord m, BuildContext context) {
    final Color hasilColor = m.hasil == 'W'
        ? Colors.greenAccent
        : m.hasil == 'D'
        ? Colors.orangeAccent
        : Colors.redAccent;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.borderColor),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              m.tanggal,
              style: TextStyle(color: context.textSecondary, fontSize: 11),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              m.lawan,
              style: TextStyle(
                color: context.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              m.skor,
              style: TextStyle(color: context.textPrimary, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: hasilColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  m.hasil,
                  style: TextStyle(
                    color: hasilColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: Text(
                '${m.totalSubstitusi}x',
                style: TextStyle(color: context.textSecondary, fontSize: 13),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: TextButton(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  backgroundColor: const Color(
                    0xFFFFF000,
                  ).withValues(alpha: 0.15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DetailMatchScreen(match: m),
                    ),
                  );
                },
                child: Text(
                  'Detail',
                  style: TextStyle(
                    color: Color(0xFFFFF000),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String text;
  _HeaderCell(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: context.textSecondary,
        fontSize: 10,
        fontWeight: FontWeight.bold,
        letterSpacing: 1,
      ),
    );
  }
}

// ─────────────────────────────────────────────
// DETAIL SCREEN
// ─────────────────────────────────────────────
class DetailMatchScreen extends StatelessWidget {
  final MatchRecord match;
  const DetailMatchScreen({super.key, required this.match});

  @override
  Widget build(BuildContext context) {
    final Color hasilColor = match.hasil == 'W'
        ? Colors.greenAccent
        : match.hasil == 'D'
        ? Colors.orangeAccent
        : Colors.redAccent;
    final String hasilLabel = match.hasil == 'W'
        ? 'MENANG'
        : match.hasil == 'D'
        ? 'SERI'
        : 'KALAH';

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
          'vs ${match.lawan}',
          style: TextStyle(
            color: context.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: hasilColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: hasilColor.withValues(alpha: 0.5)),
                ),
                child: Text(
                  hasilLabel,
                  style: TextStyle(
                    color: hasilColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Score hero card (Redesigned like Football Scoreboard)
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: context.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: Column(
                children: [
                  // Top section (Score & Teams)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Team 1
                        Expanded(
                          child: Column(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withValues(alpha: 0.1),
                                ),
                                child: const Icon(Icons.shield, color: Colors.white, size: 24),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                match.timKandang ?? 'Real Madrid',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: context.textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Score & Status
                        Column(
                          children: [
                            Text(
                              match.skor,
                              style: TextStyle(
                                color: context.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 32,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Full-time',
                                style: TextStyle(color: context.textPrimary, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              match.tanggal.split(',')[0],
                              style: TextStyle(color: context.textSecondary, fontSize: 10),
                            ),
                          ],
                        ),

                        // Team 2
                        Expanded(
                          child: Column(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withValues(alpha: 0.1),
                                ),
                                child: const Icon(Icons.sports_soccer, color: Colors.white, size: 24),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                match.lawan,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: context.textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Timeline section (Goals & Cards)
                  ..._buildMatchEventsTimeline(match),
                  const SizedBox(height: 8),
                ],
              ),
            ),
            SizedBox(height: 24),

            // A. Statistik Tim
            _buildSectionTitle('A. Statistik Tim'),
            SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.borderColor),
              ),
              child: Column(
                children: match.statistikTim.map((stat) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          stat['label'],
                          style: TextStyle(
                            color: context.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          stat['nilai'],
                          style: TextStyle(
                            color: context.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            SizedBox(height: 24),

            // B. Rekomendasi Rule Engine
            _buildSectionTitle('B. Rekomendasi Rule Engine'),
            SizedBox(height: 12),
            ...match.rekomendasi.map((rek) {
              final bool isAlert = rek.startsWith('⚠️');
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isAlert
                      ? context.alertBg
                      : context.successBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: (isAlert
                        ? context.alertBorder
                        : context.successBorder).withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isAlert ? Icons.warning_amber : Icons.check_circle,
                      color: isAlert ? context.alertText : context.successText,
                      size: 18,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        rek.replaceFirst('⚠️ ', '').replaceFirst('✅ ', ''),
                        style: TextStyle(
                          color: isAlert
                              ? context.alertText
                              : context.successText,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
            SizedBox(height: 24),

            // C. Performa Pemain
            _buildSectionTitle('C. Performa Pemain'),
            SizedBox(height: 12),
            // Table header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: context.cardAltColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(flex: 3, child: _HeaderCell('PEMAIN')),
                  Expanded(flex: 1, child: _HeaderCell('POS')),
                  Expanded(flex: 1, child: _HeaderCell('RTG')),
                  Expanded(flex: 1, child: _HeaderCell('SPRINT')),
                  Expanded(flex: 1, child: _HeaderCell('ASSIST')),
                  Expanded(flex: 1, child: _HeaderCell('GOL')),
                ],
              ),
            ),
            SizedBox(height: 6),
            ...match.performaPemain.map((p) {
              final double rating = p['rating'] as double;
              final Color ratingColor = rating >= 8.0
                  ? Colors.greenAccent
                  : rating >= 7.0
                  ? const Color(0xFFFFF000)
                  : Colors.redAccent;

              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: context.cardColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        p['nama'],
                        style: TextStyle(
                          color: context.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF636417),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          p['pos'],
                          style: TextStyle(
                            color: Color(0xFFFFF000),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        rating.toStringAsFixed(1),
                        style: TextStyle(
                          color: ratingColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        '${p['sprint']}',
                        style: TextStyle(
                          color: context.textSecondary,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        '${p['assist']}',
                        style: TextStyle(
                          color: context.textSecondary,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        '${p['gol']}',
                        style: TextStyle(
                          color: context.textSecondary,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              );
            }),
            SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            color: Color(0xFFFFF000),
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: Divider(
            color: const Color(0xFFFFF000).withValues(alpha: 0.2),
            height: 1,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildMatchEventsTimeline(MatchRecord match) {
    List<Widget> events = [];

    // Goals
    List<String> goalScorers = [];
    for (var p in match.performaPemain) {
      int gol = (p['gol'] ?? 0) as int;
      if (gol > 0) {
        List<dynamic> goalEvents = p['goalEvents'] ?? [];
        if (goalEvents.isNotEmpty) {
          String menitStr = goalEvents.map((m) => "$m'").join(', ');
          goalScorers.add('${p['nama']} ($menitStr)');
        } else {
          goalScorers.add('${p['nama']} ' + (gol > 1 ? '(x$gol)' : ''));
        }
      }
    }
    if (goalScorers.isNotEmpty) {
      events.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: goalScorers.map((name) => Text(name, style: const TextStyle(color: Colors.white70, fontSize: 13))).toList(),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Icon(Icons.sports_soccer, color: Colors.white, size: 16),
              ),
              const Expanded(child: SizedBox()), // Kosong untuk tim tamu
            ],
          ),
        ),
      );
    }

    // Assists
    List<String> assistMakers = [];
    for (var p in match.performaPemain) {
      int assist = (p['assist'] ?? 0) as int;
      if (assist > 0) {
        assistMakers.add('${p['nama']} ' + (assist > 1 ? '(x$assist)' : ''));
      }
    }
    if (assistMakers.isNotEmpty) {
      events.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: assistMakers.map((name) => Text(name, style: const TextStyle(color: Colors.white70, fontSize: 13))).toList(),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Icon(Icons.handshake_outlined, color: Colors.blueAccent, size: 16),
              ),
              const Expanded(child: SizedBox()), // Kosong untuk tim tamu
            ],
          ),
        ),
      );
    }

    // Cards
    List<Map<String, String>> cards = [];
    for (var p in match.performaPemain) {
      String kartu = (p['kartu'] ?? '-').toString();
      if (kartu == 'Kuning' || kartu == 'Merah') {
        cards.add({'nama': p['nama'].toString(), 'jenis': kartu});
      }
    }

    for (var card in cards) {
      events.add(
        Container(
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: Colors.white12, width: 1)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(card['nama']!, textAlign: TextAlign.right, style: const TextStyle(color: Colors.white70, fontSize: 13)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Container(
                  width: 12,
                  height: 16,
                  decoration: BoxDecoration(
                    color: card['jenis'] == 'Merah' ? Colors.red : Colors.yellow,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Expanded(child: SizedBox()), // Kosong untuk tim tamu
            ],
          ),
        ),
      );
    }

    if (events.isEmpty) {
      return [];
    }

    return [
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Divider(color: Colors.white12),
      ),
      const SizedBox(height: 8),
      ...events,
    ];
  }
}
