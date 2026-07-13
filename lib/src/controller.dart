// ============================================================
// SuperTabBarController — the tab strip's state, as a ChangeNotifier.
// ------------------------------------------------------------
// Single source of truth for the open tabs, the active tab, and the live
// page thumbnails. The widget delegates every operation here, and the SAME
// controller is exposed to page content via an InheritedNotifier so any
// page can drive the strip:
//
//   final tabs = SuperTabBarController.of(context); // may be null
//   tabs?.add(title: 'New report', kind: GLTabKind.chart);
//   tabs?.setDirty(myId, true);
//
// `of` returns null when a widget is not hosted inside a SuperTabBar, so
// pages can be reused stand-alone.
//
// ── Tab behavior ────────────────────────────────────────────
// [SuperTabBehavior] controls which UI actions are exposed per tab:
//
//   requiredPinned — always pinned; UI hides close / unpin / duplicate.
//                    Programmatic close() still works.
//   normal         — standard: close, duplicate, pin, unpin all available.
//   uniqueNormal   — no duplicate from UI; add() with same uniqueKey
//                    selects the existing tab instead.
//
// ── Immutability ────────────────────────────────────────────
// [BrowserTab] is now @immutable. All mutations create new instances via
// copyWith() and replace the slot in the internal list. Never mutate a
// BrowserTab field directly — it won't notify listeners.
//
//   File: lib/src/controller.dart
// ============================================================

import 'dart:ui' as ui;
import 'package:flutter/widgets.dart';
import 'models.dart';
import 'pages.dart';

class SuperTabBarController extends ChangeNotifier {
  SuperTabBarController({List<BrowserTab>? tabs, int? activeId})
      : _tabs = _normalize(tabs ?? _defaults()) {
    _seed = _tabs.fold<int>(0, (m, t) => t.id > m ? t.id : m);
    _activeId = activeId ??
        (_tabs.length > 1 ? _tabs[1].id : (_tabs.isNotEmpty ? _tabs.first.id : null));
  }

  // ── Default seed tabs ──────────────────────────────────────
  // Since v2.5 a BrowserTab carries its own icon + pageBuilder (no `kind`
  // field). The defaults use GLTabPage with the legacy GLTabKind set so the
  // zero-config demo still renders the rich built-in pages.
  static List<BrowserTab> _defaults() => [
        BrowserTab(
            id: 1,
            title: 'Chart of Accounts',
            icon: glTabIcon(GLTabKind.ledger),
            pinned: true,
            behavior: SuperTabBehavior.requiredPinned,
            pageBuilder: (ctx, t) =>
                GLTabPage(tab: t, kind: GLTabKind.ledger)),
        BrowserTab(
            id: 2,
            title: 'Opening Journal Entry — JV-2024-0042',
            icon: glTabIcon(GLTabKind.doc),
            dirty: true,
            pageBuilder: (ctx, t) =>
                GLTabPage(tab: t, kind: GLTabKind.doc)),
        BrowserTab(
            id: 3,
            title: 'Downtown Central Store',
            icon: glTabIcon(GLTabKind.store),
            pageBuilder: (ctx, t) =>
                GLTabPage(tab: t, kind: GLTabKind.store)),
        BrowserTab(
            id: 4,
            title: 'Dashboard',
            icon: glTabIcon(GLTabKind.chart),
            pageBuilder: (ctx, t) =>
                GLTabPage(tab: t, kind: GLTabKind.chart)),
        BrowserTab(
            id: 5,
            title: 'Trial Balance — FY2024 Q3',
            icon: glTabIcon(GLTabKind.ledger),
            pageBuilder: (ctx, t) =>
                GLTabPage(tab: t, kind: GLTabKind.ledger)),
      ];

  /// Ensures requiredPinned tabs always have pinned: true.
  static List<BrowserTab> _normalize(List<BrowserTab> tabs) => [
        for (final t in tabs)
          t.behavior == SuperTabBehavior.requiredPinned && !t.pinned
              ? t.copyWith(pinned: true)
              : t,
      ];

