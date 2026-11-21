import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

abstract final class AppTheme {
  // Visual refresh inspired by the approved blue/charcoal GymRecords prototype.
  static const electricLime = Color(0xFF00D9E8); // mockup cyan accent
  static const deepNavy = Color(0xFF04101B);
  static const splashNavy = Color(0xFF00112B); // almost-black background
  static const surfaceNavy = Color(0xFF0B2031); // navy cards from approved mockups
  static const royalBlue = Color(0xFF087D9F); // selected states
  static const iceBlue = Color(0xFFB7C4D0); // secondary copy
  static const polarWhite = Color(0xFFF7F9FB);
  static const limeLight = Color(0xFF63D5FF);
  static const limeDark = Color(0xFF0876A8);
  static const deepBlue = Color(0xFF254357); // cyan-tinted borders

  static const accentBlue = electricLime;
  static const accentBlueSoft = Color(0xFF0B2735);
  static const cardElevated = Color(0xFF122A3E);
  static const mutedSurface = Color(0xFF0B0F12);
  static const success = Color(0xFF32D583);
  static const warning = Color(0xFFFFA928);

  static const pagePadding = 20.0;
  static const blockGap = 16.0;
  static const radius = 20.0;
  static const smallRadius = 14.0;
  static const buttonHeight = 56.0;
  static const touchTarget = 48.0;
  static const maxContentWidth = 560.0;

  static const _base = TextStyle(
    fontFamily: 'Barlow',
    color: polarWhite,
    height: 1.15,
  );

  static ThemeData get dark {
    final scheme = const ColorScheme.dark(
      // Keep Material's internal primary surface dark. The blue accent is
      // painted explicitly by GymRecords components. This prevents transient
      // primary-color fills on the first frame / focus repaint.
      primary: deepNavy,
      onPrimary: polarWhite,
      secondary: royalBlue,
      onSecondary: polarWhite,
      surface: surfaceNavy,
      onSurface: polarWhite,
      error: Color(0xFFFF7373),
      onError: deepNavy,
      outline: deepBlue,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: 'Barlow',
      scaffoldBackgroundColor: deepNavy,
      canvasColor: deepNavy,
      primaryColor: deepNavy,
      focusColor: Colors.transparent,
      hoverColor: Colors.transparent,
      highlightColor: Colors.transparent,
      splashColor: Colors.transparent,
      colorScheme: scheme,
      splashFactory: NoSplash.splashFactory,
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: electricLime,
        selectionColor: royalBlue,
        selectionHandleColor: electricLime,
      ),
      textTheme: const TextTheme(
        displayLarge: _base,
        headlineLarge: _base,
        headlineMedium: _base,
        headlineSmall: _base,
        titleLarge: _base,
        titleMedium: _base,
        titleSmall: _base,
        bodyLarge: _base,
        bodyMedium: _base,
        bodySmall: _base,
        labelLarge: _base,
        labelMedium: _base,
        labelSmall: _base,
      ).copyWith(
        headlineLarge: _base.copyWith(fontSize: 34, fontWeight: FontWeight.w600),
        headlineMedium: _base.copyWith(fontSize: 28, fontWeight: FontWeight.w600),
        headlineSmall: _base.copyWith(fontSize: 22, fontWeight: FontWeight.w600),
        titleLarge: _base.copyWith(fontSize: 20, fontWeight: FontWeight.w600),
        titleMedium: _base.copyWith(fontSize: 18, fontWeight: FontWeight.w600),
        bodyLarge: _base.copyWith(fontSize: 17),
        bodyMedium: _base.copyWith(fontSize: 15),
        bodySmall: _base.copyWith(fontSize: 13, color: iceBlue),
        labelLarge: _base.copyWith(fontSize: 17, fontWeight: FontWeight.w600),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: deepNavy,
        foregroundColor: polarWhite,
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 64,
        titleSpacing: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: deepNavy,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceNavy,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
          side: const BorderSide(color: deepBlue),
        ),
      ),
      dividerTheme: const DividerThemeData(color: deepBlue, thickness: 1),
      iconTheme: const IconThemeData(color: iceBlue),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: surfaceNavy,
        hintStyle: const TextStyle(color: iceBlue),
        labelStyle: const TextStyle(color: iceBlue),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: deepBlue),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: electricLime, width: 1.7),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(buttonHeight),
          backgroundColor: electricLime,
          foregroundColor: deepNavy,
          textStyle: _base.copyWith(fontSize: 18, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(17),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(buttonHeight),
          foregroundColor: polarWhite,
          side: const BorderSide(color: deepBlue, width: 1.5),
          textStyle: _base.copyWith(fontSize: 17, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(17),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: electricLime),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: electricLime,
        inactiveTrackColor: deepBlue,
        thumbColor: polarWhite,
        overlayColor: electricLime.withValues(alpha: 0.14),
        trackHeight: 5,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 13),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: cardElevated,
        contentTextStyle: TextStyle(color: polarWhite, fontFamily: 'Barlow'),
        behavior: SnackBarBehavior.floating,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surfaceNavy,
        modalBackgroundColor: surfaceNavy,
      ),
    );
  }
}
