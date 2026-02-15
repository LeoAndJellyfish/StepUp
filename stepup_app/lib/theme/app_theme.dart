import 'package:flutter/material.dart';
import 'dart:math' as math;

class AppTheme {
  static const Color primaryColor = Color(0xFFFF6B9D);
  static const Color secondaryColor = Color(0xFFFFD93D);
  static const Color accentBlue = Color(0xFF6BCB77);
  static const Color accentPurple = Color(0xFF9B59B6);
  static const Color accentOrange = Color(0xFFFF8C42);
  static const Color accentTeal = Color(0xFF00D9FF);
  static const Color errorColor = Color(0xFFFF4757);
  static const Color successColor = Color(0xFF2ED573);
  static const Color warningColor = Color(0xFFFFA502);
  static const Color memphisBlack = Color(0xFF1A1A2E);
  static const Color memphisPink = Color(0xFFFF6B9D);
  static const Color memphisYellow = Color(0xFFFFD93D);
  static const Color memphisBlue = Color(0xFF00D9FF);
  static const Color memphisGreen = Color(0xFF6BCB77);
  static const Color memphisPurple = Color(0xFF9B59B6);

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.light,
      primary: primaryColor,
      secondary: secondaryColor,
      tertiary: accentBlue,
      error: errorColor,
    ),
    scaffoldBackgroundColor: const Color(0xFFFFFBF0),
    textTheme: _buildTextTheme(Brightness.light),
    appBarTheme: AppBarTheme(
      centerTitle: true,
      elevation: 0,
      scrolledUnderElevation: 2,
      backgroundColor: Colors.white,
      foregroundColor: memphisBlack,
      titleTextStyle: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: memphisBlack,
        letterSpacing: 1.2,
        fontFamily: fontFamily,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(24),
        ),
        side: BorderSide(color: memphisBlack, width: 1.5),
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: memphisBlack, width: 1.5),
      ),
      color: Colors.white,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: memphisBlack, width: 1.5),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          inherit: false,
          fontFamily: fontFamily,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return memphisBlack.withValues(alpha: 0.38);
          }
          return memphisBlack;
        }),
        backgroundColor: WidgetStateProperty.all(Colors.transparent),
        side: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return BorderSide(color: memphisBlack.withValues(alpha: 0.12), width: 1.5);
          }
          if (states.contains(WidgetState.pressed)) {
            return const BorderSide(color: primaryColor, width: 1.5);
          }
          return const BorderSide(color: memphisBlack, width: 1.5);
        }),
        shape: WidgetStateProperty.all(RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        )),
        padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 28, vertical: 14)),
        textStyle: WidgetStateProperty.all(const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          inherit: false,
          fontFamily: fontFamily,
        )),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
          inherit: false,
          fontFamily: fontFamily,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: memphisBlack, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: memphisBlack, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: primaryColor, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: errorColor, width: 1.5),
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      labelStyle: const TextStyle(
        fontWeight: FontWeight.w600,
        color: memphisBlack,
        fontFamily: fontFamily,
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      type: BottomNavigationBarType.fixed,
      elevation: 0,
      backgroundColor: Colors.white,
      selectedItemColor: primaryColor,
      unselectedItemColor: memphisBlack.withValues(alpha: 0.5),
      selectedLabelStyle: const TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 12,
        fontFamily: fontFamily,
      ),
      unselectedLabelStyle: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 12,
        fontFamily: fontFamily,
      ),
    ),
    dividerTheme: DividerThemeData(
      thickness: 2,
      space: 1,
      color: memphisBlack.withValues(alpha: 0.1),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: secondaryColor,
      foregroundColor: memphisBlack,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: memphisBlack, width: 1.5),
      ),
      elevation: 0,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: secondaryColor.withValues(alpha: 0.3),
      labelStyle: const TextStyle(
        fontWeight: FontWeight.w600,
        color: memphisBlack,
        fontFamily: fontFamily,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: memphisBlack, width: 1.5),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: primaryColor,
      contentTextStyle: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w600,
        fontSize: 14,
        fontFamily: fontFamily,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: memphisBlack, width: 2),
      ),
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: accentBlue,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: memphisBlack, width: 1.5),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
        elevation: 0,
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          inherit: false,
          fontFamily: fontFamily,
        ),
      ),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.dark,
      primary: primaryColor,
      secondary: secondaryColor,
      tertiary: accentBlue,
      error: errorColor,
    ),
    scaffoldBackgroundColor: const Color(0xFF1A1A2E),
    textTheme: _buildTextTheme(Brightness.dark),
    appBarTheme: AppBarTheme(
      centerTitle: true,
      elevation: 0,
      scrolledUnderElevation: 2,
      backgroundColor: const Color(0xFF16213E),
      foregroundColor: Colors.white,
      titleTextStyle: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: Colors.white,
        letterSpacing: 1.2,
        fontFamily: fontFamily,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(24),
        ),
        side: BorderSide(color: secondaryColor, width: 1.5),
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: secondaryColor, width: 1.5),
      ),
      color: const Color(0xFF16213E),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: secondaryColor, width: 1.5),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          inherit: false,
          fontFamily: fontFamily,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return Colors.white.withValues(alpha: 0.38);
          }
          return Colors.white;
        }),
        backgroundColor: WidgetStateProperty.all(Colors.transparent),
        side: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return BorderSide(color: secondaryColor.withValues(alpha: 0.12), width: 1.5);
          }
          if (states.contains(WidgetState.pressed)) {
            return const BorderSide(color: primaryColor, width: 1.5);
          }
          return const BorderSide(color: secondaryColor, width: 1.5);
        }),
        shape: WidgetStateProperty.all(RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        )),
        padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 28, vertical: 14)),
        textStyle: WidgetStateProperty.all(const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          inherit: false,
          fontFamily: fontFamily,
        )),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
          inherit: false,
          fontFamily: fontFamily,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: secondaryColor, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: secondaryColor, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: primaryColor, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: errorColor, width: 1.5),
      ),
      filled: true,
      fillColor: const Color(0xFF16213E),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      labelStyle: const TextStyle(
        fontWeight: FontWeight.w600,
        color: Colors.white70,
        fontFamily: fontFamily,
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      type: BottomNavigationBarType.fixed,
      elevation: 0,
      backgroundColor: Color(0xFF16213E),
      selectedItemColor: primaryColor,
      unselectedItemColor: Colors.white54,
    ),
    dividerTheme: DividerThemeData(
      thickness: 2,
      space: 1,
      color: Colors.white.withValues(alpha: 0.1),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: secondaryColor,
      foregroundColor: memphisBlack,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Colors.white, width: 1.5),
      ),
      elevation: 0,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: primaryColor.withValues(alpha: 0.3),
      labelStyle: const TextStyle(
        fontWeight: FontWeight.w600,
        color: Colors.white,
        fontFamily: fontFamily,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: secondaryColor, width: 1.5),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: primaryColor,
      contentTextStyle: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w600,
        fontSize: 14,
        fontFamily: fontFamily,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: secondaryColor, width: 2),
      ),
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),
  );

  static const TextStyle headlineLarge = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.w800,
    letterSpacing: 1.5,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontSize: 30,
    fontWeight: FontWeight.w800,
    letterSpacing: 1.2,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.0,
  );

  static const TextStyle titleLarge = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.8,
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.5,
  );

  static const TextStyle titleSmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.3,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.3,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.2,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
  );

  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.5,
  );

  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.4,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.3,
  );

  static const double spacing4 = 4.0;
  static const double spacing8 = 8.0;
  static const double spacing12 = 12.0;
  static const double spacing16 = 16.0;
  static const double spacing24 = 24.0;
  static const double spacing32 = 32.0;

  static const double radiusSmall = 8.0;
  static const double radiusMedium = 16.0;
  static const double radiusLarge = 20.0;
  static const double radiusXLarge = 28.0;

  static List<BoxShadow> get memphisShadow => [
    BoxShadow(
      color: memphisBlack.withValues(alpha: 0.15),
      offset: const Offset(4, 4),
      blurRadius: 0,
    ),
  ];

  static List<BoxShadow> get memphisShadowLarge => [
    BoxShadow(
      color: memphisBlack.withValues(alpha: 0.2),
      offset: const Offset(6, 6),
      blurRadius: 0,
    ),
  ];

  static List<BoxShadow> get memphisColorShadow => [
    BoxShadow(
      color: accentTeal.withValues(alpha: 0.6),
      offset: const Offset(4, 4),
      blurRadius: 0,
    ),
  ];

  static List<BoxShadow> get memphisPinkShadow => [
    BoxShadow(
      color: primaryColor.withValues(alpha: 0.6),
      offset: const Offset(4, 4),
      blurRadius: 0,
    ),
  ];

  static List<BoxShadow> get memphisYellowShadow => [
    BoxShadow(
      color: secondaryColor.withValues(alpha: 0.8),
      offset: const Offset(4, 4),
      blurRadius: 0,
    ),
  ];

  static const List<Color> memphisGradientColors = [
    primaryColor,
    secondaryColor,
    accentBlue,
  ];

  static const List<Color> memphisRainbowColors = [
    primaryColor,
    accentOrange,
    secondaryColor,
    accentBlue,
    accentTeal,
    accentPurple,
  ];

  static const String fontFamily = 'HarmonyOS Sans SC';

  static TextTheme _buildTextTheme(Brightness brightness) {
    final Color textColor = brightness == Brightness.light ? memphisBlack : Colors.white;
    
    return TextTheme(
      displayLarge: TextStyle(
        fontSize: 57,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.25,
        color: textColor,
        fontFamily: fontFamily,
      ),
      displayMedium: TextStyle(
        fontSize: 45,
        fontWeight: FontWeight.w800,
        color: textColor,
        fontFamily: fontFamily,
      ),
      displaySmall: TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        color: textColor,
        fontFamily: fontFamily,
      ),
      headlineLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.5,
        color: textColor,
        fontFamily: fontFamily,
      ),
      headlineMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: textColor,
        fontFamily: fontFamily,
      ),
      headlineSmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.0,
        color: textColor,
        fontFamily: fontFamily,
      ),
      titleLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: textColor,
        fontFamily: fontFamily,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
        color: textColor,
        fontFamily: fontFamily,
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
        color: textColor,
        fontFamily: fontFamily,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
        color: textColor,
        fontFamily: fontFamily,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
        color: textColor,
        fontFamily: fontFamily,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
        color: textColor,
        fontFamily: fontFamily,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.3,
        color: textColor,
        fontFamily: fontFamily,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.2,
        color: textColor,
        fontFamily: fontFamily,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        color: textColor,
        fontFamily: fontFamily,
      ),
    );
  }

  static BoxDecoration memphisCardDecoration({
    Color? backgroundColor,
    Color? borderColor,
    double borderRadius = 20,
    Color? shadowColor,
  }) {
    return BoxDecoration(
      color: backgroundColor ?? Colors.white,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: borderColor ?? memphisBlack,
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: shadowColor ?? memphisBlack.withValues(alpha: 0.2),
          offset: const Offset(4, 4),
          blurRadius: 0,
        ),
      ],
    );
  }

  static BoxDecoration memphisGradientDecoration({
    List<Color>? colors,
    double borderRadius = 20,
  }) {
    return BoxDecoration(
      gradient: LinearGradient(
        colors: colors ?? memphisGradientColors,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: memphisBlack,
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: memphisBlack.withValues(alpha: 0.2),
          offset: const Offset(4, 4),
          blurRadius: 0,
        ),
      ],
    );
  }
}

