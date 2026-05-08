import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../main.dart';
import '../services/socket_service.dart';

class RuleEngineScreen extends StatefulWidget {
  const RuleEngineScreen({super.key});

  @override
  State<RuleEngineScreen> createState() => _RuleEngineScreenState();
}

class _RuleEngineScreenState extends State<RuleEngineScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // State for tambah rule form
  bool _showAddForm = false;

  // --- Form state ---
  String _tipeRule = 'Fatigue Rule';
  String _kondisi1 = 'Stamina';
  String _operator1 = '<';
  String _kondisi2 = 'Menit Bermain';
  String _operator2 = '>';
  String _statusPertandingan = 'Kalah';
  String _aksi = 'Rekomendasi Substitusi';
  final _nilai1Ctrl = TextEditingController(text: '40');
  final _nilai2Ctrl = TextEditingController(text: '60');

  // --- Simulation state ---
  bool _showSimulation = false;
  String _simStamina = '35';
  String _simMenit = '65';
  String _simStatus = 'Kalah';
  String? _simResult;

  // --- Rule list ---
  // --- Rule list (Akan diupdate dari server) ---
  List<Map<String, dynamic>> _rules = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Connect ke real-time backend
    SocketService().connect();
    SocketService().socket.emit('request_sync');

    SocketService().socket.on('rules_sync', (data) {
      if (mounted && data != null) {
        setState(() {
          _rules = List<Map<String, dynamic>>.from(
              data.map((item) => Map<String, dynamic>.from(item)));
        });
      }
    });

    SocketService().socket.on('simulation_result', (data) {
      if (mounted && data != null) {
        setState(() {
          _simResult = data['message'];
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nilai1Ctrl.dispose();
    _nilai2Ctrl.dispose();
    super.dispose();
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
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              MainLayout.goToHome(context);
            }
          },
        ),
        title: Text(
          'Rule Engine',
          style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF000),
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                icon: Icon(Icons.add, color: Colors.black),
                onPressed: () {
                  setState(() {
                    _showAddForm = !_showAddForm;
                    _showSimulation = false;
                  });
                },
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search bar
            TextField(
              style: TextStyle(color: context.textPrimary),
              decoration: InputDecoration(
                hintText: 'Cari rule...',
                hintStyle: TextStyle(color: context.textSecondary),
                prefixIcon: Icon(Icons.search, color: context.textSecondary),
                filled: true,
                fillColor: context.cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
            SizedBox(height: 16),

            // Form Tambah Rule (expandable)
            if (_showAddForm) ...[
              _buildAddRuleForm(),
              SizedBox(height: 24),
            ],

            // Simulasi Panel (expandable)
            // Tombol simulasi
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                icon: Icon(
                  Icons.play_circle_outline,
                  color: Color(0xFFFFF000),
                ),
                label: Text(
                  'Simulasi Rule dengan Data Dummy',
                  style: TextStyle(
                    color: Color(0xFFFFF000),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Color(0xFFFFF000)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  setState(() {
                    _showSimulation = !_showSimulation;
                    _showAddForm = false;
                    _simResult = null;
                  });
                },
              ),
            ),
            SizedBox(height: 16),

            if (_showSimulation) ...[
              _buildSimulasiPanel(),
              SizedBox(height: 24),
            ],

            // Tab bar tipe rule
            Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: context.dividerColor, width: 2),
                ),
              ),
              child: TabBar(
                controller: _tabController,
                labelColor: const Color(0xFFFFF000),
                unselectedLabelColor: Colors.grey,
                indicatorColor: const Color(0xFFFFF000),
                indicatorWeight: 3,
                tabs: const [
                  Tab(text: 'Fatigue'),
                  Tab(text: 'Performance'),
                  Tab(text: 'Tactical'),
                ],
              ),
            ),
            SizedBox(height: 16),

            // Rule list
            Text(
              'DAFTAR RULE (${_rules.length})',
              style: TextStyle(
                color: context.textSecondary,
                fontSize: 11,
                letterSpacing: 1.5,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            ..._rules.asMap().entries.map((entry) {
              int i = entry.key;
              var rule = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildRuleCard(rule, i),
              );
            }),

            // Template helper
            SizedBox(height: 8),
            _buildHelpTemplateContainer(),
            SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildAddRuleForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFFF000).withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TAMBAH RULE BARU',
            style: TextStyle(
              color: Color(0xFFFFF000),
              fontWeight: FontWeight.bold,
              fontSize: 16,
              letterSpacing: 1.2,
            ),
          ),
          SizedBox(height: 16),
          _buildDropdownField(
            'Tipe Rule',
            ['Fatigue Rule', 'Performance Rule', 'Tactical Rule'],
            _tipeRule,
            (v) => setState(() => _tipeRule = v!),
          ),
          SizedBox(height: 16),
          Text(
            'KONDISI IF:',
            style: TextStyle(
              color: Color(0xFFFFF000),
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: _buildDropdownField(
                  'Kondisi 1',
                  ['Stamina', 'Menit Bermain', 'Rating', 'Jumlah Kesalahan'],
                  _kondisi1,
                  (v) => setState(() => _kondisi1 = v!),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                flex: 1,
                child: _buildDropdownField(
                  '',
                  ['<', '>', '=', '<=', '>='],
                  _operator1,
                  (v) => setState(() => _operator1 = v!),
                ),
              ),
              SizedBox(width: 8),
              Expanded(flex: 2, child: _buildInputSmall('Nilai', _nilai1Ctrl)),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: _buildDropdownField(
                  'Kondisi 2',
                  ['Menit Bermain', 'Stamina', 'Rating', 'Status'],
                  _kondisi2,
                  (v) => setState(() => _kondisi2 = v!),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                flex: 1,
                child: _buildDropdownField(
                  '',
                  ['>', '<', '=', '>=', '<='],
                  _operator2,
                  (v) => setState(() => _operator2 = v!),
                ),
              ),
              SizedBox(width: 8),
              Expanded(flex: 2, child: _buildInputSmall('Nilai', _nilai2Ctrl)),
            ],
          ),
          SizedBox(height: 8),
          _buildDropdownField(
            'Status Pertandingan',
            ['Kalah', 'Menang', 'Seri', 'Semua'],
            _statusPertandingan,
            (v) => setState(() => _statusPertandingan = v!),
          ),
          SizedBox(height: 16),
          Text(
            'AKSI THEN:',
            style: TextStyle(
              color: Color(0xFFFFF000),
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          SizedBox(height: 12),
          _buildDropdownField(
            'Rekomendasi',
            [
              'Rekomendasi Substitusi',
              'Pertahankan Tekanan',
              'Ganti Formasi',
              'Istirahatkan Pemain',
            ],
            _aksi,
            (v) => setState(() => _aksi = v!),
          ),
          SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFF000),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                // Emit ke server database
                SocketService().socket.emit('add_rule', {
                  'nama': _aksi,
                  'tipe': _tipeRule,
                  'if': 'Stamina $_operator1 ${_nilai1Ctrl.text} AND Menit $_operator2 ${_nilai2Ctrl.text} AND Status = $_statusPertandingan',
                  'then': _aksi,
                });
                
                setState(() {
                  _showAddForm = false;
                });
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Rule baru berhasil ditambahkan!'),
                  ),
                );
              },
              child: Text(
                'Simpan Rule',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimulasiPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFFF000).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SIMULASI RULE',
            style: TextStyle(
              color: Color(0xFFFFF000),
              fontWeight: FontWeight.bold,
              fontSize: 16,
              letterSpacing: 1.2,
            ),
          ),
          Text(
            'Uji rule dengan data dummy untuk melihat hasilnya',
            style: TextStyle(color: context.textSecondary, fontSize: 12),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSimInput(
                  'Stamina (%)',
                  _simStamina,
                  (v) => setState(() => _simStamina = v),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildSimInput(
                  'Menit Bermain',
                  _simMenit,
                  (v) => setState(() => _simMenit = v),
                ),
              ),
              SizedBox(width: 12),
              Expanded(child: _buildSimDropdown()),
            ],
          ),
          SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              icon: Icon(Icons.bolt, color: Colors.black),
              label: Text(
                'Jalankan Simulasi',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFF000),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                setState(() {
                  _simResult = "Memproses simulasi di server...";
                });
                SocketService().socket.emit('simulate_rule', {
                  'stamina': _simStamina,
                  'menit': _simMenit,
                  'status': _simStatus,
                });
              },
            ),
          ),
          if (_simResult != null) ...[
            SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _simResult!.startsWith('⚠️')
                    ? context.alertBg
                    : context.successBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _simResult!.startsWith('⚠️')
                      ? context.alertBorder
                      : context.successBorder,
                ),
              ),
              child: Text(
                _simResult!,
                style: TextStyle(
                  color: _simResult!.startsWith('⚠️')
                      ? context.alertText
                      : context.successText,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  height: 1.6,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSimInput(
    String label,
    String value,
    Function(String) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: context.textSecondary, fontSize: 11)),
        SizedBox(height: 6),
        TextFormField(
          initialValue: value,
          keyboardType: TextInputType.number,
          style: TextStyle(color: context.textPrimary, fontSize: 14),
          onChanged: onChanged,
          decoration: InputDecoration(
            filled: true,
            fillColor: context.cardColor,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Color(0xFF404040)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Color(0xFF404040)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Color(0xFFFFF000)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSimDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Status Match',
          style: TextStyle(color: context.textSecondary, fontSize: 11),
        ),
        SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: context.borderColor),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              dropdownColor: context.cardColor,
              value: _simStatus,
              style: TextStyle(color: context.textPrimary, fontSize: 13),
              icon: Icon(Icons.arrow_drop_down, color: context.textSecondary),
              items: ['Kalah', 'Menang', 'Seri'].map((String item) {
                return DropdownMenuItem<String>(value: item, child: Text(item));
              }).toList(),
              onChanged: (v) => setState(() => _simStatus = v!),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRuleCard(Map<String, dynamic> rule, int index) {
    final bool isActive = rule['aktif'] as bool;
    final Map<String, Color> tipeColor = {
      'Fatigue Rule': const Color(0xFFFF7043),
      'Performance Rule': const Color(0xFF42A5F5),
      'Tactical Rule': const Color(0xFF66BB6A),
    };
    final color = tipeColor[rule['tipe']] ?? const Color(0xFFFFF000);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive
              ? context.borderColor
              : context.borderColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  rule['tipe'] == 'Fatigue Rule'
                      ? Icons.local_fire_department
                      : rule['tipe'] == 'Performance Rule'
                      ? Icons.show_chart
                      : Icons.sports_soccer,
                  color: color,
                  size: 24,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rule['nama'],
                      style: TextStyle(
                        color: isActive ? Colors.white : Colors.grey,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        rule['tipe'].toUpperCase(),
                        style: TextStyle(
                          color: color,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: isActive,
                onChanged: (v) {
                  SocketService().socket.emit('toggle_rule', {
                    'id': rule['id'],
                    'aktif': v,
                  });
                  setState(() {
                    _rules[index]['aktif'] = v;
                  });
                },
                activeColor: Colors.white,
                activeTrackColor: const Color(0xFFFFF000),
                inactiveThumbColor: Colors.grey[400],
                inactiveTrackColor: Colors.white12,
              ),
            ],
          ),
          SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: context.bgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  color: context.textPrimary,
                  fontSize: 12,
                  height: 1.6,
                  fontFamily: 'monospace',
                ),
                children: [
                  TextSpan(
                    text: 'IF ',
                    style: TextStyle(color: color, fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: '${rule['if']}\n'),
                  TextSpan(
                    text: 'THEN ',
                    style: TextStyle(color: color, fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: rule['then']),
                ],
              ),
            ),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Icon(
                isActive ? Icons.access_time : Icons.info_outline,
                color: context.textSecondary,
                size: 14,
              ),
              SizedBox(width: 6),
              Text(
                isActive ? 'Terakhir aktif: ${rule['triggered']}' : 'Nonaktif',
                style: TextStyle(color: context.textSecondary, fontSize: 12),
              ),
              Spacer(),
              IconButton(
                onPressed: () {},
                icon: Icon(Icons.edit, color: context.textSecondary, size: 18),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              SizedBox(width: 16),
              IconButton(
                onPressed: () {
                  SocketService().socket.emit('delete_rule', rule['id']);
                  setState(() {
                    _rules.removeAt(index);
                  });
                },
                icon: Icon(
                  Icons.delete,
                  color: Colors.redAccent,
                  size: 18,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField(
    String label,
    List<String> items,
    String value,
    Function(String?) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) ...[
          Text(label, style: TextStyle(color: context.textSecondary, fontSize: 12)),
          SizedBox(height: 6),
        ],
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: context.bgColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: context.borderColor),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              dropdownColor: context.cardColor,
              value: value,
              style: TextStyle(color: context.textPrimary, fontSize: 13),
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

  Widget _buildInputSmall(String label, TextEditingController ctrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) ...[
          Text(label, style: TextStyle(color: context.textSecondary, fontSize: 12)),
          SizedBox(height: 6),
        ],
        TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          style: TextStyle(color: context.textPrimary, fontSize: 13),
          decoration: InputDecoration(
            filled: true,
            fillColor: context.bgColor,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 10,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Color(0xFF404040)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Color(0xFF404040)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Color(0xFFFFF000)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHelpTemplateContainer() {
    return Container(
      padding: const EdgeInsets.all(24),
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFFF000).withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(Icons.lightbulb, color: Color(0xFFFFF000), size: 36),
          SizedBox(height: 12),
          Text(
            'Butuh bantuan membuat rule?',
            style: TextStyle(color: context.textPrimary, fontSize: 14),
          ),
          SizedBox(height: 4),
          Text(
            'Klik tombol + di kanan atas untuk membuat rule IF-THEN baru.\nGunakan tombol Simulasi untuk mengujinya.',
            textAlign: TextAlign.center,
            style: TextStyle(color: context.textSecondary, fontSize: 12, height: 1.5),
          ),
        ],
      ),
    );
  }
}
