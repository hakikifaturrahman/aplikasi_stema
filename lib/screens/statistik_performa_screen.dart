import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../main.dart';
import '../services/socket_service.dart';

class StatistikPerformaScreen extends StatefulWidget {
  const StatistikPerformaScreen({super.key});

  @override
  State<StatistikPerformaScreen> createState() => _StatistikPerformaScreenState();
}

class _StatistikPerformaScreenState extends State<StatistikPerformaScreen> {
  List<dynamic> _players = [];
  List<dynamic> _riwayat = [];
  String? _selectedPlayerName;
  String _selectedMatchPeriode = 'Semua Data';

  @override
  void initState() {
    super.initState();
    // Inisialisasi koneksi dan minta data ke server
    SocketService().connect();
    SocketService().socket.emit('request_sync');

    // Dengarkan data dari server
    SocketService().socket.on('stamina_sync', (data) {
      if (mounted) {
        setState(() {
          _players = data;
          if (_selectedPlayerName == null && _players.isNotEmpty) {
            _selectedPlayerName = _players.first['nama'];
          }
        });
      }
    });

    SocketService().socket.on('riwayat_sync', (data) {
      if (mounted) {
        setState(() {
          _riwayat = data;
        });
      }
    });
  }

  // Helper untuk mendapatkan data stats pemain saat ini
  Map<String, dynamic>? get _currentPlayer {
    if (_players.isEmpty || _selectedPlayerName == null) return null;
    try {
      return _players.firstWhere((p) => p['nama'] == _selectedPlayerName);
    } catch (_) {
      return null;
    }
  }

  // Mendapatkan histori performa 5 pertandingan terakhir untuk pemain tertentu
  List<double> get _recentRatings {
    if (_riwayat.isEmpty || _selectedPlayerName == null) return [];
    
    List<double> ratings = [];
    // Riwayat index paling kecil (0) artinya match paling baru dari backend (unshift)
    for (var match in _riwayat) {
      if (match['performaPemain'] != null) {
        for (var pInfo in match['performaPemain']) {
          if (pInfo['nama'] == _selectedPlayerName) {
            // Bisa float, parse to double
            double rating = double.tryParse(pInfo['rating'].toString()) ?? 6.0;
            ratings.add(rating);
            break; // Ditemukan di match ini
          }
        }
      }
      if (ratings.length >= 5) break; 
    }
    
    // Reverse agar berurutan dari terlama ke terbaru
    return ratings.reversed.toList();
  }

