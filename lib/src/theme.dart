// ============================================================
// SuperTabBarThemeData — the component ThemeExtension.
// ------------------------------------------------------------
// v3.3.0 derives brand colors, typography, radii, and motion from super_core's
// ambient SuperMaterialThemeData. Explicit extension overrides still win.
// ============================================================

import 'package:flutter/material.dart';
import 'package:super_core/super_core.dart';

@immutable
class SuperTabBarThemeData extends ThemeExtension<SuperTabBarThemeData> {
  const SuperTabBarThemeData({
    required this.bg,
    required this.surface,
    required this.surface2,
    required this.inputBg,
    required this.hover,
    required this.border,
    required this.borderStrong,
    required this.fg1,
    required this.fg2,
    required this.fg3,
    required this.fg4,
    this.accentColor = const Color(0xFF4A7CFF),
    this.successColor = const Color(0xFF1DB88A),
    this.warningColor = const Color(0xFFF97316),
    this.dangerColor = const Color(0xFFEF4444),
    this.infoColor = const Color(0xFF0EA5E9),
    this.displayFontFamily = 'Manrope',
    this.bodyFontFamily = 'Inter',
    this.monoFontFamily = 'JetBrainsMono',
    this.radiusSmall = 4,
    this.radiusMedium = 6,
    this.radiusLarge = 8,
    this.radiusExtraLarge = 12,
    this.cardShadows = defaultCardShadow,
    this.popShadows = defaultPopShadow,
    this.fastDuration = const Duration(milliseconds: 100),
    this.baseDuration = const Duration(milliseconds: 150),
    this.slowDuration = const Duration(milliseconds: 300),
    this.slowerDuration = const Duration(milliseconds: 500),
    this.standardCurve = const Cubic(0.4, 0, 0.2, 1),
    this.decelerateCurve = const Cubic(0, 0, 0.2, 1),
    this.emphasizedCurve = const Cubic(0.2, 0, 0, 1),
  });

  // Swappable surfaces.
  final Color bg;
  final Color surface;
  final Color surface2;
  final Color inputBg;
  final Color hover;
  final Color border;
  final Color borderStrong;
  final Color fg1;
  final Color fg2;
  final Color fg3;
  final Color fg4;

  // Brand and semantic colors resolved from super_core.
  final Color accentColor;
  final Color successColor;
  final Color warningColor;
  final Color dangerColor;
  final Color infoColor;

  // Typography resolved from SuperMaterialThemeData.textTheme. Mono remains
  // token-driven because SuperTextTheme has no monospace family contract.
  final String displayFontFamily;
  final String bodyFontFamily;
  final String monoFontFamily;

  // Responsive radii resolved from SuperSpacing.
  final double radiusSmall;
  final double radiusMedium;
  final double radiusLarge;
  final double radiusExtraLarge;

  // Elevation.
  final List<BoxShadow> cardShadows;
  final List<BoxShadow> popShadows;

  // Motion resolved from SuperTokensData where possible.
  final Duration fastDuration;
  final Duration baseDuration;
  final Duration slowDuration;
  final Duration slowerDuration;
  final Curve standardCurve;
  final Curve decelerateCurve;
  final Curve emphasizedCurve;

  static const List<BoxShadow> defaultCardShadow = [
    BoxShadow(
      color: Color(0x40000000),
      blurRadius: 50,
      spreadRadius: -12,
      offset: Offset(0, 25),
    ),
  ];

  static const List<BoxShadow> defaultPopShadow = [
    BoxShadow(
      color: Color(0x73000000),
      blurRadius: 32,
      spreadRadius: -8,
      offset: Offset(0, 12),
    ),
  ];

  // Legacy constants retained for source compatibility. New code should read
  // the resolved instance from SuperTabBarThemeData.of(context).
  @Deprecated('Use SuperTabBarThemeData.of(context).accentColor.')
  static const Color accent = Color(0xFF4A7CFF);
  @Deprecated('Use SuperTabBarThemeData.of(context).successColor.')
  static const Color success = Color(0xFF1DB88A);
  @Deprecated('Use SuperTabBarThemeData.of(context).warningColor.')
  static const Color warning = Color(0xFFF97316);
  @Deprecated('Use SuperTabBarThemeData.of(context).dangerColor.')
  static const Color danger = Color(0xFFEF4444);
  @Deprecated('Use SuperTabBarThemeData.of(context).infoColor.')
  static const Color info = Color(0xFF0EA5E9);

