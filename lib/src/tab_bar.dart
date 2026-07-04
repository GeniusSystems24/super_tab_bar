// ============================================================
// SuperTabBar — browser-style workspace tab strip.
// ------------------------------------------------------------
// Drop-in rename of BrowserStyleTabBar (available as a typedef below).
//
// New in v2:
//   • Direct event callbacks (onTabSelected, onTabAdded, onTabClosed, …)
//   • [SuperTabBarLocalizations] for translatable strings
//   • [SuperTabBarPreviewOptions] for configurable hover previews
//   • [SuperTabBehavior] per-tab UI guards (requiredPinned / uniqueNormal)
//   • Accessibility Semantics on every interactive element
//   • [BrowserStyleTabBar] typedef for backward compatibility
//
// New in v2.1:
//   • Compact mode ([SuperTabBar.compact]) hides the strip for small screens;
//     pair it with the [SuperTabSwitcher] thumbnail grid.
//   • Dirty-aware back navigation ([SuperTabBar.closeTabOnBack]).
//   • Removed the tab-navigation keyboard shortcuts (Ctrl/Cmd+T, Ctrl/Cmd+W,
//     ← → Home End). Escape still dismisses open overlays.
//
// New in v2.2:
//   • [SuperTabBar.allowAutoCompact] + [SuperTabBar.compactWidth] — the strip
//     switches to compact mode automatically whenever the widget's available
//     width drops at or below [compactWidth] (default 600 px, covering all
//     phone form-factors). No manual MediaQuery boilerplate required.
//
//   File: lib/src/tab_bar.dart
// ============================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'theme.dart';
import 'controller.dart';
import 'models.dart';
import 'pages.dart';
import 'overlays.dart';
import 'localizations.dart';
import 'preview_options.dart';
import 'compact.dart';

// ════════════════════════════════════════════════════════════
// PUBLIC WIDGET
// ════════════════════════════════════════════════════════════

class SuperTabBar extends StatefulWidget {
  // ── Seed / state ─────────────────────────────────────────
  /// Seed tabs used only when [controller] is null. Defaults to the demo set.
  final List<BrowserTab>? tabsState;

  /// External controller. When provided the widget does NOT own/dispose it,
  /// and the same instance is accessible via `SuperTabBarController.of`.
  final SuperTabBarController? controller;

  /// Optional content for each tab (active surface + hover preview).
  /// Falls back to the built-in [GLTabPage] when null.
  final TabPageBuilder? pageBuilder;

  // ── Shell / embedding ────────────────────────────────────
  /// Draw the outer bordered card. Set false for edge-to-edge embedding.
  final bool showChrome;

  /// Compact mode — hides the tab strip entirely and shows only the active
  /// page. Intended for small screens (phones) where the full strip is too
  /// wide. Pair it with [SuperTabSwitcher] (see `showSuperTabSwitcher`) to give
  /// users a thumbnail grid for switching and reordering tabs. Defaults to
  /// `false`.
  ///
  /// See also [allowAutoCompact] for automatic breakpoint-driven switching.
  final bool compact;

  /// Automatically enter compact mode when the widget's available width is at
  /// or below [compactWidth]. When `true`, no manual [MediaQuery] boilerplate
  /// is needed — the widget reacts to its own layout constraints.
  ///
  /// Has no effect when [compact] is already `true`. Defaults to `false`.
  final bool allowAutoCompact;

  /// The width threshold (in logical pixels) used by [allowAutoCompact].
  /// The strip is hidden whenever `constraints.maxWidth <= compactWidth`.
  ///
  /// Defaults to **600.0**, which covers all common phone form-factors
  /// (up to large-phone landscape). Typical values:
  ///
  /// | Form-factor         | Suggested value |
  /// |---------------------|-----------------|
  /// | Phone only          | 600 (default)   |
  /// | Phone + small tablet| 768             |
  /// | Any mobile device   | 900             |
  final double compactWidth;

  /// When `true` **and** the widget is in compact mode (either via [compact]
  /// or [allowAutoCompact]), a built-in [FloatingActionButton] is rendered
  /// over the active page. Tapping it opens [showSuperTabSwitcher], giving
  /// users a one-tap path to the thumbnail switcher without any extra
  /// scaffolding in the calling widget.
  ///
  /// The FAB is positioned at the bottom-end corner of the content area
  /// (bottom-right in LTR, bottom-left in RTL).
  ///
  /// Pass [onTabClosed] and [pageBuilder] as usual — they are forwarded
  /// automatically to the switcher that the FAB opens.
  ///
  /// Defaults to `false`.
  final bool useCompactFloatingActionButton;

  /// When `true`, a system back gesture / button closes the active tab instead
  /// of popping the route — but only when that tab is **not** dirty. A dirty
  /// tab is never auto-closed on back; the pop proceeds normally so unsaved
  /// work is never discarded silently. Especially useful together with
  /// [compact] on mobile. Defaults to `false`.
  final bool closeTabOnBack;

