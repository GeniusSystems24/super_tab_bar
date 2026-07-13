// ============================================================
// super_tab_bar — models, enums & helpers.
//   File: lib/src/models.dart
// ============================================================

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Builds the content shown for a tab — both in the active content surface
/// and (scaled down) inside the hover preview.
///
/// Since v2.5 the builder lives on each [BrowserTab] via [BrowserTab.pageBuilder]
/// and is **required**. Use the built-in [GLTabPage] when you want the default
/// demo content:
///
/// ```dart
/// BrowserTab(
///   id: 1, title: 'Home', icon: Icons.public,
///   pageBuilder: (ctx, tab) => GLTabPage(tab: tab, kind: GLTabKind.globe),
/// )
/// ```
typedef TabPageBuilder = Widget Function(BuildContext context, BrowserTab tab);

// ── Tab-kind enum ──────────────────────────────────────────
/// The page-type of a workspace tab. Used by the built-in [GLTabPage] demo
/// content and by the [glTabIcon] / [glPreviewMeta] helpers.
///
/// Since v2.5 this enum is **no longer a field on [BrowserTab]** — a tab
/// carries its [BrowserTab.icon] and its [BrowserTab.pageBuilder] directly.
/// [GLTabKind] is kept for callers who want to use the built-in [GLTabPage]
/// or the icon/meta helpers inside their own [TabPageBuilder].
enum GLTabKind { ledger, doc, store, chart, user, globe }

// ── Tab-behavior enum ──────────────────────────────────────
/// Controls what operations the UI exposes for a given tab.
///
/// | Behavior | Close | Unpin | Duplicate |
/// |---|---|---|---|
/// | [requiredPinned] | UI hidden¹ | UI hidden | UI hidden |
/// | [normal] | ✓ | ✓ | ✓ |
/// | [uniqueNormal] | ✓ | ✓ | hidden |
///
/// ¹ [requiredPinned] tabs can still be removed **programmatically** via
///   `SuperTabBarController.close(id)` — the restriction is UI-level only.
enum SuperTabBehavior {
  /// Always pinned; the UI hides close, unpin and duplicate actions.
  /// Programmatic removal via the controller is still possible.
  requiredPinned,

  /// Standard tab — can be closed, duplicated, pinned and unpinned.
  normal,

  /// Like [normal] but cannot be duplicated from the UI.
  /// When [SuperTabBarController.add] is called with a matching
  /// [BrowserTab.uniqueKey], the existing tab is selected instead of
  /// creating a duplicate.
  uniqueNormal,
}

// ── BrowserTab model ───────────────────────────────────────
/// A single workspace tab. Immutable — all mutations go through
/// [SuperTabBarController] which produces new instances via [copyWith].
@immutable
class BrowserTab {
  const BrowserTab({
    required this.id,
    required this.title,
    required this.pageBuilder,
    this.icon,
    this.dirty = false,
    this.pinned = false,
    this.behavior = SuperTabBehavior.normal,
    this.uniqueKey,
  });

  /// Stable, unique identity. Never reuse an id after a tab is closed.
  final int id;

  /// Display text (truncated with a tooltip at 200 px).
  final String title;

  /// Leading icon shown in the tab chip. When `null` the chip renders
  /// without an icon. Use the [glTabIcon] helper to map a [GLTabKind] to
  /// an [IconData] when you want the legacy icon set.
  final IconData? icon;

  /// Unsaved-changes indicator. Shows an amber dot; closing triggers a
  /// confirmation dialog.
  final bool dirty;

  /// When true the tab is icon-only and anchored to the start edge.
  /// [SuperTabBehavior.requiredPinned] tabs are always pinned.
  final bool pinned;

  /// Controls which UI actions are available for this tab.
  final SuperTabBehavior behavior;

  /// Deduplication key for [SuperTabBehavior.uniqueNormal] tabs.
  /// When [SuperTabBarController.add] is called with the same non-null
  /// key and [SuperTabBehavior.uniqueNormal] behavior, the existing tab
  /// is activated rather than a new one created.
  final String? uniqueKey;

