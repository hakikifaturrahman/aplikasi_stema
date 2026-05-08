import 'package:flutter/material.dart';
import 'dart:async';
import '../theme/app_theme.dart';
import '../services/socket_service.dart';
import '../main.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // ── Live Match Simulation State ──
  int _skor1 = 0; // Tim kita
  int _skor2 = 0; // Lawan
  int _menit = 0; // Dimulai dari 0
  bool _isLive = false;
  Timer? _timer;

  // State Ekstra Waktu, Penalti & Fase
  String _fase = 'Persiapan'; // Babak 1, Half Time, Babak 2, Extra Time 1, dll
  int _tambahanWaktu = 0;
  int _menitLebih = 0;
  int _penalti1 = 0;
  int _penalti2 = 0;
  final TextEditingController _injuryCtrl = TextEditingController();

  int _shots = 0;
  int _shotsOnTarget = 0;
  final TextEditingController _possessionCtrl = TextEditingController();
  final TextEditingController _passesCtrl = TextEditingController();

  // Notifications State (Kini diamankan di global main.dart)

  // Nama Tim Dinamis
  String _timKandang = 'Real Madrid';
  String _timTandang = 'Manchester City';

  final List<String> _timList = [
    'AC Milan',
    'Ajax',
    'Arsenal',
    'AS Roma',
    'Aston Villa',
    'Atletico Madrid',
    'Barcelona',
    'Bayer Leverkusen',
    'Bayern Munich',
    'Benfica',
    'Borussia Dortmund',
    'Chelsea',
    'FC Porto',
    'Fenerbahce',
    'Feyenoord',
    'Galatasaray',
    'Inter Milan',
    'Juventus',
    'Liverpool',
    'Manchester City',
    'Manchester United',
    'Napoli',
    'Newcastle United',
    'Olympique Lyonnais',
    'Olympique Marseille',
    'PSG',
    'PSV Eindhoven',
    'RB Leipzig',
    'Sevilla',
    'Sporting CP',
    'Tottenham Hotspur',
  ];

  // ── Data Pemain (bersumber dari backend via websocket) ──
  List<Map<String, dynamic>> _players = [
    {
      'nama': 'Kylian Mbappe',
      'no': 9,
      'pos': 'FW',
      'stamina': 78,
      'status': 'Main',
    },
    {
      'nama': 'Jude Bellingham',
      'no': 8,
      'pos': 'MF',
      'stamina': 35,
      'status': 'Main',
    },
    {
      'nama': 'Vinicius Junior',
      'no': 7,
      'pos': 'FW',
      'stamina': 62,
      'status': 'Main',
    },
    {
      'nama': 'Fede Valverde',
      'no': 15,
      'pos': 'MF',
      'stamina': 55,
      'status': 'Main',
    },
    {
      'nama': 'Antonio Rudiger',
      'no': 22,
      'pos': 'DF',
      'stamina': 88,
      'status': 'Main',
    },
    {
      'nama': 'Eduardo Camavinga',
      'no': 12,
      'pos': 'MF',
      'stamina': 100,
      'status': 'Cadangan',
    },
    {
      'nama': 'Thibaut Courtois',
      'no': 1,
      'pos': 'GK',
      'stamina': 0,
      'status': 'Cedera',
    },
    {
      'nama': 'Eder Militao',
      'no': 3,
      'pos': 'DF',
      'stamina': 0,
      'status': 'Cedera',
    },
  ];

  int get _aktif => _players.where((p) => p['status'] == 'Main').length;
  int get _cedera => _players
      .where((p) => p['status'] == 'Cedera' || p['status'] == 'Tidak Hadir')
      .length;
  double get _avgStamina {
    final aktifPlayers = _players
        .where((p) => p['status'] == 'Main' || p['status'] == 'Pemanasan')
        .toList();
    if (aktifPlayers.isEmpty) return 0;
    return aktifPlayers
            .map((p) => p['stamina'] as int)
            .reduce((a, b) => a + b) /
        aktifPlayers.length;
  }

  double get _avgRating => 7.4;

  List<Map<String, dynamic>> get _kritisPlayers => _players
      .where(
        (p) =>
            (p['status'] == 'Main' || p['status'] == 'Pemanasan') &&
            p['stamina'] < 40,
      )
      .toList();

  String get _statusPertandingan {
    if (_skor1 > _skor2) return 'MENANG';
    if (_skor1 == _skor2) return 'SERI';
    return 'KALAH';
  }

  Color get _statusColor {
    if (_skor1 > _skor2) return Colors.greenAccent;
    if (_skor1 == _skor2) return Colors.orangeAccent;
    return Colors.redAccent;
  }

  @override
  void initState() {
    super.initState();
    _startLiveTimer();
    _setupSocketListeners();
    // Meminta data sekurangnya saat pertama kali load agar tidak stuck di hardcoded list
    SocketService().socket.emit('request_sync');

    // 4. (Alarm Rule Engine kini ditangani secara Global di main.dart supaya tidak terhapus)
  }

  void _setupSocketListeners() {
    // 1. Memulai Koneksi Socket.IO
    SocketService().connect();

    // 2. Mendengar Sinkronisasi Data Skor Match ("live_match_sync") dari Server
    SocketService().socket.off('live_match_sync');
    SocketService().socket.on('live_match_sync', (data) {
      if (mounted && data != null) {
        setState(() {
          _skor1 = data['skor1'] ?? _skor1;
          _skor2 = data['skor2'] ?? _skor2;
          _menit = data['menit'] ?? _menit;
          _isLive = data['isLive'] ?? _isLive;
          _fase = data['fase'] ?? _fase;
          _menitLebih = data['menitLebih'] ?? _menitLebih;
          _penalti1 = data['penalti1'] ?? _penalti1;
          _penalti2 = data['penalti2'] ?? _penalti2;
        });
      }
    });

    // 3. Mendengar Sinkronisasi STAMINA ("stamina_sync") dari Server
    SocketService().socket.off('stamina_sync');
    SocketService().socket.on('stamina_sync', (data) {
      if (mounted && data != null) {
        setState(() {
          // Data berupa List of Map yang dikirim dari server
          _players = List<Map<String, dynamic>>.from(
            data.map((item) => Map<String, dynamic>.from(item)),
          );
        });
      }
    });
  }

  void _startLiveTimer() {
    _timer = Timer.periodic(const Duration(seconds: 4), (t) {
      if (!_isLive) return;

      setState(() {
        if (_fase == 'Babak 1') {
          if (_menit < 45) {
            _menit++;
          } else {
            _isLive = false;
            _fase = 'Tunggu Injury 45';
          }
        } else if (_fase == 'Injury 45') {
          if (_menitLebih < _tambahanWaktu) {
            _menitLebih++;
          } else {
            _isLive = false;
            _fase = 'Half Time';
            _showStaminaPresentationDialog();
          }
        } else if (_fase == 'Babak 2') {
          if (_menit < 90) {
            _menit++;
          } else {
            _isLive = false;
            _fase = 'Tunggu Injury 90';
          }
        } else if (_fase == 'Injury 90') {
          if (_menitLebih < _tambahanWaktu) {
            _menitLebih++;
          } else {
            _isLive = false;
            if (_skor1 == _skor2) {
              _fase = 'Tunggu Extra Time';
            } else {
              _fase = 'Full Time';
            }
            _showStaminaPresentationDialog();
          }
        } else if (_fase == 'Extra Time 1') {
          if (_menit < 105) {
            _menit++;
          } else {
            _isLive = false;
            _fase = 'Tunggu Injury 105';
          }
        } else if (_fase == 'Injury 105') {
          if (_menitLebih < _tambahanWaktu) {
            _menitLebih++;
          } else {
            _isLive = false;
            _fase = 'Jeda ET';
            _showStaminaPresentationDialog();
          }
        } else if (_fase == 'Extra Time 2') {
          if (_menit < 120) {
            _menit++;
          } else {
            _isLive = false;
            _fase = 'Tunggu Injury 120';
          }
        } else if (_fase == 'Injury 120') {
          if (_menitLebih < _tambahanWaktu) {
            _menitLebih++;
          } else {
            _isLive = false;
            if (_skor1 == _skor2) {
              _fase = 'Penalti';
            } else {
              _fase = 'Full Time';
            }
            _showStaminaPresentationDialog();
          }
        }
      });

      SocketService().socket.emit('update_match', {
        'skor1': _skor1,
        'skor2': _skor2,
        'menit': _menit,
        'isLive': _isLive,
        'fase': _fase,
        'menitLebih': _menitLebih,
        'penalti1': _penalti1,
        'penalti2': _penalti2,
      });
    });
  }

  void _inputInjury(String nextPhase) {
    _injuryCtrl.text = '3'; // Default 3 menit
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: context.cardColor,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Data dari Wasit', style: TextStyle(color: Colors.white, fontSize: 18)),
              InkWell(
                onTap: () => Navigator.pop(ctx),
                child: const Icon(Icons.close, color: Colors.white70),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Masukkan Tambahan Waktu (Menit):',
                style: TextStyle(color: Colors.white70),
              ),
              SizedBox(height: 12),
              TextField(
                controller: _injuryCtrl,
                keyboardType: TextInputType.number,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.black26,
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _tambahanWaktu = int.tryParse(_injuryCtrl.text) ?? 1;
                  _menitLebih = 0;
                  _fase = nextPhase;
                  _isLive = true;
                });
                Navigator.pop(ctx);
              },
              child: Text(
                'Mulai Injury Time',
                style: TextStyle(
                  color: Color(0xFFFFF000),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _possessionCtrl.dispose();
    _passesCtrl.dispose();
    super.dispose();
  }

  void _showNotificationPanel() {
    setState(() {
      globalHasUnreadNotification = false;
    });

    showModalBottomSheet(
      context: context,
      backgroundColor: context.bgColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Riwayat Notifikasi',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: context.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: context.textSecondary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(color: Colors.white24),
              Expanded(
                child: globalNotifications.isEmpty
                    ? Center(
                        child: Text(
                          'Belum ada notifikasi.',
                          style: TextStyle(color: context.textSecondary),
                        ),
                      )
                    : ListView.builder(
                        itemCount: globalNotifications.length,
                        itemBuilder: (context, index) {
                          final notif = globalNotifications[index];
                          final isCritical = notif['level'] == 'CRITICAL';

                          // Format time
                          final dt = notif['time'] as DateTime;
                          final timeStr =
                              "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";

                          return ListTile(
                            leading: Icon(
                              isCritical
                                  ? Icons.warning_rounded
                                  : Icons.info_outline,
                              color: isCritical
                                  ? Colors.redAccent
                                  : const Color(0xFFFFF000),
                            ),
                            title: Text(
                              notif['message'],
                              style: TextStyle(
                                color: context.textPrimary,
                                fontSize: 13,
                              ),
                            ),
                            subtitle: Text(
                              timeStr,
                              style: TextStyle(
                                color: context.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 4,
                              horizontal: 8,
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Presentasi Stamina Pemain Setelah Break ──
  void _showStaminaPresentationDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.bgColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final mainPlayers = _players
            .where((p) => p['status'] == 'Main' || p['status'] == 'Pemanasan')
            .toList();
        final subPlayers = _players
            .where((p) => p['status'] == 'Cadangan')
            .toList();

        return FractionallySizedBox(
          heightFactor: 0.85,
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Laporan Stamina Pemain\n($_fase)',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: context.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStaminaGroup(
                        'Pemain Utama & Pemanasan',
                        mainPlayers,
                        context,
                      ),
                      const SizedBox(height: 20),
                      _buildStaminaGroup(
                        'Pemain Cadangan',
                        subPlayers,
                        context,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStaminaGroup(
    String title,
    List<Map<String, dynamic>> players,
    BuildContext context,
  ) {
    if (players.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: const Color(0xFFFFF000),
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 10),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: players.length,
          separatorBuilder: (ctx, idx) =>
              const Divider(color: Colors.white12, height: 1),
          itemBuilder: (ctx, idx) {
            final p = players[idx];
            final int stamina = p['stamina'] as int? ?? 0;
            final Color color = stamina >= 70
                ? Colors.greenAccent
                : (stamina >= 40 ? Colors.orangeAccent : Colors.redAccent);
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: context.cardColor,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '#${p['no']}',
                  style: TextStyle(
                    color: context.textSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(
                p['nama'],
                style: TextStyle(
                  color: context.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                p['pos'],
                style: TextStyle(color: context.textSecondary, fontSize: 12),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 60,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: stamina / 100,
                        backgroundColor: Colors.white12,
                        color: color,
                        minHeight: 6,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '$stamina%',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  // ── Rekomendasi dari Rule Engine ──
  List<Map<String, dynamic>> get _rekomendasi {
    final List<Map<String, dynamic>> result = [];
    for (final p in _players) {
      if ((p['status'] == 'Main' || p['status'] == 'Pemanasan') &&
          p['stamina'] < 40) {
        result.add({
          'level': 'critical',
          'pesan':
              'Pemain #${p['no']} ${p['nama']} stamina rendah (${p['stamina']}%)',
          'saran': 'Pertimbangkan substitusi segera',
        });
      } else if ((p['status'] == 'Main' || p['status'] == 'Pemanasan') &&
          p['stamina'] < 55) {
        result.add({
          'level': 'warning',
          'pesan':
              'Pemain #${p['no']} ${p['nama']} stamina mulai menurun (${p['stamina']}%)',
          'saran': 'Pantau kondisi secara berkala',
        });
      }
    }
    if (_menit > 60 && _skor1 < _skor2) {
      result.insert(0, {
        'level': 'critical',
        'pesan': 'Menit $_menit — Tim sedang Kalah',
        'saran': 'Pertimbangkan untuk ganti formasi menjadi lebih menyerang',
      });
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),

              // ── A. Ringkasan Tim ──
              _buildSectionLabel('A. Ringkasan Tim', 'Season 25/26'),
              const SizedBox(height: 14),
              _buildTeamSummary(),
              const SizedBox(height: 24),

              // ── B. Live Match Panel ──
              _buildSectionLabel(
                'B. Live Match Panel',
                _isLive ? '🔴 LIVE' : 'Selesai',
              ),
              const SizedBox(height: 14),
              _buildLiveMatchPanel(),
              const SizedBox(height: 24),

              // ── Input Statistik Manual (HT/FT) ──
              _buildSectionLabel('Input Statistik Manual (HT/FT)', 'Opsional'),
              const SizedBox(height: 14),
              _buildManualStatsInput(),
              const SizedBox(height: 24),

              // ── C. Rekomendasi Rule Engine ──
              _buildSectionLabel('C. Rekomendasi Rule Engine', 'View All'),
              const SizedBox(height: 14),
              if (_rekomendasi.isEmpty)
                _buildEmptyRekomendasi()
              else
                ..._rekomendasi.map((r) => _buildRekomendasiCard(r)),
              const SizedBox(height: 24),

              // ── Quick Menu ──
              _buildSectionLabel('Quick Menu', ''),
              const SizedBox(height: 14),
              _buildQuickMenus(context),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Builder(
      builder: (context) {
        return Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFFFF000),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.asset(
                  'assets/images/madrid.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Real Madrid CF',
                    style: TextStyle(
                      color: context.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Liga Champions \u00b7 2025/26',
                    style: TextStyle(
                      color: context.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: _showNotificationPanel,
              child: Stack(
                children: [
                  Icon(
                    Icons.notifications,
                    color: context.textPrimary,
                    size: 28,
                  ),
                  if (globalHasUnreadNotification)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSectionLabel(String title, String trailing) {
    return Builder(
      builder: (context) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                color: context.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (trailing.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: context.sectionBadgeBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  trailing,
                  style: TextStyle(
                    color: context.isDark
                        ? const Color(0xFFFFF000)
                        : const Color(0xFF8B7A00),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  // ── A. RINGKASAN TIM ──
  Widget _buildTeamSummary() {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.5,
      children: [
        _buildSummaryCard(
          label: 'PEMAIN AKTIF',
          value: '$_aktif',
          sub: 'dari ${_players.length} total',
          subColor: Colors.greenAccent,
          icon: Icons.person_outline,
          iconColor: Colors.greenAccent,
        ),
        _buildSummaryCard(
          label: 'PEMAIN CEDERA',
          value: '$_cedera',
          sub: 'perlu pemantauan',
          subColor: Colors.redAccent,
          icon: Icons.local_hospital_outlined,
          iconColor: Colors.redAccent,
        ),
        _buildStaminaCard(
          label: 'RATA-RATA STAMINA',
          value: '${_avgStamina.toStringAsFixed(0)}%',
          ratio: _avgStamina / 100,
        ),
        _buildSummaryCard(
          label: 'RATA-RATA RATING',
          value: '${_avgRating.toStringAsFixed(1)}',
          sub: '↑ dari pertandingan lalu',
          subColor: Colors.greenAccent,
          icon: Icons.star_outline,
          iconColor: const Color(0xFFFFF000),
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String label,
    required String value,
    required String sub,
    required Color subColor,
    required IconData icon,
    required Color iconColor,
  }) {
    return Builder(
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Icon(icon, color: iconColor, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        color: context.textSecondary,
                        fontSize: 10,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  color: context.textPrimary,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(sub, style: TextStyle(color: subColor, fontSize: 10)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStaminaCard({
    required String label,
    required String value,
    required double ratio,
  }) {
    final Color barColor = ratio >= 0.7
        ? Colors.greenAccent
        : ratio >= 0.4
        ? const Color(0xFFFFF000)
        : Colors.redAccent;
    return Builder(
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Icon(Icons.bolt, color: barColor, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        color: context.textSecondary,
                        fontSize: 10,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: TextStyle(
                  color: context.textPrimary,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: ratio,
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                  color: barColor,
                  minHeight: 5,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── B. LIVE MATCH PANEL ──
  Widget _buildLiveMatchPanel() {
    return Builder(
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isLive
                  ? const Color(0xFFFFF000).withValues(alpha: 0.4)
                  : Colors.white.withValues(alpha: 0.08),
            ),
          ),
          child: Column(
            children: [
              // Score row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Tim kita
                  Expanded(
                    child: Column(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFFFFF000),
                              width: 3,
                            ),
                          ),
                          child: const Icon(
                            Icons.shield,
                            color: Color(0xFFFFF000),
                            size: 28,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: context.cardColor,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: context.borderColor),
                          ),
                          child: Center(
                            child: Text(
                              'Real Madrid',
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).textTheme.bodyMedium?.color,
                                fontWeight: FontWeight.bold,
                                fontSize:
                                    12, // Sedikit diperkecil agar pas 2 baris
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Score middle
                  Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$_skor1',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).textTheme.bodyMedium?.color,
                              fontSize: 42,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4),
                            child: Text(
                              ':',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 28,
                              ),
                            ),
                          ),
                          Text(
                            '$_skor2',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 42,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      if (_fase == 'Penalti' || _penalti1 > 0 || _penalti2 > 0)
                        Text(
                          '( $_penalti1 - $_penalti2 ) PEN',
                          style: const TextStyle(
                            color: Colors.orangeAccent,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      const SizedBox(height: 6),
                      // Status badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _statusColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _statusColor.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Text(
                          _statusPertandingan,
                          style: TextStyle(
                            color: _statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _isLive
                              ? const Color(0xFFFFF000)
                              : Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _isLive
                              ? "$_menit' " +
                                    (_menitLebih > 0 ? "+$_menitLebih' " : "") +
                                    "($_fase)"
                              : "TERHENTI - $_fase",
                          style: TextStyle(
                            color: _isLive ? Colors.black : Colors.orangeAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Lawan
                  Expanded(
                    child: Column(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.sports_soccer,
                            color: Colors.grey,
                            size: 28,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: context.cardColor,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: context.borderColor),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              value: _timTandang,
                              dropdownColor: context.cardColor,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                                height: 1.2,
                              ),
                              icon: const Icon(
                                Icons.arrow_drop_down,
                                color: Colors.grey,
                                size: 16,
                              ),
                              selectedItemBuilder: (BuildContext context) {
                                return _timList.map<Widget>((String item) {
                                  return Container(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      item,
                                      maxLines: 2,
                                      softWrap: true,
                                      textAlign: TextAlign.left,
                                    ),
                                  );
                                }).toList();
                              },
                              items: _timList.map((String item) {
                                return DropdownMenuItem<String>(
                                  value: item,
                                  child: Text(item),
                                );
                              }).toList(),
                              onChanged: (v) =>
                                  setState(() => _timTandang = v!),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Shots counter
              const SizedBox(height: 16),
              const Divider(color: Colors.white12),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatCounter(
                    'Shots',
                    _shots,
                    () => setState(() => _shots++),
                  ),
                  _buildStatCounter(
                    'Target',
                    _shotsOnTarget,
                    () => setState(() => _shotsOnTarget++),
                  ),
                ],
              ),
              // Stamina kritis alert
              if (_kritisPlayers.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Divider(color: Colors.white12),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      Icons.warning_rounded,
                      color: Colors.orangeAccent,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Pemain Stamina Kritis (${_kritisPlayers.length}):',
                      style: const TextStyle(
                        color: Colors.orangeAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: _kritisPlayers.map((p) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.redAccent.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        '#${p['no']} ${p['nama']} — ${p['stamina']}%',
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
              // Admin Action Dialog Button
              if (!_isLive && _fase != 'Selesai') ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.sports, color: Colors.black),
                    label: Text(
                      _fase.startsWith('Tunggu Injury')
                          ? 'Input Injury Time Wasit'
                          : _fase == 'Half Time'
                          ? 'Mulai Babak 2'
                          : _fase == 'Tunggu Extra Time'
                          ? 'Mulai Extra Time 1'
                          : _fase == 'Jeda ET'
                          ? 'Mulai Extra Time 2'
                          : _fase == 'Penalti'
                          ? 'Skor Seri! Mulai Penalti'
                          : _fase == 'Persiapan'
                          ? 'Mulai Babak 1 (Tanpa Atur Skuad)'
                          : 'Akhiri Pertandingan',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFFFF000),
                    ),
                    onPressed: () {
                      if (_fase.startsWith('Tunggu Injury')) {
                        final targetPhase = _fase.replaceAll('Tunggu ', '');
                        _inputInjury(targetPhase);
                      } else if (_fase == 'Half Time') {
                        setState(() {
                          _fase = 'Babak 2';
                          _isLive = true;
                          _menit = 45;
                          _menitLebih = 0;
                        });
                      } else if (_fase == 'Tunggu Extra Time') {
                        setState(() {
                          _fase = 'Extra Time 1';
                          _isLive = true;
                          _menit = 90;
                          _menitLebih = 0;
                        });
                      } else if (_fase == 'Jeda ET') {
                        setState(() {
                          _fase = 'Extra Time 2';
                          _isLive = true;
                          _menit = 105;
                          _menitLebih = 0;
                        });
                      } else if (_fase == 'Penalti') {
                        setState(() {
                          _isLive = true;
                        }); // Activate penalti UI dynamically
                      } else if (_fase == 'Full Time') {
                        SocketService().socket.emit('finish_match', {
                          'timKandang': _timKandang,
                          'timTandang': _timTandang,
                          'possession': _possessionCtrl.text,
                          'passes': _passesCtrl.text,
                          'shots': _shots,
                          'shotsOnTarget': _shotsOnTarget,
                        });
                        setState(() {
                          _fase = 'Selesai';
                          _shots = 0;
                          _shotsOnTarget = 0;
                          _possessionCtrl.clear();
                          _passesCtrl.clear();
                        });
                      }
                    },
                  ),
                ),
              ],

              // Simulasi control buttons
              const SizedBox(height: 16),
              const Divider(color: Colors.white12),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildSimBtn(
                    _fase == 'Penalti' ? '+ Penalti' : '+ Gol Tim',
                    Icons.add_circle_outline,
                    Colors.greenAccent,
                    () {
                      if (_fase == 'Penalti') {
                        _penalti1++;
                      } else {
                        _skor1++;
                      }
                      SocketService().socket.emit('update_match', {
                        'skor1': _skor1,
                        'skor2': _skor2,
                        'penalti1': _penalti1,
                        'penalti2': _penalti2,
                        'fase': _fase,
                      });
                    },
                  ),
                  _buildSimBtn(
                    _fase == 'Penalti' ? '+ Penalti' : '+ Gol Lawan',
                    Icons.remove_circle_outline,
                    Colors.redAccent,
                    () {
                      if (_fase == 'Penalti') {
                        _penalti2++;
                      } else {
                        _skor2++;
                      }
                      SocketService().socket.emit('update_match', {
                        'skor1': _skor1,
                        'skor2': _skor2,
                        'penalti1': _penalti1,
                        'penalti2': _penalti2,
                        'fase': _fase,
                      });
                    },
                  ),
                  _buildSimBtn(
                    'Selesai & Simpan', // SEBELUMNYA RESET
                    Icons.task_alt,
                    Colors.orangeAccent,
                    () {
                      // MENGIRIM KE NODE.JS MENUJU RIWAYAT:
                      // Sertakan tim yang dipakai agar tercatat dengan akurat (Dinamis)
                      SocketService().socket.emit('finish_match', {
                        'timKandang': _timKandang,
                        'timTandang': _timTandang,
                        'possession': _possessionCtrl.text,
                        'passes': _passesCtrl.text,
                        'shots': _shots,
                        'shotsOnTarget': _shotsOnTarget,
                      });
                      _timer?.cancel();
                      setState(() {
                        _shots = 0;
                        _shotsOnTarget = 0;
                        _possessionCtrl.clear();
                        _passesCtrl.clear();
                      });
                      _startLiveTimer(); // Mulai timer ulang dari awal untuk match selanjutnya
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    ); // end Builder
  }

  Widget _buildStatCounter(String label, int value, VoidCallback onAdd) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$value',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: onAdd,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(Icons.add, size: 16, color: Colors.white),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildManualStatsInput() {
    return Builder(
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ball Possession (%)',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _possessionCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: context.cardAltColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        hintText: 'Misal: 55',
                        hintStyle: const TextStyle(color: Colors.white30),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total Operan',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _passesCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: context.cardAltColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        hintText: 'Misal: 450',
                        hintStyle: const TextStyle(color: Colors.white30),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSimBtn(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: color, fontSize: 10)),
        ],
      ),
    );
  }

  // ── C. REKOMENDASI ──
  Widget _buildRekomendasiCard(Map<String, dynamic> r) {
    final bool isCritical = r['level'] == 'critical';
    final Color color = isCritical
        ? Colors.orangeAccent
        : const Color(0xFFFFF000);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isCritical ? Icons.warning_rounded : Icons.info_outline,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  r['pesan'],
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Rekomendasi: ${r['saran']}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyRekomendasi() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.3)),
      ),
      child: const Row(
        children: [
          Icon(Icons.check_circle_outline, color: Colors.greenAccent, size: 22),
          SizedBox(width: 12),
          Text(
            'Tidak ada rekomendasi saat ini.\nKondisi tim dalam keadaan baik.',
            style: TextStyle(
              color: Colors.greenAccent,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ── QUICK MENU ──
  Widget _buildQuickMenus(BuildContext context) {
    final menus = [
      {
        'label': 'Pertandingan\nBaru',
        'icon': Icons.add_circle_outline,
        'route': '/match',
      },
      {
        'label': 'Atur\nSkuad',
        'icon': Icons.group_add,
        'route': '/manage_squad',
      },
      {'label': 'Riwayat\nMatch', 'icon': Icons.history, 'route': '/history'},
      {
        'label': 'Laporan\nAnalitik',
        'icon': Icons.insert_chart_outlined,
        'route': '/reports',
      },
      {
        'label': 'Rule\nEngine',
        'icon': Icons.rule_folder_outlined,
        'route': '/rules',
      },
    ];

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.0,
      children: menus.map((m) {
        return GestureDetector(
          onTap: () async {
            await Navigator.pushNamed(context, m['route'] as String);
            // Re-attach listeners when returning, as other screens might have wiped them using .off()
            if (mounted) {
              _setupSocketListeners();
              SocketService().socket.emit('request_sync');
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Row(
              children: [
                Icon(
                  m['icon'] as IconData,
                  color: const Color(0xFFFFF000),
                  size: 26,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    m['label'] as String,
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