  /// Let the content surface fill all available height via [Expanded].
  /// Default caps at 440 px.
  final bool fillContent;

  /// Padding around the active page inside the content surface.
  final EdgeInsets contentPadding;

  /// Wrap the active page in a [SingleChildScrollView].
  final bool scrollContent;

  /// Build only the active page (cheaper, but resets state on revisit).
  /// Default [false] mounts all pages in an [IndexedStack].
  final bool lazyPages;

  /// Content surface background. Defaults to the theme `surface`.
  final Color? contentBackground;

  /// Intercepts the + button. Called instead of the controller's `add()`.
  /// When set, [onTabAdded] will NOT fire (the id is unknown to the widget).
  final VoidCallback? onAddTab;

  // ── Localizations ────────────────────────────────────────
  /// All user-facing strings. Defaults to [SuperTabBarLocalizations.en].
  final SuperTabBarLocalizations? localizations;

  // ── Preview options ──────────────────────────────────────
  /// Controls hover-preview behaviour. Defaults to
  /// [SuperTabBarPreviewOptions.defaults].
  final SuperTabBarPreviewOptions? previewOptions;

  // ── Direct event callbacks ───────────────────────────────
  // These fire for actions initiated by the widget's own UI. For
  // dirty/rename changes that originate in page content, set
  // `controller.onDirtyChanged` / `controller.onRenamed` instead.

  /// A tab was activated (strip tap, keyboard nav, or tab-list pick).
  final void Function(int id)? onTabSelected;

  /// A new tab was created via the + button (not fired when [onAddTab] is set,
  /// since the widget does not control the id in that case).
  final void Function(int id)? onTabAdded;

  /// A tab was closed (after any dirty-confirmation dialog).
  final void Function(int id)? onTabClosed;

  /// A tab was duplicated via the context menu.
  final void Function(int newId)? onTabDuplicated;

  /// A tab's pinned state changed via the context menu.
  final void Function(int id, bool isPinned)? onTabPinChanged;

  /// A tab's dirty flag was cleared by the "Save & close" dialog.
  /// For all dirty changes (including from page content), use
  /// `controller.onDirtyChanged`.
  final void Function(int id, bool isDirty)? onTabDirtyChanged;

  /// A tab was drag-reordered. [fromId] moved to the position of [toId].
  final void Function(int fromId, int toId)? onTabReordered;

  const SuperTabBar({
    super.key,
    this.tabsState,
    this.controller,
    this.pageBuilder,
    this.showChrome = true,
    this.compact = false,
    this.allowAutoCompact = false,
    this.compactWidth = 600.0,
    this.closeTabOnBack = false,
    this.useCompactFloatingActionButton = true,
    this.fillContent = false,
    this.lazyPages = false,
    this.contentPadding = const EdgeInsets.all(24),
    this.scrollContent = true,
    this.contentBackground,
    this.onAddTab,
    this.localizations,
    this.previewOptions,
    this.onTabSelected,
    this.onTabAdded,
    this.onTabClosed,
    this.onTabDuplicated,
    this.onTabPinChanged,
    this.onTabDirtyChanged,
    this.onTabReordered,
  });

  @override
  State<SuperTabBar> createState() => _SuperTabBarState();
}

// ════════════════════════════════════════════════════════════
// STATE
// ════════════════════════════════════════════════════════════

class _SuperTabBarState extends State<SuperTabBar> {
  late SuperTabBarController _ctrl;
  bool _ownsCtrl = false;

  int? _dragId;
  int? _overId;
  bool _chevStart = false;
  bool _chevEnd = false;

  final _scroll = ScrollController();
  final _caretKey = GlobalKey();
  final _focusNode = FocusNode();
  final _boundaryKey = GlobalKey();
  Timer? _captureTimer;

  OverlayEntry? _menuEntry;
  OverlayEntry? _listEntry;
  OverlayEntry? _previewEntry;
  int? _previewId;
  bool get _listOpen => _listEntry != null;

  // ── Convenience accessors ─────────────────────────────────
  SuperTabBarLocalizations get _loc =>
      widget.localizations ?? SuperTabBarLocalizations.en;

  SuperTabBarPreviewOptions get _prev =>
      widget.previewOptions ?? SuperTabBarPreviewOptions.defaults;

