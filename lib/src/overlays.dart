// ============================================================
// super_tab_bar — overlays.
// Context menu · tab-list dropdown · dirty-close confirm dialog ·
// hover/long-press mini-page preview.
//   File: lib/src/overlays.dart
// ============================================================

import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'theme.dart';
import 'models.dart';
import 'localizations.dart';
import 'preview_options.dart';

/// Wraps a widget so a fallback page built inside an overlay can still reach
/// the controller via `SuperTabBarController.of(context)`.
typedef ScopeWrapper = Widget Function(Widget child);

// ── Shared pop-card decoration ──────────────────────────────
BoxDecoration _popDecoration(SuperTabBarThemeData s) => BoxDecoration(
      color: s.surface,
      border: Border.all(color: s.borderStrong),
      borderRadius: BorderRadius.circular(SuperTabBarThemeData.radiusMd),
      boxShadow: SuperTabBarThemeData.popShadow,
    );

// ════════════════════════════════════════════════════════════
// CONTEXT MENU
// ════════════════════════════════════════════════════════════

class TabMenuItem {
  final IconData? icon;
  final String? label;
  final String? hint;
  final bool danger;
  final bool disabled;
  final bool divider;
  final VoidCallback? run;

  const TabMenuItem({
    this.icon,
    this.label,
    this.hint,
    this.danger = false,
    this.disabled = false,
    this.run,
  }) : divider = false;

  const TabMenuItem.divider()
      : icon = null,
        label = null,
        hint = null,
        danger = false,
        disabled = false,
        run = null,
        divider = true;
}

/// Right-click context menu, opened at the cursor [at] (global).
/// Clamps inside the screen; dismisses on outside tap / Esc.
class TabContextMenu extends StatelessWidget {
  final Offset at;
  final List<TabMenuItem> items;
  final VoidCallback onClose;

