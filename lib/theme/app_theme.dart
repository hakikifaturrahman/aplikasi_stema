import 'package:flutter/material.dart';

// ─── Theme Colors ─────────────────────────────────────────────────────────────
class AppColors {
  // Dark Mode
  static const Color darkBg = Color(0xFF1B1A12);
  static const Color darkCard = Color(0xFF242217);
  static const Color darkCardAlt = Color(0xFF2C2B1E);
  static const Color darkBorder = Color(0xFF404040);
  static const Color darkSearchFill = Color(0xFF1F202B);
  static const Color darkSectionBadge = Color(0xFF2B2A0F);
  static const Color darkPosBadge = Color(0xFF636417);

  // Light Mode
  static const Color lightBg = Color(0xFFF5F4EC);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightCardAlt = Color(0xFFF0EFE5);
  static const Color lightBorder = Color(0xFFDDDDD0);
  static const Color lightSearchFill = Color(0xFFEEEEEE);
  static const Color lightSectionBadge = Color(0xFFFFF9CC);
  static const Color lightPosBadge = Color(0xFFF5E040);

  // Shared
  static const Color primary = Color(0xFFFFF000);
  static const Color primaryDark = Color(0xFFCCC000); // for light mode text
}

// ─── BuildContext Extension ────────────────────────────────────────────────────
extension AppColorsExt on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  Color get bgColor => isDark ? AppColors.darkBg : AppColors.lightBg;
  Color get cardColor => isDark ? AppColors.darkCard : AppColors.lightCard;
  Color get cardAltColor =>
      isDark ? AppColors.darkCardAlt : AppColors.lightCardAlt;
  Color get borderColor =>
      isDark ? AppColors.darkBorder : AppColors.lightBorder;
  Color get textPrimary => isDark ? Colors.white : const Color(0xFF1B1A12);
  Color get textSecondary => isDark ? Colors.grey : const Color(0xFF666650);
  Color get textHint => isDark ? Colors.white38 : Colors.black26;
  Color get searchFill =>
      isDark ? AppColors.darkSearchFill : AppColors.lightSearchFill;
  Color get sectionBadgeBg =>
      isDark ? AppColors.darkSectionBadge : AppColors.lightSectionBadge;
  Color get posBadgeBg =>
      isDark ? AppColors.darkPosBadge : AppColors.lightPosBadge;
  Color get posBadgeText =>
      isDark ? AppColors.primary : const Color(0xFF5A4A00);
  Color get dividerColor => isDark ? Colors.white12 : Colors.black12;
  Color get iconMuted => isDark ? Colors.grey : const Color(0xFF888870);
  Color get alertBg =>
      isDark ? const Color(0xFF3E1F00) : const Color(0xFFFFF3E0);
  Color get alertBorder => isDark ? Colors.orangeAccent : Colors.orange;
  Color get alertText => isDark ? Colors.orangeAccent : const Color(0xFFE65100);
  Color get successBg =>
      isDark ? const Color(0xFF1A3E1A) : const Color(0xFFF1F8E9);
  Color get successBorder => isDark ? Colors.greenAccent : Colors.green;
  Color get successText =>
      isDark ? Colors.greenAccent : const Color(0xFF2E7D32);
}

// ─── ThemeProvider ─────────────────────────────────────────────────────────────
class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark;

  ThemeMode get themeMode => _themeMode;
  bool get isDark => _themeMode == ThemeMode.dark;

  void toggleTheme() {
    _themeMode = isDark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }

  void setDark() {
    _themeMode = ThemeMode.dark;
    notifyListeners();
  }

  void setLight() {
    _themeMode = ThemeMode.light;
    notifyListeners();
  }
}

// ─── Global Theme Provider Instance ──────────────────────────────────────────
final themeProvider = ThemeProvider();