  @override
  Widget build(BuildContext context) {
    bool isLoading = _players.isEmpty;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            MainLayout.goToHome(context);
          },
        ),
        title: const Text('Statistik Performa'),
        actions: [
          IconButton(icon: const Icon(Icons.share), onPressed: () {}),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF000),
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                icon: const Icon(Icons.add_chart, color: Colors.black),
                onPressed: () {
                  Navigator.pushNamed(context, '/tambah_statistik');
                },
              ),
            ),
          ),
        ],
      ),
      body: isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFF000)))
        : SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Periode/Filter',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 8),
            _buildPeriodeDropdown(),
            const SizedBox(height: 16),
            const Text(
              'Pilih Pemain',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 8),
            _buildPlayerDropdown(),
            const SizedBox(height: 24),
            _buildMatchSummaryCard(),
            const SizedBox(height: 24),
            _buildRadarChartCard(),
            const SizedBox(height: 24),
            _buildLineChartCard(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodeDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF242217),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          dropdownColor: const Color(0xFF242217),
          value: _selectedMatchPeriode,
          items: ['Semua Data', 'Bulan Ini', 'Minggu Ini'].map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 16)),
            );
          }).toList(),
          onChanged: (newValue) {
            setState(() {
              _selectedMatchPeriode = newValue!;
            });
          },
        ),
      ),
    );
  }

  Widget _buildPlayerDropdown() {
    List<String> playerNames = _players.map((p) => p['nama'].toString()).toSet().toList();
    if (_selectedPlayerName != null && !playerNames.contains(_selectedPlayerName)) {
      playerNames.add(_selectedPlayerName!);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF242217),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          dropdownColor: const Color(0xFF242217),
          value: _selectedPlayerName,
          items: playerNames.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 16)),
            );
          }).toList(),
          onChanged: (newValue) {
            setState(() {
              _selectedPlayerName = newValue;
            });
          },
        ),
      ),
    );
  }

  Widget _buildMatchSummaryCard() {
    // Ambil rating terbaru
    double latestRating = 0.0;
    int latestSprints = 0;
    
    if (_riwayat.isNotEmpty && _selectedPlayerName != null) {
      for (var match in _riwayat) {
        if (match['performaPemain'] != null) {
          for(var pInfo in match['performaPemain']){
            if(pInfo['nama'] == _selectedPlayerName){
               latestRating = double.tryParse(pInfo['rating'].toString()) ?? 0.0;
               latestSprints = int.tryParse(pInfo['sprint']?.toString() ?? '0') ?? 0;
               break;
            }
          }
        }
        if (latestRating > 0) break; // Berhenti jika sudah menemukan rating di match terbaru
      }
    }

    // Fallback jika belum pernah main
    if (latestRating == 0.0) latestRating = 6.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF000),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'MATCH LATEST PERTANDINGAN',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _selectedPlayerName?.toUpperCase() ?? 'PEMAIN',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'TOTAL SPRINT',
                          style: TextStyle(
                            color: Colors.black54,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$latestSprints',
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 24),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'RATING',
                          style: TextStyle(
                            color: Colors.black54,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          latestRating.toStringAsFixed(1),
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF1B1A12),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black, width: 2),
            ),
            alignment: Alignment.center,
            child: Text(
              latestRating.toStringAsFixed(1),
              style: const TextStyle(
                color: Color(0xFFFFF000),
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRadarChartCard() {
    final player = _currentPlayer;
    Map<String, dynamic> attr = player?['attributes'] ?? {
       'speed': 70, 'shooting': 70, 'passing': 70, 'defensive': 70, 'vision': 70, 'stamina': 70, 'dribbling': 70
    };

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
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF000),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.bar_chart,
                  color: Colors.black,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Analisis Skill Atribut',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 60),
          SizedBox(
            height: 250,
            child: RadarChart(
              RadarChartData(
                dataSets: [
                  RadarDataSet(
                    fillColor: const Color(0xFFFFF000).withValues(alpha: 0.4),
                    borderColor: Colors.transparent,
                    entryRadius: 0,
                    dataEntries: [
                      RadarEntry(value: double.parse(attr['speed'].toString())),
                      RadarEntry(value: double.parse(attr['shooting'].toString())),
                      RadarEntry(value: double.parse(attr['passing'].toString())),
                      RadarEntry(value: double.parse(attr['defensive'].toString())),
                      RadarEntry(value: double.parse(attr['vision'].toString())),
                      RadarEntry(value: double.parse(attr['stamina'].toString())),
                    ],
                  ),
                ],
                radarBackgroundColor: Colors.transparent,
                borderData: FlBorderData(show: false),
                radarBorderData: const BorderSide(color: Colors.white12),
                tickCount: 4,
                ticksTextStyle: const TextStyle(color: Colors.transparent),
                tickBorderData: const BorderSide(color: Colors.white12),
                gridBorderData: const BorderSide(color: Colors.white12),
                radarShape: RadarShape.polygon,
                getTitle: (index, angle) {
                  final titles = [
                    'SPEED',
                    'SHOOTING',
                    'PASSING',
                    'DEFENSIVE',
                    'VISION',
                    'STAMINA',
                  ];
                  return RadarChartTitle(text: titles[index], angle: angle);
                },
                titleTextStyle: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B1A12),
                    borderRadius: BorderRadius.circular(8),
                    border: const Border(
                      left: BorderSide(color: Color(0xFFFFF000), width: 4),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'DRIBBLING',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${attr['dribbling']}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B1A12),
                    borderRadius: BorderRadius.circular(8),
                    border: const Border(
                      left: BorderSide(color: Color(0xFFFFF000), width: 4),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'PASSING',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${attr['passing']}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLineChartCard() {
    List<double> recentRatings = _recentRatings;
    
    // Jika tidak ada data histori
    if (recentRatings.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF242217),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Text(
              'Belum ada riwayat pertandingan',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ),
      );
    }
    
    // Siapkan titik data minimal 2 (agar bisa digambar), sisanya isi ulang nilai terakhir atau pad.
    // FlSpot butuh x ganjil dan y minimal > 0.
    List<FlSpot> spots = [];
    for (int i = 0; i < recentRatings.length; i++) {
      spots.add(FlSpot(i.toDouble(), recentRatings[i]));
    }
    // minimal line chart punya titik
    if (spots.length == 1) {
       spots.insert(0, FlSpot(-1, spots.first.y)); // padding awal supaya jadi line 
    }

    double minScore = recentRatings.reduce((a, b) => a < b ? a : b);
    double maxScore = recentRatings.reduce((a, b) => a > b ? a : b);
    
    // Margin untuk chart Y axis
    double minY = (minScore - 1.0).clamp(0.0, 10.0);
    double maxY = (maxScore + 1.0).clamp(0.0, 10.0);

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
            children: [
              const Icon(Icons.timeline, color: Color(0xFFFFF000), size: 18),
              const SizedBox(width: 12),
              Text(
                'Tren Performa (${recentRatings.length} Match Terakhir)',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: const Color(0xFFFFF000),
                    barWidth: 4,
                    dotData: FlDotData(
                      show: true,
                      checkToShowDot: (spot, barData) => true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: const Color(0xFFFFF000),
                          strokeWidth: 0,
                        );
                      },
                    ),
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
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        // Offset the negative padding if used
                        int val = value.toInt();
                        if (val < 0) return const Text('');
                        final label = 'M${val + 1}';
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            label,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                minX: spots.first.x,
                maxX: spots.last.x,
                minY: minY,
                maxY: maxY,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Terendah: ${minScore.toStringAsFixed(1)}',
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                ),
              ),
              Text(
                'Tertinggi: ${maxScore.toStringAsFixed(1)}',
                style: const TextStyle(
                  color: Color(0xFFFFF000),
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

