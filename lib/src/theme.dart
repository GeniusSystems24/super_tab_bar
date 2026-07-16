// ============================================================
// SuperTabBarThemeData — the component's own ThemeExtension.
// ------------------------------------------------------------
// Self-contained: all surfaces and brand constants needed by SuperTabBar.
//
//   • Instance fields  = surfaces that SWAP between dark & light (lerped).
//   • Static const     = brand constants that don't vary by theme.
//
// v2.5.0 — SuperMaterialThemeData compatibility
// ----------------------------------------------
// SuperTabBarThemeData.of(context) now bridges from the Material ColorScheme
// automatically when no explicit extension is registered. This means
// registering SuperMaterialThemeData.light/dark() in MaterialApp is
// sufficient — no extra extension wiring is needed:
//
//   MaterialApp(
//     theme:     SuperMaterialThemeData.light(palette: SuperPalette.bluePalette),
//     darkTheme: SuperMaterialThemeData.dark(palette: SuperPalette.bluePalette),
//     // SuperTabBar themes automatically from ColorScheme.
//   )
//
// To override explicitly:
//
//   ThemeData(
//     extensions: [SuperTabBarThemeData.fromColorScheme(colorScheme)],
//   )
//
//   File: lib/src/theme.dart
// ============================================================

import 'package:flutter/material.dart';
import 'package:super_core/super_core.dart';

