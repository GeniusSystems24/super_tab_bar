// ============================================================
// super_tab_bar — compact-mode tab switcher.
// ------------------------------------------------------------
// A mobile-friendly alternative to the horizontal tab strip. On small
// screens the strip is too wide to be usable, so [SuperTabBar.compact]
// hides it and you surface this switcher instead — a scrollable grid of
// thumbnail previews of every open tab.
//
//   • Tap a thumbnail  → activates that tab and (via [showSuperTabSwitcher])
//                        closes the switcher.
//   • Long-press-drag  → reorders tabs by dropping one thumbnail onto another
//                        (drives [SuperTabBarController.reorder]).
//   • Close (×) button → closes the tab (respects behavior + dirty guard via
//                        the supplied [onCloseTab]).
//
// The thumbnails reuse the live page snapshots the controller already
// captures for hover previews. Tabs without a fresh snapshot fall back to a
// scaled live render of their page (or a plain icon card when previews are
// disabled). Page content comes from each tab's [BrowserTab.pageBuilder].
//
//   File: lib/src/compact.dart
// ============================================================

import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'controller.dart';
import 'models.dart';
import 'theme.dart';
import 'localizations.dart';
import 'preview_options.dart';
import 'pages.dart';

// ════════════════════════════════════════════════════════════
// PUBLIC ENTRY POINT
// ════════════════════════════════════════════════════════════

/// Opens the compact-mode [SuperTabSwitcher] as a full-screen modal route and
/// returns the id of the tab the user picked — or `null` if they dismissed it
/// without choosing.
///
/// Picking a thumbnail activates that tab on [controller] and pops the route.
/// This is the recommended way to switch tabs on phones: keep the tab bar in
/// [SuperTabBar.compact] mode (strip hidden) and open this from a
/// [FloatingActionButton] or app-bar button.
///
/// ```dart
/// FloatingActionButton(
///   child: const Icon(Icons.grid_view_rounded),
///   onPressed: () => showSuperTabSwitcher(context, controller: controller),
/// )
/// ```
///
/// Thumbnail content comes from each tab's [BrowserTab.pageBuilder]. Pass
/// [onCloseTab] to route the per-thumbnail close button through your own
/// dirty-confirmation logic; when omitted, close falls back to
/// [SuperTabBarController.close] for tabs the UI permits closing.
Future<int?> showSuperTabSwitcher(
  BuildContext context, {
  required SuperTabBarController controller,
  SuperTabBarLocalizations? localizations,
  SuperTabBarPreviewOptions? previewOptions,
  int? crossAxisCount,
  bool showCloseButtons = true,
  void Function(int id)? onCloseTab,
}) {
  final loc = localizations ?? SuperTabBarLocalizations.en;
  final prev = previewOptions ?? SuperTabBarPreviewOptions.defaults;
  return Navigator.of(context).push<int>(
    PageRouteBuilder<int>(
      opaque: true,
      barrierColor: const Color(0x99000000),
      transitionDuration: SuperTabBarThemeData.durSlow,
      reverseTransitionDuration: SuperTabBarThemeData.durBase,
      pageBuilder: (ctx, anim, _) => SuperTabSwitcher(
        controller: controller,
        localizations: loc,
        previewOptions: prev,
        crossAxisCount: crossAxisCount,
        showCloseButtons: showCloseButtons,
        onCloseTab: onCloseTab,
        onSelect: (id) {
          controller.select(id);
          Navigator.of(ctx).pop(id);
        },
        onDismiss: () => Navigator.of(ctx).pop(),
      ),
      transitionsBuilder: (ctx, anim, _, child) {
        final curved = CurvedAnimation(
          parent: anim,
          curve: SuperTabBarThemeData.curveDecelerate,
        );
        return FadeTransition(
          opacity: curved,
          child: Transform.scale(
            scale: 0.98 + 0.02 * curved.value,
            child: child,
          ),
        );
      },
    ),
  );
}

// ════════════════════════════════════════════════════════════
// SWITCHER SCREEN
// ════════════════════════════════════════════════════════════