// ─── Theme Data ──────────────────────────────────────────────────────────────
ThemeData buildDarkTheme() {
  const textTheme = TextTheme(
    displayLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
    displayMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
    displaySmall: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
    headlineLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
    headlineMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
    headlineSmall: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
    titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
    titleMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
    titleSmall: TextStyle(color: Colors.white70),
    bodyLarge: TextStyle(color: Colors.white),
    bodyMedium: TextStyle(color: Colors.white),
    bodySmall: TextStyle(color: Colors.grey),
    labelLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
    labelMedium: TextStyle(color: Colors.white70),
    labelSmall: TextStyle(color: Colors.grey),
  );

  return ThemeData.dark().copyWith(
    scaffoldBackgroundColor: AppColors.darkBg,
    cardColor: AppColors.darkCard,
    textTheme: textTheme,
    primaryTextTheme: textTheme,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.darkBg,
      elevation: 0,
      centerTitle: false,
      iconTheme: IconThemeData(color: Colors.white),
      foregroundColor: Colors.white,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: AppColors.darkBg,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: Colors.grey[600],
    ),
    iconTheme: const IconThemeData(color: Colors.white70),
    colorScheme: const ColorScheme.dark().copyWith(
      primary: AppColors.primary,
      surface: AppColors.darkCard,
      onSurface: Colors.white,
      onBackground: Colors.white,
    ),
    dividerColor: Colors.white12,
    listTileTheme: const ListTileThemeData(
      textColor: Colors.white,
      iconColor: Colors.white70,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.darkCard,
      hintStyle: const TextStyle(color: Colors.grey),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.darkBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.darkBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return AppColors.primary;
        return null;
      }),
      checkColor: WidgetStateProperty.all(Colors.black),
      side: const BorderSide(color: Colors.grey),
    ),
  );
}

ThemeData buildLightTheme() {
  const Color textDark = Color(0xFF1B1A12);
  const Color textMuted = Color(0xFF555540);
  const Color textSecondary = Color(0xFF666650);

  const textTheme = TextTheme(
    displayLarge: TextStyle(color: textDark, fontWeight: FontWeight.bold),
    displayMedium: TextStyle(color: textDark, fontWeight: FontWeight.bold),
    displaySmall: TextStyle(color: textDark, fontWeight: FontWeight.bold),
    headlineLarge: TextStyle(color: textDark, fontWeight: FontWeight.bold),
    headlineMedium: TextStyle(color: textDark, fontWeight: FontWeight.bold),
    headlineSmall: TextStyle(color: textDark, fontWeight: FontWeight.bold),
    titleLarge: TextStyle(color: textDark, fontWeight: FontWeight.bold),
    titleMedium: TextStyle(color: textDark, fontWeight: FontWeight.w600),
    titleSmall: TextStyle(color: textMuted, fontWeight: FontWeight.w600),
    bodyLarge: TextStyle(color: textDark),
    bodyMedium: TextStyle(color: textDark),
    bodySmall: TextStyle(color: textSecondary),
    labelLarge: TextStyle(color: textDark, fontWeight: FontWeight.bold),
    labelMedium: TextStyle(color: textMuted),
    labelSmall: TextStyle(color: textSecondary),
  );

  return ThemeData.light().copyWith(
    scaffoldBackgroundColor: AppColors.lightBg,
    cardColor: AppColors.lightCard,
    // ── Global text theme: teks otomatis gelap di light mode ──
    textTheme: textTheme,
    primaryTextTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.lightBg,
      elevation: 0,
      centerTitle: false,
      iconTheme: const IconThemeData(color: textDark),
      titleTextStyle: const TextStyle(
        color: textDark,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      surfaceTintColor: Colors.transparent,
      // AppBar teks juga perlu di-set
      foregroundColor: textDark,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.lightBg,
      selectedItemColor: Color(0xFF8B7A00),
      unselectedItemColor: Color(0xFF999980),
    ),
    colorScheme: const ColorScheme.light().copyWith(
      primary: AppColors.primaryDark,
      surface: AppColors.lightCard,
      onSurface: textDark,
      onBackground: textDark,
    ),
    dividerColor: Colors.black12,
    // ── Default icon color di light mode ──
    iconTheme: const IconThemeData(color: textMuted),
    // ── Input fields ──
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.lightCard,
      hintStyle: const TextStyle(color: Color(0xFF999980)),
      labelStyle: const TextStyle(color: textMuted),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.lightBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.lightBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF8B7A00), width: 2),
      ),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected))
          return const Color(0xFF8B7A00);
        return null;
      }),
      checkColor: WidgetStateProperty.all(Colors.white),
      side: const BorderSide(color: Color(0xFF999980)),
    ),
    // ── ListTile, Card default ──
    listTileTheme: const ListTileThemeData(
      textColor: textDark,
      iconColor: textMuted,
    ),
  );
}