  const TabContextMenu({
    super.key,
    required this.at,
    required this.items,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final s = SuperTabBarThemeData.of(context);
    final screen = MediaQuery.of(context).size;
    const w = 220.0;
    final h = items.length * 36 + 12.0;
    final left = at.dx.clamp(8.0, screen.width - w - 8);
    final top = at.dy.clamp(8.0, screen.height - h - 8);

    return Positioned(
      left: left,
      top: top,
      child: _Appear(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: w,
            padding: const EdgeInsets.all(6),
            decoration: _popDecoration(s),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final it in items)
                  if (it.divider)
                    Container(
                      height: 1,
                      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                      color: s.border,
                    )
                  else
                    _MenuRow(item: it, onClose: onClose),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuRow extends StatefulWidget {
  final TabMenuItem item;
  final VoidCallback onClose;
  const _MenuRow({required this.item, required this.onClose});

  @override
  State<_MenuRow> createState() => _MenuRowState();
}

class _MenuRowState extends State<_MenuRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final s = SuperTabBarThemeData.of(context);
    final it = widget.item;
    final color = it.danger ? SuperTabBarThemeData.danger : s.fg1;

    return MouseRegion(
      cursor: it.disabled ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: it.disabled
            ? null
            : () {
                it.run?.call();
                widget.onClose();
              },
        child: Semantics(
          button: true,
          enabled: !it.disabled,
          label: it.label,
          child: Opacity(
            opacity: it.disabled ? 0.4 : 1,
            child: Container(
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: (_hover && !it.disabled) ? s.hover : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(it.icon, size: 15, color: color),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      it.label ?? '',
                      style: TextStyle(
                        fontFamily: SuperTabBarThemeData.bodyFont,
                        fontSize: 13,
                        color: color,
                      ),
                    ),
                  ),
                  if (it.hint != null)
                    Text(
                      it.hint!,
                      style: TextStyle(
                        fontFamily: SuperTabBarThemeData.monoFont,
                        fontSize: 11,
                        color: s.fg3,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// TAB-LIST DROPDOWN  (jump to any open tab)
// ════════════════════════════════════════════════════════════

class TabListDropdown extends StatelessWidget {
  final Rect anchor;
  final List<BrowserTab> tabs;
  final int activeId;
  final ValueChanged<int> onPick;
  final VoidCallback onClose;
  final SuperTabBarLocalizations localizations;

  const TabListDropdown({
    super.key,
    required this.anchor,
    required this.tabs,
    required this.activeId,
    required this.onPick,
    required this.onClose,
    this.localizations = SuperTabBarLocalizations.en,
  });

  @override
  Widget build(BuildContext context) {
    final s = SuperTabBarThemeData.of(context);
    final screen = MediaQuery.of(context).size;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    const w = 280.0;
    final left =
        (rtl ? anchor.left : anchor.right - w).clamp(8.0, screen.width - w - 8);
    final top = (anchor.bottom + 6).clamp(8.0, screen.height - 8);
    final maxH = (screen.height - top - 16).clamp(160.0, screen.height);

    return Positioned(
      left: left,
      top: top,
      child: _Appear(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: w,
            constraints: BoxConstraints(maxHeight: maxH),
            padding: const EdgeInsets.all(6),
            decoration: _popDecoration(s),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 4, 10, 6),
                  child: Text(
                    localizations.openTabsHeaderFor(tabs.length),
                    style: TextStyle(
                      fontFamily: SuperTabBarThemeData.monoFont,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: s.fg3,
                    ),
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final t in tabs)
                          _ListRow(
                            tab: t,
                            active: t.id == activeId,
                            onPick: onPick,
                            onClose: onClose,
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ListRow extends StatefulWidget {
  final BrowserTab tab;
  final bool active;
  final ValueChanged<int> onPick;
  final VoidCallback onClose;
  const _ListRow({
    required this.tab,
    required this.active,
    required this.onPick,
    required this.onClose,
  });

  @override
  State<_ListRow> createState() => _ListRowState();
}

class _ListRowState extends State<_ListRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final s = SuperTabBarThemeData.of(context);
    final t = widget.tab;
    final bg = widget.active ? s.inputBg : (_hover ? s.hover : Colors.transparent);

    return Semantics(
      button: true,
      selected: widget.active,
      label: t.title,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTap: () {
            widget.onPick(t.id);
            widget.onClose();
          },
          child: Container(
            constraints: const BoxConstraints(minHeight: 34),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                if (t.icon != null) ...[
                  Icon(
                    t.icon,
                    size: 15,
                    color: widget.active ? SuperTabBarThemeData.accent : s.fg3,
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Text(
                    t.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: SuperTabBarThemeData.bodyFont,
                      fontSize: 13,
                      fontWeight: widget.active ? FontWeight.w600 : FontWeight.w500,
                      color: widget.active ? s.fg1 : s.fg2,
                    ),
                  ),
                ),
                if (t.pinned) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.push_pin, size: 13, color: s.fg3),
                ],
                if (t.dirty) ...[
                  const SizedBox(width: 8),
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
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// MINI-PAGE PREVIEW  (hover-intent popover)
// ════════════════════════════════════════════════════════════

class MiniPagePreview extends StatefulWidget {
  final BrowserTab tab;
  final Rect anchor;
  final ui.Image? snapshot;
  final ScopeWrapper? scope;
  final PreviewFallback fallback;

  const MiniPagePreview({
    super.key,
    required this.tab,
    required this.anchor,
    this.snapshot,
    this.scope,
    this.fallback = PreviewFallback.liveRender,
  });

  @override
  State<MiniPagePreview> createState() => _MiniPagePreviewState();
}

class _MiniPagePreviewState extends State<MiniPagePreview> {
  static const double _w = 268;
  static const double _thumbH = 150;
  bool _show = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _show = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = SuperTabBarThemeData.of(context);
    final tab = widget.tab;
    final screen = MediaQuery.of(context).size;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final r = widget.anchor;
    const cardH = 210.0;

    final left = r.left.clamp(8.0, screen.width - _w - 8);
    var top = r.bottom + 9;
    var above = false;
    if (top + cardH > screen.height - 8) {
      top = r.top - cardH - 9;
      above = true;
    }
    final arrowX = (r.left + r.width / 2 - left).clamp(16.0, _w - 16);

    return Positioned(
      left: left,
      top: top,
      child: IgnorePointer(
        child: Semantics(
          label: 'Preview of ${tab.title}',
          excludeSemantics: true,
          child: AnimatedOpacity(
            opacity: _show ? 1 : 0,
            duration: SuperTabBarThemeData.durBase,
            curve: SuperTabBarThemeData.curveDecelerate,
            child: AnimatedSlide(
              offset: _show ? Offset.zero : Offset(0, above ? 0.03 : -0.03),
              duration: SuperTabBarThemeData.durBase,
              curve: SuperTabBarThemeData.curveDecelerate,
              child: SizedBox(
                width: _w,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Material(
                      color: Colors.transparent,
                      child: Container(
                        decoration: _popDecoration(s),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // header
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 11, vertical: 9),
                              decoration: BoxDecoration(
                                  border: Border(bottom: BorderSide(color: s.border))),
                              child: Row(
                                children: [
                                  if (tab.icon != null) ...[
                                    Icon(
                                      tab.icon,
                                      size: 15,
                                      color: SuperTabBarThemeData.accent,
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          tab.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontFamily: SuperTabBarThemeData.bodyFont,
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w600,
                                            color: s.fg1,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (tab.pinned) ...[
                                    const SizedBox(width: 6),
                                    Icon(Icons.push_pin, size: 12, color: s.fg3),
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
                            // thumbnail
                            _Thumbnail(
                              tab: tab,
                              rtl: rtl,
                              width: _w,
                              height: _thumbH,
                              surface: s.surface,
                              snapshot: widget.snapshot,
                              scope: widget.scope,
                              fallback: widget.fallback,
                            ),
                          ],
                        ),
                      ),
                    ),
                    // caret arrow
                    Positioned(
                      left: arrowX - 5,
                      top: above ? null : -5,
                      bottom: above ? -5 : null,
                      child: Transform.rotate(
                        angle: 0.785398,
                        child: Container(
                          width: 9,
                          height: 9,
                          decoration: BoxDecoration(
                            color: s.surface,
                            border: Border(
                              top: above
                                  ? BorderSide.none
                                  : BorderSide(color: s.borderStrong),
                              left: above
                                  ? BorderSide.none
                                  : BorderSide(color: s.borderStrong),
                              right: above
                                  ? BorderSide(color: s.borderStrong)
                                  : BorderSide.none,
                              bottom: above
                                  ? BorderSide(color: s.borderStrong)
                                  : BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  final BrowserTab tab;
  final bool rtl;
  final double width, height;
  final Color surface;
  final ui.Image? snapshot;
  final ScopeWrapper? scope;
  final PreviewFallback fallback;

  const _Thumbnail({
    required this.tab,
    required this.rtl,
    required this.width,
    required this.height,
    required this.surface,
    this.snapshot,
    this.scope,
    this.fallback = PreviewFallback.liveRender,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: ClipRect(
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
              _buildLiveFallback(context),
            // sheen gradient
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.78, 1],
                    colors: [Colors.transparent, surface.withOpacity(0.7)],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveFallback(BuildContext context) {
    const designW = 940.0;
    final scale = width / designW;
    final align = rtl ? Alignment.topRight : Alignment.topLeft;
    Widget page = Container(
      width: designW,
      color: surface,
      padding: const EdgeInsets.all(20),
      child: tab.pageBuilder.call(context, tab),
    );
    if (scope != null) page = scope!(page);
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
          child: page,
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// DIRTY-CLOSE CONFIRM DIALOG
// ════════════════════════════════════════════════════════════

/// Shows a confirmation dialog when closing a tab with unsaved changes.
///
/// Returns `'discard'`, `'save'`, or `null` (cancel / Esc / backdrop tap).
///
/// Pass [localizations] to translate all dialog strings.
Future<String?> showSuperTabDirtyCloseDialog(
  BuildContext context,
  BrowserTab tab, {
  SuperTabBarLocalizations localizations = SuperTabBarLocalizations.en,
}) {
  return showGeneralDialog<String>(
    context: context,
    barrierDismissible: true,
    barrierLabel: localizations.cancel,
    barrierColor: const Color(0x61000000),
    transitionDuration: SuperTabBarThemeData.durSlow,
    pageBuilder: (ctx, a1, a2) => const SizedBox.shrink(),
    transitionBuilder: (ctx, anim, _, __) {
      final s = SuperTabBarThemeData.of(ctx);
      final curved =
          CurvedAnimation(parent: anim, curve: SuperTabBarThemeData.curveEmphasized);
      return FadeTransition(
        opacity: curved,
        child: Transform.scale(
          scale: 0.96 + 0.04 * curved.value,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 420),
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: s.surface,
                    border: Border.all(color: s.borderStrong),
                    borderRadius:
                        BorderRadius.circular(SuperTabBarThemeData.radiusXl),
                    boxShadow: SuperTabBarThemeData.popShadow,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: SuperTabBarThemeData.warning.withOpacity(0.14),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.warning_amber_rounded,
                              size: 18,
                              color: SuperTabBarThemeData.warning,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  localizations.discardChangesTitle,
                                  style: TextStyle(
                                    fontFamily: SuperTabBarThemeData.displayFont,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: s.fg1,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  localizations.dirtyTabBody(tab.title),
                                  style: TextStyle(
                                    fontFamily: SuperTabBarThemeData.bodyFont,
                                    fontSize: 13,
                                    height: 1.5,
                                    color: s.fg3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Wrap(
                        alignment: WrapAlignment.end,
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _DialogBtn(
                            label: localizations.cancel,
                            onTap: () => Navigator.of(ctx).pop(),
                          ),
                          _DialogBtn(
                            label: localizations.saveAndClose,
                            icon: Icons.save_outlined,
                            onTap: () => Navigator.of(ctx).pop('save'),
                          ),
                          _DialogBtn(
                            label: localizations.discardAndClose,
                            danger: true,
                            onTap: () => Navigator.of(ctx).pop('discard'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

/// Backward-compatible alias for [showSuperTabDirtyCloseDialog].
Future<String?> showGLDirtyCloseDialog(
  BuildContext context,
  BrowserTab tab, {
  SuperTabBarLocalizations localizations = SuperTabBarLocalizations.en,
}) =>
    showSuperTabDirtyCloseDialog(context, tab, localizations: localizations);

class _DialogBtn extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool danger;
  final VoidCallback onTap;
  const _DialogBtn({
    required this.label,
    this.icon,
    this.danger = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final s = SuperTabBarThemeData.of(context);
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: danger ? SuperTabBarThemeData.danger : Colors.transparent,
              border: Border.all(
                  color: danger ? Colors.transparent : s.borderStrong),
              borderRadius:
                  BorderRadius.circular(SuperTabBarThemeData.radiusMd),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 14, color: s.fg1),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: SuperTabBarThemeData.bodyFont,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: danger ? Colors.white : s.fg1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Enter animation for menus / popovers ──────────────────────
class _Appear extends StatefulWidget {
  final Widget child;
  const _Appear({required this.child});

  @override
  State<_Appear> createState() => _AppearState();
}

class _AppearState extends State<_Appear> {
  double _o = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _o = 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _o,
      duration: SuperTabBarThemeData.durFast,
      child: AnimatedSlide(
        offset: _o == 1 ? Offset.zero : const Offset(0, -0.02),
        duration: SuperTabBarThemeData.durFast,
        curve: SuperTabBarThemeData.curveDecelerate,
        child: widget.child,
      ),
    );
  }
}