  @Deprecated('Use SuperTabBarThemeData.of(context).displayFontFamily.')
  static const String displayFont = 'Manrope';
  @Deprecated('Use SuperTabBarThemeData.of(context).bodyFontFamily.')
  static const String bodyFont = 'Inter';
  @Deprecated('Use SuperTabBarThemeData.of(context).monoFontFamily.')
  static const String monoFont = 'JetBrainsMono';

  @Deprecated('Use SuperTabBarThemeData.of(context).radiusSmall.')
  static const double radiusSm = 4;
  @Deprecated('Use SuperTabBarThemeData.of(context).radiusMedium.')
  static const double radiusMd = 6;
  @Deprecated('Use SuperTabBarThemeData.of(context).radiusLarge.')
  static const double radiusLg = 8;
  @Deprecated('Use SuperTabBarThemeData.of(context).radiusExtraLarge.')
  static const double radiusXl = 12;

  @Deprecated('Use SuperTabBarThemeData.of(context).cardShadows.')
  static const List<BoxShadow> cardShadow = defaultCardShadow;
  @Deprecated('Use SuperTabBarThemeData.of(context).popShadows.')
  static const List<BoxShadow> popShadow = defaultPopShadow;

  @Deprecated('Use SuperTabBarThemeData.of(context).fastDuration.')
  static const Duration durFast = Duration(milliseconds: 100);
  @Deprecated('Use SuperTabBarThemeData.of(context).baseDuration.')
  static const Duration durBase = Duration(milliseconds: 150);
  @Deprecated('Use SuperTabBarThemeData.of(context).slowDuration.')
  static const Duration durSlow = Duration(milliseconds: 300);
  @Deprecated('Use SuperTabBarThemeData.of(context).slowerDuration.')
  static const Duration durSlower = Duration(milliseconds: 500);
  @Deprecated('Use SuperTabBarThemeData.of(context).standardCurve.')
  static const Curve curveStandard = Cubic(0.4, 0, 0.2, 1);
  @Deprecated('Use SuperTabBarThemeData.of(context).decelerateCurve.')
  static const Curve curveDecelerate = Cubic(0, 0, 0.2, 1);
  @Deprecated('Use SuperTabBarThemeData.of(context).emphasizedCurve.')
  static const Curve curveEmphasized = Cubic(0.2, 0, 0, 1);

  static const SuperTabBarThemeData dark = SuperTabBarThemeData(
    bg: Color(0xFF111318),
    surface: Color(0xFF1E2025),
    surface2: Color(0xFF292D38),
    inputBg: Color(0xFF33353A),
    hover: Color(0xFF2F3540),
    border: Color(0x6643464F),
    borderStrong: Color(0xFF434654),
    fg1: Color(0xFFE2E2E9),
    fg2: Color(0xFFC3C6D7),
    fg3: Color(0xFF8D90A0),
    fg4: Color(0xFF44474E),
  );

  static const SuperTabBarThemeData light = SuperTabBarThemeData(
    bg: Color(0xFFF7F8FA),
    surface: Color(0xFFFFFFFF),
    surface2: Color(0xFFFFFFFF),
    inputBg: Color(0xFFE6ECF5),
    hover: Color(0xFFDDE5F2),
    border: Color(0xFFE2E8F0),
    borderStrong: Color(0xFFC2C6D6),
    fg1: Color(0xFF0F172A),
    fg2: Color(0xFF424754),
    fg3: Color(0xFF64748B),
    fg4: Color(0xFFC2C6D6),
  );

  /// Derives the component theme from a regular Material [ColorScheme].
  factory SuperTabBarThemeData.fromColorScheme(ColorScheme cs) {
    return SuperTabBarThemeData(
      bg: cs.surface,
      surface: cs.surfaceContainerLow,
      surface2: cs.surfaceContainer,
      inputBg: cs.surfaceContainerHighest,
      hover: cs.onSurface.withValues(alpha: 0.08),
      border: cs.outlineVariant,
      borderStrong: cs.outline,
      fg1: cs.onSurface,
      fg2: cs.onSurfaceVariant,
      fg3: cs.onSurfaceVariant.withValues(alpha: 0.78),
      fg4: cs.onSurface.withValues(alpha: 0.38),
      accentColor: cs.primary,
      dangerColor: cs.error,
      infoColor: cs.tertiary,
    );
  }