class MemphisPatterns {
  static CustomPainter dots({
    Color color = AppTheme.memphisBlack,
    double spacing = 20,
    double dotRadius = 3,
  }) {
    return _DotsPattern(color: color, spacing: spacing, dotRadius: dotRadius);
  }

  static CustomPainter zigzag({
    Color color = AppTheme.memphisBlack,
    double strokeWidth = 2,
  }) {
    return _ZigzagPattern(color: color, strokeWidth: strokeWidth);
  }

  static CustomPainter circles({
    Color color = AppTheme.primaryColor,
    double minRadius = 5,
    double maxRadius = 15,
  }) {
    return _CirclesPattern(
      color: color,
      minRadius: minRadius,
      maxRadius: maxRadius,
    );
  }

  static CustomPainter triangles({
    Color color = AppTheme.secondaryColor,
    double size = 20,
  }) {
    return _TrianglesPattern(color: color, size: size);
  }
}

class _DotsPattern extends CustomPainter {
  final Color color;
  final double spacing;
  final double dotRadius;

  _DotsPattern({
    required this.color,
    required this.spacing,
    required this.dotRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    for (double x = spacing; x < size.width; x += spacing) {
      for (double y = spacing; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), dotRadius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class MemphisAnimations {
  static const Duration durationFast = Duration(milliseconds: 150);
  static const Duration durationNormal = Duration(milliseconds: 300);
  static const Duration durationSlow = Duration(milliseconds: 500);
  static const Duration durationVerySlow = Duration(milliseconds: 800);

  static const Curve bounceOut = _BounceOutCurve();
  static const Curve elasticOut = _ElasticOutCurve();
  static const Curve overshoot = _OvershootCurve();
  static const Curve memphisEase = _MemphisEaseCurve();

  static Widget animatedScale({
    required Widget child,
    required bool condition,
    Duration duration = durationNormal,
    Curve curve = overshoot,
    double scale = 1.02,
  }) {
    return AnimatedScale(
      scale: condition ? scale : 1.0,
      duration: duration,
      curve: curve,
      child: child,
    );
  }

  static Widget animatedSlideIn({
    required Widget child,
    required Animation<double> animation,
    Offset beginOffset = const Offset(0.0, 0.1),
    Curve curve = memphisEase,
  }) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: beginOffset,
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: curve,
      )),
      child: child,
    );
  }

