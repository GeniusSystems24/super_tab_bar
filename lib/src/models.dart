// ============================================================
// super_tab_bar — models, enums & helpers.
//   File: lib/src/models.dart
// ============================================================

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Page builder type for [BrowserTab.pageBuilder].
///
/// Called at build time with the current [BuildContext] and the live
/// [BrowserTab] (as read from the controller, reflecting current
/// dirty / title state):
/// ```dart
/// BrowserTab(
///   id: 1, title: 'Home',
///   pageBuilder: (ctx, tab) => HomePage(title: tab.title),
/// )
/// ```
typedef TabPageBuilder = Widget Function(BuildContext context, BrowserTab tab);

// ── Tab-kind enum ──────────────────────────────────────────
/// The page-type of a workspace tab. Drives the leading icon, mini-page
/// preview layout and the full content surface.
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
  BrowserTab({
    required this.id,
    required this.title,
    this.dirty = false,
    this.pinned = false,
    this.behavior = SuperTabBehavior.normal,
    this.uniqueKey,
    this.leading,
    this.trailing,
    required this.pageBuilder,
  });

  /// Stable, unique identity. Never reuse an id after a tab is closed.
  final int id;

  /// Display text (truncated with a tooltip at 200 px).
  final String title;

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

  /// Optional widget shown before the tab title in the tab chip.
  ///
  /// When null the strip renders a default tab outline icon. Supply any
  /// widget — an [Icon], an [Image], a colored [Container] — to override it:
  ///
  /// ```dart
  /// BrowserTab(
  ///   id: 1, title: 'Accounts',
  ///   leading: const Icon(Icons.account_balance_outlined, size: 14),
  ///   pageBuilder: (ctx, tab) => const AccountsPage(),
  /// )
  /// ```
  ///
  /// In pinned (icon-only) mode [leading] fills the entire chip area.
  ///
  /// **Excluded from [operator ==] and [hashCode].**
  final Widget? leading;

  /// Optional widget shown after the tab title, before the close / dirty
  /// indicator.
  ///
  /// Use for badges, counters, or status chips:
  ///
  /// ```dart
  /// BrowserTab(
  ///   id: 2, title: 'Inbox',
  ///   trailing: _UnreadBadge(count: 3),
  ///   pageBuilder: (ctx, tab) => const InboxPage(),
  /// )
  /// ```
  ///
  /// **Excluded from [operator ==] and [hashCode].**
  final Widget? trailing;

  /// Builds the content page for this tab.
  ///
  /// Required. Receives the current [BuildContext] and the live [BrowserTab]
  /// (as read from the controller at build time, reflecting current dirty /
  /// title state):
  ///
  /// ```dart
  /// BrowserTab(
  ///   id: 1, title: 'Dashboard',
  ///   pageBuilder: (ctx, tab) => const DashboardPage(),
  /// )
  /// ```
  ///
  /// **Note:** excluded from [operator ==] and [hashCode] — two [BrowserTab]
  /// instances are considered equal when their data fields match, regardless
  /// of their [pageBuilder] function references.
  final TabPageBuilder pageBuilder;

  /// Returns a copy with the given fields replaced.
  ///
  /// Note: passing `null` for [pageBuilder] keeps the existing value.
  BrowserTab copyWith({
    int? id,
    String? title,
    bool? dirty,
    bool? pinned,
    SuperTabBehavior? behavior,
    String? uniqueKey,
    Widget? leading,
    Widget? trailing,
    TabPageBuilder? pageBuilder,
  }) {
    return BrowserTab(
      id: id ?? this.id,
      title: title ?? this.title,
      dirty: dirty ?? this.dirty,
      pinned: pinned ?? this.pinned,
      behavior: behavior ?? this.behavior,
      uniqueKey: uniqueKey ?? this.uniqueKey,
      leading: leading ?? this.leading,
      trailing: trailing ?? this.trailing,
      pageBuilder: pageBuilder ?? this.pageBuilder,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BrowserTab &&
          other.id == id &&
          other.title == title &&
          other.dirty == dirty &&
          other.pinned == pinned &&
          other.behavior == behavior &&
          other.uniqueKey == uniqueKey);

  @override
  int get hashCode =>
      Object.hash(id, title, dirty, pinned, behavior, uniqueKey);

  @override
  String toString() =>
      'BrowserTab(id: $id, title: "$title", '
      'dirty: $dirty, pinned: $pinned, behavior: $behavior)';
}

// ── Helpers ────────────────────────────────────────────────
/// Material icon for each [GLTabKind].
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

/// Type label shown in the hover-preview header.
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

/// Rotating [GLTabKind]s for the "New Tab" (+) button.
const List<GLTabKind> kNewTabCycle = [
  GLTabKind.globe,
  GLTabKind.user,
  GLTabKind.store,
  GLTabKind.chart,
  GLTabKind.doc,
];
