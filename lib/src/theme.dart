// ============================================================
// SuperTabBarThemeData — the component's own ThemeExtension.
// ------------------------------------------------------------
// Self-contained: replaces design-system token / surface / theme files.
// Everything SuperTabBar (and its pages / overlays) needs to paint lives here.
//
//   • Instance fields  = surfaces that SWAP between dark & light
//     (bg / surface / hover / border / fg1..fg4 …). These are lerped.
//   • Static const     = brand constants that DON'T vary by theme
//     (accent + semantic palette, font families, radii, shadows, motion).
//
// Register on your app theme:
//
//   ThemeData(
//     extensions: [SuperTabBarThemeData.dark],   // or .light
//   )
//
// then read it anywhere:
//
//   SuperTabBarThemeData.of(context)   // falls back to .dark if none registered
//
//   File: lib/src/theme.dart
// ============================================================

import 'package:flutter/material.dart';

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
  static const Color accent = Color(0xFF4A7CFF);
  static const Color success = Color(0xFF1DB88A);
  static const Color warning = Color(0xFFF97316);
  static const Color danger = Color(0xFFEF4444);
  static const Color info = accent;

  // ── Typography ─────────────────────────────────────────────
  static const String displayFont = 'Manrope';
  static const String bodyFont = 'Inter';
  static const String monoFont = 'JetBrainsMono';

  // ── Radii ──────────────────────────────────────────────────
  static const double radiusSm = 4;
  static const double radiusMd = 6;
  static const double radiusLg = 8;
  static const double radiusXl = 12;

  // ── Elevation ──────────────────────────────────────────────
  static const List<BoxShadow> cardShadow = [
    BoxShadow(color: Color(0x40000000), blurRadius: 50, spreadRadius: -12, offset: Offset(0, 25)),
  ];
  static const List<BoxShadow> popShadow = [
    BoxShadow(color: Color(0x73000000), blurRadius: 32, spreadRadius: -8, offset: Offset(0, 12)),
  ];

  // ── Motion ─────────────────────────────────────────────────
  static const Duration durFast = Duration(milliseconds: 100);
  static const Duration durBase = Duration(milliseconds: 150);
  static const Duration durSlow = Duration(milliseconds: 300);
  static const Duration durSlower = Duration(milliseconds: 500);
  static const Curve curveStandard = Cubic(0.4, 0, 0.2, 1);
  static const Curve curveDecelerate = Cubic(0, 0, 0.2, 1);
  static const Curve curveEmphasized = Cubic(0.2, 0, 0, 1);

  // ── Presets ────────────────────────────────────────────────
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
    inputBg: Color(0xFFF1F3F8),
    hover: Color(0xFFEEF1F7),
    border: Color(0xFFE2E8F0),
    borderStrong: Color(0xFFC2C6D6),
    fg1: Color(0xFF0F172A),
    fg2: Color(0xFF424754),
    fg3: Color(0xFF64748B),
    fg4: Color(0xFFC2C6D6),
  );

  /// Reads the registered extension, or falls back to [dark].
  static SuperTabBarThemeData of(BuildContext context) =>
      Theme.of(context).extension<SuperTabBarThemeData>() ?? dark;

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
      );

  @override
  SuperTabBarThemeData lerp(ThemeExtension<SuperTabBarThemeData>? other, double t) {
    if (other is! SuperTabBarThemeData) return this;
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
    );
  }
}

// ── Backward-compatible alias ──────────────────────────────────
/// Alias for [SuperTabBarThemeData]. Maintained for backward compatibility.
typedef BrowserStyleTabBarThemeData = SuperTabBarThemeData;