  static Widget animatedFadeSlide({
    required Widget child,
    required Animation<double> animation,
    Offset beginOffset = const Offset(0.0, 0.05),
    Curve curve = memphisEase,
  }) {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: animation,
        curve: curve,
      ),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: beginOffset,
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: curve,
        )),
        child: child,
      ),
    );
  }

  static Widget staggeredList({
    required Widget child,
    required int index,
    required Animation<double> animation,
    Duration staggerDelay = const Duration(milliseconds: 50),
    Curve curve = memphisEase,
  }) {
    final delayedAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: animation,
        curve: Interval(
          staggerDelay.inMilliseconds * index / 1000.0,
          (staggerDelay.inMilliseconds * index / 1000.0) + 0.3,
          curve: curve,
        ),
      ),
    );

    return FadeTransition(
      opacity: delayedAnimation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.0, 0.1),
          end: Offset.zero,
        ).animate(delayedAnimation),
        child: child,
      ),
    );
  }

  static Widget shimmerEffect({
    required Widget child,
    required Color baseColor,
    required Color highlightColor,
  }) {
    return _ShimmerEffect(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: child,
    );
  }

  static Widget pulseAnimation({
    required Widget child,
    Duration duration = const Duration(milliseconds: 1000),
    double minScale = 0.97,
    double maxScale = 1.0,
  }) {
    return _PulseAnimation(
      duration: duration,
      minScale: minScale,
      maxScale: maxScale,
      child: child,
    );
  }

  static Widget wobbleAnimation({
    required Widget child,
    Duration duration = const Duration(milliseconds: 500),
  }) {
    return _WobbleAnimation(
      duration: duration,
      child: child,
    );
  }

  static Widget bounceInAnimation({
    required Widget child,
    Duration duration = const Duration(milliseconds: 600),
    Duration delay = Duration.zero,
  }) {
    return _BounceInAnimation(
      duration: duration,
      delay: delay,
      child: child,
    );
  }

  static Widget colorShiftAnimation({
    required Widget child,
    required List<Color> colors,
    Duration duration = const Duration(milliseconds: 3000),
  }) {
    return _ColorShiftAnimation(
      colors: colors,
      duration: duration,
      child: child,
    );
  }
}

