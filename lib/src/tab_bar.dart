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
//   • Keyboard shortcuts: Ctrl/Cmd+T → new tab, Ctrl/Cmd+W → close active
//   • [BrowserStyleTabBar] typedef for backward compatibility
//
//   File: lib/src/tab_bar.dart
// ============================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'key_directions.dart';
import 'theme.dart';
import 'controller.dart';
import 'models.dart';
import 'pages.dart';
import 'overlays.dart';
import 'localizations.dart';
import 'preview_options.dart';

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
  KeyEventResult _onKey(FocusNode node, KeyEvent e) {
    if (e is! KeyDownEvent) return KeyEventResult.ignored;

    // Ctrl / Cmd + T → new tab
    final mod = HardwareKeyboard.instance.isControlPressed ||
        HardwareKeyboard.instance.isMetaPressed;
    if (mod && e.logicalKey == LogicalKeyboardKey.keyT) {
      _add();
      return KeyEventResult.handled;
    }
    // Ctrl / Cmd + W → close active tab
    if (mod && e.logicalKey == LogicalKeyboardKey.keyW) {
      final active = _ctrl.activeId;
      if (active != null && _ctrl.canCloseFromUi(active)) {
        _requestClose(active);
      }
      return KeyEventResult.handled;
    }

    // Escape → close open overlays
    if (e.logicalKey == LogicalKeyboardKey.escape) {
      if (_menuEntry != null || _listEntry != null) {
        _hideMenu();
        _hideList();
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }

    final arrowKeys = {
      LogicalKeyboardKey.arrowRight,
      LogicalKeyboardKey.arrowLeft,
      LogicalKeyboardKey.home,
      LogicalKeyboardKey.end,
    };
    if (!arrowKeys.contains(e.logicalKey)) return KeyEventResult.ignored;

    final ord = _ctrl.ordered;
    if (ord.isEmpty) return KeyEventResult.handled;
    final i = ord.indexWhere((t) => t.id == _ctrl.activeId);
    var ni = i;
    final step = horizontalStep(e.logicalKey, Directionality.of(context));
    if (step != 0) {
      ni = (i + step).clamp(0, ord.length - 1);
    } else if (e.logicalKey == LogicalKeyboardKey.home) {
      ni = 0;
    } else if (e.logicalKey == LogicalKeyboardKey.end) {
      ni = ord.length - 1;
    }
    if (ni >= 0 && ni < ord.length) _select(ord[ni].id);
    return KeyEventResult.handled;
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

  // ════════ BUILD ═══════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final s = SuperTabBarThemeData.of(context);
    final activeTab = _ctrl.activeTab;
    final content = _buildContent(s, activeTab);

    return SuperTabBarScope(
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
                    borderRadius:
                        BorderRadius.circular(SuperTabBarThemeData.radiusLg),
                  )
                : BoxDecoration(color: s.bg),
            clipBehavior:
                widget.showChrome ? Clip.antiAlias : Clip.none,
            child: Column(
              mainAxisSize:
                  widget.fillContent ? MainAxisSize.max : MainAxisSize.min,
              children: [
                _buildStrip(s),
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
  }

  Widget _buildStrip(SuperTabBarThemeData s) {
    final pinned = _ctrl.pinned;
    final unpinned = _ctrl.unpinned;
    return Container(
      constraints: const BoxConstraints(minHeight: 44),
      color: s.bg,
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
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
              margin: const EdgeInsets.only(left: 4, right: 4, top: 8),
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
                crossAxisAlignment: CrossAxisAlignment.end,
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
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(9)),
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
        borderRadius: const BorderRadius.vertical(top: Radius.circular(9)),
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
