// super_tab_bar — public API barrel.
//
// Import this one file for the full public surface:
//   import 'package:super_tab_bar/super_tab_bar.dart';
//
// ── Core ──────────────────────────────────────────────────────────
// SuperTabBar              — the widget (alias: BrowserStyleTabBar)
// SuperTabBarController    — ChangeNotifier state (alias: BrowserStyleTabBarController)
// SuperTabBarScope         — InheritedNotifier (alias: BrowserStyleTabBarScope)
// SuperTabBarThemeData     — ThemeExtension (alias: BrowserStyleTabBarThemeData)
//
// ── Models ────────────────────────────────────────────────────────
// BrowserTab               — immutable tab data model
// SuperTabBehavior         — requiredPinned · normal · uniqueNormal
// GLTabKind                — ledger · doc · store · chart · user · globe
// TabPageBuilder           — Widget Function(BuildContext, BrowserTab)
// glTabIcon · glPreviewMeta · kNewTabCycle
//
// ── Localizations ────────────────────────────────────────────────
// SuperTabBarLocalizations — translatable strings (.en · .ar built-in)
//
// ── Preview options ───────────────────────────────────────────────
// SuperTabBarPreviewOptions — enabled · hoverDelay · snapshotPixelRatio · fallback
// PreviewFallback           — liveRender · blank
//
// ── Overlays ─────────────────────────────────────────────────────
// TabContextMenu · TabListDropdown · MiniPagePreview
// TabMenuItem
// showSuperTabDirtyCloseDialog (alias: showGLDirtyCloseDialog)
// ScopeWrapper
//
// ── Compact mode (mobile) ─────────────────────────────────────────
// SuperTabSwitcher        — thumbnail grid of open tabs (tap to switch,
//                           drag to reorder)
// showSuperTabSwitcher    — opens the switcher as a full-screen modal
//
// ── Pages ────────────────────────────────────────────────────────
// GLTabPage
//
//
// ── Removed in v2.1 ───────────────────────────────────────────────
// The tab-navigation keyboard shortcuts and the `horizontalStep` /
// `arrowGoesInto` helpers were removed. Compact mode replaces keyboard
// switching on mobile; see SuperTabSwitcher.

export 'src/models.dart';
export 'src/localizations.dart';
export 'src/preview_options.dart';
export 'src/theme.dart';
export 'src/controller.dart';
export 'src/tab_bar.dart';
export 'src/pages.dart';
export 'src/overlays.dart';
export 'src/compact.dart';
