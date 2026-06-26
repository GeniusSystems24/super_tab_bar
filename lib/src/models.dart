// ============================================================
// super_tab_bar — models, enums & helpers.
//   File: lib/src/models.dart
// ============================================================

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Builds the content shown for a tab — both in the active content surface
/// and (scaled down) inside the hover preview.
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
  const BrowserTab({
    required this.id,
    required this.title,
    required this.kind,
    this.dirty = false,
    this.pinned = false,
    this.behavior = SuperTabBehavior.normal,
    this.uniqueKey,
  });

  /// Stable, unique identity. Never reuse an id after a tab is closed.
  final int id;

  /// Display text (truncated with a tooltip at 200 px).
  final String title;

  /// Drives the leading icon and the built-in page content.
  final GLTabKind kind;

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

  /// Returns a copy with the given fields replaced.
  BrowserTab copyWith({
    int? id,
    String? title,
    GLTabKind? kind,
    bool? dirty,
    bool? pinned,
    SuperTabBehavior? behavior,
    String? uniqueKey,
  }) {
    return BrowserTab(
      id: id ?? this.id,
      title: title ?? this.title,
      kind: kind ?? this.kind,
      dirty: dirty ?? this.dirty,
      pinned: pinned ?? this.pinned,
      behavior: behavior ?? this.behavior,
      uniqueKey: uniqueKey ?? this.uniqueKey,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BrowserTab &&
          other.id == id &&
          other.title == title &&
          other.kind == kind &&
          other.dirty == dirty &&
          other.pinned == pinned &&
          other.behavior == behavior &&
          other.uniqueKey == uniqueKey);

  @override
  int get hashCode =>
      Object.hash(id, title, kind, dirty, pinned, behavior, uniqueKey);

  @override
  String toString() =>
      'BrowserTab(id: $id, title: "$title", kind: $kind, '
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
