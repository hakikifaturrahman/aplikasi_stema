/// Halaman Pemantauan Stamina Pemain secara Real-time
/// 
/// Halaman ini menampilkan visualisasi grafik tren stamina mingguan pemain,
/// indikator level stamina saat ini (siap tanding/mulai terkuras/kritis),
/// dan form input data sesi latihan fisik pemain (Stamina awal/akhir, jarak lari, intensitas).
/// Terhubung dengan server Node.js melalui Socket.IO.

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:convert';
import '../main.dart';
import '../theme/app_theme.dart';
import '../services/socket_service.dart';

/// Widget Halaman Pemantauan Fisik: MonitoringStaminaScreen
class MonitoringStaminaScreen extends StatefulWidget {
  const MonitoringStaminaScreen({super.key});

  @override
  State<MonitoringStaminaScreen> createState() =>
      _MonitoringStaminaScreenState();
}

class _MonitoringStaminaScreenState extends State<MonitoringStaminaScreen> {
  // ── State Pemantauan Stamina Pemain ──
  String _selectedPlayer = 'Fede Valverde';    // Pemain aktif yang dipilih untuk dimonitor staminanya
  String _intensitas = 'Medium';                // Nilai intensitas latihan default
  List<Map<String, dynamic>> _players = [];      // Menyimpan daftar seluruh pemain yang disinkronkan dari server
  String? _myProfileBase64;                     // Menyimpan foto profil pengguna aktif saat ini (Base64)

  @override
  void initState() {
    super.initState();
    // 1. Menggunakan koneksi Socket.IO global
    SocketService().connect();

    // 2. Mengirim event 'request_sync' ke server saat halaman diinisialisasi
    SocketService().socket.emit('request_sync');

    // 3. Menerima sinkronisasi data stamina pemain secara real-time via event 'stamina_sync'
    SocketService().socket.on('stamina_sync', (data) {
      if (mounted && data != null) {
        setState(() {
          // Update data players secara global di screen ini
          _players = List<Map<String, dynamic>>.from(
              data.map((item) => Map<String, dynamic>.from(item)));
          
          if (_players.isNotEmpty) {
            bool found = _players.any((p) => p['nama'] == _selectedPlayer);
            if (!found) {
               _selectedPlayer = _players.first['nama'];
            }
          }
        });
      }
    });

    // 4. Menerima sinkronisasi data user/profil pelatih via event 'user_sync'
    SocketService().socket.on('user_sync', (data) {
      if (mounted && data != null) {
        setState(() {
          _myProfileBase64 = data['foto']; // Sinkronisasi gambar profil
        });
      }
    });
  }

  /// Properti Helper: Mendapatkan string base64 foto dari pemain yang sedang dipilih saat ini
  String? get _currentImageBase64 {
    try {
      final p = _players.firstWhere((p) => p['nama'] == _selectedPlayer);
      return p['foto'];
    } catch (e) {
      return null;
    }
  }

  // ── Controller Input Formulir Latihan Fisik Pemain ──
  final _staminaAwalCtrl = TextEditingController(text: '85');
  final _staminaAkhirCtrl = TextEditingController(text: '60');
  final _jarakLariCtrl = TextEditingController(text: '8.5');