/// A grid of thumbnail previews for every open tab — the compact-mode
/// counterpart to the horizontal [SuperTabBar] strip.
///
/// Use [showSuperTabSwitcher] for the common full-screen modal flow, or embed
/// this widget directly (e.g. in a bottom sheet or a dedicated route) when you
/// need more control over presentation.
class SuperTabSwitcher extends StatefulWidget {
  /// The controller whose tabs are shown. The switcher rebuilds when it
  /// notifies.
  final SuperTabBarController controller;

  /// User-facing strings. Defaults to [SuperTabBarLocalizations.en].
  final SuperTabBarLocalizations? localizations;

  /// Hover-preview options — only [SuperTabBarPreviewOptions.fallback] is used
  /// here, to decide whether snapshot-less tabs render a live preview or a
  /// blank card.
  final SuperTabBarPreviewOptions? previewOptions;

  /// Fixed column count. When null the grid adapts to the available width.
  final int? crossAxisCount;

  /// Whether to show a close (×) button on each closable thumbnail.
  final bool showCloseButtons;

  /// Called when a thumbnail is tapped, with the tab's id. When used through
  /// [showSuperTabSwitcher] this selects the tab and pops the route.
  final void Function(int id)? onSelect;

  /// Called when the user dismisses the switcher (back button / close icon).
  final VoidCallback? onDismiss;

  /// Routes the per-thumbnail close button. When null, closable tabs are
  /// removed via [SuperTabBarController.close]. Provide this to run your own
  /// dirty-confirmation dialog first.
  final void Function(int id)? onCloseTab;

  const SuperTabSwitcher({
    super.key,
    required this.controller,
    this.localizations,
    this.previewOptions,
    this.crossAxisCount,
    this.showCloseButtons = true,
    this.onSelect,
    this.onDismiss,
    this.onCloseTab,
  });

  @override
  State<SuperTabSwitcher> createState() => _SuperTabSwitcherState();
}

class _SuperTabSwitcherState extends State<SuperTabSwitcher> {
  int? _dragId;
  int? _overId;

