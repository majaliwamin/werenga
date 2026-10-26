import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Spacing, radius and motion tokens used across the interface.
abstract final class AppSpace {
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 20.0;
  static const xl = 24.0;
  static const xxl = 32.0;
  static const xxxl = 40.0;
  static const huge = 56.0;
}

abstract final class AppRadius {
  static const sm = 10.0;
  static const md = 16.0;
  static const lg = 20.0;
  static const xl = 26.0;
  static const pill = 999.0;
}

abstract final class AppMotion {
  static const quick = Duration(milliseconds: 160);
  static const standard = Duration(milliseconds: 280);
  static const gentle = Duration(milliseconds: 520);
  static const slow = Duration(milliseconds: 900);
}

/// Theme-aware colours exposed through [ThemeData.extensions].
@immutable
class WerengaPalette extends ThemeExtension<WerengaPalette> {
  const WerengaPalette({
    required this.background,
    required this.backgroundAlt,
    required this.surface,
    required this.surfaceMuted,
    required this.card,
    required this.cardBorder,
    required this.ink,
    required this.inkMuted,
    required this.gold,
    required this.goldStrong,
    required this.emerald,
    required this.emeraldDeep,
    required this.onEmblem,
    required this.heroStart,
    required this.heroEnd,
    required this.pattern,
    required this.shadow,
    required this.navBackground,
    required this.navIndicator,
    required this.danger,
    required this.success,
    required this.overlay,
  });

  final Color background;
  final Color backgroundAlt;
  final Color surface;
  final Color surfaceMuted;
  final Color card;
  final Color cardBorder;
  final Color ink;
  final Color inkMuted;
  final Color gold;
  final Color goldStrong;
  final Color emerald;
  final Color emeraldDeep;
  final Color onEmblem;
  final Color heroStart;
  final Color heroEnd;
  final Color pattern;
  final Color shadow;
  final Color navBackground;
  final Color navIndicator;
  final Color danger;
  final Color success;
  final Color overlay;

  static const light = WerengaPalette(
    background: AppColors.ivory,
    backgroundAlt: AppColors.parchment,
    surface: AppColors.ivoryBright,
    surfaceMuted: AppColors.parchment,
    card: AppColors.ivoryBright,
    cardBorder: Color(0xFFE2D3B7),
    ink: AppColors.ink,
    inkMuted: AppColors.inkMuted,
    gold: AppColors.gold,
    goldStrong: AppColors.goldDeep,
    emerald: AppColors.emerald,
    emeraldDeep: AppColors.emeraldDeep,
    onEmblem: AppColors.ivory,
    heroStart: AppColors.forestLight,
    heroEnd: AppColors.emeraldDeep,
    pattern: Color(0xFFB99A5F),
    shadow: Color(0x1F2A2213),
    navBackground: AppColors.ivoryBright,
    navIndicator: Color(0x2EC6A664),
    danger: AppColors.danger,
    success: AppColors.success,
    overlay: Color(0x660B1612),
  );

  static const dark = WerengaPalette(
    background: AppColors.night,
    backgroundAlt: Color(0xFF0E1C16),
    surface: AppColors.nightSurface,
    surfaceMuted: Color(0xFF0D1B15),
    card: AppColors.nightCard,
    cardBorder: AppColors.nightLine,
    ink: AppColors.nightInk,
    inkMuted: AppColors.nightInkMuted,
    gold: AppColors.gold,
    goldStrong: AppColors.goldBright,
    emerald: AppColors.forestLight,
    emeraldDeep: AppColors.emeraldNight,
    onEmblem: AppColors.ivory,
    heroStart: Color(0xFF14503C),
    heroEnd: Color(0xFF082A21),
    pattern: Color(0xFF7E9A87),
    shadow: Color(0x66000000),
    navBackground: Color(0xFF0E1C16),
    navIndicator: Color(0x38C6A664),
    danger: Color(0xFFD08A80),
    success: Color(0xFF7FB79A),
    overlay: Color(0x99040D0A),
  );

  @override
  WerengaPalette copyWith({
    Color? background,
    Color? backgroundAlt,
    Color? surface,
    Color? surfaceMuted,
    Color? card,
    Color? cardBorder,
    Color? ink,
    Color? inkMuted,
    Color? gold,
    Color? goldStrong,
    Color? emerald,
    Color? emeraldDeep,
    Color? onEmblem,
    Color? heroStart,
    Color? heroEnd,
    Color? pattern,
    Color? shadow,
    Color? navBackground,
    Color? navIndicator,
    Color? danger,
    Color? success,
    Color? overlay,
  }) {
    return WerengaPalette(
      background: background ?? this.background,
      backgroundAlt: backgroundAlt ?? this.backgroundAlt,
      surface: surface ?? this.surface,
      surfaceMuted: surfaceMuted ?? this.surfaceMuted,
      card: card ?? this.card,
      cardBorder: cardBorder ?? this.cardBorder,
      ink: ink ?? this.ink,
      inkMuted: inkMuted ?? this.inkMuted,
      gold: gold ?? this.gold,
      goldStrong: goldStrong ?? this.goldStrong,
      emerald: emerald ?? this.emerald,
      emeraldDeep: emeraldDeep ?? this.emeraldDeep,
      onEmblem: onEmblem ?? this.onEmblem,
      heroStart: heroStart ?? this.heroStart,
      heroEnd: heroEnd ?? this.heroEnd,
      pattern: pattern ?? this.pattern,
      shadow: shadow ?? this.shadow,
      navBackground: navBackground ?? this.navBackground,
      navIndicator: navIndicator ?? this.navIndicator,
      danger: danger ?? this.danger,
      success: success ?? this.success,
      overlay: overlay ?? this.overlay,
    );
  }

  @override
  WerengaPalette lerp(covariant WerengaPalette? other, double t) {
    if (other == null) return this;
    Color lerpColor(Color a, Color b) => Color.lerp(a, b, t) ?? b;
    return WerengaPalette(
      background: lerpColor(background, other.background),
      backgroundAlt: lerpColor(backgroundAlt, other.backgroundAlt),
      surface: lerpColor(surface, other.surface),
      surfaceMuted: lerpColor(surfaceMuted, other.surfaceMuted),
      card: lerpColor(card, other.card),
      cardBorder: lerpColor(cardBorder, other.cardBorder),
      ink: lerpColor(ink, other.ink),
      inkMuted: lerpColor(inkMuted, other.inkMuted),
      gold: lerpColor(gold, other.gold),
      goldStrong: lerpColor(goldStrong, other.goldStrong),
      emerald: lerpColor(emerald, other.emerald),
      emeraldDeep: lerpColor(emeraldDeep, other.emeraldDeep),
      onEmblem: lerpColor(onEmblem, other.onEmblem),
      heroStart: lerpColor(heroStart, other.heroStart),
      heroEnd: lerpColor(heroEnd, other.heroEnd),
      pattern: lerpColor(pattern, other.pattern),
      shadow: lerpColor(shadow, other.shadow),
      navBackground: lerpColor(navBackground, other.navBackground),
      navIndicator: lerpColor(navIndicator, other.navIndicator),
      danger: lerpColor(danger, other.danger),
      success: lerpColor(success, other.success),
      overlay: lerpColor(overlay, other.overlay),
    );
  }
}

extension WerengaPaletteContext on BuildContext {
  WerengaPalette get palette =>
      Theme.of(this).extension<WerengaPalette>() ?? WerengaPalette.light;

  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}
