import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'dart:convert';
import '../services/socket_service.dart';

/// Widget Screen: TambahPemainScreen
/// Digunakan untuk menambah pemain baru atau mengedit data pemain yang sudah ada.
/// Menerima parameter [playerData] opsional. Jika [playerData] diisi, layar bertindak sebagai mode Edit.
class TambahPemainScreen extends StatefulWidget {
  final Map<String, dynamic>? playerData; // Data pemain untuk mode Edit

  const TambahPemainScreen({super.key, this.playerData});

  @override
  State<TambahPemainScreen> createState() => _TambahPemainScreenState();
}

class _TambahPemainScreenState extends State<TambahPemainScreen> {
  // GlobalKey untuk validasi status Form
  final _formKey = GlobalKey<FormState>();

  Uint8List? _playerImageBytes;      // Data byte foto pemain hasil konversi
  final ImagePicker _picker = ImagePicker(); // Instance untuk memilih foto dari galeri

  // Fungsi untuk mengambil foto dari galeri HP dengan batas kompresi kualitas
  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery, 
      imageQuality: 50, // Kompres kualitas gambar menjadi 50%
      maxWidth: 300     // Batas lebar maksimal 300px agar payload base64 tidak terlalu besar
    );
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _playerImageBytes = bytes;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    // Jika dalam Mode Edit, isi form dengan data awal pemain yang diterima
    if (widget.playerData != null) {
      final p = widget.playerData!;
      _namaCtrl.text = p['nama']?.toString() ?? '';
      _noCtrl.text = p['no']?.toString() ?? '';
      _posisiUtama = p['pos'] ?? 'CMF';
      if (!['GK', 'RB', 'CB', 'LB', 'AMF', 'CMF', 'DMF', 'LW', 'RW', 'ST', 'SS', 'CF'].contains(_posisiUtama)) {
        _posisiUtama = 'CMF';
      }
      _stamina = (p['stamina'] is int) 
          ? (p['stamina'] as int).toDouble() 
          : (double.tryParse(p['stamina'].toString()) ?? 70.0);
      _status = p['status'] ?? 'Main';
      
      _posisiAlternatif = p['posisiAlternatif'] ?? 'None';
      if (!['None', 'GK', 'RB', 'CB', 'LB', 'AMF', 'CMF', 'DMF', 'LW', 'RW', 'ST', 'SS', 'CF'].contains(_posisiAlternatif)) _posisiAlternatif = 'None';
      _tipePemain = p['tipe'] ?? 'Balanced';
      if (!['Attacking', 'Defensive', 'Balanced'].contains(_tipePemain)) _tipePemain = 'Balanced';
      if (p['tinggi'] != null) _tinggiCtrl.text = p['tinggi'].toString();
      if (p['berat'] != null) _beratCtrl.text = p['berat'].toString();
      if (p['tgllahir'] != null) {
        _selectedDate = DateTime.tryParse(p['tgllahir']);
      }
      
      // Decode foto profil pemain dari base64 string jika tersedia
      if (p['foto'] != null) {
        try {
          _playerImageBytes = base64Decode(p['foto']);
        } catch (e) {}
      }
      
      // Sinkronisasi slider atribut performa pemain
      if (p['attributes'] != null) {
         final attr = p['attributes'];
         _speed = (attr['speed'] is int) ? (attr['speed'] as int).toDouble() : (double.tryParse(attr['speed'].toString()) ?? 70.0);
         _shooting = (attr['shooting'] is int) ? (attr['shooting'] as int).toDouble() : (double.tryParse(attr['shooting'].toString()) ?? 70.0);
         _passing = (attr['passing'] is int) ? (attr['passing'] as int).toDouble() : (double.tryParse(attr['passing'].toString()) ?? 70.0);
         _defensive = (attr['defensive'] is int) ? (attr['defensive'] as int).toDouble() : (double.tryParse(attr['defensive'].toString()) ?? 70.0);
         _vision = (attr['vision'] is int) ? (attr['vision'] as int).toDouble() : (double.tryParse(attr['vision'].toString()) ?? 70.0);
         _dribbling = (attr['dribbling'] is int) ? (attr['dribbling'] as int).toDouble() : (double.tryParse(attr['dribbling'].toString()) ?? 70.0);
      }
    }
  }

  // State Dropdown Form
  String _posisiUtama = 'CMF';
  String _posisiAlternatif = 'None';
  String _status = 'Main';
  String _tipePemain = 'Balanced';

  // Controller Field Teks
  final TextEditingController _namaCtrl = TextEditingController();
  final TextEditingController _noCtrl = TextEditingController();
  final TextEditingController _tinggiCtrl = TextEditingController();
  final TextEditingController _beratCtrl = TextEditingController();

  // State Nilai Atribut Fisik & Skill (Default: 70)
  double _speed = 70;
  double _stamina = 70;
  double _passing = 70;
  double _shooting = 70;
  double _dribbling = 70;
  double _defensive = 70;
  double _vision = 70;

  DateTime? _selectedDate; // Tanggal lahir terpilih

  // Membuka dialog pemilih tanggal lahir
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1980),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFFFF000),
              onPrimary: Colors.black,
              surface: Color(0xFF242217),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B1A12),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B1A12),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.playerData != null ? 'Edit Pemain' : 'Tambah Pemain',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bagian A: Profil Dasar (Nama, No Punggung, Foto)
              _buildSectionTitle('A. Profil Dasar Pemain'),
              const SizedBox(height: 16),
              
              // Widget lingkaran foto profil interaktif
              Center(
                child: Stack(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: const Color(0xFF242217),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF404040)),
                        image: _playerImageBytes != null
                            ? DecorationImage(
                                image: MemoryImage(_playerImageBytes!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: _playerImageBytes == null
                          ? const Icon(
                              Icons.person,
                              size: 50,
                              color: Colors.grey,
                            )
                          : null,
                    ),
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
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _buildTextField('Nama Lengkap', 'Masukkan nama pemain', controller: _namaCtrl),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      'Nomor Punggung',
                      'Misal: 10',
                      isNumber: true,
                      controller: _noCtrl,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _selectDate(context),
                      child: AbsorbPointer(
                        child: _buildTextField(
                          'Tanggal Lahir',
                          _selectedDate == null
                              ? 'Pilih Tanggal'
                              : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildDropdown(
                      'Posisi Utama',
                      ['GK', 'RB', 'CB', 'LB', 'AMF', 'CMF', 'DMF', 'LW', 'RW', 'ST', 'SS', 'CF'],
                      _posisiUtama,
                      (v) => setState(() => _posisiUtama = v!),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildDropdown(
                      'Posisi Alternatif',
                      ['None', 'GK', 'RB', 'CB', 'LB', 'AMF', 'CMF', 'DMF', 'LW', 'RW', 'ST', 'SS', 'CF'],
                      _posisiAlternatif,
                      (v) => setState(() => _posisiAlternatif = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      'Tinggi Badan (cm)',
                      '180',
                      isNumber: true,
                      controller: _tinggiCtrl,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      'Berat Badan (kg)',
                      '75',
                      isNumber: true,
                      controller: _beratCtrl,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildDropdown(
                      'Status',
                      ['Main', 'Cadangan', 'Pemanasan', 'Cedera', 'Tidak Hadir'],
                      _status,
                      (v) => setState(() => _status = v!),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildDropdown(
                      'Tipe Pemain',
                      ['Attacking', 'Defensive', 'Balanced'],
                      _tipePemain,
                      (v) => setState(() => _tipePemain = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              
              // Bagian B: Atribut Statistik Kemampuan
              _buildSectionTitle('B. Atribut Performa (1 - 100)'),
              const SizedBox(height: 16),
              _buildAttributeSlider(
                'Speed',
                _speed,
                (v) => setState(() => _speed = v),
              ),
              _buildAttributeSlider(
                'Stamina',
                _stamina,
                (v) => setState(() => _stamina = v),
              ),
              _buildAttributeSlider(
                'Passing',
                _passing,
                (v) => setState(() => _passing = v),
              ),
              _buildAttributeSlider(
                'Shooting',
                _shooting,
                (v) => setState(() => _shooting = v),
              ),
              _buildAttributeSlider(
                'Dribbling',
                _dribbling,
                (v) => setState(() => _dribbling = v),
              ),
              _buildAttributeSlider(
                'Defensive Skill',
                _defensive,
                (v) => setState(() => _defensive = v),
              ),
              _buildAttributeSlider(
                'Vision',
                _vision,
                (v) => setState(() => _vision = v),
              ),
              const SizedBox(height: 32),
              
              // Tombol Submit Simpan
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFF000),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    // MENGIRIM DATA KE NODE.JS BACKEND
                    if (_namaCtrl.text.isNotEmpty) {
                      final payload = {
                        'nama': _namaCtrl.text,
                        'no': int.tryParse(_noCtrl.text) ?? 99,
                        'pos': _posisiUtama,
                        'posisiAlternatif': _posisiAlternatif,
                        'tgllahir': _selectedDate?.toIso8601String(),
                        'tinggi': int.tryParse(_tinggiCtrl.text) ?? 180,
                        'berat': int.tryParse(_beratCtrl.text) ?? 75,
                        'tipe': _tipePemain,
                        'stamina': _stamina.toInt(),
                        'status': _status,
                        // Encode byte foto ke Base64 String sebelum dikirim via Socket
                        'foto': _playerImageBytes != null ? base64Encode(_playerImageBytes!) : null,
                        'attributes': {
                          'speed': _speed.toInt(),
                          'shooting': _shooting.toInt(),
                          'passing': _passing.toInt(),
                          'defensive': _defensive.toInt(),
                          'vision': _vision.toInt(),
                          'stamina': _stamina.toInt(),
                          'dribbling': _dribbling.toInt(),
                        }
                      };

                      if (widget.playerData != null) {
                        // Jika dalam mode Edit, sertakan nama asli 'originalName' untuk pencarian query backend
                        payload['originalName'] = widget.playerData!['nama'];
                        SocketService().socket.emit('edit_player', payload);
                      } else {
                        // Mode Tambah Baru
                        SocketService().socket.emit('add_player', payload);
                      }
                    }

                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(widget.playerData != null 
                            ? 'Data pemain berhasil diperbarui!' 
                            : 'Pemain berhasil ditambahkan!'),
                      ),
                    );
                  },
                  child: const Text(
                    'Simpan Data Pemain',
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

  // Builder judul bagian
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

  // Builder text field standard
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

  // Builder Dropdown Form
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

  // Builder Slider Atribut Performa
  Widget _buildAttributeSlider(
    String label,
    double value,
    Function(double) onChanged,
  ) {
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
                '${value.toInt()}',
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
              value: value.clamp(0.0, 100.0),
              min: 0,
              max: 100,
              divisions: 100,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