  SuperTabBarLocalizations get _loc =>
      widget.localizations ?? SuperTabBarLocalizations.en;
  PreviewFallback get _fallback =>
      (widget.previewOptions ?? SuperTabBarPreviewOptions.defaults).fallback;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onCtrl);
  }

  @override
  void didUpdateWidget(covariant SuperTabSwitcher old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_onCtrl);
      widget.controller.addListener(_onCtrl);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onCtrl);
    super.dispose();
  }

  void _onCtrl() {
    if (mounted) setState(() {});
  }

  Widget _scope(Widget child) =>
      SuperTabBarScope(controller: widget.controller, child: child);

  void _select(int id) => widget.onSelect?.call(id);

  void _close(int id) {
    if (widget.onCloseTab != null) {
      widget.onCloseTab!(id);
    } else if (widget.controller.canCloseFromUi(id)) {
      widget.controller.close(id);
    }
  }

  void _drop(int fromId, int toId) {
    if (fromId != toId) widget.controller.reorder(fromId, toId);
    setState(() {
      _dragId = null;
      _overId = null;
    });
  }

  int _columnsFor(double width) {
    if (widget.crossAxisCount != null) return widget.crossAxisCount!;
    if (width >= 1000) return 4;
    if (width >= 680) return 3;
    return 2;
  }

  @override
  Widget build(BuildContext context) {
    final s = SuperTabBarThemeData.of(context);
    final tabs = widget.controller.ordered;

    return Material(
      color: s.bg,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _header(s, tabs.length),
            Expanded(
              child: tabs.isEmpty
                  ? _empty(s)
                  : LayoutBuilder(
                      builder: (ctx, c) {
                        final cols = _columnsFor(c.maxWidth);
                        return GridView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: cols,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                            childAspectRatio: 0.82,
                          ),
                          itemCount: tabs.length,
                          itemBuilder: (ctx, i) => _cell(s, tabs[i]),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────
  Widget _header(SuperTabBarThemeData s, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _loc.switcherTitle,
                  style: TextStyle(
                    fontFamily: SuperTabBarThemeData.displayFont,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: s.fg1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_loc.openTabsHeaderFor(count)}  ·  ${_loc.reorderHint}',
                  style: TextStyle(
                    fontFamily: SuperTabBarThemeData.bodyFont,
                    fontSize: 12,
                    color: s.fg3,
                  ),
                ),
              ],
            ),
          ),
          Semantics(
            button: true,
            label: _loc.cancel,
            child: IconButton(
              icon: Icon(Icons.close, color: s.fg2),
              onPressed: widget.onDismiss,
              tooltip: _loc.cancel,
            ),
          ),
        ],
      ),
    );
  }

  Widget _empty(SuperTabBarThemeData s) => Center(
        child: Text(
          _loc.noOpenTabs,
          style: TextStyle(
            fontFamily: SuperTabBarThemeData.bodyFont,
            fontSize: 13,
            color: s.fg3,
          ),
        ),
      );

  // ── One thumbnail cell (draggable + drop target) ──────────
  Widget _cell(SuperTabBarThemeData s, BrowserTab tab) {
    final isOver = _overId == tab.id && _dragId != tab.id;
    final card = _TabThumbnail(
      tab: tab,
      active: widget.controller.isActive(tab.id),
      isOver: isOver,
      dragging: _dragId == tab.id,
      snapshot: widget.controller.snapshot(tab.id),
      scope: _scope,
      fallback: _fallback,
      localizations: _loc,
      showClose:
          widget.showCloseButtons && widget.controller.canCloseFromUi(tab.id),
      onTap: () => _select(tab.id),
      onClose: () => _close(tab.id),
    );

    return DragTarget<int>(
      onWillAcceptWithDetails: (d) => d.data != tab.id,
      onMove: (_) {
        if (_overId != tab.id) setState(() => _overId = tab.id);
      },
      onLeave: (_) {
        if (_overId == tab.id) setState(() => _overId = null);
      },
      onAcceptWithDetails: (d) => _drop(d.data, tab.id),
      builder: (ctx, cand, rej) => LongPressDraggable<int>(
        data: tab.id,
        onDragStarted: () => setState(() => _dragId = tab.id),
        onDraggableCanceled: (_, __) => setState(() {
          _dragId = null;
          _overId = null;
        }),
        onDragEnd: (_) => setState(() {
          _dragId = null;
          _overId = null;
        }),
        feedback: Material(
          color: Colors.transparent,
          child: Opacity(
            opacity: 0.9,
            child: SizedBox(
              width: 168,
              height: 205,
              child: _TabThumbnail(
                tab: tab,
                active: widget.controller.isActive(tab.id),
                isOver: false,
                dragging: false,
                elevated: true,
                snapshot: widget.controller.snapshot(tab.id),
                scope: _scope,
                fallback: _fallback,
                localizations: _loc,
                showClose: false,
                onTap: () {},
                onClose: () {},
              ),
            ),
          ),
        ),
        childWhenDragging: Opacity(opacity: 0.35, child: card),
        child: card,
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// THUMBNAIL CARD
// ════════════════════════════════════════════════════════════

class _TabThumbnail extends StatelessWidget {
  final BrowserTab tab;
  final bool active;
  final bool isOver;
  final bool dragging;
  final bool elevated;
  final ui.Image? snapshot;
  final Widget Function(Widget) scope;
  final PreviewFallback fallback;
  final SuperTabBarLocalizations localizations;
  final bool showClose;
  final VoidCallback onTap;
  final VoidCallback onClose;

  const _TabThumbnail({
    required this.tab,
    required this.active,
    required this.isOver,
    required this.dragging,
    required this.snapshot,
    required this.scope,
    required this.fallback,
    required this.localizations,
    required this.showClose,
    required this.onTap,
    required this.onClose,
    this.elevated = false,
  });

  @override
  Widget build(BuildContext context) {
    final s = SuperTabBarThemeData.of(context);
    final borderColor = isOver
        ? SuperTabBarThemeData.accent
        : (active ? SuperTabBarThemeData.accent : s.border);

    return Semantics(
      button: true,
      selected: active,
      label: tab.title,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: SuperTabBarThemeData.durBase,
          curve: SuperTabBarThemeData.curveStandard,
          decoration: BoxDecoration(
            color: s.surface,
            borderRadius: BorderRadius.circular(SuperTabBarThemeData.radiusXl),
            border: Border.all(
              color: borderColor,
              width: (active || isOver) ? 2 : 1,
            ),
            boxShadow: elevated
                ? SuperTabBarThemeData.popShadow
                : (isOver
                    ? [
                        BoxShadow(
                          color: SuperTabBarThemeData.accent.withOpacity(0.28),
                          blurRadius: 18,
                          spreadRadius: -4,
                        )
                      ]
                    : null),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Preview area
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: _PreviewArea(
                        tab: tab,
                        surface: s.surface,
                        snapshot: snapshot,
                        scope: scope,
                        fallback: fallback,
                      ),
                    ),
                    if (active)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: _Badge(
                          color: SuperTabBarThemeData.accent,
                          child: const Text('ACTIVE'),
                        ),
                      ),
                    if (showClose)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Semantics(
                          button: true,
                          label: localizations.closeTab,
                          child: GestureDetector(
                            onTap: onClose,
                            child: Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                color: const Color(0xCC000000),
                                borderRadius: BorderRadius.circular(13),
                              ),
                              child: const Icon(Icons.close,
                                  size: 15, color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Footer: icon · title · dirty / pin
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                decoration: BoxDecoration(
                  color: s.surface,
                  border: Border(top: BorderSide(color: s.border)),
                ),
                child: Row(
                  children: [
                    if (tab.icon != null) ...[
                      Icon(tab.icon,
                          size: 15,
                          color: active
                              ? SuperTabBarThemeData.accent
                              : s.fg3),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: Text(
                        tab.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: SuperTabBarThemeData.bodyFont,
                          fontSize: 12.5,
                          fontWeight:
                              active ? FontWeight.w600 : FontWeight.w500,
                          color: s.fg1,
                        ),
                      ),
                    ),
                    if (tab.pinned) ...[
                      const SizedBox(width: 6),
                      Icon(Icons.push_pin, size: 13, color: s.fg3),
                    ],
                    if (tab.dirty) ...[
                      const SizedBox(width: 6),
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: SuperTabBarThemeData.warning,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Preview area: cached snapshot, else scaled live render, else blank.
class _PreviewArea extends StatelessWidget {
  final BrowserTab tab;
  final Color surface;
  final ui.Image? snapshot;
  final Widget Function(Widget) scope;
  final PreviewFallback fallback;

  const _PreviewArea({
    required this.tab,
    required this.surface,
    required this.snapshot,
    required this.scope,
    required this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return ClipRect(
      child: Stack(
        children: [
          Positioned.fill(child: ColoredBox(color: surface)),
          if (snapshot != null)
            Positioned.fill(
              child: FittedBox(
                fit: BoxFit.fitWidth,
                alignment: rtl ? Alignment.topRight : Alignment.topLeft,
                clipBehavior: Clip.hardEdge,
                child: RawImage(
                    image: snapshot, filterQuality: FilterQuality.medium),
              ),
            )
          else if (fallback == PreviewFallback.liveRender)
            _live(context, rtl)
          else
            _blank(context),
        ],
      ),
    );
  }

  Widget _live(BuildContext context, bool rtl) {
    return LayoutBuilder(
      builder: (ctx, c) {
        const designW = 940.0;
        final scale = c.maxWidth / designW;
        final align = rtl ? Alignment.topRight : Alignment.topLeft;
        Widget page = Container(
          width: designW,
          color: surface,
          padding: const EdgeInsets.all(20),
          child: tab.pageBuilder.call(ctx, tab),
        );
        page = scope(page);
        return OverflowBox(
          alignment: align,
          minWidth: 0,
          maxWidth: double.infinity,
          minHeight: 0,
          maxHeight: double.infinity,
          child: Transform.scale(
            scale: scale,
            alignment: align,
            child: Directionality(
              textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
              child: IgnorePointer(child: page),
            ),
          ),
        );
      },
    );
  }

  Widget _blank(BuildContext context) {
    final s = SuperTabBarThemeData.of(context);
    return Center(
      child: tab.icon != null
          ? Icon(tab.icon, size: 34, color: s.fg4)
          : const SizedBox.shrink(),
    );
  }
}

class _Badge extends StatelessWidget {
  final Color color;
  final Widget child;
  const _Badge({required this.color, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(SuperTabBarThemeData.radiusSm),
      ),
      child: DefaultTextStyle(
        style: const TextStyle(
          fontFamily: SuperTabBarThemeData.bodyFont,
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          color: Colors.white,
        ),
        child: child,
      ),
    );
  }
}
