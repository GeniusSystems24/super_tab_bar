// ============================================================
// super_tab_bar — preview options.
//   File: lib/src/preview_options.dart
// ============================================================

/// Controls how hover-intent mini-page previews behave in [SuperTabBar].
///
/// Pass to [SuperTabBar.previewOptions]. Common presets:
///
/// ```dart
/// // Disable previews entirely:
/// SuperTabBar(previewOptions: SuperTabBarPreviewOptions.disabled)
///
/// // Faster appear, higher-quality snapshot:
/// SuperTabBar(
///   previewOptions: SuperTabBarPreviewOptions(
///     hoverDelay: Duration(milliseconds: 250),
///     snapshotPixelRatio: 1.0,
///   ),
/// )
/// ```
class SuperTabBarPreviewOptions {
  const SuperTabBarPreviewOptions({
    this.enabled = true,
    this.hoverDelay = const Duration(milliseconds: 480),
    this.snapshotPixelRatio = 0.6,
    this.fallback = PreviewFallback.liveRender,
  });

  /// Whether hover previews are shown at all. Default: `true`.
  final bool enabled;

  /// How long the cursor must hover over a tab before the preview appears.
  /// Default: 480 ms.
  final Duration hoverDelay;

  /// Device-pixel ratio used when capturing the active page via
  /// [RenderRepaintBoundary.toImage]. Lower = faster but blurrier.
  /// Default: `0.6`.
  final double snapshotPixelRatio;

  /// What to show when no snapshot has been captured yet for a tab.
  final PreviewFallback fallback;

  /// Default options (previews on, 480 ms delay, 0.6× ratio, live fallback).
  static const SuperTabBarPreviewOptions defaults = SuperTabBarPreviewOptions();

  /// Previews fully disabled — no capture, no popover.
  static const SuperTabBarPreviewOptions disabled = SuperTabBarPreviewOptions(
    enabled: false,
  );
}

/// What to display inside [MiniPagePreview] when no
/// [RenderRepaintBoundary] snapshot is available for a tab yet.
enum PreviewFallback {
  /// Re-render the page at a small scale (default). Useful when the page is
  /// cheap to build and its static layout is meaningful as a thumbnail.
  liveRender,

  /// Show only the theme's surface color. Useful for expensive or
  /// sensitive page content.
  blank,
}