class _BounceOutCurve extends Curve {
  const _BounceOutCurve();

  @override
  double transform(double t) {
    if (t < 0.3636) {
      return 2.75 * t * t;
    } else if (t < 0.7272) {
      return 2.75 * (t - 0.5454) * (t - 0.5454) + 0.75;
    } else if (t < 0.909) {
      return 2.75 * (t - 0.8181) * (t - 0.8181) + 0.9375;
    }
    return 2.75 * (t - 0.9545) * (t - 0.9545) + 0.984375;
  }
}

class _ElasticOutCurve extends Curve {
  const _ElasticOutCurve();

  @override
  double transform(double t) {
    if (t == 0 || t == 1) return t;
    return math.pow(2.0, -10.0 * t) * math.sin((t - 0.1) * 5.0 * math.pi) + 1.0;
  }
}

class _OvershootCurve extends Curve {
  const _OvershootCurve();

  @override
  double transform(double t) {
    return (t * t * ((2.5 + 1) * t - 2.5)) + 1.0;
  }
}

class _MemphisEaseCurve extends Curve {
  const _MemphisEaseCurve();

  @override
  double transform(double t) {
    return 1.0 - math.pow(1.0 - t, 3.0);
  }
}

class _ShimmerEffect extends StatefulWidget {
  final Widget child;
  final Color baseColor;
  final Color highlightColor;