  // ── Lifecycle ─────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _ctrl = widget.controller ??
        SuperTabBarController(tabs: widget.tabsState);
    _ownsCtrl = widget.controller == null;
    _ctrl.addListener(_onCtrl);
    _scroll.addListener(_measure);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _measure();
      _scheduleCapture();
    });
  }

  @override
  void didUpdateWidget(covariant SuperTabBar old) {
    super.didUpdateWidget(old);
    if (widget.controller != old.controller) {
      _ctrl.removeListener(_onCtrl);
      if (_ownsCtrl) _ctrl.dispose();
      _ctrl = widget.controller ??
          SuperTabBarController(tabs: widget.tabsState);
      _ownsCtrl = widget.controller == null;
      _ctrl.addListener(_onCtrl);
    }
  }

  void _onCtrl() {
    if (mounted) setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
    _scheduleCapture();
  }

  @override
  void dispose() {
    _captureTimer?.cancel();
    _hideAllOverlays();
    _ctrl.removeListener(_onCtrl);
    if (_ownsCtrl) _ctrl.dispose();
    _scroll.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // ── Callback helpers ──────────────────────────────────────
  /// Select a tab and fire [SuperTabBar.onTabSelected].
  void _select(int id) {
    _ctrl.select(id);
    widget.onTabSelected?.call(id);
  }

  /// Duplicate a tab and fire [SuperTabBar.onTabDuplicated].
  void _duplicateTab(int id) {
    final nid = _ctrl.duplicate(id);
    if (nid > 0) widget.onTabDuplicated?.call(nid);
  }

  /// Toggle pin and fire [SuperTabBar.onTabPinChanged].
  void _togglePinTab(int id) {
    final before = _ctrl.tabById(id)?.pinned ?? false;
    _ctrl.togglePin(id);
    final after = _ctrl.tabById(id)?.pinned ?? false;
    if (before != after) widget.onTabPinChanged?.call(id, after);
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  // ── Thumbnail capture ─────────────────────────────────────
  void _scheduleCapture() {
    _captureTimer?.cancel();
    _captureTimer = Timer(const Duration(milliseconds: 260), _captureActive);
  }

  Future<void> _captureActive() async {
    if (!_prev.enabled) return;
    final id = _ctrl.activeId;
    if (id == null || !mounted) return;
    final ro = _boundaryKey.currentContext?.findRenderObject();
    if (ro is! RenderRepaintBoundary) return;
    if (ro.debugNeedsPaint) {
      _scheduleCapture();
      return;
    }
    try {
      final img = await ro.toImage(pixelRatio: _prev.snapshotPixelRatio);
      if (!mounted) {
        img.dispose();
        return;
      }
      _ctrl.setSnapshot(id, img);
      if (_previewId == id) _previewEntry?.markNeedsBuild();
    } catch (_) {}
  }

  // ── Overflow chevrons ─────────────────────────────────────
  void _measure() {
    if (!_scroll.hasClients) return;
    final pos = _scroll.position;
    final max = pos.maxScrollExtent;
    final off = pos.pixels;
    final start = max > 2 && off > 2;
    final end = max > 2 && off < max - 2;
    if (start != _chevStart || end != _chevEnd) {
      setState(() {
        _chevStart = start;
        _chevEnd = end;
      });
    }
  }

  void _scrollByDir(bool towardEnd) {
    if (!_scroll.hasClients) return;
    final target =
        (_scroll.offset + 220 * (towardEnd ? 1 : -1)).clamp(
            0.0, _scroll.position.maxScrollExtent);
    _scroll.animateTo(target,
        duration: SuperTabBarThemeData.durSlow,
        curve: SuperTabBarThemeData.curveStandard);
  }

  // ── Close (with dirty guard) ──────────────────────────────
  Future<void> _requestClose(int id) async {
    final t = _ctrl.tabById(id);
    if (t == null) return;
    if (t.dirty) {
      final r = await showSuperTabDirtyCloseDialog(
        context,
        t,
        localizations: _loc,
      );
      if (r == 'discard') {
        _ctrl.close(id);
        widget.onTabClosed?.call(id);
      } else if (r == 'save') {
        _ctrl.setDirty(id, false);
        widget.onTabDirtyChanged?.call(id, false);
        _ctrl.close(id);
        widget.onTabClosed?.call(id);
      }
    } else {
      _ctrl.close(id);
      widget.onTabClosed?.call(id);
    }
  }

  // ── New tab ───────────────────────────────────────────────
  void _add() {
    if (widget.onAddTab != null) {
      widget.onAddTab!();
      _scrollToEnd();
      return;
    }
    final id = _ctrl.add();
    widget.onTabAdded?.call(id);
    _scrollToEnd();
  }

  // ── Keyboard ──────────────────────────────────────────────
  // The tab-navigation shortcuts (Ctrl/Cmd+T, Ctrl/Cmd+W, ← → Home End) were
  // removed in v2.1. Only Escape is handled, purely to dismiss open overlays.
  KeyEventResult _onKey(FocusNode node, KeyEvent e) {
    if (e is! KeyDownEvent) return KeyEventResult.ignored;

    // Escape → close open overlays (not tab navigation).
    if (e.logicalKey == LogicalKeyboardKey.escape) {
      if (_menuEntry != null || _listEntry != null) {
        _hideMenu();
        _hideList();
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  // ════════ OVERLAYS ════════════════════════════════════════
  void _hideAllOverlays() {
    _hideMenu();
    _hideList();
    _hidePreview();
  }

  void _hideMenu() {
    _menuEntry?.remove();
    _menuEntry = null;
  }

  void _hideList() {
    _listEntry?.remove();
    _listEntry = null;
    if (mounted) setState(() {});
  }

  void _hidePreview() {
    _previewEntry?.remove();
    _previewEntry = null;
    _previewId = null;
  }

  // Context menu (right-click / long-press)
  void _openMenu(Offset at, int id) {
    _hidePreview();
    _hideMenu();
    final t = _ctrl.tabById(id);
    if (t == null) return;

    final canClose = _ctrl.canCloseFromUi(id);
    final canDuplicate = _ctrl.canDuplicateFromUi(id);
    final canTogglePin = _ctrl.canTogglePinFromUi(id);
    final showDivider = canDuplicate || canTogglePin;

    final items = <TabMenuItem>[
      if (canClose)
        TabMenuItem(
          icon: Icons.close,
          label: _loc.closeTab,
          hint: 'Del',
          danger: true,
          run: () => _requestClose(id),
        ),
      TabMenuItem(
        icon: Icons.clear_all,
        label: _loc.closeOtherTabs,
        disabled: !_ctrl.canCloseOthers(id),
        run: () => _ctrl.closeOthers(id),
      ),
      TabMenuItem(
        icon: Icons.east,
        label: _loc.closeTabsToRight,
        disabled: !_ctrl.canCloseRight(id),
        run: () => _ctrl.closeToRight(id),
      ),
      if (showDivider) const TabMenuItem.divider(),
      if (canDuplicate)
        TabMenuItem(
          icon: Icons.content_copy_outlined,
          label: _loc.duplicateTab,
          run: () => _duplicateTab(id),
        ),
      if (canTogglePin)
        TabMenuItem(
          icon: Icons.push_pin_outlined,
          label: t.pinned ? _loc.unpinTab : _loc.pinTab,
          run: () => _togglePinTab(id),
        ),
    ];

    _menuEntry = OverlayEntry(
      builder: (ctx) => _DismissLayer(
        onDismiss: _hideMenu,
        child: TabContextMenu(at: at, items: items, onClose: _hideMenu),
      ),
    );
    Overlay.of(context).insert(_menuEntry!);
  }

  // Tab-list dropdown (▾)
  void _toggleList() {
    _hidePreview();
    if (_listEntry != null) {
      _hideList();
      return;
    }
    final box = _caretKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final anchor = box.localToGlobal(Offset.zero) & box.size;
    _listEntry = OverlayEntry(
      builder: (ctx) => _DismissLayer(
        onDismiss: _hideList,
        child: TabListDropdown(
          anchor: anchor,
          tabs: _ctrl.ordered,
          activeId: _ctrl.activeId ?? -1,
          onPick: (id) {
            _select(id);
          },
          onClose: _hideList,
          localizations: _loc,
        ),
      ),
    );
    Overlay.of(context).insert(_listEntry!);
    setState(() {});
  }

  // Hover mini-page preview
  void _requestPreview(int id, Rect anchor) {
    if (!_prev.enabled) return;
    if (_dragId != null || _menuEntry != null || _listEntry != null) return;
    if (_previewId == id) return;
    _hidePreview();
    final tab = _ctrl.tabById(id);
    if (tab == null) return;
    _previewId = id;
    if (id == _ctrl.activeId) _captureActive();
    _previewEntry = OverlayEntry(
      builder: (ctx) => MiniPagePreview(
        tab: _ctrl.tabById(id) ?? tab,
        anchor: anchor,
        snapshot: _ctrl.snapshot(id),
        pageBuilder: widget.pageBuilder,
        scope: _scopeFor,
        fallback: _prev.fallback,
      ),
    );
    Overlay.of(context).insert(_previewEntry!);
  }

  void _cancelPreview(int id) {
    if (_previewId == id) _hidePreview();
  }

  Widget _scopeFor(Widget child) =>
      SuperTabBarScope(controller: _ctrl, child: child);

  // ── Back navigation ───────────────────────────────────────
  /// Whether a system back gesture is allowed to pop the route. Returns false
  /// (i.e. we intercept the back to close the active tab) only when
  /// [SuperTabBar.closeTabOnBack] is on AND there is a non-dirty active tab.
  bool _canPopOnBack() {
    if (!widget.closeTabOnBack) return true;
    final t = _ctrl.activeTab;
    if (t == null) return true; // nothing to close → allow normal pop
    if (t.dirty) return true; // dirty → never auto-close → allow normal pop
    return false; // non-dirty tab present → intercept and close it
  }

  void _handleBack(bool didPop) {
    if (didPop) return; // route already popped; nothing to do
    final id = _ctrl.activeId;
    if (id == null) return;
    final t = _ctrl.tabById(id);
    if (t == null || t.dirty) return; // guard: never close a dirty tab here
    _ctrl.close(id);
    widget.onTabClosed?.call(id);
  }

  // ════════ BUILD ═══════════════════════════════════════════

  /// Returns `true` when compact layout should be active, considering both the
  /// manual [SuperTabBar.compact] flag and the [SuperTabBar.allowAutoCompact]
  /// breakpoint evaluated against the widget's current layout width.
  bool _isCompact(double availableWidth) =>
      widget.compact ||
      (widget.allowAutoCompact && availableWidth <= widget.compactWidth);

  @override
  Widget build(BuildContext context) {
    final s = SuperTabBarThemeData.of(context);
    final activeTab = _ctrl.activeTab;
    final content = _buildContent(s, activeTab);

    // LayoutBuilder lets us react to the widget's own available width so that
    // allowAutoCompact works correctly whether the widget is full-screen or
    // embedded inside a smaller parent.
    Widget shell = LayoutBuilder(
      builder: (ctx, constraints) {
        final compact = _isCompact(constraints.maxWidth);
        Widget inner = SuperTabBarScope(
          controller: _ctrl,
          child: Focus(
            focusNode: _focusNode,
            onKeyEvent: _onKey,
            child: GestureDetector(
              onTap: () => _focusNode.requestFocus(),
              child: Container(
                decoration: widget.showChrome
                    ? BoxDecoration(
                        color: s.bg,
                        border: Border.all(color: s.border),
                        borderRadius: BorderRadius.circular(
                            SuperTabBarThemeData.radiusLg),
                      )
                    : BoxDecoration(color: s.bg),
                clipBehavior:
                    widget.showChrome ? Clip.antiAlias : Clip.none,
                child: Column(
                  mainAxisSize:
                      widget.fillContent ? MainAxisSize.max : MainAxisSize.min,
                  children: [
                    // Compact mode hides the strip; pair with SuperTabSwitcher.
                    if (!compact) _buildStrip(s),
                    if (widget.fillContent)
                      Expanded(child: content)
                    else
                      content,
                  ],
                ),
              ),
            ),
          ),
        );

        // Built-in compact FAB — overlays the content and opens the switcher.
        if (compact && widget.useCompactFloatingActionButton) {
          inner = Stack(
            children: [
              Positioned.fill(child: inner),
              Positioned(
                bottom: 16,
                right: Directionality.of(ctx) == TextDirection.rtl ? null : 16,
                left: Directionality.of(ctx) == TextDirection.rtl ? 16 : null,
                child: FloatingActionButton(
                  heroTag: 'super_tab_bar_compact_fab_${hashCode}',
                  backgroundColor: SuperTabBarThemeData.accent,
                  foregroundColor: Colors.white,
                  tooltip: 'Open tab switcher',
                  onPressed: () => showSuperTabSwitcher(
                    ctx,
                    controller: _ctrl,
                    pageBuilder: widget.pageBuilder,
                    onCloseTab: widget.onTabClosed != null
                        ? (id) => widget.onTabClosed!(id)
                        : null,
                  ),
                  child: const Icon(Icons.grid_view_rounded),
                ),
              ),
            ],
          );
        }

        return inner;
      },
    );

    if (widget.closeTabOnBack) {
      shell = PopScope(
        canPop: _canPopOnBack(),
        onPopInvoked: _handleBack,
        child: shell,
      );
    }
    return shell;
  }

  Widget _buildStrip(SuperTabBarThemeData s) {
    final pinned = _ctrl.pinned;
    final unpinned = _ctrl.unpinned;
    return Container(
      constraints: const BoxConstraints(minHeight: 44),
      color: s.bg,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Pinned region — anchored, does not scroll
          if (pinned.isNotEmpty) ...[
            for (int i = 0; i < pinned.length; i++) ...[
              if (i > 0) const SizedBox(width: 2),
              _tabChip(pinned[i], compact: true, first: i == 0),
            ],
            Container(
              width: 1,
              height: 24,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              color: s.borderStrong,
            ),
          ],
          _chevron(false, _chevStart, s),
          // Scrolling region
          Expanded(
            child: SingleChildScrollView(
              controller: _scroll,
              scrollDirection: Axis.horizontal,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  for (int i = 0; i < unpinned.length; i++) ...[
                    if (i > 0) const SizedBox(width: 2),
                    _draggableTab(unpinned[i], i == 0 && pinned.isEmpty),
                  ],
                ],
              ),
            ),
          ),
          _chevron(true, _chevEnd, s),
          const SizedBox(width: 4),
          _IconBtn(
            icon: Icons.add,
            tooltip: _loc.newTab,
            onTap: _add,
          ),
          const SizedBox(width: 2),
          _IconBtn(
            key: _caretKey,
            icon: Icons.expand_more,
            tooltip: _loc.showAllTabs,
            active: _listOpen,
            onTap: _toggleList,
          ),
        ],
      ),
    );
  }

  Widget _draggableTab(BrowserTab tab, bool first) {
    final active = _ctrl.isActive(tab.id);
    final isOver = _overId == tab.id && _dragId != tab.id;
    return DragTarget<int>(
      onWillAcceptWithDetails: (d) => d.data != tab.id,
      onMove: (_) {
        if (_overId != tab.id) setState(() => _overId = tab.id);
      },
      onLeave: (_) {
        if (_overId == tab.id) setState(() => _overId = null);
      },
      onAcceptWithDetails: (d) {
        _ctrl.reorder(d.data, tab.id);
        widget.onTabReordered?.call(d.data, tab.id);
        setState(() {
          _dragId = null;
          _overId = null;
        });
      },
      builder: (ctx, cand, rej) => Draggable<int>(
        data: tab.id,
        axis: Axis.horizontal,
        onDragStarted: () {
          _hidePreview();
          setState(() => _dragId = tab.id);
        },
        onDraggableCanceled: (_, __) => setState(() {
          _dragId = null;
          _overId = null;
        }),
        onDragEnd: (_) => setState(() {
          _dragId = null;
          _overId = null;
        }),
        feedback: _StaticTab(tab: tab, active: active, feedback: true),
        childWhenDragging: Opacity(
            opacity: 0.4,
            child: IgnorePointer(
                child: _StaticTab(tab: tab, active: active))),
        child: _tabChip(tab,
            compact: false, first: first, isOver: isOver),
      ),
    );
  }

  Widget _tabChip(
    BrowserTab tab, {
    required bool compact,
    required bool first,
    bool isOver = false,
  }) {
    return _TabChip(
      key: ValueKey('tab-${tab.id}'),
      tab: tab,
      active: _ctrl.isActive(tab.id),
      compact: compact,
      first: first,
      isOver: isOver,
      previewEnabled: _prev.enabled,
      previewDelay: _prev.hoverDelay,
      onSelect: () {
        _hidePreview();
        _select(tab.id);
      },
      onClose: () => _requestClose(tab.id),
      onContextMenu: (offset) => _openMenu(offset, tab.id),
      onPreviewRequest: (rect) => _requestPreview(tab.id, rect),
      onPreviewCancel: () => _cancelPreview(tab.id),
    );
  }

  Widget _chevron(bool towardEnd, bool show, SuperTabBarThemeData s) {
    return AnimatedContainer(
      duration: SuperTabBarThemeData.durBase,
      curve: SuperTabBarThemeData.curveStandard,
      width: show ? 26 : 0,
      height: 32,
      margin: const EdgeInsets.only(bottom: 2),
      child: show
          ? _IconBtn(
              icon: towardEnd ? Icons.chevron_right : Icons.chevron_left,
              tooltip:
                  towardEnd ? _loc.scrollForward : _loc.scrollBack,
              size: 26,
              onTap: () => _scrollByDir(towardEnd),
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildContent(SuperTabBarThemeData s, BrowserTab? activeTab) {
    final bg = widget.contentBackground ?? s.surface;
    final decoration = BoxDecoration(
      color: bg,
      border: Border(top: BorderSide(color: s.border)),
    );

    if (activeTab == null) {
      return Container(
        decoration: decoration,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Text(
            _loc.noOpenTabs,
            style: TextStyle(
              fontFamily: SuperTabBarThemeData.bodyFont,
              fontSize: 13,
              color: s.fg3,
            ),
          ),
        ),
      );
    }

    final ordered = _ctrl.ordered;
    final activeIndex =
        ordered.indexWhere((t) => t.id == activeTab.id).clamp(0, ordered.length - 1);

    Widget pageFor(BrowserTab t) {
      final raw = widget.pageBuilder?.call(context, t) ?? GLTabPage(tab: t);
      final page = KeyedSubtree(
          key: ValueKey('tabpage-content-${t.id}'), child: raw);
      final body = widget.scrollContent
          ? SingleChildScrollView(
              key: PageStorageKey('tabpage-${t.id}'),
              padding: widget.contentPadding,
              child: page,
            )
          : Padding(padding: widget.contentPadding, child: page);
      return widget.fillContent ? SizedBox.expand(child: body) : body;
    }

    final Widget surface;
    if (widget.lazyPages) {
      final body = pageFor(activeTab);
      surface = widget.fillContent
          ? body
          : ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 440),
              child: body);
    } else {
      final stack = IndexedStack(
        index: activeIndex,
        sizing: StackFit.loose,
        children: [
          for (final t in ordered)
            _KeepAliveTabPage(
                key: ValueKey('keepalive-${t.id}'), child: pageFor(t)),
        ],
      );
      surface = widget.fillContent
          ? stack
          : ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 440),
              child: stack);
    }

    return Container(
      decoration: decoration,
      child: RepaintBoundary(key: _boundaryKey, child: surface),
    );
  }
}