@immutable
class SuperTabBarThemeData extends ThemeExtension<SuperTabBarThemeData> {
  // ── Swappable surfaces (dark ↔ light) ──────────────────────
  final Color bg;           // strip container / page base
  final Color surface;      // active-tab content / card
  final Color surface2;     // nested card
  final Color inputBg;      // input fill / close-button hover
  final Color hover;        // hover tint
  final Color border;       // hairline
  final Color borderStrong; // solid divider / pop-card edge
  final Color fg1;          // primary text
  final Color fg2;          // secondary
  final Color fg3;          // tertiary / placeholder
  final Color fg4;          // disabled

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
  });

  // ── Brand + semantic palette (theme-independent · const) ───
  static const Color accent  = Color(0xFF4A7CFF);
  static const Color success = Color(0xFF1DB88A);
  static const Color warning = Color(0xFFF97316);
  static const Color danger  = Color(0xFFEF4444);
  static const Color info    = accent;

  // ── Typography ─────────────────────────────────────────────
  static const String displayFont = 'Manrope';
  static const String bodyFont    = 'Inter';
  static const String monoFont    = 'JetBrainsMono';

  // ── Radii ──────────────────────────────────────────────────
  static const double radiusSm = 4;
  static const double radiusMd = 6;
  static const double radiusLg = 8;
  static const double radiusXl = 12;

  // ── Elevation ──────────────────────────────────────────────
  static const List<BoxShadow> cardShadow = [
    BoxShadow(
        color: Color(0x40000000),
        blurRadius: 50,
        spreadRadius: -12,
        offset: Offset(0, 25)),
  ];
  static const List<BoxShadow> popShadow = [
    BoxShadow(
        color: Color(0x73000000),
        blurRadius: 32,
        spreadRadius: -8,
        offset: Offset(0, 12)),
  ];

  // ── Motion ─────────────────────────────────────────────────
  static const Duration durFast    = Duration(milliseconds: 100);
  static const Duration durBase    = Duration(milliseconds: 150);
  static const Duration durSlow    = Duration(milliseconds: 300);
  static const Duration durSlower  = Duration(milliseconds: 500);
  static const Curve curveStandard    = Cubic(0.4, 0, 0.2, 1);
  static const Curve curveDecelerate  = Cubic(0, 0, 0.2, 1);
  static const Curve curveEmphasized  = Cubic(0.2, 0, 0, 1);

  // ── Static presets ─────────────────────────────────────────
  static const SuperTabBarThemeData dark = SuperTabBarThemeData(
    bg:           Color(0xFF111318),
    surface:      Color(0xFF1E2025),
    surface2:     Color(0xFF292D38),
    inputBg:      Color(0xFF33353A),
    hover:        Color(0xFF2F3540),
    border:       Color(0x6643464F),
    borderStrong: Color(0xFF434654),
    fg1:          Color(0xFFE2E2E9),
    fg2:          Color(0xFFC3C6D7),
    fg3:          Color(0xFF8D90A0),
    fg4:          Color(0xFF44474E),
  );

  static const SuperTabBarThemeData light = SuperTabBarThemeData(
    bg:           Color(0xFFF7F8FA),
    surface:      Color(0xFFFFFFFF),
    surface2:     Color(0xFFFFFFFF),
    inputBg:      Color(0xFFE6ECF5),
    hover:        Color(0xFFDDE5F2),
    border:       Color(0xFFE2E8F0),
    borderStrong: Color(0xFFC2C6D6),
    fg1:          Color(0xFF0F172A),
    fg2:          Color(0xFF424754),
    fg3:          Color(0xFF64748B),
    fg4:          Color(0xFFC2C6D6),
  );

  // ── SuperMaterialThemeData compatibility ──────────────────

  /// Derives a [SuperTabBarThemeData] from a Material [ColorScheme].
  ///
  /// Called automatically by [of] when no explicit extension is registered,
  /// enabling seamless use with [SuperMaterialThemeData]. Reads GeniusLink
  /// neutral surface constants for surface/border tokens so the tab bar
  /// remains visually consistent with the rest of the Super toolkit.
  factory SuperTabBarThemeData.fromColorScheme(ColorScheme cs) {
    final isDark = cs.brightness == Brightness.dark;
    final fallback = isDark ? dark : light;
    // Use GeniusLink-standard neutral surfaces for visual consistency;
    // fg tokens come from the ColorScheme for accurate palette adaptation.
    return SuperTabBarThemeData(
      bg:           isDark ? const Color(0xFF111318) : const Color(0xFFF7F8FA),
      surface:      isDark ? const Color(0xFF1E2025) : cs.surface,
      surface2:     isDark ? const Color(0xFF292D38) : cs.surfaceContainerHighest,
      inputBg:      isDark ? const Color(0xFF33353A) : cs.surfaceContainerHighest,
      hover:        isDark ? const Color(0xFF2F3540) : fallback.hover,
      border:       isDark ? const Color(0x6643464F) : cs.outline,
      borderStrong: isDark ? const Color(0xFF434654) : cs.outlineVariant,
      fg1:          cs.onSurface,
      fg2:          cs.onSurfaceVariant,
      fg3:          isDark ? const Color(0xFF8D90A0) : cs.onSurfaceVariant,
      fg4:          isDark ? const Color(0xFF44474E) : fallback.fg4,
    );
  }

  /// Derives a [SuperTabBarThemeData] from a [SuperMaterialThemeData].
  ///
  /// This is the preferred bridge (v2.7.0): it reads the palette-, brightness-
  /// and device-mode-aware surface tokens from `theme.superTheme` (the
  /// [SuperThemeData] that [SuperMaterialThemeData] registers) so the tab bar
  /// shares one source of truth with the rest of the toolkit instead of
  /// duplicating hard-coded light/dark hex. Explicit extensions still win in
  /// [of]; this is the automatic default.
  factory SuperTabBarThemeData.fromMaterialTheme(SuperMaterialThemeData theme) {
    return SuperTabBarThemeData.fromColorScheme(theme.colorScheme);
    // final s = theme.superTheme;
    // final isDark = theme.brightness == Brightness.dark;
    // return SuperTabBarThemeData(
    //   bg: s.bg,
    //   surface: s.surface,
    //   surface2: isDark ? s.hover : s.surface,
    //   inputBg: s.inputBg,
    //   hover: s.hover,
    //   border: s.border,
    //   borderStrong: s.borderStrong,
    //   fg1: s.fg1,
    //   fg2: s.fg2,
    //   fg3: s.fg3,
    //   fg4: s.fg4,
    // );
  }

  /// Reads the registered [ThemeExtension], or bridges from the current
  /// Material [ColorScheme] (enables [SuperMaterialThemeData] compatibility),
  /// or falls back to [dark] when no Material theme is present.
  ///
  /// Priority:
  /// 1. Explicit `SuperTabBarThemeData` extension registered on [ThemeData]
  /// 2. Derived from `Theme.of(context).colorScheme` via [fromColorScheme]
  /// 3. Static [dark] preset (last resort / no-theme environments)
  static SuperTabBarThemeData of(BuildContext context) {
    final ext = Theme.of(context).extension<SuperTabBarThemeData>();
    if (ext != null) return ext;
    final superTheme = SuperMaterialThemeData.maybeOf(context);
    if (superTheme != null) {
      return SuperTabBarThemeData.fromMaterialTheme(superTheme);
    }
    return SuperTabBarThemeData.fromColorScheme(
        Theme.of(context).colorScheme);
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
  }) =>
      SuperTabBarThemeData(
        bg:           bg           ?? this.bg,
        surface:      surface      ?? this.surface,
        surface2:     surface2     ?? this.surface2,
        inputBg:      inputBg      ?? this.inputBg,
        hover:        hover        ?? this.hover,
        border:       border       ?? this.border,
        borderStrong: borderStrong ?? this.borderStrong,
        fg1:          fg1          ?? this.fg1,
        fg2:          fg2          ?? this.fg2,
        fg3:          fg3          ?? this.fg3,
        fg4:          fg4          ?? this.fg4,
      );

  @override
  SuperTabBarThemeData lerp(
      ThemeExtension<SuperTabBarThemeData>? other, double t) {
    if (other is! SuperTabBarThemeData) return this;
    return SuperTabBarThemeData(
      bg:           Color.lerp(bg,           other.bg,           t)!,
      surface:      Color.lerp(surface,      other.surface,      t)!,
      surface2:     Color.lerp(surface2,     other.surface2,     t)!,
      inputBg:      Color.lerp(inputBg,      other.inputBg,      t)!,
      hover:        Color.lerp(hover,        other.hover,        t)!,
      border:       Color.lerp(border,       other.border,       t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      fg1:          Color.lerp(fg1,          other.fg1,          t)!,
      fg2:          Color.lerp(fg2,          other.fg2,          t)!,
      fg3:          Color.lerp(fg3,          other.fg3,          t)!,
      fg4:          Color.lerp(fg4,          other.fg4,          t)!,
    );
  }
}

// ── Backward-compatible alias ──────────────────────────────────
/// Alias for [SuperTabBarThemeData]. Maintained for backward compatibility.
typedef BrowserStyleTabBarThemeData = SuperTabBarThemeData;
