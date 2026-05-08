import 'package:flutter/material.dart';

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
import 'theme/app_theme.dart';

export 'theme/app_theme.dart' show themeProvider, AppColors, AppColorsExt;

final GlobalKey<ScaffoldMessengerState> globalMessengerKey =
    GlobalKey<ScaffoldMessengerState>();
List<Map<String, dynamic>> globalNotifications = [];
bool globalHasUnreadNotification = false;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    themeProvider.addListener(() {
      if (mounted) setState(() {});
    });

    // START GLOBAL LISTENER UNTUK NOTIFIKASI
    SocketService().connect();
    SocketService().socket.off('rule_alert');
    SocketService().socket.on('rule_alert', (data) {
      if (data != null) {
        final bool isCritical = data['level'] == 'CRITICAL';
        globalHasUnreadNotification = true;
        globalNotifications.insert(0, {
          'level': data['level'],
          'message': data['message'],
          'time': DateTime.now(),
        });

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
                : const Color(0xFFFFF000),
            duration: const Duration(seconds: 10),
            behavior: SnackBarBehavior.floating, // Muncul mengambang keren
            margin: const EdgeInsets.all(16), // Memberi sedikit jarak
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
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: themeProvider.themeMode,
      initialRoute: '/',
      routes: {
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

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  static void goToHome(BuildContext context) {
    context.findAncestorStateOfType<MainLayoutState>()?.setTab(0);
  }

  @override
  State<MainLayout> createState() => MainLayoutState();
}

class MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;

  void setTab(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  final List<Widget> _screens = [
    const DashboardScreen(),
    const DataPemainScreen(),
    const StatistikPerformaScreen(),
    const MonitoringStaminaScreen(),
    const PengaturanScreen(),
    // extra screens to switch directly from menu without layout
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
        child: _screens[_selectedIndex],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        bottom: true,
        child: BottomNavigationBar(
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
