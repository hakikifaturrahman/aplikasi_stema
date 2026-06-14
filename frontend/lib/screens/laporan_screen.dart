import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:universal_html/html.dart' as html;
import '../theme/app_theme.dart';
import '../services/socket_service.dart';

/// Widget Screen: LaporanScreen
/// Halaman untuk menyusun dan mengekspor laporan kinerja tim (PDF dan Excel).
/// Menggunakan data real-time dari database backend (pemain, riwayat match, rule engine)
/// dan menyajikan pratinjau statistik sebelum diekspor.
class LaporanScreen extends StatefulWidget {
  const LaporanScreen({super.key});

  @override
  State<LaporanScreen> createState() => _LaporanScreenState();
}

class _LaporanScreenState extends State<LaporanScreen> {
  String _selectedPeriode = 'Minggu Ini'; // Periode laporan yang dipilih
  bool _isGeneratingPdf = false;           // Status pemrosesan export PDF
  bool _isGeneratingExcel = false;         // Status pemrosesan export Excel
  String? _exportMessage;                  // Pesan feedback hasil export (sukses/error)
  bool _isLoading = true;                  // Status pemuatan awal data

  // Data sinkronisasi dari server backend
  List<dynamic> _players = [];
  List<dynamic> _riwayat = [];
  List<dynamic> _rules = [];

  // Konfigurasi struktur data masing-masing jenis laporan
  final List<Map<String, dynamic>> _reportTypes = [
    {
      'judul': 'Laporan Performa Pemain',
      'subtitle': 'Statistik individu lengkap: rating, sprint, assist, dan kesalahan',
      'icon': Icons.person_outline,
      'color': const Color(0xFF42A5F5),
      'kategori': 'PERFORMA & KESEHATAN',
      'data': [
        {'label': 'Rata-rata Rating', 'value': '-'},
        {'label': 'Pemain Terbaik', 'value': '-'},
        {'label': 'Total Sprint', 'value': '-'},
      ],
      'selected': false,
    },
    {
      'judul': 'Laporan Stamina Mingguan',
      'subtitle': 'Tren kelelahan dan perkiraan pemulihan stamina per pemain',
      'icon': Icons.show_chart,
      'color': const Color(0xFF66BB6A),
      'kategori': 'PERFORMA & KESEHATAN',
      'data': [
        {'label': 'Rata-rata Stamina', 'value': '-'},
        {'label': 'Pemain Kritis', 'value': '-'},
        {'label': 'Stamina Tertinggi', 'value': '-'},
      ],
      'selected': false,
    },
    {
      'judul': 'Rekomendasi Substitusi',
      'subtitle': 'Pola rata-rata penggantian pemain berdasarkan riwayat match',
      'icon': Icons.swap_horiz,
      'color': const Color(0xFFFF7043),
      'kategori': 'ANALISIS TAKTIKAL',
      'data': [
        {'label': 'Total Match Hist', 'value': '-'},
        {'label': 'Total Substitusi', 'value': '-'},
        {'label': 'Avg Sub/Match', 'value': '-'},
      ],
      'selected': false,
    },
    {
      'judul': 'Evaluasi Efektivitas Rule',
      'subtitle': 'Analisis dampak setiap rule otomatis',
      'icon': Icons.rule_folder,
      'color': const Color(0xFFAB47BC),
      'kategori': 'ANALISIS TAKTIKAL',
      'data': [
        {'label': 'Rule Aktif', 'value': '-'},
        {'label': 'Total Trigger', 'value': '-'},
        {'label': 'Rule Tersibuk', 'value': '-'},
      ],
      'selected': false,
    },
  ];

  @override
  void initState() {
    super.initState();
    _connectSocket();
  }

