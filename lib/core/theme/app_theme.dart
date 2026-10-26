import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_tokens.dart';

abstract final class AppFonts {
  static const display = 'CormorantGaramond';
  static const body = 'Manrope';
}

abstract final class AppTheme {
  static ThemeData light() => _build(WerengaPalette.light, Brightness.light);

  static ThemeData dark() => _build(WerengaPalette.dark, Brightness.dark);

  static ThemeData _build(WerengaPalette palette, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final textTheme = _textTheme(palette);

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: isDark ? AppColors.gold : palette.emerald,
      onPrimary: isDark ? AppColors.emeraldNight : AppColors.ivory,
      primaryContainer: isDark ? AppColors.forest : AppColors.parchmentDeep,
      onPrimaryContainer: isDark ? AppColors.ivory : AppColors.emeraldDeep,
      secondary: palette.gold,
      onSecondary: AppColors.emeraldNight,
      secondaryContainer: isDark
          ? const Color(0xFF3B3321)
          : const Color(0xFFF1E5C9),
      onSecondaryContainer: isDark ? AppColors.goldBright : AppColors.goldDeep,
      tertiary: palette.emerald,
      onTertiary: AppColors.ivory,
      error: palette.danger,
      onError: Colors.white,
      surface: palette.surface,
      onSurface: palette.ink,
      onSurfaceVariant: palette.inkMuted,
      outline: palette.cardBorder,
      outlineVariant: palette.cardBorder,
      shadow: palette.shadow,
      scrim: palette.overlay,
      inverseSurface: isDark ? AppColors.ivory : AppColors.emeraldDeep,
      onInverseSurface: isDark ? AppColors.ink : AppColors.ivory,
      inversePrimary: palette.gold,
      surfaceTint: Colors.transparent,
    );

    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      borderSide: BorderSide(color: palette.cardBorder),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: palette.background,
      canvasColor: palette.background,
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.standard,
      textTheme: textTheme,
      extensions: [palette],
      appBarTheme: AppBarThemeData(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: palette.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: palette.ink, size: 22),
        titleTextStyle: textTheme.titleLarge?.copyWith(color: palette.ink),
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),
      iconTheme: IconThemeData(color: palette.ink, size: 22),
      dividerTheme: DividerThemeData(
        color: palette.cardBorder,
        thickness: 1,
        space: 1,
      ),
      cardTheme: CardThemeData(
        color: palette.card,
        surfaceTintColor: Colors.transparent,
        shadowColor: palette.shadow,
        elevation: 0,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: palette.cardBorder),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: palette.emerald,
          foregroundColor: AppColors.ivory,
          disabledBackgroundColor: palette.cardBorder,
          disabledForegroundColor: palette.inkMuted,
          minimumSize: const Size(0, 50),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          textStyle: textTheme.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ).copyWith(
          overlayColor: WidgetStatePropertyAll(
            AppColors.ivory.withValues(alpha: 0.12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: palette.ink,
          minimumSize: const Size(0, 50),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          side: BorderSide(color: palette.cardBorder),
          textStyle: textTheme.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: palette.goldStrong,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: palette.ink,
          highlightColor: palette.gold.withValues(alpha: 0.12),
          minimumSize: const Size(44, 44),
          padding: const EdgeInsets.all(10),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        backgroundColor: palette.navBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        indicatorColor: palette.navIndicator,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 23,
            color: selected ? palette.emerald : palette.inkMuted,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return textTheme.labelSmall?.copyWith(
            color: selected ? palette.emerald : palette.inkMuted,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
            letterSpacing: 0.2,
          );
        }),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: palette.surfaceMuted,
        selectedColor: palette.emerald,
        disabledColor: palette.surfaceMuted,
        side: BorderSide(color: palette.cardBorder),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        labelPadding: const EdgeInsets.symmetric(horizontal: 3),
        labelStyle: textTheme.labelMedium?.copyWith(color: palette.ink),
        secondaryLabelStyle: textTheme.labelMedium?.copyWith(
          color: AppColors.ivory,
        ),
        showCheckmark: false,
        checkmarkColor: AppColors.ivory,
        brightness: brightness,
      ),
      sliderTheme: SliderThemeData(
        trackHeight: 3,
        activeTrackColor: palette.gold,
        inactiveTrackColor: palette.cardBorder,
        thumbColor: palette.goldStrong,
        overlayColor: palette.gold.withValues(alpha: 0.14),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
        trackShape: const RoundedRectSliderTrackShape(),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 16),
      ),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: palette.surfaceMuted,
        hintStyle: textTheme.bodyMedium?.copyWith(color: palette.inkMuted),
        labelStyle: textTheme.bodyMedium?.copyWith(color: palette.inkMuted),
        prefixIconColor: palette.inkMuted,
        suffixIconColor: palette.inkMuted,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpace.md,
          vertical: 14,
        ),
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(
          borderSide: BorderSide(color: palette.gold, width: 1.4),
        ),
        errorBorder: border.copyWith(
          borderSide: BorderSide(color: palette.danger),
        ),
        focusedErrorBorder: border.copyWith(
          borderSide: BorderSide(color: palette.danger, width: 1.4),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: palette.card,
        surfaceTintColor: Colors.transparent,
        elevation: 12,
        shadowColor: palette.shadow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          side: BorderSide(color: palette.cardBorder),
        ),
        titleTextStyle: textTheme.headlineSmall?.copyWith(color: palette.ink),
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: palette.inkMuted),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: palette.card,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: palette.card,
        modalBarrierColor: palette.overlay,
        elevation: 16,
        showDragHandle: true,
        dragHandleColor: palette.cardBorder,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? AppColors.nightCard : AppColors.emeraldDeep,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: AppColors.ivory,
        ),
        actionTextColor: AppColors.goldBright,
        behavior: SnackBarBehavior.floating,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: const BorderSide(color: Color(0x33C6A664)),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: palette.gold,
        linearTrackColor: palette.cardBorder,
        circularTrackColor: palette.cardBorder,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: palette.inkMuted,
        textColor: palette.ink,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpace.md,
          vertical: AppSpace.xxs,
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: isDark ? AppColors.nightCard : AppColors.emeraldDeep,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0x33C6A664)),
        ),
        textStyle: textTheme.bodySmall?.copyWith(color: AppColors.ivory),
        waitDuration: const Duration(milliseconds: 450),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }

  static TextTheme _textTheme(WerengaPalette palette) {
    final base = TextTheme(
      displayLarge: const TextStyle(
        fontFamily: AppFonts.display,
        fontSize: 46,
        fontWeight: FontWeight.w600,
        height: 1.0,
        letterSpacing: -0.8,
      ),
      displayMedium: const TextStyle(
        fontFamily: AppFonts.display,
        fontSize: 38,
        fontWeight: FontWeight.w600,
        height: 1.03,
        letterSpacing: -0.6,
      ),
      displaySmall: const TextStyle(
        fontFamily: AppFonts.display,
        fontSize: 32,
        fontWeight: FontWeight.w600,
        height: 1.06,
        letterSpacing: -0.4,
      ),
      headlineLarge: const TextStyle(
        fontFamily: AppFonts.display,
        fontSize: 30,
        fontWeight: FontWeight.w600,
        height: 1.08,
        letterSpacing: -0.3,
      ),
      headlineMedium: const TextStyle(
        fontFamily: AppFonts.display,
        fontSize: 26,
        fontWeight: FontWeight.w600,
        height: 1.12,
        letterSpacing: -0.2,
      ),
      headlineSmall: const TextStyle(
        fontFamily: AppFonts.display,
        fontSize: 23,
        fontWeight: FontWeight.w600,
        height: 1.15,
      ),
      titleLarge: const TextStyle(
        fontFamily: AppFonts.display,
        fontSize: 21,
        fontWeight: FontWeight.w600,
        height: 1.18,
        letterSpacing: -0.1,
      ),
      titleMedium: const TextStyle(
        fontFamily: AppFonts.body,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.28,
        letterSpacing: -0.1,
      ),
      titleSmall: const TextStyle(
        fontFamily: AppFonts.body,
        fontSize: 13.5,
        fontWeight: FontWeight.w600,
        height: 1.25,
        letterSpacing: 0.1,
      ),
      bodyLarge: const TextStyle(
        fontFamily: AppFonts.body,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
        letterSpacing: -0.1,
      ),
      bodyMedium: const TextStyle(
        fontFamily: AppFonts.body,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.48,
        letterSpacing: -0.05,
      ),
      bodySmall: const TextStyle(
        fontFamily: AppFonts.body,
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.42,
      ),
      labelLarge: const TextStyle(
        fontFamily: AppFonts.body,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.2,
        letterSpacing: 0.1,
      ),
      labelMedium: const TextStyle(
        fontFamily: AppFonts.body,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 1.2,
        letterSpacing: 0.3,
      ),
      labelSmall: const TextStyle(
        fontFamily: AppFonts.body,
        fontSize: 10.5,
        fontWeight: FontWeight.w600,
        height: 1.2,
        letterSpacing: 0.8,
      ),
    );
    return base
        .apply(
          bodyColor: palette.ink,
          displayColor: palette.ink,
          fontFamily: AppFonts.body,
        )
        .copyWith(
          displayLarge: base.displayLarge?.copyWith(color: palette.ink),
          displayMedium: base.displayMedium?.copyWith(color: palette.ink),
          displaySmall: base.displaySmall?.copyWith(color: palette.ink),
          headlineLarge: base.headlineLarge?.copyWith(color: palette.ink),
          headlineMedium: base.headlineMedium?.copyWith(color: palette.ink),
          headlineSmall: base.headlineSmall?.copyWith(color: palette.ink),
          titleLarge: base.titleLarge?.copyWith(color: palette.ink),
        );
  }
}
