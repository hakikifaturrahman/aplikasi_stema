import 'package:flutter/material.dart';
import 'dart:convert';
import '../theme/app_theme.dart';
import '../services/socket_service.dart';

class SquadManagementScreen extends StatefulWidget {
  const SquadManagementScreen({super.key});

  @override
  State<SquadManagementScreen> createState() => _SquadManagementScreenState();
}

class _SquadManagementScreenState extends State<SquadManagementScreen> {
  List<Map<String, dynamic>> _players = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    SocketService().connect();
    SocketService().socket.emit('request_sync');

    SocketService().socket.off('stamina_sync');
    SocketService().socket.on('stamina_sync', (data) {
      if (mounted && data != null) {
        setState(() {
          _players = List<Map<String, dynamic>>.from(
              data.map((item) => Map<String, dynamic>.from(item)));
          _isLoading = false;
        });
      }
    });
  }

  void _updateStatus(String playerName, String newStatus) {
    // Cari data pemain dan kirim edit
    final player = _players.firstWhere((p) => p['nama'] == playerName);
    final payload = {
      ...player,
      'originalName': player['nama'],
      'status': newStatus,
    };
    SocketService().socket.emit('edit_player', payload);
  }

  void _updateStamina(String playerName, int newStamina) {
    final player = _players.firstWhere((p) => p['nama'] == playerName);
    final payload = {
      ...player,
      'originalName': player['nama'],
      'stamina': newStamina,
    };
    SocketService().socket.emit('edit_player', payload);
  }

  void _showEditStaminaDialog(String playerName, int currentStamina) {
    final ctrl = TextEditingController(text: currentStamina.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.cardColor,
        title: Text('Edit Stamina', style: TextStyle(color: context.textPrimary)),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          style: TextStyle(color: context.textPrimary),
          decoration: InputDecoration(
            labelText: 'Stamina (0-100)',
            labelStyle: TextStyle(color: context.textSecondary),
            filled: true,
            fillColor: context.cardAltColor,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal', style: TextStyle(color: context.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFF000)),
            onPressed: () {
              final val = int.tryParse(ctrl.text);
              if (val != null && val >= 0 && val <= 100) {
                _updateStamina(playerName, val);
                Navigator.pop(ctx);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Masukkan angka 0 - 100 yang valid')),
                );
              }
            },
            child: const Text('Simpan', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      )
    );
  }

  void _showSubstitutionDialog() {
    final activePlayers = _players.where((p) => p['status'] == 'Main' || p['status'].startsWith('Cedera')).toList();
    
    activePlayers.sort((a, b) {
      bool aIsCedera = a['status'].toString().startsWith('Cedera');
      bool bIsCedera = b['status'].toString().startsWith('Cedera');
      if (aIsCedera && !bIsCedera) return -1;
      if (!aIsCedera && bIsCedera) return 1;
      return a['nama'].toString().compareTo(b['nama'].toString());
    });

    final benchPlayers = _players.where((p) => p['status'] == 'Cadangan' || p['status'] == 'Pemanasan').toList();
    String substitutionReason = 'Taktikal / Stamina';

    String? selectedOut = activePlayers.isNotEmpty ? activePlayers.first['nama'] : null;
    String? selectedIn = benchPlayers.isNotEmpty ? benchPlayers.first['nama'] : null;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: context.cardColor,
              title: Text('Substitusi Pemain', style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Pilih Pemain Keluar (Main)', style: TextStyle(color: context.textSecondary, fontSize: 13)),
                    const SizedBox(height: 8),
                    _buildDropdownSelect(
                      items: activePlayers.map((p) => '${p['nama']} (${p['status']})').toList(),
                      value: selectedOut != null ? '${activePlayers.firstWhere((p) => p['nama'] == selectedOut)['nama']} (${activePlayers.firstWhere((p) => p['nama'] == selectedOut)['status']})' : null,
                      onChanged: (v) {
                        if (v != null) {
                          final nama = v.substring(0, v.lastIndexOf(' ('));
                          setStateDialog(() => selectedOut = nama);
                        }
                      },
                      context: context,
                    ),
                    const SizedBox(height: 16),
                    Text('Alasan Substitusi', style: TextStyle(color: context.textSecondary, fontSize: 13)),
                    const SizedBox(height: 8),
                    _buildDropdownSelect(
                      items: ['Taktikal / Stamina', 'Cedera', 'Kartu Merah / Pelanggaran'],
                      value: substitutionReason,
                      onChanged: (v) => setStateDialog(() => substitutionReason = v ?? 'Taktikal / Stamina'),
                      context: context,
                    ),
                    const SizedBox(height: 16),
                    Text('Pilih Pemain Masuk (Cadangan/Pemanasan)', style: TextStyle(color: context.textSecondary, fontSize: 13)),
                    const SizedBox(height: 8),
                    _buildDropdownSelect(
                      items: benchPlayers.map((p) => p['nama'].toString()).toList(),
                      value: selectedIn,
                      onChanged: (v) => setStateDialog(() => selectedIn = v),
                      context: context,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orangeAccent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orangeAccent.withOpacity(0.3)),
                      ),
                      child: Text(
                        'Pilih "Pemanasan Dulu" agar stamina pemain masuk mulai menyesuaikan, atau "Langsung Masuk" untuk substitusi instan.',
                        style: TextStyle(color: Colors.orangeAccent, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                 TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('Batal', style: TextStyle(color: context.textSecondary)),
                ),
                TextButton(
                  onPressed: selectedIn == null ? null : () {
                    // Update main -> pemanasan
                    _updateStatus(selectedIn!, 'Pemanasan');
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      SnackBar(content: Text('$selectedIn mulai melakukan pemanasan!')),
                    );
                  },
                  child: Text('Pemanasan Dulu', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFF000)),
                  onPressed: (selectedOut == null || selectedIn == null) ? null : () {
                    // Eksekusi: Masuk jadi Main, Keluar jadi Cadangan atau tetap Cedera
                    
                    // Cek status awal pemain keluar
                    final outPlayer = activePlayers.firstWhere((p) => p['nama'] == selectedOut);
                    final outStatus = outPlayer['status'];
                    
                    // Jika alasan cedera, paksa status jadi Cedera. Jika kartu merah, paksa. Jika tidak, Cadangan.
                    String finalOutStatus = 'Cadangan';
                    if (substitutionReason == 'Cedera') {
                      finalOutStatus = 'Cedera';
                    } else if (substitutionReason == 'Kartu Merah / Pelanggaran') {
                      finalOutStatus = 'Kartu Merah';
                    } else if (outStatus.startsWith('Cedera')) {
                       // Jika statusnya sudah diubah ke cedera lewat dropdown sebelumnya
                       finalOutStatus = outStatus;
                    }

                    _updateStatus(selectedOut!, finalOutStatus);
                    _updateStatus(selectedIn!, 'Main');
                    
                    // Emit event spesifik untuk logging riwayat substitusi jika ada sistem log
                    SocketService().socket.emit('log_substitution', {
                       'pemainKeluar': selectedOut,
                       'pemainMasuk': selectedIn,
                       'alasan': substitutionReason
                    });

                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      SnackBar(content: Text('Substitusi berhasil: $selectedIn menggantikan $selectedOut ($substitutionReason)')),
                    );
                  },
                  child: const Text('Langsung Masuk', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          }
        );
      }
    );
  }

  Widget _buildDropdownSelect({required List<String> items, required String? value, required Function(String?) onChanged, required BuildContext context}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: context.cardAltColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.borderColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          dropdownColor: context.cardAltColor,
          value: value != null && items.contains(value) ? value : (items.isNotEmpty ? items.first : null),
          style: TextStyle(color: context.textPrimary, fontSize: 14),
          icon: Icon(Icons.arrow_drop_down, color: context.iconMuted),
          items: items.map((String item) {
            return DropdownMenuItem<String>(value: item, child: Text(item));
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        backgroundColor: context.bgColor,
        title: Text('Atur Skuad & Status', style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  color: context.cardColor,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Pilih status masing-masing pemain sebelum pertandingan. Gunakan tombol substitusi jika pertandingan sedang berlangsung.',
                          style: TextStyle(color: context.textSecondary, fontSize: 13),
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFF000),
                          foregroundColor: Colors.black,
                        ),
                        icon: const Icon(Icons.swap_horiz),
                        label: const Text('Substitusi'),
                        onPressed: _showSubstitutionDialog,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    itemCount: _players.length,
                    separatorBuilder: (context, index) => Divider(color: context.dividerColor, height: 1),
                    itemBuilder: (context, index) {
                      final player = _players[index];
                      final name = player['nama'] ?? 'Unknown';
                      final pos = player['pos'] ?? '-';
                      final status = player['status'] ?? 'Main';
                      final stamina = player['stamina'] ?? 100;
                      final imageBase64 = player['foto'];

                      final kartu = player['kartu'] ?? '-';
                      final gol = player['gol'] ?? 0;
                      final assist = player['assist'] ?? 0;

                      Color statusColor;
                      if (status == 'Main' || status == 'Pemanasan') statusColor = Colors.greenAccent;
                      else if (status.startsWith('Cedera') || status == 'Tidak Hadir' || status == 'Kartu Merah') statusColor = Colors.redAccent;
                      else if (status == 'Kartu Kuning') statusColor = Colors.yellowAccent;
                      else statusColor = Colors.orangeAccent;

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: statusColor, width: 2),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CircleAvatar(
                                backgroundColor: context.cardAltColor,
                                backgroundImage: imageBase64 != null 
                                    ? MemoryImage(base64Decode(imageBase64)) as ImageProvider 
                                    : null,
                                child: imageBase64 == null
                                    ? Icon(Icons.person, color: context.iconMuted, size: 24)
                                    : null,
                              ),
                              if (kartu == 'Kuning')
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    width: 14,
                                    height: 18,
                                    decoration: BoxDecoration(
                                      color: Colors.yellow,
                                      borderRadius: BorderRadius.circular(2),
                                      border: Border.all(color: Colors.black, width: 1),
                                    ),
                                  ),
                                ),
                              if (kartu == 'Merah')
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    width: 14,
                                    height: 18,
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(2),
                                      border: Border.all(color: Colors.black, width: 1),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        title: Text(name, style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.bold)),
                        subtitle: Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('$pos • Stamina: $stamina%', style: TextStyle(color: context.textSecondary, fontSize: 12)),
                                const SizedBox(width: 6),
                                InkWell(
                                  onTap: () => _showEditStaminaDialog(name, stamina),
                                  child: Icon(Icons.edit, size: 14, color: context.textSecondary),
                                ),
                              ],
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.sports_soccer, size: 14, color: Colors.white70),
                                const SizedBox(width: 4),
                                Text('$gol', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                const SizedBox(width: 8),
                                InkWell(
                                  onTap: () {
                                    Map<String, dynamic> updatedPlayer = Map.from(player);
                                    updatedPlayer['originalName'] = player['nama'];
                                    updatedPlayer['gol'] = gol + 1;
                                    SocketService().socket.emit('edit_player', updatedPlayer);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.8), borderRadius: BorderRadius.circular(4)),
                                    child: const Text('+1', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                                  ),
                                ),
                                if (gol > 0) ...[
                                  const SizedBox(width: 4),
                                  InkWell(
                                    onTap: () {
                                      Map<String, dynamic> updatedPlayer = Map.from(player);
                                      updatedPlayer['originalName'] = player['nama'];
                                      updatedPlayer['gol'] = gol - 1;
                                      SocketService().socket.emit('edit_player', updatedPlayer);
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.8), borderRadius: BorderRadius.circular(4)),
                                      child: const Text('-1', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                                    ),
                                  ),
                                ],
                                const SizedBox(width: 12),
                                Icon(Icons.handshake_outlined, size: 14, color: Colors.white70),
                                const SizedBox(width: 4),
                                Text('$assist', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                const SizedBox(width: 8),
                                InkWell(
                                  onTap: () {
                                    Map<String, dynamic> updatedPlayer = Map.from(player);
                                    updatedPlayer['originalName'] = player['nama'];
                                    updatedPlayer['assist'] = assist + 1;
                                    SocketService().socket.emit('edit_player', updatedPlayer);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(color: Colors.blueAccent.withValues(alpha: 0.8), borderRadius: BorderRadius.circular(4)),
                                    child: const Text('+1', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                                  ),
                                ),
                                if (assist > 0) ...[
                                  const SizedBox(width: 4),
                                  InkWell(
                                    onTap: () {
                                      Map<String, dynamic> updatedPlayer = Map.from(player);
                                      updatedPlayer['originalName'] = player['nama'];
                                      updatedPlayer['assist'] = assist - 1;
                                      SocketService().socket.emit('edit_player', updatedPlayer);
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.8), borderRadius: BorderRadius.circular(4)),
                                      child: const Text('-1', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                                    ),
                                  ),
                                ]
                              ],
                            ),
                          ],
                        ),
                        trailing: Container(
                          height: 40,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            color: context.cardAltColor,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: context.borderColor),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: ['Main', 'Cadangan', 'Pemanasan', 'Cedera', 'Kartu Merah', 'Kartu Kuning', 'Tidak Hadir'].contains(status) ? status : 'Main',
                              dropdownColor: context.cardAltColor,
                              style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 13),
                              icon: Icon(Icons.arrow_drop_down, color: context.iconMuted),
                              items: ['Main', 'Cadangan', 'Pemanasan', 'Cedera', 'Kartu Merah', 'Kartu Kuning', 'Tidak Hadir'].map((String item) {
                                return DropdownMenuItem<String>(value: item, child: Text(item));
                              }).toList(),
                              onChanged: (v) {
                                if (v != null && v != status) {
                                  _updateStatus(name, v);
                                }
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  color: context.bgColor,
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.greenAccent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      SocketService().socket.emit('start_match');
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Pertandingan Dimulai! Pengurangan stamina dimulai.')),
                      );
                    },
                    child: const Text('Start Pertandingan', style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                )
              ],
            ),
    );
  }
}
