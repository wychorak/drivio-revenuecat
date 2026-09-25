import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Color constants
  static const Color primary = Color(0xFFE30613);
  static const Color primaryBright = Color(0xFFFF3341);
  static const Color bgDark = Color(0xFF080A12);
  static const Color bgCard = Color(0xFF121521);
  static const Color bgElevated = Color(0xFF1A1E2C);
  static const Color trapPin = Color(0xFFE30613);
  static const Color schoolPin = Color(0xFF00C853);
  static const Color routeBlue = Color(0xFF2979FF);
  static const Color premiumGold = Color(0xFFFFD700);
  static Color premiumAccent(BuildContext context) =>
      Theme.of(context).brightness == Brightness.light
      ? const Color(0xFF8A6400)
      : premiumGold;
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFA7B0C8);
  static const Color dividerColor = Color(0xFF282D3D);
  static const Color errorColor = Color(0xFFE30613);
  static const Color successColor = Color(0xFF00C853);
  static const Color bgLight = Color(0xFFF4F6FA);
  static const Color bgCardLight = Color(0xFFFFFFFF);
  static const Color textLight = Color(0xFF151824);
  static const Color textSecondaryLight = Color(0xFF60697C);

  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryBright, Color(0xFFB90012)],
  );

  static ThemeData? _cachedDarkTheme;
  static ThemeData? _cachedLightTheme;

  static ThemeData get darkTheme => _cachedDarkTheme ??= _buildDarkTheme();

  static ThemeData _buildDarkTheme() {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: routeBlue,
        surface: bgCard,
        error: errorColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimary,
        onSurfaceVariant: textSecondary,
        outline: dividerColor,
      ),
      scaffoldBackgroundColor: bgDark,
      textTheme: GoogleFonts.poppinsTextTheme(
        base.textTheme,
      ).apply(bodyColor: textPrimary, displayColor: textPrimary),
      appBarTheme: AppBarTheme(
        backgroundColor: bgDark,
        foregroundColor: textPrimary,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
          systemNavigationBarColor: bgDark,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.poppins(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(color: textPrimary),
      ),
      cardTheme: CardThemeData(
        color: bgCard,
        elevation: 2,
        shadowColor: Colors.black.withAlpha(80),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: dividerColor, width: 1),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 2,
          shadowColor: primary.withAlpha(90),
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          side: const BorderSide(color: dividerColor),
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: bgElevated,
        floatingLabelStyle: GoogleFonts.poppins(
          color: primary,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: dividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: errorColor),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: errorColor, width: 2),
        ),
        labelStyle: GoogleFonts.poppins(color: textSecondary, fontSize: 14),
        hintStyle: GoogleFonts.poppins(color: textSecondary, fontSize: 14),
        errorStyle: GoogleFonts.poppins(color: errorColor, fontSize: 12),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: bgCard,
        selectedItemColor: primary,
        unselectedItemColor: textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 70,
        backgroundColor: bgCard,
        indicatorColor: primary.withAlpha(34),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? primaryBright
                : textSecondary,
            size: 24,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => GoogleFonts.poppins(
            color: states.contains(WidgetState.selected)
                ? textPrimary
                : textSecondary,
            fontSize: 11,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
          ),
        ),
      ),
      drawerTheme: const DrawerThemeData(backgroundColor: bgCard, elevation: 0),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: bgCard,
        contentTextStyle: GoogleFonts.poppins(color: textPrimary, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
      dividerTheme: const DividerThemeData(color: dividerColor, thickness: 1),
      chipTheme: ChipThemeData(
        backgroundColor: bgCard,
        selectedColor: primary.withAlpha(30),
        labelStyle: GoogleFonts.poppins(color: textPrimary, fontSize: 12),
        side: const BorderSide(color: Color(0xFF1E2030)),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: primary,
        unselectedLabelColor: textSecondary,
        indicatorColor: primary,
        labelStyle: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
        unselectedLabelStyle: GoogleFonts.poppins(
          fontWeight: FontWeight.w400,
          fontSize: 13,
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: primary),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: GoogleFonts.poppins(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        contentTextStyle: GoogleFonts.poppins(
          color: textSecondary,
          fontSize: 14,
        ),
      ),
      listTileTheme: ListTileThemeData(
        textColor: textPrimary,
        iconColor: textSecondary,
        titleTextStyle: GoogleFonts.poppins(
          color: textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        subtitleTextStyle: GoogleFonts.poppins(
          color: textSecondary,
          fontSize: 12,
        ),
        tileColor: Colors.transparent,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
        minTileHeight: 54,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: bgCard,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: bgCard,
        showDragHandle: true,
        dragHandleColor: dividerColor,
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? primary
              : Colors.transparent,
        ),
        side: const BorderSide(color: textSecondary, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      ),
    );
  }

  static ThemeData get lightTheme => _cachedLightTheme ??= _buildLightTheme();

  static ThemeData _buildLightTheme() {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: routeBlue,
        surface: bgCardLight,
        error: errorColor,
        onPrimary: Colors.white,
        onSurface: textLight,
        onSurfaceVariant: textSecondaryLight,
        outline: Color(0xFFDDE1EA),
      ),
      scaffoldBackgroundColor: bgLight,
      textTheme: GoogleFonts.poppinsTextTheme(
        base.textTheme,
      ).apply(bodyColor: textLight, displayColor: textLight),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A2E),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
          systemNavigationBarColor: Colors.white,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.poppins(
          color: const Color(0xFF1A1A2E),
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: bgCardLight,
        elevation: 2,
        shadowColor: const Color(0x140F172A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 2,
          shadowColor: primary.withAlpha(50),
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        labelStyle: GoogleFonts.poppins(
          color: Colors.grey.shade600,
          fontSize: 14,
        ),
        hintStyle: GoogleFonts.poppins(
          color: Colors.grey.shade400,
          fontSize: 14,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: primary,
        unselectedItemColor: Color(0xFF9E9E9E),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 70,
        backgroundColor: Colors.white,
        indicatorColor: primary.withAlpha(24),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? primary
                : textSecondaryLight,
            size: 24,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => GoogleFonts.poppins(
            color: states.contains(WidgetState.selected)
                ? textLight
                : textSecondaryLight,
            fontSize: 11,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textLight,
          side: const BorderSide(color: Color(0xFFDDE1EA)),
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF1A1A2E),
        contentTextStyle: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: primary),
      drawerTheme: const DrawerThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFE4E7EE),
        thickness: 1,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: primary,
        unselectedLabelColor: textSecondaryLight,
        indicatorColor: primary,
        dividerColor: const Color(0xFFE4E7EE),
        labelStyle: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
        unselectedLabelStyle: GoogleFonts.poppins(
          fontWeight: FontWeight.w400,
          fontSize: 13,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      listTileTheme: ListTileThemeData(
        textColor: textLight,
        iconColor: textSecondaryLight,
        titleTextStyle: GoogleFonts.poppins(
          color: textLight,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        subtitleTextStyle: GoogleFonts.poppins(
          color: textSecondaryLight,
          fontSize: 12,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
        minTileHeight: 54,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        modalBackgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? primary
              : Colors.transparent,
        ),
        side: const BorderSide(color: textSecondaryLight, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      ),
    );
  }
}
