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
      ),
      unselectedLabelStyle: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 12,
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
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: memphisBlack, width: 1.5),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: secondaryColor, width: 1.5),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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

  static TextTheme _buildTextTheme(Brightness brightness) {
    final Color textColor = brightness == Brightness.light ? memphisBlack : Colors.white;
    
    return TextTheme(
      displayLarge: TextStyle(
        fontSize: 57,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.25,
        color: textColor,
      ),
      displayMedium: TextStyle(
        fontSize: 45,
        fontWeight: FontWeight.w800,
        color: textColor,
      ),
      displaySmall: TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        color: textColor,
      ),
      headlineLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.5,
        color: textColor,
      ),
      headlineMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: textColor,
      ),
      headlineSmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.0,
        color: textColor,
      ),
      titleLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: textColor,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
        color: textColor,
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
        color: textColor,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
        color: textColor,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
        color: textColor,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
        color: textColor,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.3,
        color: textColor,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.2,
        color: textColor,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        color: textColor,
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
