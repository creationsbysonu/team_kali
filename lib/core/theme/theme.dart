import 'package:flutter/material.dart';

class AppTheme {
  // Government Color Palette - Cobalt Blue and Red
  // Primary Colors - Cobalt Blue Variants
  static const Color primaryCobalt = Color(0xFF0047AB); // Main Cobalt Blue
  static const Color primaryCobaltDark = Color(0xFF003580); // Darker Cobalt
  static const Color primaryCobaltLight = Color(0xFF4A7BA7); // Lighter Cobalt
  static const Color primaryLight = Color(
    0xFF4A7BA7,
  ); // Alias for primaryCobaltLight
  static const Color primaryCobaltPale = Color(
    0xFFE3F2FD,
  ); // Very light blue for backgrounds

  // Accent Colors - Red Variants (Government Official)
  static const Color accentRed = Color(0xFFDC143C); // Crimson Red
  static const Color accentRedDark = Color(0xFFB71C1C); // Dark Red
  static const Color accentRedLight = Color(0xFFEF5350); // Light Red
  static const Color accentRedPale = Color(
    0xFFFFEBEE,
  ); // Very light red for highlights
  static const Color accentBlue = Color(0xFF2196F3); // Additional accent blue

  // Main theme colors
  static const Color primary = primaryCobalt;
  static const Color secondary = accentRed;
  static const Color background = Color(0xFFF5F5F5); // Light grey background

  // Additional aliases for compatibility
  static const Color positive = success;
  static const Color negative = error;
  static const Color primaryDark = primaryCobaltDark;
  static const Color primaryMedium = primaryCobalt;
  static const Color primaryCobaltMedium = primaryCobalt; // Alias

  // Accent Colors - Extended
  static const Color accentGreen = Color(0xFF2E7D32); // Dark Green
  static const Color accentPurple = Color(0xFF7B1FA2); // Purple

  // Status colors - Government appropriate
  static const Color success = Color(0xFF2E7D32); // Dark Green
  static const Color successLight = Color(0xFF66BB6A); // Light Green
  static const Color warning = Color(0xFFF57C00); // Orange
  static const Color error = accentRedDark;
  static const Color info = primaryCobalt;

  // Background Colors - Light theme for government
  static const Color backgroundLight = Color(0xFFFAFAFA);
  static const Color backgroundMedium = Color(0xFFF5F5F5);
  static const Color backgroundDark = Color(0xFFE0E0E0);
  static const Color cardBackground = Colors.white;
  static const Color surfaceColor = Colors.white;

  // Text Colors - Dark text on light backgrounds
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textMuted = Color(0xFF9E9E9E);
  static const Color textLight = Colors.white;
  static const Color textAccent = primaryCobalt;

  // Border & Divider Colors
  static const Color borderColor = Color(0xFFE0E0E0);
  static const Color dividerColor = Color(0xFFBDBDBD);

  // Sidebar Colors
  static const Color sidebarBackground = primaryCobaltDark;
  static const Color sidebarText = Colors.white;
  static const Color sidebarTextActive = accentRedLight;
  static const Color sidebarDivider = Color(0xFF004BA0);

  // Header Colors
  static const Color headerBackground = Colors.white;
  static const Color headerText = textPrimary;
  static const Color headerBorder = borderColor;

  // Status Colors
  static const Color statusActive = success;
  static const Color statusSuspended = accentRedDark;
  static const Color statusPending = warning;