  /// Derives every available value from the active GeniusLink design system.
  factory SuperTabBarThemeData.fromMaterialTheme(SuperMaterialThemeData theme) {
    final s = theme.superTheme;
    final tokens = s.tokens;
    final spacing = s.spacing;
    final textTheme = theme.textTheme;
    return SuperTabBarThemeData(
      bg: s.bg,
      surface: s.surface,
      surface2: theme.colorScheme.surfaceContainerHigh,
      inputBg: s.inputBg,
      hover: s.hover,
      border: s.border,
      borderStrong: s.borderStrong,
      fg1: s.fg1,
      fg2: s.fg2,
      fg3: s.fg3,
      fg4: s.fg4,
      accentColor: tokens.accent,
      successColor: tokens.success,
      warningColor: tokens.warning,
      dangerColor: tokens.danger,
      infoColor: tokens.info,
      // super_core 3.3.0 makes SuperTextTheme the typography source of truth.
      // Do not infer body/display families from SuperTokensData: they are no
      // longer synchronized implicitly from the supplied SuperTextTheme.
      displayFontFamily:
          textTheme.displayLarge?.fontFamily ?? tokens.displayFont,
      bodyFontFamily: textTheme.bodyMedium?.fontFamily ?? tokens.bodyFont,
      monoFontFamily: tokens.monoFont,
      radiusSmall: spacing.radiusControl,
      radiusMedium: spacing.radiusMd,
      radiusLarge: spacing.radiusCard,
      radiusExtraLarge: spacing.radiusPill,
      fastDuration: tokens.durFast,
      baseDuration: tokens.durBase,
      slowDuration: tokens.durExpand,
      standardCurve: tokens.curveStandard,
      decelerateCurve: tokens.curveOut,
    );
  }

  /// Reads an explicit extension first, then derives from super_core or Material.
  static SuperTabBarThemeData of(BuildContext context) {
    final material = Theme.of(context);
    final ext = material.extension<SuperTabBarThemeData>();
    if (ext != null) return ext;
    final superTheme = SuperMaterialThemeData.maybeOf(context);
    if (superTheme != null) {
      return SuperTabBarThemeData.fromMaterialTheme(superTheme);
    }
    return SuperTabBarThemeData.fromColorScheme(material.colorScheme);
  }

  @override
  SuperTabBarThemeData copyWith({
    Color? bg,
    Color? surface,
    Color? surface2,
    Color? inputBg,
    Color? hover,
    Color? border,
    Color? borderStrong,
    Color? fg1,
    Color? fg2,
    Color? fg3,
    Color? fg4,
    Color? accentColor,
    Color? successColor,
    Color? warningColor,
    Color? dangerColor,
    Color? infoColor,
    String? displayFontFamily,
    String? bodyFontFamily,
    String? monoFontFamily,
    double? radiusSmall,
    double? radiusMedium,
    double? radiusLarge,
    double? radiusExtraLarge,
    List<BoxShadow>? cardShadows,
    List<BoxShadow>? popShadows,
    Duration? fastDuration,
    Duration? baseDuration,
    Duration? slowDuration,
    Duration? slowerDuration,
    Curve? standardCurve,
    Curve? decelerateCurve,
    Curve? emphasizedCurve,
  }) => SuperTabBarThemeData(
    bg: bg ?? this.bg,
    surface: surface ?? this.surface,
    surface2: surface2 ?? this.surface2,
    inputBg: inputBg ?? this.inputBg,
    hover: hover ?? this.hover,
    border: border ?? this.border,
    borderStrong: borderStrong ?? this.borderStrong,
    fg1: fg1 ?? this.fg1,
    fg2: fg2 ?? this.fg2,
    fg3: fg3 ?? this.fg3,
    fg4: fg4 ?? this.fg4,
    accentColor: accentColor ?? this.accentColor,
    successColor: successColor ?? this.successColor,
    warningColor: warningColor ?? this.warningColor,
    dangerColor: dangerColor ?? this.dangerColor,
    infoColor: infoColor ?? this.infoColor,
    displayFontFamily: displayFontFamily ?? this.displayFontFamily,
    bodyFontFamily: bodyFontFamily ?? this.bodyFontFamily,
    monoFontFamily: monoFontFamily ?? this.monoFontFamily,
    radiusSmall: radiusSmall ?? this.radiusSmall,
    radiusMedium: radiusMedium ?? this.radiusMedium,
    radiusLarge: radiusLarge ?? this.radiusLarge,
    radiusExtraLarge: radiusExtraLarge ?? this.radiusExtraLarge,
    cardShadows: cardShadows ?? this.cardShadows,
    popShadows: popShadows ?? this.popShadows,
    fastDuration: fastDuration ?? this.fastDuration,
    baseDuration: baseDuration ?? this.baseDuration,
    slowDuration: slowDuration ?? this.slowDuration,
    slowerDuration: slowerDuration ?? this.slowerDuration,
    standardCurve: standardCurve ?? this.standardCurve,
    decelerateCurve: decelerateCurve ?? this.decelerateCurve,
    emphasizedCurve: emphasizedCurve ?? this.emphasizedCurve,
  );