  const _ShimmerEffect({
    required this.child,
    required this.baseColor,
    required this.highlightColor,
  });

  @override
  State<_ShimmerEffect> createState() => _ShimmerEffectState();
}

class _ShimmerEffectState extends State<_ShimmerEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                widget.baseColor,
                widget.highlightColor,
                widget.baseColor,
              ],
              stops: const [0.0, 0.5, 1.0],
              transform: _SlideGradientTransform(_animation.value),
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcATop,
          child: widget.child,
        );
      },
      child: widget.child,
    );
  }
}

class _SlideGradientTransform extends GradientTransform {
  final double slidePercent;

  const _SlideGradientTransform(this.slidePercent);

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * slidePercent, 0.0, 0.0);
  }
}

class _PulseAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double minScale;
  final double maxScale;

  const _PulseAnimation({
    required this.child,
    required this.duration,
    required this.minScale,
    required this.maxScale,
  });

  @override
  State<_PulseAnimation> createState() => _PulseAnimationState();
}

class _PulseAnimationState extends State<_PulseAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat(reverse: true);
    _animation = Tween<double>(
      begin: widget.minScale,
      end: widget.maxScale,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scale: _animation.value,
          child: widget.child,
        );
      },
      child: widget.child,
    );
  }
}

class _WobbleAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;

  const _WobbleAnimation({
    required this.child,
    required this.duration,
  });

  @override
  State<_WobbleAnimation> createState() => _WobbleAnimationState();
}

class _WobbleAnimationState extends State<_WobbleAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _animation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: 0.05), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.05, end: -0.03), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -0.03, end: 0.02), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.02, end: -0.01), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -0.01, end: 0), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  void trigger() {
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.rotate(
          angle: _animation.value * math.pi,
          child: widget.child,
        );
      },
      child: widget.child,
    );
  }
}

class _BounceInAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;

  const _BounceInAnimation({
    required this.child,
    required this.duration,
    required this.delay,
  });

  @override
  State<_BounceInAnimation> createState() => _BounceInAnimationState();
}

class _BounceInAnimationState extends State<_BounceInAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
      ),
    );

    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: widget.child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

class _ColorShiftAnimation extends StatefulWidget {
  final Widget child;
  final List<Color> colors;
  final Duration duration;

  const _ColorShiftAnimation({
    required this.child,
    required this.colors,
    required this.duration,
  });

  @override
  State<_ColorShiftAnimation> createState() => _ColorShiftAnimationState();
}

class _ColorShiftAnimationState extends State<_ColorShiftAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: widget.colors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              transform: _SlideGradientTransform(_controller.value),
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
      child: widget.child,
    );
  }
}

class MemphisAnimatedCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color? shadowColor;
  final Duration hoverDuration;
  final Duration tapDuration;

  const MemphisAnimatedCard({
    super.key,
    required this.child,
    this.onTap,
    this.shadowColor,
    this.hoverDuration = const Duration(milliseconds: 200),
    this.tapDuration = const Duration(milliseconds: 100),
  });

  @override
  State<MemphisAnimatedCard> createState() => _MemphisAnimatedCardState();
}

class _MemphisAnimatedCardState extends State<MemphisAnimatedCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _shadowAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.hoverDuration,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _shadowAnimation = Tween<double>(begin: 4.0, end: 6.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _controller.forward(),
      onExit: (_) => _controller.reverse(),
      child: GestureDetector(
        onTapDown: widget.onTap != null ? _onTapDown : null,
        onTapUp: widget.onTap != null ? _onTapUp : null,
        onTapCancel: widget.onTap != null ? _onTapCancel : null,
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: _isPressed ? 0.98 : _scaleAnimation.value,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: (widget.shadowColor ?? AppTheme.memphisBlack)
                          .withValues(alpha: 0.2),
                      offset: Offset(_shadowAnimation.value, _shadowAnimation.value),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: widget.child,
              ),
            );
          },
        ),
      ),
    );
  }
}

class MemphisAnimatedButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? shadowColor;
  final bool isFilled;

  const MemphisAnimatedButton({
    super.key,
    required this.child,
    this.onPressed,
    this.backgroundColor,
    this.shadowColor,
    this.isFilled = true,
  });

  @override
  State<MemphisAnimatedButton> createState() => _MemphisAnimatedButtonState();
}

class _MemphisAnimatedButtonState extends State<MemphisAnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _shadowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _shadowAnimation = Tween<Offset>(
      begin: const Offset(4, 4),
      end: const Offset(2, 2),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.backgroundColor ?? AppTheme.primaryColor;
    final shadowColor = widget.shadowColor ?? AppTheme.memphisBlack;

    return GestureDetector(
      onTapDown: widget.onPressed != null
          ? (_) => _controller.forward()
          : null,
      onTapUp: widget.onPressed != null
          ? (_) {
              _controller.reverse();
              widget.onPressed?.call();
            }
          : null,
      onTapCancel: widget.onPressed != null
          ? () => _controller.reverse()
          : null,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                color: widget.isFilled ? bgColor : null,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.memphisBlack,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: shadowColor.withValues(alpha: 0.3),
                    offset: _shadowAnimation.value,
                    blurRadius: 0,
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: widget.child,
            ),
          );
        },
      ),
    );
  }
}

class _ZigzagPattern extends CustomPainter {
  final Color color;
  final double strokeWidth;