// ════════════════════════════════════════════════════════════
// KEEP-ALIVE PAGE WRAPPER
// ════════════════════════════════════════════════════════════

class _KeepAliveTabPage extends StatefulWidget {
  final Widget child;
  const _KeepAliveTabPage({super.key, required this.child});

  @override
  State<_KeepAliveTabPage> createState() => _KeepAliveTabPageState();
}

class _KeepAliveTabPageState extends State<_KeepAliveTabPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

// ════════════════════════════════════════════════════════════
// DISMISS LAYER
// ════════════════════════════════════════════════════════════

class _DismissLayer extends StatelessWidget {
  final VoidCallback onDismiss;
  final Widget child;
  const _DismissLayer({required this.onDismiss, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: onDismiss,
            onSecondaryTap: onDismiss,
          ),
        ),
        child,
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════
// TAB CHIP  (active / inactive / hover / pressed + preview)
// ════════════════════════════════════════════════════════════

class _TabChip extends StatefulWidget {
  final BrowserTab tab;
  final bool active, compact, first, isOver;
  final bool previewEnabled;
  final Duration previewDelay;
  final VoidCallback onSelect, onClose, onPreviewCancel;
  final ValueChanged<Offset> onContextMenu;
  final ValueChanged<Rect> onPreviewRequest;