  /// Builds the page content for this tab — rendered both in the active
  /// content surface and (scaled down) inside the hover preview and the
  /// compact-mode tab switcher thumbnail.
  ///
  /// **Required since v2.5.** Every tab must carry its own page factory.
  /// Use the built-in [GLTabPage] when you want the default demo content:
  ///
  /// ```dart
  /// BrowserTab(
  ///   id: 1, title: 'Home', icon: Icons.public,
  ///   pageBuilder: (ctx, tab) => GLTabPage(tab: tab, kind: GLTabKind.globe),
  /// )
  /// ```
  final TabPageBuilder pageBuilder;

  /// Returns a copy with the given fields replaced.
  BrowserTab copyWith({
    int? id,
    String? title,
    IconData? icon,
    bool? dirty,
    bool? pinned,
    SuperTabBehavior? behavior,
    String? uniqueKey,
    TabPageBuilder? pageBuilder,
  }) {
    return BrowserTab(
      id: id ?? this.id,
      title: title ?? this.title,
      icon: icon ?? this.icon,
      dirty: dirty ?? this.dirty,
      pinned: pinned ?? this.pinned,
      behavior: behavior ?? this.behavior,
      uniqueKey: uniqueKey ?? this.uniqueKey,
      pageBuilder: pageBuilder ?? this.pageBuilder,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BrowserTab &&
          other.id == id &&
          other.title == title &&
          other.icon == icon &&
          other.dirty == dirty &&
          other.pinned == pinned &&
          other.behavior == behavior &&
          other.uniqueKey == uniqueKey);

  @override
  int get hashCode =>
      Object.hash(id, title, icon, dirty, pinned, behavior, uniqueKey);

  @override
  String toString() =>
      'BrowserTab(id: $id, title: "$title", '
      'dirty: $dirty, pinned: $pinned, behavior: $behavior)';
}

// ── Helpers ────────────────────────────────────────────────
/// Material icon for each [GLTabKind]. Use this inside your [TabPageBuilder]
/// or when constructing a [BrowserTab] to map a kind to its leading icon:
///
/// ```dart
/// BrowserTab(
///   id: 1, title: 'Ledger', icon: glTabIcon(GLTabKind.ledger),
///   pageBuilder: (ctx, tab) => GLTabPage(tab: tab, kind: GLTabKind.ledger),
/// )
/// ```
IconData glTabIcon(GLTabKind kind) {
  switch (kind) {
    case GLTabKind.ledger:
      return Icons.menu_book_outlined;
    case GLTabKind.doc:
      return Icons.description_outlined;
    case GLTabKind.store:
      return Icons.storefront_outlined;
    case GLTabKind.chart:
      return Icons.bar_chart_rounded;
    case GLTabKind.user:
      return Icons.people_alt_outlined;
    case GLTabKind.globe:
      return Icons.public;
  }
}

/// Type label shown in the hover-preview header. Use inside your
/// [TabPageBuilder] when you want the legacy per-kind meta caption.
String glPreviewMeta(GLTabKind kind) {
  switch (kind) {
    case GLTabKind.ledger:
      return 'Accounting · Ledger';
    case GLTabKind.doc:
      return 'Journal · Document';
    case GLTabKind.store:
      return 'Branch · Storefront';
    case GLTabKind.chart:
      return 'Analytics · Dashboard';
    case GLTabKind.user:
      return 'Directory · People';
    case GLTabKind.globe:
      return 'Workspace · Page';
  }
}

/// Rotating [GLTabKind]s for the "New Tab" (+) button. Use inside your
/// [SuperTabBar.onAddTab] handler when you want the legacy cycling behaviour.
const List<GLTabKind> kNewTabCycle = [
  GLTabKind.globe,
  GLTabKind.user,
  GLTabKind.store,
  GLTabKind.chart,
  GLTabKind.doc,
];