  final List<BrowserTab> _tabs;
  int? _activeId;
  late int _seed;
  final Map<int, ui.Image> _snaps = {};

  // ── Optional event callbacks ───────────────────────────────
  /// Called whenever [setDirty] changes a tab's dirty flag.
  /// Useful for pages that drive dirty-state through the controller and
  /// want to react without listening to the whole ChangeNotifier.
  void Function(int id, bool isDirty)? onDirtyChanged;

  /// Called whenever [rename] changes a tab's title.
  void Function(int id, String newTitle)? onRenamed;

  // ── Reads ──────────────────────────────────────────────────
  List<BrowserTab> get tabs => List.unmodifiable(_tabs);
  int? get activeId => _activeId;
  int get length => _tabs.length;
  bool isActive(int id) => id == _activeId;

  BrowserTab? get activeTab => tabById(_activeId);
  BrowserTab? tabById(int? id) {
    if (id == null) return null;
    for (final t in _tabs) {
      if (t.id == id) return t;
    }
    return null;
  }

  List<BrowserTab> get pinned => _tabs.where((t) => t.pinned).toList();
  List<BrowserTab> get unpinned => _tabs.where((t) => !t.pinned).toList();

  /// Visual order: pinned first (preserving relative order), then unpinned.
  List<BrowserTab> get ordered => [...pinned, ...unpinned];

  bool canCloseOthers(int id) => _tabs.any((t) => t.id != id && !t.pinned);
  bool canCloseRight(int id) {
    final oi = ordered.indexWhere((t) => t.id == id);
    if (oi < 0) return false;
    return ordered.skip(oi + 1).any((t) => !t.pinned);
  }

  // ── UI-behavior guards ─────────────────────────────────────
  // These are used by the widget to decide which UI actions to surface
  // (close button, context-menu items). They do NOT restrict programmatic ops.

  /// Whether the UI should offer a close action for [id].
  bool canCloseFromUi(int id) {
    final t = tabById(id);
    return t != null && t.behavior != SuperTabBehavior.requiredPinned;
  }

  /// Whether the UI should offer a duplicate action for [id].
  bool canDuplicateFromUi(int id) {
    final t = tabById(id);
    return t != null &&
        t.behavior != SuperTabBehavior.requiredPinned &&
        t.behavior != SuperTabBehavior.uniqueNormal;
  }

  /// Whether the UI should offer a pin/unpin toggle for [id].
  bool canTogglePinFromUi(int id) {
    final t = tabById(id);
    return t != null && t.behavior != SuperTabBehavior.requiredPinned;
  }

  // ── Live page thumbnails ───────────────────────────────────
  ui.Image? snapshot(int id) => _snaps[id];

  void setSnapshot(int id, ui.Image img) {
    final old = _snaps[id];
    if (identical(old, img)) return;
    _snaps[id] = img;
    old?.dispose();
    // No notifyListeners(): snapshots don't affect strip layout.
  }

  void _dropSnapshot(int id) {
    _snaps.remove(id)?.dispose();
  }

  // ── Mutations ──────────────────────────────────────────────

  void select(int id) {
    if (_activeId == id || !_tabs.any((t) => t.id == id)) return;
    _activeId = id;
    notifyListeners();
  }

