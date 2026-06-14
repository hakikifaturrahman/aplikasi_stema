import 'package:flutter/material.dart';
import '../services/socket_service.dart';

/// Widget Screen: TambahStatistikScreen
/// Halaman formulir bagi asisten pelatih untuk menginput statistik pertandingan individu pemain.
/// Data dikirim langsung ke backend via Socket.io untuk dianalisis oleh Rule Engine.
class TambahStatistikScreen extends StatefulWidget {
  const TambahStatistikScreen({super.key});

  @override
  State<TambahStatistikScreen> createState() => _TambahStatistikScreenState();
}

class _TambahStatistikScreenState extends State<TambahStatistikScreen> {
  // GlobalKey untuk kontrol form
  final _formKey = GlobalKey<FormState>();

  // State untuk data pilihan Dropdown
  String _selectedMatch = 'Liga Weekend - Pekan 12';
  String _selectedPlayer = 'Memuat Data...';
  List<String> _playerNames = ['Memuat Data...']; // Menyimpan list nama pemain dari sync
  String _kartu = 'Tidak Ada';

  // State nilai performa rating (1.0 - 10.0)
  double _rating = 7.0;

  // Controller input numerik/teks
  final _menitCtrl = TextEditingController();
  final _kesalahanCtrl = TextEditingController();

  // Callback sinkronisasi daftar nama pemain dari backend (melalui event 'stamina_sync')
  void _onPlayerSync(dynamic data) {
    if (mounted && data != null) {
      // Mengonversi data dynamic menjadi tipe List yang aman
      final list = List<Map<String, dynamic>>.from(data.map((item) => Map<String, dynamic>.from(item)));
      if (list.isNotEmpty) {
        // Ekstrak nama pemain unik
        final names = list.map((p) => p['nama'].toString()).toSet().toList();
        setState(() {
          if (names.isNotEmpty) {
            _playerNames = names;
          } else {
            _playerNames = ['Belum ada pemain'];
          }
          // Set pilihan default ke pemain pertama jika pilihan saat ini tidak ada di list baru
          if (!_playerNames.contains(_selectedPlayer)) {
            _selectedPlayer = _playerNames.first;
          }
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    // Membuka koneksi socket dan mendaftarkan listener 'stamina_sync'
    SocketService().connect();
    SocketService().socket.on('stamina_sync', _onPlayerSync);
    
    // Meminta pembaruan data terbaru dari server
    SocketService().socket.emit('request_sync');
  }

  @override
  void dispose() {
    // Mematikan listener socket dan membersihkan memory controller
    SocketService().socket.off('stamina_sync', _onPlayerSync);
    _menitCtrl.dispose();
    _kesalahanCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B1A12), // Warna gelap khas STEMA
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B1A12),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Input Statistik Match',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bagian A: Info Identitas Match & Pemain
              _buildSectionTitle('A. Info Pertandingan & Pemain'),
              const SizedBox(height: 16),
              _buildDropdown(
                'Pilih Match',
                [
                  'Liga Weekend - Pekan 12',
                  'Piala Kota - Semifinal',
                  'Friendly vs FC Garuda',
                ],
                _selectedMatch,
                (v) => setState(() => _selectedMatch = v!),
              ),
              const SizedBox(height: 16),
              _buildDropdown(
                'Pilih Pemain',
                _playerNames,
                _selectedPlayer,
                (v) => setState(() => _selectedPlayer = v!),
              ),
              const SizedBox(height: 16),
              _buildTextField('Menit Bermain', 'Misal: 90', isNumber: true, controller: _menitCtrl),
              const SizedBox(height: 32),

              // Bagian B: Slider Rating Performa Pemain
              _buildSectionTitle('B. Rating Performa (1 - 10)'),
              const SizedBox(height: 16),
              _buildAttributeSlider(
                'Rating Keseluruhan',
                _rating,
                (v) => setState(() => _rating = v),
                max: 10,
              ),
              const SizedBox(height: 32),

              // Bagian C: Detail Data Kinerja Lapangan
              _buildSectionTitle('C. Detail Statistik'),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      'Jumlah Sprint',
                      '0',
                      isNumber: true,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      'Jumlah Tembakan',
                      '0',
                      isNumber: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      'Jumlah Assist',
                      '0',
                      isNumber: true,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      'Jumlah Kesalahan',
                      '0',
                      isNumber: true,
                      controller: _kesalahanCtrl,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField('Pelanggaran', '0', isNumber: true),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildDropdown(
                      'Kartu',
                      ['Tidak Ada', 'Kuning', 'Merah'],
                      _kartu,
                      (v) => setState(() => _kartu = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),

              // Tombol Submit Laporan Statistik
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFF000), // Warna primer kuning
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    final kesalahan = int.tryParse(_kesalahanCtrl.text) ?? 0;
                    
                    // Mengirim data laporan asisten 'assistant_report' ke server backend Socket
                    SocketService().socket.emit('assistant_report', {
                      'pemain': _selectedPlayer,
                      'match': _selectedMatch,
                      'rating': _rating,
                      'kesalahan': kesalahan,
                      'kartu': _kartu,
                    });

                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Statistik performa berhasil disimpan!'),
                      ),
                    );
                  },
                  child: const Text(
                    'Simpan Statistik',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // Builder judul bagian form
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Color(0xFFFFF000),
        fontWeight: FontWeight.bold,
        fontSize: 18,
      ),
    );
  }

  // Builder input teks / numerik
  Widget _buildTextField(String label, String hint, {bool isNumber = false, TextEditingController? controller}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white38),
            filled: true,
            fillColor: const Color(0xFF242217),
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

  // Builder Dropdown Pilihan
  Widget _buildDropdown(
    String label,
    List<String> items,
    String value,
    Function(String?) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF242217),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF404040)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              dropdownColor: const Color(0xFF242217),
              value: value,
              style: const TextStyle(color: Colors.white),
              icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
              items: items.map((String item) {
                return DropdownMenuItem<String>(value: item, child: Text(item));
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  // Builder Slider Pengaturan Rating Performa
  Widget _buildAttributeSlider(
    String label,
    double value,
    Function(double) onChanged, {
    double max = 100,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                value.toStringAsFixed(1),
                style: const TextStyle(
                  color: Color(0xFFFFF000),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFFFFF000),
              inactiveTrackColor: const Color(0xFF404040),
              thumbColor: const Color(0xFFFFF000),
              overlayColor: const Color(0x33FFF000),
              trackHeight: 4.0,
            ),
            child: Slider(
              value: value,
              min: 1,
              max: max,
              divisions: (max * 10).toInt() - 10,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