  _ZigzagPattern({
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path();
    final double amplitude = 10;
    final double wavelength = 20;
    
    for (double y = 0; y < size.height; y += 30) {
      path.moveTo(0, y);
      for (double x = 0; x < size.width; x += wavelength) {
        path.lineTo(x + wavelength / 2, y + amplitude);
        path.lineTo(x + wavelength, y);
      }
    }
    
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CirclesPattern extends CustomPainter {
  final Color color;
  final double minRadius;
  final double maxRadius;

  _CirclesPattern({
    required this.color,
    required this.minRadius,
    required this.maxRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final random = math.Random(42);
    
    for (int i = 0; i < 15; i++) {
      final double x = random.nextDouble() * size.width;
      final double y = random.nextDouble() * size.height;
      final double radius = minRadius + random.nextDouble() * (maxRadius - minRadius);
      
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _TrianglesPattern extends CustomPainter {
  final Color color;
  final double size;

  _TrianglesPattern({
    required this.color,
    required this.size,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final random = math.Random(123);
    
    for (int i = 0; i < 10; i++) {
      final double x = random.nextDouble() * size.width;
      final double y = random.nextDouble() * size.height;
      final double triangleSize = this.size * (0.5 + random.nextDouble());
      
      final path = Path()
        ..moveTo(x, y - triangleSize / 2)
        ..lineTo(x - triangleSize / 2, y + triangleSize / 2)
        ..lineTo(x + triangleSize / 2, y + triangleSize / 2)
        ..close();
      
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class MemphisDecorations {
  static Widget dotBadge({
    required Widget child,
    Color? dotColor,
    double dotSize = 12,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          top: -dotSize / 2,
          right: -dotSize / 2,
          child: Container(
            width: dotSize,
            height: dotSize,
            decoration: BoxDecoration(
              color: dotColor ?? AppTheme.secondaryColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppTheme.memphisBlack,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  static Widget stripedContainer({
    required Widget child,
    Color? stripeColor,
    double stripeWidth = 10,
    double stripeSpacing = 20,
  }) {
    return CustomPaint(
      painter: _StripedPainter(
        color: stripeColor ?? AppTheme.primaryColor.withValues(alpha: 0.1),
        stripeWidth: stripeWidth,
        stripeSpacing: stripeSpacing,
      ),
      child: child,
    );
  }
}

class _StripedPainter extends CustomPainter {
  final Color color;
  final double stripeWidth;
  final double stripeSpacing;

  _StripedPainter({
    required this.color,
    required this.stripeWidth,
    required this.stripeSpacing,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final double totalSpacing = stripeWidth + stripeSpacing;
    
    for (double x = -size.height; x < size.width + size.height; x += totalSpacing) {
      final path = Path()
        ..moveTo(x, 0)
        ..lineTo(x + stripeWidth, 0)
        ..lineTo(x + stripeWidth + size.height, size.height)
        ..lineTo(x + size.height, size.height)
        ..close();
      
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class MemphisPageTransitions {
  static Widget slideFadeTransition({
    required Animation<double> animation,
    required Animation<double> secondaryAnimation,
    required Widget child,
    Offset beginOffset = const Offset(0.1, 0.0),
  }) {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      ),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: beginOffset,
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        )),
        child: child,
      ),
    );
  }

  static Widget scaleFadeTransition({
    required Animation<double> animation,
    required Animation<double> secondaryAnimation,
    required Widget child,
    double beginScale = 0.95,
  }) {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      ),
      child: ScaleTransition(
        scale: Tween<double>(
          begin: beginScale,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        )),
        child: child,
      ),
    );
  }

  static Widget memphisSlideTransition({
    required Animation<double> animation,
    required Animation<double> secondaryAnimation,
    required Widget child,
  }) {
    final slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
    ));

    final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: animation,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );

    final scaleAnimation = Tween<double>(begin: 0.98, end: 1.0).animate(
      CurvedAnimation(
        parent: animation,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
      ),
    );

    return FadeTransition(
      opacity: fadeAnimation,
      child: SlideTransition(
        position: slideAnimation,
        child: ScaleTransition(
          scale: scaleAnimation,
          child: child,
        ),
      ),
    );
  }

  static Widget memphisPopTransition({
    required Animation<double> animation,
    required Animation<double> secondaryAnimation,
    required Widget child,
  }) {
    final scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: animation,
        curve: const Interval(0.0, 0.5, curve: Curves.elasticOut),
      ),
    );

    final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: animation,
        curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
      ),
    );

    return FadeTransition(
      opacity: fadeAnimation,
      child: ScaleTransition(
        scale: scaleAnimation,
        child: child,
      ),
    );
  }

  static Widget memphisSharedAxisTransition({
    required Animation<double> animation,
    required Animation<double> secondaryAnimation,
    required Widget child,
    Axis direction = Axis.horizontal,
  }) {
    final offset = direction == Axis.horizontal
        ? const Offset(0.1, 0.0)
        : const Offset(0.0, 0.1);

    return FadeTransition(
      opacity: CurvedAnimation(
        parent: animation,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: offset,
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
        )),
        child: child,
      ),
    );
  }
}

class MemphisAnimatedList extends StatefulWidget {
  final int itemCount;
  final Widget Function(BuildContext, int) itemBuilder;
  final Duration staggerDelay;
  final Duration itemDuration;
  final ScrollPhysics? physics;
  final EdgeInsetsGeometry? padding;
  final ScrollController? controller;

  const MemphisAnimatedList({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.staggerDelay = const Duration(milliseconds: 50),
    this.itemDuration = const Duration(milliseconds: 400),
    this.physics,
    this.padding,
    this.controller,
  });

  @override
  State<MemphisAnimatedList> createState() => _MemphisAnimatedListState();
}

class _MemphisAnimatedListState extends State<MemphisAnimatedList>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(
        milliseconds: widget.itemDuration.inMilliseconds +
            (widget.staggerDelay.inMilliseconds * widget.itemCount),
      ),
    )..forward();
  }

  @override
  void didUpdateWidget(MemphisAnimatedList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.itemCount != widget.itemCount) {
      _controller.duration = Duration(
        milliseconds: widget.itemDuration.inMilliseconds +
            (widget.staggerDelay.inMilliseconds * widget.itemCount),
      );
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: widget.controller,
      physics: widget.physics,
      padding: widget.padding,
      itemCount: widget.itemCount,
      itemBuilder: (context, index) {
        final startDelay = index * widget.staggerDelay.inMilliseconds / 1000.0;
        final endDelay = startDelay + (widget.itemDuration.inMilliseconds / 1000.0);

        final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _controller,
            curve: Interval(
              startDelay.clamp(0.0, 1.0),
              endDelay.clamp(0.0, 1.0),
              curve: Curves.easeOutCubic,
            ),
          ),
        );

        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.0, 0.1),
              end: Offset.zero,
            ).animate(animation),
            child: widget.itemBuilder(context, index),
          ),
        );
      },
    );
  }
}