  /// Adds a tab and (by default) activates it. Returns the id of the
  /// affected tab.
  ///
  /// [pageBuilder] is **required** since v2.5 — every tab carries its own
  /// page factory. Pass [icon] to set the leading tab-chip icon (or `null`
  /// for an iconless chip). The legacy [GLTabKind] cycling fallback for the
  /// title/icon was removed; use [kNewTabCycle] / [glTabIcon] inside your
  /// [SuperTabBar.onAddTab] handler if you want that behaviour.
  ///
  /// For [SuperTabBehavior.uniqueNormal] tabs with a non-null [uniqueKey]:
  /// if a tab with the same key already exists it is activated and its id
  /// returned — no new tab is created.
  ///
  /// [SuperTabBehavior.requiredPinned] tabs are always created with
  /// `pinned: true` regardless of the [pinned] argument.
  int add({
    required TabPageBuilder pageBuilder,
    String? title,
    IconData? icon,
    bool activate = true,
    bool pinned = false,
    int? at,
    SuperTabBehavior behavior = SuperTabBehavior.normal,
    String? uniqueKey,
  }) {
    // Deduplication for uniqueNormal tabs.
    if (behavior == SuperTabBehavior.uniqueNormal && uniqueKey != null) {
      final existing = _findByUniqueKey(uniqueKey);
      if (existing != null) {
        if (activate) select(existing.id);
        return existing.id;
      }
    }

    final id = ++_seed;
    final tab = BrowserTab(
      id: id,
      title: title ?? 'New Tab',
      icon: icon,
      pinned: behavior == SuperTabBehavior.requiredPinned ? true : pinned,
      behavior: behavior,
      uniqueKey: uniqueKey,
      pageBuilder: pageBuilder,
    );

    if (at != null && at >= 0 && at <= _tabs.length) {
      _tabs.insert(at, tab);
    } else {
      _tabs.add(tab);
    }
    if (activate) _activeId = id;
    notifyListeners();
    return id;
  }

  /// Removes [id]. For [SuperTabBehavior.requiredPinned] tabs, the UI hides
  /// the close button — but programmatic removal is always allowed.
  ///
  /// To make the intent explicit you can also call [forceClose], which is
  /// semantically identical.
  void close(int id) {
    final i = _tabs.indexWhere((t) => t.id == id);
    if (i < 0) return;
    final wasActive = _activeId == id;
    final ord = ordered;
    final oi = ord.indexWhere((t) => t.id == id);
    _tabs.removeAt(i);
    _dropSnapshot(id);
    if (wasActive) {
      if (_tabs.isEmpty) {
        _activeId = null;
      } else {
        final candidates =
            ord.where((t) => t.id != id && _tabs.any((n) => n.id == t.id)).toList();
        final idx = oi.clamp(0, candidates.length - 1);
        _activeId = candidates.isEmpty ? _tabs.first.id : candidates[idx].id;
      }
    }
    notifyListeners();
  }

  /// Explicitly removes a [SuperTabBehavior.requiredPinned] tab (or any tab).
  /// Semantically identical to [close] — use this to make programmatic
  /// removal of a "required" tab clear at the call site.
  void forceClose(int id) => close(id);

  void closeOthers(int id) {
    _tabs.removeWhere((t) => t.id != id && !t.pinned);
    for (final key in _snaps.keys.toList()) {
      if (!_tabs.any((t) => t.id == key)) _dropSnapshot(key);
    }
    _activeId = id;
    notifyListeners();
  }

  void closeToRight(int id) {
    final oi = ordered.indexWhere((t) => t.id == id);
    if (oi < 0) return;
    final kill = ordered.skip(oi + 1).where((t) => !t.pinned).map((t) => t.id).toSet();
    if (kill.isEmpty) return;
    _tabs.removeWhere((t) => kill.contains(t.id));
    for (final k in kill) {
      _dropSnapshot(k);
    }
    if (kill.contains(_activeId)) _activeId = id;
    notifyListeners();
  }

  /// Duplicates [id] as the next sibling and activates the copy.
  /// Returns the new tab's id, or `-1` if the tab doesn't exist or its
  /// [SuperTabBehavior] doesn't permit duplication.
  int duplicate(int id) {
    final i = _tabs.indexWhere((t) => t.id == id);
    if (i < 0) return -1;
    final src = _tabs[i];
    if (src.behavior == SuperTabBehavior.uniqueNormal ||
        src.behavior == SuperTabBehavior.requiredPinned) {
      return -1;
    }
    final nid = ++_seed;
    _tabs.insert(i + 1, src.copyWith(id: nid, dirty: false, pinned: false));
    _activeId = nid;
    notifyListeners();
    return nid;
  }

  void togglePin(int id) => setPinned(id, !(tabById(id)?.pinned ?? false));

