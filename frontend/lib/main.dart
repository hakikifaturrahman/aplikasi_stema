import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'services/socket_service.dart';
import 'screens/dashboard_screen.dart';
import 'screens/data_pemain_screen.dart';
import 'screens/statistik_performa_screen.dart';
import 'screens/monitoring_stamina_screen.dart';
import 'screens/pertandingan_screen.dart';
import 'screens/riwayat_match_screen.dart';
import 'screens/rule_engine_screen.dart';
import 'screens/laporan_screen.dart';
import 'screens/pengaturan_screen.dart';
import 'screens/tambah_pemain_screen.dart';
import 'screens/tambah_statistik_screen.dart';
import 'screens/squad_management_screen.dart';
import 'screens/login_screen.dart';
import 'theme/app_theme.dart';

export 'theme/app_theme.dart' show themeProvider, AppColors, AppColorsExt;

// GlobalKey untuk ScaffoldMessenger agar bisa menampilkan SnackBar notifikasi secara global dari mana saja
final GlobalKey<ScaffoldMessengerState> globalMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

// Menyimpan histori notifikasi global secara real-time
List<Map<String, dynamic>> globalNotifications = [];

// Flag untuk melacak apakah ada notifikasi baru yang belum dibaca
bool globalHasUnreadNotification = false;

void main() async {
  // Memastikan binding Flutter terinisialisasi sebelum proses asinkron SharedPreferences dijalankan
  WidgetsFlutterBinding.ensureInitialized();
  
  // Mengambil status login dari memori lokal (SharedPreferences)
  final prefs = await SharedPreferences.getInstance();
  final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

  runApp(MyApp(isLoggedIn: isLoggedIn));
}

/// MyApp: Root Widget Aplikasi STEMA
/// Menginisialisasi State global, tema (Terang/Gelap), rute aplikasi, dan pendengar event notifikasi.
class MyApp extends StatefulWidget {
  final bool isLoggedIn; // Status apakah user sudah login sebelumnya
  const MyApp({super.key, required this.isLoggedIn});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    // Mendengarkan perubahan tema (Terang/Gelap) dari themeProvider
    themeProvider.addListener(() {
      if (mounted) setState(() {});
    });

    // MENGINISIALISASI KONEKSI SOCKET.IO GLOBAL
    SocketService().connect();
    
    // Hapus listener 'rule_alert' yang sudah terdaftar sebelumnya untuk mencegah duplikasi
    SocketService().socket.off('rule_alert');
    
    // Daftarkan listener baru untuk event 'rule_alert' dari backend
    SocketService().socket.on('rule_alert', (data) {
      if (data != null) {
        final bool isCritical = data['level'] == 'CRITICAL';
        globalHasUnreadNotification = true;
        
        // Memasukkan notifikasi baru di baris paling atas (index 0)
        globalNotifications.insert(0, {
          'level': data['level'],
          'message': data['message'],
          'time': DateTime.now(),
        });

        // Menampilkan pesan SnackBar melayang (floating SnackBar) yang informatif secara global
        globalMessengerKey.currentState?.clearSnackBars();
        globalMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text(
              data['message'],
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isCritical ? Colors.white : Colors.black,
              ),
            ),
            backgroundColor: isCritical
                ? Colors.redAccent
                : const Color(0xFFFFF000), // Warna kuning mencolok untuk alert biasa
            duration: const Duration(seconds: 10),
            behavior: SnackBarBehavior.floating, // Posisi mengambang
            margin: const EdgeInsets.all(16),
            action: SnackBarAction(
              label: 'Oke',
              textColor: isCritical ? Colors.white : Colors.black,
              onPressed: () {},
            ),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scaffoldMessengerKey: globalMessengerKey,
      title: 'STEMA',
      debugShowCheckedModeBanner: false,
      theme: buildLightTheme(),     // Tema Terang Kustom
      darkTheme: buildDarkTheme(),   // Tema Gelap Kustom
      themeMode: themeProvider.themeMode,
      initialRoute: widget.isLoggedIn ? '/' : '/login', // Tentukan rute awal berdasarkan status login
      routes: {
        '/login': (context) => const LoginScreen(),
        '/': (context) => const MainLayout(),
        '/match': (context) => const PertandinganScreen(),
        '/history': (context) => const RiwayatMatchScreen(),
        '/reports': (context) => const LaporanScreen(),
        '/settings': (context) => const PengaturanScreen(),
        '/rules': (context) => const RuleEngineScreen(),
        '/tambah_pemain': (context) => const TambahPemainScreen(),
        '/tambah_statistik': (context) => const TambahStatistikScreen(),
        '/manage_squad': (context) => const SquadManagementScreen(),
      },
    );
  }
}

/// MainLayout: Widget Tata Letak Utama dengan Bottom Navigation Bar
/// Memfasilitasi perpindahan tab antar halaman utama menggunakan animasi halus (AnimatedSwitcher).
class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  // Fungsi helper untuk mengarahkan pengguna kembali ke tab home/dashboard dari screen lain
  static void goToHome(BuildContext context) {
    context.findAncestorStateOfType<MainLayoutState>()?.setTab(0);
  }

  @override
  State<MainLayout> createState() => MainLayoutState();
}

class MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0; // Menyimpan index tab aktif

  // Mengubah tab aktif dan memperbarui UI
  void setTab(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Daftar screen widget yang berkorespondensi dengan masing-masing tab BottomNavigationBar
  final List<Widget> _screens = [
    const DashboardScreen(),
    const DataPemainScreen(),
    const StatistikPerformaScreen(),
    const MonitoringStaminaScreen(),
    const PengaturanScreen(),
    // Rute screen ekstra untuk navigasi langsung di dalam layout
    const RuleEngineScreen(),
    const PertandinganScreen(),
    const RiwayatMatchScreen(),
    const LaporanScreen(),
  ];

  void _onItemTapped(int index) {
    setTab(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _screens[_selectedIndex], // Menampilkan halaman dengan transisi halus
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        bottom: true,
        child: BottomNavigationBar(
          // Memastikan BottomNavigationBar tetap menyorot index valid (0-4) meskipun layar extra terbuka
          currentIndex: _selectedIndex > 4 ? 0 : _selectedIndex,
          onTap: (idx) {
            if (idx <= 4) _onItemTapped(idx);
          },
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_filled),
              label: 'HOME',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.group), label: 'PLAYERS'),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart),
              label: 'STATS',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.monitor_heart),
              label: 'MONITOR',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.manage_accounts),
              label: 'SETTINGS',
            ),
          ],
        ),
      ),
    );
  }
}