  // Menghubungkan Socket dan mendaftarkan event listener sinkronisasi database
  void _connectSocket() {
    SocketService().connect();
    SocketService().socket.emit('request_sync');

    // Mendengarkan pembaruan roster pemain
    SocketService().socket.on('stamina_sync', (data) {
      if (mounted) {
        setState(() {
          _players = data;
          _updateReports();
        });
      }
    });

    // Mendengarkan pembaruan riwayat pertandingan
    SocketService().socket.on('riwayat_sync', (data) {
      if (mounted) {
        setState(() {
          _riwayat = data;
          _updateReports();
        });
      }
    });

    // Mendengarkan pembaruan aturan rule engine
    SocketService().socket.on('rules_sync', (data) {
      if (mounted) {
        setState(() {
          _rules = data;
          _updateReports();
        });
      }
    });

    // Batas waktu fallback jika koneksi lambat agar loading spinner berhenti
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted && _isLoading) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  // Melakukan kalkulasi statistik dinamis berdasarkan data terbaru yang diterima
  void _updateReports() {
    // 1. Kalkulasi Laporan Performa Pemain
    double totalRating = 0;
    int ratingCount = 0;
    int totalSprint = 0;
    Map<String, List<double>> playerRatings = {};

    for (var match in _riwayat) {
      if (match['performaPemain'] != null) {
        for (var p in match['performaPemain']) {
          double? r = double.tryParse(p['rating']?.toString() ?? '');
          int? s = int.tryParse(p['sprint']?.toString() ?? '');
          if (r != null) {
            totalRating += r;
            ratingCount++;
            playerRatings.putIfAbsent(p['nama'].toString(), () => []).add(r);
          }
          if (s != null) totalSprint += s;
        }
      }
    }

    String avgRating = ratingCount > 0 ? (totalRating / ratingCount).toStringAsFixed(1) : '-';
    
    String bestPlayer = '-';
    double highestAvg = 0;
    playerRatings.forEach((nama, ratings) {
      double avg = ratings.reduce((a, b) => a + b) / ratings.length;
      if (avg > highestAvg) {
        highestAvg = avg;
        bestPlayer = nama;
      }
    });
    
    // Potong nama panjang untuk menjaga estetika UI
    if (bestPlayer.contains(' ')) bestPlayer = bestPlayer.split(' ').first;

    // 2. Kalkulasi Laporan Stamina Mingguan
    double totalStamina = 0;
    int criticalCount = 0;
    String highestStaminaPlayer = '-';
    int highestStamina = -1;

    for (var p in _players) {
      int stam = p['stamina'] != null ? int.tryParse(p['stamina'].toString()) ?? 100 : 100;
      totalStamina += stam;
      if (stam < 40) criticalCount++; // Di bawah 40% dianggap kritis kelelahan
      if (stam > highestStamina) {
        highestStamina = stam;
        String namaPendek = p['nama'].toString().contains(' ') ? p['nama'].toString().split(' ').first : p['nama'].toString();
        highestStaminaPlayer = '$namaPendek ($stam%)';
      }
    }
    String avgStamina = _players.isNotEmpty ? '${(totalStamina / _players.length).toStringAsFixed(0)}%' : '-';

    // 3. Kalkulasi Info Substitusi
    int totalSubs = 0;
    for (var match in _riwayat) {
      int subs = int.tryParse(match['totalSubstitusi']?.toString() ?? '0') ?? 0;
      totalSubs += subs;
    }

    // 4. Kalkulasi Evaluasi Efektivitas Rule
    int activeRules = _rules.where((r) => r['aktif'] == true).length;
    int sumTrigger = 0;
    String bestRule = '-';
    int maxTrigger = -1;

    for (var r in _rules) {
      int t = int.tryParse(r['triggered']?.toString() ?? '0') ?? 0;
      sumTrigger += t;
      if (t > maxTrigger && t > 0) {
        maxTrigger = t;
        bestRule = r['nama']?.toString() ?? '-';
      }
    }
    if (bestRule.length > 12) {
      bestRule = bestRule.substring(0, 10) + '..'; // Memotong teks rule tersibuk
    }

    // Memperbarui visual pratinjau data pada masing-masing card laporan
    setState(() {
      _reportTypes[0]['data'] = [
        {'label': 'Rata-rata Rating', 'value': avgRating},
        {'label': 'Pemain Terbaik', 'value': bestPlayer},
        {'label': 'Total Sprint', 'value': totalSprint.toString()},
      ];
      _reportTypes[1]['data'] = [
        {'label': 'Rata-rata Stamina', 'value': avgStamina},
        {'label': 'Pemain Kritis', 'value': '$criticalCount'},
        {'label': 'Stamina Tertinggi', 'value': highestStaminaPlayer},
      ];
      _reportTypes[2]['data'] = [
        {'label': 'Total Match', 'value': '${_riwayat.length}'},
        {'label': 'Total Substitusi', 'value': '$totalSubs'},
        {'label': 'Avg Sub/Match', 'value': _riwayat.isNotEmpty ? (totalSubs/_riwayat.length).toStringAsFixed(1) : '-'},
      ];
      _reportTypes[3]['data'] = [
        {'label': 'Rule Aktif', 'value': '$activeRules'},
        {'label': 'Total Trigger', 'value': '$sumTrigger'},
        {'label': 'Rule Tersibuk', 'value': bestRule},
      ];
      _isLoading = false;
    });
  }