class MemphisAnimatedGrid extends StatefulWidget {
  final int itemCount;
  final Widget Function(BuildContext, int) itemBuilder;
  final SliverGridDelegate gridDelegate;
  final Duration staggerDelay;
  final Duration itemDuration;
  final ScrollPhysics? physics;
  final EdgeInsetsGeometry? padding;
  final ScrollController? controller;

  const MemphisAnimatedGrid({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    required this.gridDelegate,
    this.staggerDelay = const Duration(milliseconds: 30),
    this.itemDuration = const Duration(milliseconds: 400),
    this.physics,
    this.padding,
    this.controller,
  });

  @override
  State<MemphisAnimatedGrid> createState() => _MemphisAnimatedGridState();
}

class _MemphisAnimatedGridState extends State<MemphisAnimatedGrid>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(
        milliseconds: widget.itemDuration.inMilliseconds +
            (widget.staggerDelay.inMilliseconds * widget.itemCount),
      ),
    )..forward();
  }

  @override
  void didUpdateWidget(MemphisAnimatedGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.itemCount != widget.itemCount) {
      _controller.duration = Duration(
        milliseconds: widget.itemDuration.inMilliseconds +
            (widget.staggerDelay.inMilliseconds * widget.itemCount),
      );
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      controller: widget.controller,
      physics: widget.physics,
      padding: widget.padding,
      gridDelegate: widget.gridDelegate,
      itemCount: widget.itemCount,
      itemBuilder: (context, index) {
        final startDelay = index * widget.staggerDelay.inMilliseconds / 1000.0;
        final endDelay = startDelay + (widget.itemDuration.inMilliseconds / 1000.0);

        final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _controller,
            curve: Interval(
              startDelay.clamp(0.0, 1.0),
              endDelay.clamp(0.0, 1.0),
              curve: Curves.easeOutCubic,
            ),
          ),
        );

        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.9, end: 1.0).animate(animation),
            child: widget.itemBuilder(context, index),
          ),
        );
      },
    );
  }
}

class MemphisFloatingActionButton extends StatefulWidget {
  final VoidCallback onPressed;
  final Widget icon;
  final String? tooltip;
  final Color? backgroundColor;
  final Color? shadowColor;

  const MemphisFloatingActionButton({
    super.key,
    required this.onPressed,
    required this.icon,
    this.tooltip,
    this.backgroundColor,
    this.shadowColor,
  });

  @override
  State<MemphisFloatingActionButton> createState() =>
      _MemphisFloatingActionButtonState();
}

class _MemphisFloatingActionButtonState
    extends State<MemphisFloatingActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _rotationAnimation = Tween<double>(begin: 0.0, end: 0.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.backgroundColor ?? AppTheme.primaryColor;
    final shadowColor = widget.shadowColor ?? AppTheme.memphisBlack;

    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onPressed();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Transform.rotate(
              angle: _rotationAnimation.value * math.pi,
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.memphisBlack,
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: shadowColor.withValues(alpha: 0.3),
                      offset: const Offset(4, 4),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: Center(child: widget.icon),
              ),
            ),
          );
        },
      ),
    );
  }
}

class MemphisAnimatedIcon extends StatefulWidget {
  final IconData icon;
  final double size;
  final Color? color;
  final Duration duration;
  final bool animateOnLoad;

  const MemphisAnimatedIcon({
    super.key,
    required this.icon,
    this.size = 24,
    this.color,
    this.duration = const Duration(milliseconds: 300),
    this.animateOnLoad = true,
  });

  @override
  State<MemphisAnimatedIcon> createState() => _MemphisAnimatedIconState();
}

class _MemphisAnimatedIconState extends State<MemphisAnimatedIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.2), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _rotationAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.1), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.1, end: -0.05), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -0.05, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    if (widget.animateOnLoad) {
      _controller.forward();
    }
  }

  void animate() {
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Transform.rotate(
            angle: _rotationAnimation.value * math.pi,
            child: Icon(
              widget.icon,
              size: widget.size,
              color: widget.color,
            ),
          ),
        );
      },
    );
  }
}
