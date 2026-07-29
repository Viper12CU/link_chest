import 'package:flutter/material.dart';

class AppTheme {
  // ── Palette ──────────────────────────────────────────────
static const _background = Color.fromARGB(255, 227, 228, 228);      // gris claro (CCD0CF)
static const _backgroundDark = Color(0xFF06141B);   // casi negro azulado (06141B)
static const _surfaceLight = Color(0xFFFFFFFF);     // blanco puro para cards sobre el gris claro
static const _surfaceDark = Color(0xFF11212D);      // navy carbón (11212D)
static const _primary = Color(0xFF253745);          // slate oscuro (253745) — acciones principales, mejor contraste
static const _secondary = Color(0xFF4A5C6A);        // slate medio (4A5C6A)
static const _accentBlue = Color(0xFF9BA8AB);       // gris azulado claro (9BA8AB) — bordes, disabled, iconos secundarios
static const _accentAmber = Color(0xFF9BA8AB);      // mismo gris — no hay tono cálido real en esta paleta
static const _textPrimary = Color(0xFF06141B);      // casi negro (06141B)
static const _textSecondary = Color(0xFF4A5C6A);    // slate medio (4A5C6A)


  // ── Shared shape ─────────────────────────────────────────
  static final _cardShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(16),
  );

  // ── Input decoration ─────────────────────────────────────
  static InputDecorationTheme _inputTheme(ColorScheme cs) =>
      InputDecorationTheme(
        filled: true,
        fillColor: cs.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _primary),
        ),
        labelStyle: TextStyle(color: _textSecondary),
        hintStyle: TextStyle(color: _textSecondary),
      );

  // ── Light theme ──────────────────────────────────────────
  static ThemeData get light {
    final cs = ColorScheme.fromSeed(
      seedColor: _primary,
      brightness: Brightness.light,
      primary: _primary,
      secondary: _secondary,
      surface: _surfaceLight,
      onSurface: _textPrimary,
      onPrimary: Colors.white,
      outline: const Color(0xFFE4E7F0),
      outlineVariant: const Color(0xFFEEF0F6),
    ).copyWith(tertiary: _accentBlue, tertiaryContainer: _accentAmber);

    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      scaffoldBackgroundColor: _background,
      fontFamily: 'PlusJakartaSans',

      // AppBar
      appBarTheme: const AppBarTheme(
        backgroundColor: _background,
        foregroundColor: _textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: _textPrimary,
        ),
      ),

      // Cards
      cardTheme: CardThemeData(
        color: _surfaceLight,
        elevation: 0,
        shape: _cardShape,
        shadowColor: Colors.black.withOpacity(0.07),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      ),

      // FAB
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),

      // Drawer
      drawerTheme: const DrawerThemeData(
        backgroundColor: _background,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(right: Radius.circular(24)),
        ),
      ),

      // Bottom sheet
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: _surfaceLight,
        modalBackgroundColor: _surfaceLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        showDragHandle: true,
        dragHandleColor: Color(0xFF9BA3B8),
        dragHandleSize: Size(40, 4),
      ),

      // Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size.fromHeight(52),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _secondary,
          side: const BorderSide(color: _secondary, width: 1.5),
          minimumSize: const Size.fromHeight(48),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontWeight: FontWeight.w400,
            fontSize: 12,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _secondary,
          textStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // Chips / badges
      chipTheme: ChipThemeData(
        shape: const StadiumBorder(),
        side: BorderSide.none,
        backgroundColor: _background,
        labelStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: Color(0xFFEEF0F6),
        thickness: 1,
        space: 1,
      ),

      // Input
      inputDecorationTheme: _inputTheme(cs),

      // List tile
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        iconColor: _textSecondary,
        titleTextStyle: TextStyle(
          fontFamily: 'PlusJakartaSans',
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: _textPrimary,
        ),
        subtitleTextStyle: TextStyle(
          fontFamily: 'PlusJakartaSans',
          fontSize: 12,
          color: _textSecondary,
        ),
      ),

      // Text // fuente por defecto (body)
      textTheme: const TextTheme(
        // --- Headings -> Sora ---
        displayLarge: TextStyle(
          fontFamily: 'Sora',
          fontWeight: FontWeight.w700,
          fontSize: 32,
        ),
        displayMedium: TextStyle(
          fontFamily: 'Sora',
          fontWeight: FontWeight.w700,
          fontSize: 28,
        ),
        displaySmall: TextStyle(
          fontFamily: 'Sora',
          fontWeight: FontWeight.w600,
          fontSize: 24,
        ),
        headlineLarge: TextStyle(
          fontFamily: 'Sora',
          fontWeight: FontWeight.w600,
          fontSize: 22,
        ),
        headlineMedium: TextStyle(
          fontFamily: 'Sora',
          fontWeight: FontWeight.w600,
          fontSize: 20,
        ),
        headlineSmall: TextStyle(
          fontFamily: 'Sora',
          fontWeight: FontWeight.w600,
          fontSize: 18,
        ),
        titleLarge: TextStyle(
          fontFamily: 'Sora',
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),

        // --- Body -> Plus Jakarta Sans ---
        titleMedium: TextStyle(
          fontFamily: 'PlusJakartaSans',
          fontWeight: FontWeight.w500,
          fontSize: 16,
        ),
        titleSmall: TextStyle(
          fontFamily: 'PlusJakartaSans',
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
        bodyLarge: TextStyle(
          fontFamily: 'PlusJakartaSans',
          fontWeight: FontWeight.w400,
          fontSize: 16,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'PlusJakartaSans',
          fontWeight: FontWeight.w400,
          fontSize: 14,
        ),
        bodySmall: TextStyle(
          fontFamily: 'PlusJakartaSans',
          fontWeight: FontWeight.w400,
          fontSize: 12,
        ),
        labelLarge: TextStyle(
          fontFamily: 'PlusJakartaSans',
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
        labelMedium: TextStyle(
          fontFamily: 'PlusJakartaSans',
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
        labelSmall: TextStyle(
          fontFamily: 'PlusJakartaSans',
          fontWeight: FontWeight.w500,
          fontSize: 11,
        ),
      ),

      iconTheme: const IconThemeData(color: _textSecondary, size: 22),
    );
  }

  // ── Dark theme ───────────────────────────────────────────
  static ThemeData get dark {
    final cs = ColorScheme.fromSeed(
      seedColor: _primary,
      brightness: Brightness.dark,
      primary: _primary,
      secondary: _secondary,
      surface: _surfaceDark,
      onSurface: Colors.white,
      onPrimary: Colors.white,
      outline: const Color(0xFF2E3250),
      outlineVariant: const Color(0xFF2A2D45),
    ).copyWith(tertiary: _accentBlue, tertiaryContainer: _accentAmber);

    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      scaffoldBackgroundColor: _backgroundDark,
      fontFamily: 'Poppins',

      appBarTheme: const AppBarTheme(
        backgroundColor: _backgroundDark,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),

      cardTheme: CardThemeData(
        color: _surfaceDark,
        elevation: 0,
        shape: _cardShape,
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),

      drawerTheme: const DrawerThemeData(
        backgroundColor: _surfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(right: Radius.circular(24)),
        ),
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: _surfaceDark,
        modalBackgroundColor: _surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        showDragHandle: true,
        dragHandleColor: Color(0xFF9BA3B8),
        dragHandleSize: Size(40, 4),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size.fromHeight(52),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _secondary,
          side: const BorderSide(color: _secondary, width: 1.5),
          minimumSize: const Size.fromHeight(48),
          shape: const StadiumBorder(),
        ),
      ),

      chipTheme: ChipThemeData(
        shape: const StadiumBorder(),
        side: BorderSide.none,
        backgroundColor: const Color(0xFF2A2D45),
        labelStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
      ),

      dividerTheme: const DividerThemeData(
        color: Color(0xFF2E3250),
        thickness: 1,
        space: 1,
      ),

      inputDecorationTheme: _inputTheme(cs),

      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        iconColor: _textSecondary,
        titleTextStyle: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        subtitleTextStyle: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 12,
          color: _textSecondary,
        ),
      ),

      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        titleMedium: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        bodyLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: Colors.white,
        ),
        bodyMedium: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: _textSecondary,
        ),
        bodySmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w400,
          color: _textSecondary,
        ),
        labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: _textSecondary,
        ),
      ),

      iconTheme: const IconThemeData(color: _textSecondary, size: 22),
    );
  }
}