  // Menghitung berapa banyak jenis laporan yang dipilih pengguna
  int get _selectedCount =>
      _reportTypes.where((r) => r['selected'] == true).length;

  // Fungsi internal memproses export data ke dokumen spreadsheet Excel (.xlsx)
  Future<void> _exportExcel() async {
    setState(() {
      _isGeneratingExcel = true;
      _exportMessage = null;
    });

    try {
      var excel = Excel.createExcel();

      for (var report in _reportTypes) {
        if (report['selected']) {
          final String title = report['judul'] as String;
          // Excel membatasi panjang nama sheet maksimal 31 karakter
          final String safeSheetName = title.length > 31 ? title.substring(0, 31) : title;
          final Sheet sheetObject = excel[safeSheetName];

          // Pengaturan header sheet
          final headerStyle = CellStyle(bold: true);
          var headerIndikator = sheetObject.cell(CellIndex.indexByString("A1"));
          headerIndikator.value = TextCellValue("Indikator");
          headerIndikator.cellStyle = headerStyle;

          var headerNilai = sheetObject.cell(CellIndex.indexByString("B1"));
          headerNilai.value = TextCellValue("Nilai / Hasil");
          headerNilai.cellStyle = headerStyle;

          final data = (report['data'] as List).cast<Map<String, String>>();
          int rowIndex = 2;
          
          // Mengisi baris demi baris data
          for (var item in data) {
            sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex - 1)).value = TextCellValue(item['label'] ?? '');
            sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex - 1)).value = TextCellValue(item['value'] ?? '');
            rowIndex++;
          }
        }
      }

      // Menghapus lembar default 'Sheet1' bawaan excel kosong jika lembar lain sudah terbuat
      if (excel.tables.keys.contains('Sheet1') && excel.tables.keys.length > 1) {
        excel.delete('Sheet1');
      }

      final String safePeriode = _selectedPeriode.replaceAll(' ', '_');
      final fileName = 'Laporan_SFA_$safePeriode.xlsx';
      final List<int>? fileBytes = excel.save();

      // Eksekusi pengunduhan file (Web environment)
      if (fileBytes != null) {
        final blob = html.Blob([fileBytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        html.AnchorElement(href: url)
          ..setAttribute("download", fileName)
          ..click();
        html.Url.revokeObjectUrl(url);

        if (mounted) {
          setState(() {
            _isGeneratingExcel = false;
            _exportMessage = '✅ File Excel Laporan berhasil di-download!';
          });
        }
      } else {
        throw Exception("Gagal membuat bytes Excel");
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isGeneratingExcel = false;
          _exportMessage = '❌ Terjadi kesalahan saat menggenerate Excel: $e';
        });
      }
    }
  }

  // Fungsi pengarah untuk memilih PDF atau Excel saat penekanan tombol export
  Future<void> _simulateExport(bool isPdf) async {
    if (_selectedCount == 0) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih minimal 1 laporan untuk diexport!')),
      );
      return;
    }

    if (!isPdf) {
      await _exportExcel();
      return;
    }

    setState(() {
      _isGeneratingPdf = true;
      _exportMessage = null;
    });

    try {
      final doc = pw.Document();

      // Menyusun halaman PDF demi halaman untuk setiap laporan terpilih
      for (var report in _reportTypes) {
        if (report['selected']) {
          final title = report['judul'];
          final subtitle = report['subtitle'];
          final data = (report['data'] as List).cast<Map<String, String>>();
          
          doc.addPage(
            pw.Page(
              pageFormat: PdfPageFormat.a4,
              build: (pw.Context context) {
                return pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('SMART FOOTBALL ASSISTANT', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
                    pw.SizedBox(height: 5),
                    pw.Text('Laporan Analitik & Performa', style: pw.TextStyle(fontSize: 16, color: PdfColors.grey700)),
                    pw.Divider(color: PdfColors.grey400),
                    pw.SizedBox(height: 20),

                    pw.Text(title, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
                    pw.Text(subtitle, style: pw.TextStyle(fontSize: 12, color: PdfColors.grey600)),
                    pw.SizedBox(height: 15),

                    // Penyusunan tabel data laporan
                    pw.TableHelper.fromTextArray(
                      border: pw.TableBorder.all(color: PdfColors.grey300),
                      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
                      headers: ['Indikator', 'Nilai / Hasil'],
                      data: data.map((item) => [item['label'] ?? '', item['value'] ?? '']).toList(),
                      cellAlignment: pw.Alignment.centerLeft,
                      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      cellPadding: const pw.EdgeInsets.all(10),
                    ),
                    
                    pw.Spacer(),
                    pw.Divider(color: PdfColors.grey400),
                    pw.Text('Digenerate otomatis pada: ${DateTime.now().toLocal()}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey500)),
                  ],
                );
              },
            ),
          );
        }
      }

      final String safePeriode = _selectedPeriode.replaceAll(' ', '_');
      final bytes = await doc.save();
      
      // Membuka native print dialogue atau sharing sheet
      await Printing.sharePdf(bytes: bytes, filename: 'Laporan_SFA_$safePeriode.pdf');

      if (mounted) {
        setState(() {
          _isGeneratingPdf = false;
          _exportMessage = '✅ File PDF Laporan berhasil di-download!';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isGeneratingPdf = false;
          _exportMessage = '❌ Terjadi kesalahan saat menggenerate PDF: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: context.bgColor,
        body: const Center(child: CircularProgressIndicator(color: Color(0xFFFFF000))),
      );
    }

    // Mengelompokkan laporan berdasarkan kategorinya
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (var r in _reportTypes) {
      final cat = r['kategori'] as String;
      grouped.putIfAbsent(cat, () => []).add(r);
    }

    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        backgroundColor: context.bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.textPrimary),
          onPressed: () {
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
        ),
        title: Text(
          'Laporan & Analitik',
          style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.share, color: context.textPrimary),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner Info Sinkronisasi
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: context.isDark
                      ? const [Color(0xFF2D5016), Color(0xFF3A6A20)]
                      : const [Color(0xFFC8E6C9), Color(0xFFA5D6A7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: context.isDark
                      ? const Color(0xFF4A7C2F)
                      : const Color(0xFF66BB6A),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.analytics_outlined,
                    color: Color(0xFFFFF000),
                    size: 40,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Generate Laporan Aktual',
                          style: TextStyle(
                            color: context.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Data disinkronisasi langsung dari database backend. Pilih kategori untuk export.',
                          style: TextStyle(
                            color: context.textSecondary,
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Dropdown Pemilihan Filter Periode Laporan
            Row(
              children: [
                Text(
                  'Periode:',
                  style: TextStyle(color: context.textSecondary, fontSize: 13),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
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
                        value: _selectedPeriode,
                        style: TextStyle(color: context.textPrimary),
                        icon: Icon(
                          Icons.arrow_drop_down,
                          color: context.textSecondary,
                        ),
                        items:
                            [
                              'Minggu Ini',
                              'Bulan Ini',
                              'Musim Ini',
                              'Kustom...',
                            ].map((String item) {
                              return DropdownMenuItem<String>(
                                value: item,
                                child: Text(item),
                              );
                            }).toList(),
                        onChanged: (v) => setState(() => _selectedPeriode = v!),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Daftar Card Kategori Laporan
            ...grouped.entries.map((entry) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.key,
                    style: TextStyle(
                      color: context.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...entry.value.map((report) {
                    final idx = _reportTypes.indexOf(report);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildReportCard(report, idx),
                    );
                  }),
                  const SizedBox(height: 12),
                ],
              );
            }),

            // Summary Informasi Laporan yang Terpilih
            if (_selectedCount > 0) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: context.cardColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFFFFF000).withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Color(0xFFFFF000),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$_selectedCount laporan dipilih untuk diexport',
                      style: TextStyle(
                        color: context.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Bagian Pilihan Format File Ekspor (Opsi Export)
            Text(
              'OPSI EXPORT',
              style: TextStyle(
                color: context.textSecondary,
                fontWeight: FontWeight.bold,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildExportButton(
                    label: 'Export PDF',
                    icon: Icons.picture_as_pdf,
                    isLoading: _isGeneratingPdf,
                    backgroundColor: Colors.white,
                    textColor: Colors.black,
                    onTap: () => _simulateExport(true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildExportButton(
                    label: 'Export Excel',
                    icon: Icons.table_chart,
                    isLoading: _isGeneratingExcel,
                    backgroundColor: const Color(0xFFFFF000),
                    textColor: Colors.black,
                    onTap: () => _simulateExport(false),
                  ),
                ),
              ],
            ),

            // Tampilan Pesan Hasil Pengerjaan Ekspor (Berhasil / Gagal)
            if (_exportMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: context.successBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: context.successBorder.withValues(alpha: 0.5),
                  ),
                ),
                child: Text(
                  _exportMessage!,
                  style: TextStyle(
                    color: context.successText,
                    fontSize: 13,
                    height: 1.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // Builder Kartu Laporan Individu
  Widget _buildReportCard(Map<String, dynamic> report, int idx) {
    final bool isSelected = report['selected'] as bool;
    final Color color = report['color'] as Color;
    final List<Map<String, String>> data = (report['data'] as List)
        .cast<Map<String, String>>();

    return GestureDetector(
      onTap: () {
        setState(() {
          _reportTypes[idx]['selected'] = !isSelected;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? color.withValues(alpha: 0.8)
                : context.borderColor,
            width: isSelected ? 1.5 : 1,
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
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    report['icon'] as IconData,
                    color: color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        report['judul'],
                        style: TextStyle(
                          color: context.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        report['subtitle'],
                        style: TextStyle(
                          color: context.textSecondary,
                          fontSize: 12,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                Checkbox(
                  value: isSelected,
                  onChanged: (v) {
                    setState(() {
                      _reportTypes[idx]['selected'] = v!;
                    });
                  },
                  activeColor: color,
                  checkColor: Colors.white,
                  side: BorderSide(color: color.withValues(alpha: 0.5)),
                ),
              ],
            ),
            
            // Baris Pratinjau Nilai Indikator Ringkas
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: context.bgColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: data.map((item) {
                  return Column(
                    children: [
                      Text(
                        item['value']!,
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item['label']!,
                        style: TextStyle(
                          color: context.textSecondary,
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Builder Tombol Aksi Ekspor File
  Widget _buildExportButton({
    required String label,
    required IconData icon,
    required Color backgroundColor,
    required Color textColor,
    required bool isLoading,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: isLoading
              ? SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: textColor,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: textColor, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
