import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/socket_service.dart';

class PertandinganScreen extends StatefulWidget {
  const PertandinganScreen({super.key});

  @override
  State<PertandinganScreen> createState() => _PertandinganScreenState();
}

class _PertandinganScreenState extends State<PertandinganScreen> {
  final _formKey = GlobalKey<FormState>();

  String _kompetisi = 'Liga Domestik';
  String _formasi = '4-3-3';
  String _hasil = 'Menang (W)';
  DateTime? _selectedDate;

  final TextEditingController _namaCtrl = TextEditingController();
  final TextEditingController _lawanCtrl = TextEditingController();
  final TextEditingController _skorCtrl = TextEditingController();
  final TextEditingController _catatanCtrl = TextEditingController();

  List<dynamic> _players = [];
  Map<String, bool> _startingXI = {};

  int get _selectedCount => _startingXI.values.where((v) => v).length;

  @override
  void initState() {
    super.initState();
    _connectToSocket();
  }

  void _connectToSocket() {
    SocketService().connect();
    SocketService().socket.emit('request_sync');

    SocketService().socket.on('stamina_sync', (data) {
      if (mounted) {
        setState(() {
          _players = data;
          // Inisialisasi map checkbox untuk setiap pemain
          for (var p in _players) {
            String namaPemain = p['nama'];
            if (!_startingXI.containsKey(namaPemain)) {
              _startingXI[namaPemain] = false;
            }
          }
        });
      }
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
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
    bool isLoading = _players.isEmpty;

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
          'Match Management',
          style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.bold),
        ),
      ),
      body: isLoading 
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFF000)))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('A. Info Pertandingan'),
              const SizedBox(height: 16),
              _buildTextField(
                'Nama Pertandingan',
                'Misal: Matchday 3 Group Stage',
                controller: _namaCtrl,
              ),
              const SizedBox(height: 16),
              _buildTextField('Lawan', 'Misal: Manchester City', controller: _lawanCtrl),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _selectDate(context),
                      child: AbsorbPointer(
                        child: _buildTextField(
                          'Tanggal',
                          _selectedDate == null
                              ? 'Pilih Tanggal'
                              : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildDropdown(
                      'Kompetisi',
                      [
                        'Liga Domestik',
                        'Piala Domestik',
                        'Liga Champions',
                        'Persahabatan',
                      ],
                      _kompetisi,
                      (v) => setState(() => _kompetisi = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildDropdown(
                'Formasi Awal',
                ['4-3-3', '4-2-3-1', '4-3-2-1', '4-1-4-1', '4-2-2-2', '4-3-1-2', '4-2-1-3', '4-1-2-3', '3-2-3-2', '3-3-2-2', '3-2-2-3', '3-2-4-1', '5-2-2-1', '5-2-1-2', '5-3-2'],
                _formasi,
                (v) => setState(() => _formasi = v!),
              ),
              const SizedBox(height: 32),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   _buildSectionTitle('B. Starting XI'),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _selectedCount == 11
                          ? (context.isDark ? const Color(0xFF3A5F1A) : const Color(0xFFC8E6C9))
                          : context.cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _selectedCount == 11
                            ? const Color(0xFFFFF000)
                            : context.borderColor,
                      ),
                    ),
                    child: Text(
                      '$_selectedCount / 11',
                      style: TextStyle(
                        color: _selectedCount == 11
                            ? const Color(0xFFFFF000)
                            : context.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: context.bgColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.borderColor),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _players.length,
                  separatorBuilder: (context, index) => Divider(
                    color: context.dividerColor,
                    height: 1,
                  ),
                  itemBuilder: (context, index) {
                    final playerObj = _players[index];
                    final nama = playerObj['nama'];
                    final pos = playerObj['pos'] ?? '';
                    final isSelected = _startingXI[nama] ?? false;
                    return CheckboxListTile(
                      title: Text(
                        '$nama ($pos)',
                        style: TextStyle(
                          color: isSelected ? context.textPrimary : context.textSecondary,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      value: isSelected,
                      activeColor: const Color(0xFFFFF000),
                      checkColor: Colors.black,
                      side: BorderSide(color: context.textSecondary),
                      onChanged: (bool? val) {
                        setState(() {
                          if (val == true && _selectedCount >= 11) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Starting XI maksimal 11 pemain!',
                                ),
                              ),
                            );
                            return;
                          }
                          _startingXI[nama] = val!;
                        });
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 32),

              _buildSectionTitle('C. Catatan Pertandingan'),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildTextField('Skor Akhir', 'Misal: 3-1', controller: _skorCtrl)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildDropdown(
                      'Hasil Akhir',
                      ['Menang (W)', 'Seri (D)', 'Kalah (L)'],
                      _hasil,
                      (v) => setState(() => _hasil = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Catatan Pelatih',
                    style: TextStyle(color: context.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _catatanCtrl,
                    maxLines: 4,
                    style: TextStyle(color: context.textPrimary),
                    decoration: InputDecoration(
                      hintText:
                          'Tuliskan catatan evaluasi taktikal atau performa pemain secara umum di sini...',
                      hintStyle: TextStyle(color: context.textHint),
                      filled: true,
                      fillColor: context.cardColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: context.borderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: context.borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFFFF000)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFF000),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    if (_selectedCount < 11) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Pilih tepat 11 pemain untuk Starting XI!',
                          ),
                        ),
                      );
                    } else if (_namaCtrl.text.isEmpty || _lawanCtrl.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Harap lengkapi nama pertandingan dan lawan!'),
                        ),
                      );
                    } else {
                      // Kumpulkan starting XI text namanya
                      List<String> listPemain = [];
                      _startingXI.forEach((nama, selected) {
                        if (selected) listPemain.add(nama);
                      });

                      String tgl = _selectedDate == null 
                         ? DateTime.now().toIso8601String() 
                         : _selectedDate!.toIso8601String();

                      // Broadcast to node.js socket backend
                      SocketService().socket.emit('save_manual_match', {
                        'namaPertandingan': _namaCtrl.text,
                        'lawan': _lawanCtrl.text,
                        'kompetisi': _kompetisi,
                        'formasi': _formasi,
                        'tanggal': tgl,
                        'skorAkhir': _skorCtrl.text.isNotEmpty ? _skorCtrl.text : '0 - 0',
                        'hasilAkhir': _hasil,
                        'catatan': _catatanCtrl.text,
                        'startingXI': listPemain
                      });

                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Data Pertandingan berhasil disimpan! Silakan cek Riwayat Match.'),
                        ),
                      );
                    }
                  },
                  child: const Text(
                    'Simpan Pertandingan',
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

  Widget _buildTextField(String label, String hint, {TextEditingController? controller}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: context.textSecondary, fontSize: 13)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          style: TextStyle(color: context.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: context.textHint),
            filled: true,
            fillColor: context.cardColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: context.borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: context.borderColor),
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

  Widget _buildDropdown(
    String label,
    List<String> items,
    String value,
    Function(String?) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: context.textSecondary, fontSize: 13)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: context.borderColor),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              dropdownColor: context.cardColor,
              value: value,
              style: TextStyle(color: context.textPrimary),
              icon: Icon(Icons.arrow_drop_down, color: context.textSecondary),
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
}