  // Gradients - Government theme
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryCobalt, primaryCobaltDark],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentRed, accentRedDark],
  );

  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryCobalt, Color(0xFF0056C8)],
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryCobaltDark, primaryCobalt],
  );

  // Font Sizes
  static const double fontSizeXSmall = 11.0;
  static const double fontSizeSmall = 12.0;
  static const double fontSizeBody = 14.0; // Body text size
  static const double fontSizeMedium = 14.0;
  static const double fontSizeLarge = 16.0;
  static const double fontSizeXLarge = 18.0;
  static const double fontSizeXXLarge = 20.0;
  static const double fontSizeTitle = 24.0;
  static const double fontSizeHeading = 28.0;
  static const double fontSizeDisplay = 32.0;

  // Font Weights
  static const FontWeight fontWeightLight = FontWeight.w300;
  static const FontWeight fontWeightRegular = FontWeight.w400;
  static const FontWeight fontWeightMedium = FontWeight.w500;
  static const FontWeight fontWeightSemiBold = FontWeight.w600;
  static const FontWeight fontWeightBold = FontWeight.w700;

  // Spacing
  static const double spacingXSmall = 4.0;
  static const double spacingSmall = 8.0;
  static const double spacingMedium = 16.0;
  static const double spacingLarge = 24.0;
  static const double spacingXLarge = 32.0;
  static const double spacingXXLarge = 48.0;

  // Border Radius
  static const double radiusSmall = 4.0;
  static const double radiusMedium = 8.0;
  static const double radiusLarge = 12.0;
  static const double radiusXLarge = 16.0;
  static const double radiusCircular = 100.0;

  // Border Radius Aliases (for compatibility)
  static const double borderRadiusSmall = radiusSmall;
  static const double borderRadiusMedium = radiusMedium;
  static const double borderRadiusLarge = radiusLarge;

  // Shadows
  static List<BoxShadow> get shadowSmall => [
    BoxShadow(
      color: Colors.black.withOpacity(0.05),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get shadowMedium => [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get shadowLarge => [
    BoxShadow(
      color: Colors.black.withOpacity(0.12),
      blurRadius: 16,
      offset: const Offset(0, 8),
    ),
  ];

  // Build Theme Data
  static ThemeData buildThemeData() {
    return ThemeData(
      useMaterial3: true,
      primaryColor: primaryCobalt,
      scaffoldBackgroundColor: backgroundLight,
      colorScheme: const ColorScheme.light(
        primary: primaryCobalt,
        secondary: accentRed,
        surface: surfaceColor,
        error: error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimary,
        onError: Colors.white,
      ),

      // AppBar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: headerBackground,
        foregroundColor: headerText,
        elevation: 1,
        centerTitle: false,
        iconTheme: IconThemeData(color: textPrimary),
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: fontSizeXLarge,
          fontWeight: fontWeightSemiBold,
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: cardBackground,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
      ),

      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryCobalt,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(
            horizontal: spacingLarge,
            vertical: spacingMedium,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          textStyle: const TextStyle(
            fontSize: fontSizeMedium,
            fontWeight: fontWeightSemiBold,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryCobalt,
          side: const BorderSide(color: primaryCobalt, width: 1.5),
          padding: const EdgeInsets.symmetric(
            horizontal: spacingLarge,
            vertical: spacingMedium,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          textStyle: const TextStyle(
            fontSize: fontSizeMedium,
            fontWeight: fontWeightSemiBold,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryCobalt,
          padding: const EdgeInsets.symmetric(
            horizontal: spacingMedium,
            vertical: spacingSmall,
          ),
          textStyle: const TextStyle(
            fontSize: fontSizeMedium,
            fontWeight: fontWeightMedium,
          ),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: backgroundLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: primaryCobalt, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: error),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spacingMedium,
          vertical: spacingMedium,
        ),
        labelStyle: const TextStyle(color: textSecondary),
        hintStyle: const TextStyle(color: textMuted),
      ),

      // Text Theme
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: fontSizeDisplay,
          fontWeight: fontWeightBold,
          color: textPrimary,
        ),
        displayMedium: TextStyle(
          fontSize: fontSizeHeading,
          fontWeight: fontWeightBold,
          color: textPrimary,
        ),
        displaySmall: TextStyle(
          fontSize: fontSizeTitle,
          fontWeight: fontWeightSemiBold,
          color: textPrimary,
        ),
        headlineMedium: TextStyle(
          fontSize: fontSizeXXLarge,
          fontWeight: fontWeightSemiBold,
          color: textPrimary,
        ),
        headlineSmall: TextStyle(
          fontSize: fontSizeXLarge,
          fontWeight: fontWeightMedium,
          color: textPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: fontSizeLarge,
          fontWeight: fontWeightSemiBold,
          color: textPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: fontSizeMedium,
          fontWeight: fontWeightMedium,
          color: textPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: fontSizeLarge,
          fontWeight: fontWeightRegular,
          color: textPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: fontSizeMedium,
          fontWeight: fontWeightRegular,
          color: textPrimary,
        ),
        bodySmall: TextStyle(
          fontSize: fontSizeSmall,
          fontWeight: fontWeightRegular,
          color: textSecondary,
        ),
        labelLarge: TextStyle(
          fontSize: fontSizeMedium,
          fontWeight: fontWeightMedium,
          color: textPrimary,
        ),
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: dividerColor,
        thickness: 1,
        space: spacingMedium,
      ),

      // Icon Theme
      iconTheme: const IconThemeData(color: textSecondary, size: 24),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: backgroundMedium,
        deleteIconColor: textSecondary,
        labelStyle: const TextStyle(color: textPrimary),
        padding: const EdgeInsets.symmetric(
          horizontal: spacingSmall,
          vertical: spacingXSmall,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
        ),
      ),

      // DataTable Theme
      dataTableTheme: DataTableThemeData(
        headingRowColor: WidgetStateProperty.all(primaryCobaltPale),
        dataRowColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryCobaltPale;
          }
          return null;
        }),
        headingTextStyle: const TextStyle(
          color: textPrimary,
          fontWeight: fontWeightSemiBold,
          fontSize: fontSizeMedium,
        ),
        dataTextStyle: const TextStyle(
          color: textPrimary,
          fontSize: fontSizeMedium,
        ),
      ),
    );
  }

  // Helper method to get status color
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return statusActive;
      case 'suspended':
        return statusSuspended;
      case 'pending':
        return statusPending;
      default:
        return textMuted;
    }
  }

  // Helper method to get status badge
  static Widget buildStatusBadge(String status) {
    final color = getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: spacingSmall,
        vertical: spacingXSmall,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(radiusSmall),
        border: Border.all(color: color),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: fontSizeXSmall,
          fontWeight: fontWeightSemiBold,
        ),
      ),
    );
  }

  // Text Style Helper Methods
  static TextStyle labelSmall() {
    return const TextStyle(
      fontSize: fontSizeSmall,
      fontWeight: fontWeightMedium,
      color: textSecondary,
    );
  }

  static TextStyle bodyXSmall() {
    return const TextStyle(
      fontSize: fontSizeXSmall,
      fontWeight: fontWeightRegular,
      color: textPrimary,
    );
  }

  static TextStyle bodySmall() {
    return const TextStyle(
      fontSize: fontSizeSmall,
      fontWeight: fontWeightRegular,
      color: textPrimary,
    );
  }

  static TextStyle bodyMedium() {
    return const TextStyle(
      fontSize: fontSizeMedium,
      fontWeight: fontWeightRegular,
      color: textPrimary,
    );
  }

  static TextStyle bodyLarge() {
    return const TextStyle(
      fontSize: fontSizeLarge,
      fontWeight: fontWeightRegular,
      color: textPrimary,
    );
  }

  static TextStyle headingSmall() {
    return const TextStyle(
      fontSize: fontSizeXLarge,
      fontWeight: fontWeightSemiBold,
      color: textPrimary,
    );
  }

  static TextStyle headingMedium() {
    return const TextStyle(
      fontSize: fontSizeXXLarge,
      fontWeight: fontWeightSemiBold,
      color: textPrimary,
    );
  }

  static TextStyle headingLarge() {
    return const TextStyle(
      fontSize: fontSizeTitle,
      fontWeight: fontWeightBold,
      color: textPrimary,
    );
  }
}