  /// Sets the pinned flag for [id].
  /// No-op for [SuperTabBehavior.requiredPinned] tabs (they cannot be unpinned).
  void setPinned(int id, bool pinned) {
    final i = _tabs.indexWhere((t) => t.id == id);
    if (i < 0 || _tabs[i].pinned == pinned) return;
    if (_tabs[i].behavior == SuperTabBehavior.requiredPinned && !pinned) return;
    _tabs[i] = _tabs[i].copyWith(pinned: pinned);
    notifyListeners();
  }

  void reorder(int fromId, int toId) {
    if (fromId == toId) return;
    final from = _tabs.indexWhere((t) => t.id == fromId);
    final to = _tabs.indexWhere((t) => t.id == toId);
    if (from < 0 || to < 0) return;
    _tabs.insert(to, _tabs.removeAt(from));
    notifyListeners();
  }

  /// Sets the dirty flag for [id] and fires [onDirtyChanged] if the value
  /// actually changed.
  void setDirty(int id, bool dirty) {
    final i = _tabs.indexWhere((t) => t.id == id);
    if (i < 0 || _tabs[i].dirty == dirty) return;
    _tabs[i] = _tabs[i].copyWith(dirty: dirty);
    onDirtyChanged?.call(id, dirty);
    notifyListeners();
  }

  /// Renames [id] and fires [onRenamed] if the title actually changed.
  void rename(int id, String title) {
    final i = _tabs.indexWhere((t) => t.id == id);
    if (i < 0 || _tabs[i].title == title) return;
    _tabs[i] = _tabs[i].copyWith(title: title);
    onRenamed?.call(id, title);
    notifyListeners();
  }

  /// Escape hatch for arbitrary batch edits. Call inside [fn] and
  /// [notifyListeners] will fire once when it returns.
  ///
  /// Note: [BrowserTab] is immutable — you cannot mutate tab fields
  /// directly. Use [tabById] to read, then [mutate] with list-index
  /// replacement via [copyWith], e.g.:
  ///
  /// ```dart
  /// controller.mutate(() {
  ///   final i = controller.tabs.indexWhere((t) => t.id == myId);
  ///   // tabs is unmodifiable — use the internal list via the controller API
  ///   controller.rename(myId, 'New title');
  ///   controller.setDirty(myId, false);
  /// });
  /// ```
  void mutate(VoidCallback fn) {
    fn();
    notifyListeners();
  }

  @override
  void dispose() {
    for (final img in _snaps.values) {
      img.dispose();
    }
    _snaps.clear();
    super.dispose();
  }

  // ── Inherited lookup ───────────────────────────────────────
  /// The controller hosting [context], or null if not inside a [SuperTabBar].
  static SuperTabBarController? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SuperTabBarScope>()?.controller;

  /// Non-listening variant — use in callbacks / initState.
  static SuperTabBarController? read(BuildContext context) =>
      (context.getElementForInheritedWidgetOfExactType<SuperTabBarScope>()?.widget
              as SuperTabBarScope?)
          ?.controller;

  // ── Private helpers ────────────────────────────────────────
  BrowserTab? _findByUniqueKey(String key) {
    for (final t in _tabs) {
      if (t.behavior == SuperTabBehavior.uniqueNormal && t.uniqueKey == key) {
        return t;
      }
    }
    return null;
  }
}

// ── InheritedNotifier scope ───────────────────────────────────
/// Exposes [controller] to descendants; rebuilds dependents on notify.
class SuperTabBarScope extends InheritedNotifier<SuperTabBarController> {
  const SuperTabBarScope({
    super.key,
    required SuperTabBarController controller,
    required super.child,
  }) : super(notifier: controller);

  SuperTabBarController get controller => notifier!;
}

// ── Backward-compatible aliases ────────────────────────────────
/// Alias for [SuperTabBarController]. Maintained for backward compatibility.
typedef BrowserStyleTabBarController = SuperTabBarController;

/// Alias for [SuperTabBarScope]. Maintained for backward compatibility.
typedef BrowserStyleTabBarScope = SuperTabBarScope;