  @override
  SuperTabBarThemeData lerp(
    ThemeExtension<SuperTabBarThemeData>? other,
    double t,
  ) {
    if (other is! SuperTabBarThemeData) return this;
    Duration duration(Duration a, Duration b) => Duration(
      microseconds:
          (a.inMicroseconds + (b.inMicroseconds - a.inMicroseconds) * t)
              .round(),
    );
    final useOther = t >= 0.5;
    return SuperTabBarThemeData(
      bg: Color.lerp(bg, other.bg, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surface2: Color.lerp(surface2, other.surface2, t)!,
      inputBg: Color.lerp(inputBg, other.inputBg, t)!,
      hover: Color.lerp(hover, other.hover, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      fg1: Color.lerp(fg1, other.fg1, t)!,
      fg2: Color.lerp(fg2, other.fg2, t)!,
      fg3: Color.lerp(fg3, other.fg3, t)!,
      fg4: Color.lerp(fg4, other.fg4, t)!,
      accentColor: Color.lerp(accentColor, other.accentColor, t)!,
      successColor: Color.lerp(successColor, other.successColor, t)!,
      warningColor: Color.lerp(warningColor, other.warningColor, t)!,
      dangerColor: Color.lerp(dangerColor, other.dangerColor, t)!,
      infoColor: Color.lerp(infoColor, other.infoColor, t)!,
      displayFontFamily:
          useOther ? other.displayFontFamily : displayFontFamily,
      bodyFontFamily: useOther ? other.bodyFontFamily : bodyFontFamily,
      monoFontFamily: useOther ? other.monoFontFamily : monoFontFamily,
      radiusSmall: radiusSmall + (other.radiusSmall - radiusSmall) * t,
      radiusMedium: radiusMedium + (other.radiusMedium - radiusMedium) * t,
      radiusLarge: radiusLarge + (other.radiusLarge - radiusLarge) * t,
      radiusExtraLarge:
          radiusExtraLarge + (other.radiusExtraLarge - radiusExtraLarge) * t,
      cardShadows: useOther ? other.cardShadows : cardShadows,
      popShadows: useOther ? other.popShadows : popShadows,
      fastDuration: duration(fastDuration, other.fastDuration),
      baseDuration: duration(baseDuration, other.baseDuration),
      slowDuration: duration(slowDuration, other.slowDuration),
      slowerDuration: duration(slowerDuration, other.slowerDuration),
      standardCurve: useOther ? other.standardCurve : standardCurve,
      decelerateCurve: useOther ? other.decelerateCurve : decelerateCurve,
      emphasizedCurve: useOther ? other.emphasizedCurve : emphasizedCurve,
    );
  }
}

/// Alias for [SuperTabBarThemeData]. Maintained for backward compatibility.
typedef BrowserStyleTabBarThemeData = SuperTabBarThemeData;