  const _TabChip({
    super.key,
    required this.tab,
    required this.active,
    required this.compact,
    required this.first,
    required this.isOver,
    this.previewEnabled = true,
    this.previewDelay = const Duration(milliseconds: 480),
    required this.onSelect,
    required this.onClose,
    required this.onContextMenu,
    required this.onPreviewRequest,
    required this.onPreviewCancel,
  });

  @override
  State<_TabChip> createState() => _TabChipState();
}

class _TabChipState extends State<_TabChip> {
  bool _hover = false;
  bool _closeHover = false;
  Timer? _previewTimer;

  void _armPreview() {
    if (!widget.previewEnabled) return;
    _previewTimer?.cancel();
    _previewTimer = Timer(widget.previewDelay, () {
      final box = context.findRenderObject() as RenderBox?;
      if (box != null && box.attached) {
        widget.onPreviewRequest(box.localToGlobal(Offset.zero) & box.size);
      }
    });
  }

  void _dropPreview() {
    _previewTimer?.cancel();
    _previewTimer = null;
    widget.onPreviewCancel();
  }

  @override
  void dispose() {
    _previewTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = SuperTabBarThemeData.of(context);
    final tab = widget.tab;
    final active = widget.active;
    final bg = active
        ? s.surface
        : (_hover ? s.hover : Colors.transparent);
    final fg = active ? s.fg1 : s.fg3;

    // Build the semantic label for screen readers.
    final semanticLabel = StringBuffer(tab.title);
    if (active) semanticLabel.write(', selected');
    if (tab.dirty) semanticLabel.write(', has unsaved changes');
    if (tab.pinned) semanticLabel.write(', pinned');
    if (tab.behavior == SuperTabBehavior.requiredPinned) {
      semanticLabel.write(', required');
    }

    return Semantics(
      label: semanticLabel.toString(),
      button: true,
      selected: active,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) {
          setState(() => _hover = true);
          _armPreview();
        },
        onExit: (_) {
          setState(() => _hover = false);
          _dropPreview();
        },
        child: GestureDetector(
          onTap: () {
            _dropPreview();
            widget.onSelect();
          },
          onSecondaryTapDown: (d) {
            _dropPreview();
            widget.onContextMenu(d.globalPosition);
          },
          onLongPressStart: (d) {
            _dropPreview();
            widget.onContextMenu(d.globalPosition);
          },
          child: AnimatedContainer(
            duration: SuperTabBarThemeData.durBase,
            curve: SuperTabBarThemeData.curveStandard,
            height: 36,
            width: widget.compact ? 40 : null,
            constraints: widget.compact
                ? null
                : const BoxConstraints(minWidth: 120, maxWidth: 200),
            padding: widget.compact
                ? EdgeInsets.zero
                : const EdgeInsetsDirectional.only(start: 12, end: 8),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                if (widget.isOver)
                  PositionedDirectional(
                    start: -1,
                    top: 6,
                    bottom: 6,
                    child: Container(
                      width: 2,
                      decoration: BoxDecoration(
                        color: SuperTabBarThemeData.accent,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                if (!active && !widget.first && !widget.isOver)
                  PositionedDirectional(
                    start: 0,
                    top: 9,
                    bottom: 9,
                    child: Container(width: 1, color: s.border),
                  ),
                _content(s, tab, active, fg),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _content(SuperTabBarThemeData s, BrowserTab tab, bool active, Color fg) {
    if (widget.compact) {
      return Stack(
        children: [
          Center(
            child: Icon(
              glTabIcon(tab.kind),
              size: 14,
              color: active ? SuperTabBarThemeData.accent : s.fg3,
            ),
          ),
          if (tab.dirty)
            PositionedDirectional(
              top: 7,
              end: 7,
              child: Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: SuperTabBarThemeData.warning,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      );
    }

    return Row(
      children: [
        Icon(
          glTabIcon(tab.kind),
          size: 14,
          color: active ? SuperTabBarThemeData.accent : s.fg3,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Tooltip(
            message: tab.title,
            waitDuration: const Duration(milliseconds: 600),
            child: Text(
              tab.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: SuperTabBarThemeData.bodyFont,
                fontSize: 13,
                fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                color: fg,
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        _trailing(s, tab, active),
      ],
    );
  }

  Widget _trailing(SuperTabBarThemeData s, BrowserTab tab, bool active) {
    if (tab.dirty && !_hover) {
      return Container(
        width: 8,
        height: 8,
        margin: const EdgeInsetsDirectional.only(end: 4),
        decoration: const BoxDecoration(
          color: SuperTabBarThemeData.warning,
          shape: BoxShape.circle,
        ),
      );
    }
    final visible = _hover || active;
    return Opacity(
      opacity: visible ? 1 : 0,
      child: Semantics(
        button: true,
        label: 'Close ${tab.title}',
        excludeSemantics: true,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _closeHover = true),
          onExit: (_) => setState(() => _closeHover = false),
          child: GestureDetector(
            onTap: visible
                ? () {
                    _dropPreview();
                    widget.onClose();
                  }
                : null,
            child: Container(
              width: 18,
              height: 18,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _closeHover ? s.inputBg : Colors.transparent,
                borderRadius: BorderRadius.circular(5),
              ),
              child: Icon(
                Icons.close,
                size: 12,
                color: _closeHover ? s.fg1 : s.fg3,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// STATIC TAB  (drag feedback / childWhenDragging)
// ════════════════════════════════════════════════════════════

class _StaticTab extends StatelessWidget {
  final BrowserTab tab;
  final bool active;
  final bool feedback;
  const _StaticTab({
    required this.tab,
    required this.active,
    this.feedback = false,
  });

  @override
  Widget build(BuildContext context) {
    final s = SuperTabBarThemeData.of(context);
    final chip = Container(
      height: 36,
      constraints: const BoxConstraints(minWidth: 120, maxWidth: 200),
      padding: const EdgeInsetsDirectional.only(start: 12, end: 8),
      decoration: BoxDecoration(
        color: active ? s.surface : s.hover,
        borderRadius: BorderRadius.circular(9),
        border: feedback ? Border.all(color: s.borderStrong) : null,
      ),
      child: Row(
        children: [
          Icon(
            glTabIcon(tab.kind),
            size: 14,
            color: active ? SuperTabBarThemeData.accent : s.fg3,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              tab.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: SuperTabBarThemeData.bodyFont,
                fontSize: 13,
                fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                color: active ? s.fg1 : s.fg2,
              ),
            ),
          ),
        ],
      ),
    );
    if (!feedback) return chip;
    return Material(
        color: Colors.transparent, child: Opacity(opacity: 0.9, child: chip));
  }
}

// ════════════════════════════════════════════════════════════
// ICON BUTTON  (+ / ▾ / chevrons)
// ════════════════════════════════════════════════════════════

class _IconBtn extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final bool active;
  final double size;
  final VoidCallback onTap;

  const _IconBtn({
    super.key,
    required this.icon,
    required this.tooltip,
    this.active = false,
    this.size = 32,
    required this.onTap,
  });

  @override
  State<_IconBtn> createState() => _IconBtnState();
}

class _IconBtnState extends State<_IconBtn> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final s = SuperTabBarThemeData.of(context);
    final on = widget.active || _hover;
    return Tooltip(
      message: widget.tooltip,
      waitDuration: const Duration(milliseconds: 500),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            width: widget.size,
            height: 32,
            margin: const EdgeInsets.only(bottom: 2),
            decoration: BoxDecoration(
              color: on ? s.hover : Colors.transparent,
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(
              widget.icon,
              size: 16,
              color: on ? s.fg1 : s.fg3,
            ),
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// BACKWARD-COMPATIBLE ALIAS
// ════════════════════════════════════════════════════════════

/// Alias for [SuperTabBar]. Maintained for backward compatibility.
typedef BrowserStyleTabBar = SuperTabBar;