  @override
  void dispose() {
    // Membersihkan listener socket agar tidak memakan memori berlebih
    SocketService().socket.off('stamina_sync');
    SocketService().socket.off('user_sync');

    // Menghancurkan controller input teks
    _staminaAwalCtrl.dispose();
    _staminaAkhirCtrl.dispose();
    _jarakLariCtrl.dispose();
    super.dispose();
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
        title: const Text('Monitoring Stamina'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileHeader(),
            const SizedBox(height: 24),
            _buildKondisiFisikCard(),
            const SizedBox(height: 16),
            _buildTrenStaminaCard(),
            const SizedBox(height: 24),
            _buildInputHeader(),
            const SizedBox(height: 16),
            _buildInputFields(),
            const SizedBox(height: 24),
            _buildSimpanButton(),
            const SizedBox(height: 32),
            _buildLegend(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    Map<String, dynamic> currentPlayer = {};
    if (_players.isNotEmpty) {
       currentPlayer = _players.firstWhere((p) => p['nama'] == _selectedPlayer, orElse: () => {});
    }
    final String pos = currentPlayer['pos'] ?? 'MF';
    final String status = currentPlayer['status'] ?? 'Main';
    
    return Row(
      children: [
        Stack(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFFFF000), width: 3),
              ),
              child: CircleAvatar(
                backgroundColor: const Color(0xFF242217),
                backgroundImage: _currentImageBase64 != null
                    ? MemoryImage(base64Decode(_currentImageBase64!)) as ImageProvider
                    : null,
                child: _currentImageBase64 == null
                    ? const Icon(Icons.person, color: Colors.grey, size: 40)
                    : null,
              ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.greenAccent,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF1B1A12), width: 2),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF242217),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF404040)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    dropdownColor: const Color(0xFF242217),
                    value: _selectedPlayer,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
                    items: _players.isEmpty 
                        ? [DropdownMenuItem<String>(value: _selectedPlayer, child: Text(_selectedPlayer))]
                        : _players.map((p) {
                            final String name = p['nama'].toString();
                            return DropdownMenuItem<String>(
                              value: name,
                              child: Text(name),
                            );
                        }).toList(),
                    onChanged: (v) {
                      setState(() {
                        _selectedPlayer = v!;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                pos == 'FW' ? 'Penyerang' : pos == 'MF' ? 'Gelandang' : pos == 'DF' ? 'Bek' : 'Kiper',
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 6),
              Text(
                status.toUpperCase(),
                style: TextStyle(
                  color: status.contains('Cedera') ? Colors.redAccent : Colors.greenAccent,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildKondisiFisikCard() {
    int staminaInfo = 85; 
    String statusFisik = "MEMUAT...";
    Color warnaFisik = Colors.grey;

    if (_players.isNotEmpty) {
      final player = _players.firstWhere(
        (p) => p['nama'] == _selectedPlayer,
        orElse: () => <String, dynamic>{},
      );
      if (player.isNotEmpty) {
        staminaInfo = player['stamina'] as int? ?? 0;
        if (staminaInfo >= 70) {
          statusFisik = "SIAP TANDING";
          warnaFisik = Colors.greenAccent;
        } else if (staminaInfo >= 40) {
          statusFisik = "MULAI TERKURAS";
          warnaFisik = const Color(0xFFFFF000);
        } else {
          statusFisik = "KRITIS (BUTUH GANTI)";
          warnaFisik = Colors.redAccent;
        }
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF242217),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'KONDISI FISIK SAAT INI (LIVE SERVER)',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$staminaInfo%',
                style: TextStyle(
                  color: warnaFisik,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: warnaFisik.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  statusFisik,
                  style: TextStyle(
                    color: warnaFisik,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Animating the bar using AnimatedContainer is even better for real-time
          Container(
            height: 12,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF333322),
              borderRadius: BorderRadius.circular(6),
            ),
            alignment: Alignment.centerLeft,
            child: AnimatedFractionallySizedBox(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOut,
              widthFactor: (staminaInfo / 100.0).clamp(0.0, 1.0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                decoration: BoxDecoration(
                  color: warnaFisik,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'LEMAH',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'OPTIMAL',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrenStaminaCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF242217),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tren Stamina Mingguan',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: const [
                  Icon(Icons.trending_up, color: Colors.greenAccent, size: 16),
                  SizedBox(width: 4),
                  Text(
                    '+5%',
                    style: TextStyle(
                      color: Colors.greenAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 120,
            child: LineChart(
              LineChartData(
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 70),
                      FlSpot(1, 85),
                      FlSpot(2, 60),
                      FlSpot(3, 80),
                      FlSpot(4, 90),
                      FlSpot(5, 85),
                      FlSpot(6, 75),
                    ],
                    isCurved: true,
                    color: const Color(0xFFFFF000),
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(show: false),
                  ),
                ],
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1, // Ini sangat penting agar hari (SenSelRab) tidak tercetak double/ganda (ex: Sen Sen Sel Sel)
                      getTitlesWidget: (value, meta) {
                        final days = [
                          'Sen',
                          'Sel',
                          'Rab',
                          'Kam',
                          'Jum',
                          'Sab',
                          'Min',
                        ];
                        if (value >= 0 && value < days.length) {
                          bool isRab = days[value.toInt()] == 'Rab';
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              days[value.toInt()],
                              style: TextStyle(
                                color: isRab ? Colors.white : Colors.grey,
                                fontSize: 11,
                                fontWeight: isRab
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                decoration: isRab
                                    ? TextDecoration.underline
                                    : TextDecoration.none,
                              ),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: 6,
                minY: 50,
                maxY: 100,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputHeader() {
    return Builder(builder: (context) {
      return Row(
        children: [
          const Icon(Icons.edit, color: Color(0xFFFFF000)),
          const SizedBox(width: 12),
          Text(
            'Input Data Fisik Latihan',
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyMedium?.color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      );
    });
  }

  Widget _buildInputFields() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildTextField(context, 'Stamina Awal (%)', _staminaAwalCtrl),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextField(context, 'Stamina Akhir (%)', _staminaAkhirCtrl),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildTextField(context, 'Jarak Lari (km)', _jarakLariCtrl)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Intensitas',
                    style: TextStyle(color: context.textSecondary, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 0,
                    ),
                    height: 48,
                    decoration: BoxDecoration(
                      color: context.cardAltColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: context.borderColor,
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        dropdownColor: context.cardAltColor,
                        value: _intensitas,
                        style: TextStyle(
                          color: context.textPrimary,
                          fontSize: 14,
                        ),
                        icon: Icon(
                          Icons.keyboard_arrow_down,
                          color: context.iconMuted,
                        ),
                        items: ['Low', 'Medium', 'High'].map((String item) {
                          return DropdownMenuItem<String>(
                            value: item,
                            child: Text(item),
                          );
                        }).toList(),
                        onChanged: (v) {
                          setState(() {
                            _intensitas = v!;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTextField(BuildContext context, String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: context.textSecondary, fontSize: 12)),
        const SizedBox(height: 6),
        SizedBox(
          height: 48,
          child: TextFormField(
            controller: controller,
            keyboardType: TextInputType.number,
            style: TextStyle(color: context.textPrimary, fontSize: 14),
            decoration: InputDecoration(
              filled: true,
              fillColor: context.cardAltColor,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 0,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: context.borderColor,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: context.borderColor,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: context.isDark ? const Color(0xFFFFF000) : const Color(0xFF8B7A00),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSimpanButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Data stamina berhasil disimpan!')),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFFF000),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'Simpan Data Sesi',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildLegendItem(Colors.greenAccent, 'HIJAU (>=70%)'),
        _buildLegendItem(const Color(0xFFFFF000), 'KUNING (40-69%)'),
        _buildLegendItem(Colors.redAccent, 'MERAH (<40%)'),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Builder(builder: (context) {
      return Row(
        children: [
          CircleAvatar(radius: 4, backgroundColor: color),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: Theme.of(context).textTheme.bodySmall?.color,
              fontSize: 10,
              letterSpacing: 1.0,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      );
    });
  }
}
