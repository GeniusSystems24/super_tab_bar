// super_tab_bar · Example app launcher
//
// A polished launcher: hero header + responsive card grid, each card carrying
// a live token-driven mini-preview of the tab strip it opens. Every example is
// a self-contained screen pushed with a floating "back to demos" button.

import 'package:flutter/material.dart';
import 'package:super_core/super_core.dart';
import 'package:super_tab_bar/super_tab_bar.dart';

import 'example_01_basic_workspace.dart';
import 'example_02_document_shell.dart';
import 'example_03_theme_rtl_overflow.dart';
import 'example_04_tab_behaviors.dart';
import 'example_05_compact_mobile.dart';
import 'browser_tabs_demo.dart';
import 'shell_kit.dart';

void main() => runApp(const ExampleApp());

class ExampleApp extends StatefulWidget {
  const ExampleApp({super.key});
  @override
  State<ExampleApp> createState() => _ExampleAppState();
}

class _ExampleAppState extends State<ExampleApp> {
  bool _dark = true;

  @override
  Widget build(BuildContext context) {
    final t = _dark
        ? SuperMaterialThemeData.dark(
            palette: SuperPalette.purplePalette
          )
        : SuperMaterialThemeData.light(
            palette: SuperPalette.purplePalette
          );
    return MaterialApp(
      title: 'super_tab_bar examples',
      debugShowCheckedModeBanner: false,
      theme: t.copyWith(
        extensions: [SuperTabBarThemeData.fromMaterialTheme(t)],
      ),
      darkTheme: t.copyWith(
        extensions: [SuperTabBarThemeData.fromMaterialTheme(t)],
      ),
      themeMode: _dark ? ThemeMode.dark : ThemeMode.light,
      home: LauncherScreen(
        dark: _dark,
        onToggleTheme: (v) => setState(() => _dark = v),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// LAUNCHER
// ════════════════════════════════════════════════════════════
class LauncherScreen extends StatelessWidget {
  final bool dark;
  final ValueChanged<bool> onToggleTheme;
  const LauncherScreen(
      {super.key, required this.dark, required this.onToggleTheme});

  @override
  Widget build(BuildContext context) {
    final s = SuperTabBarThemeData.of(context);

    final demos = <_Demo>[
      _Demo(
        title: 'Basic workspace',
        subtitle:
            'Four stateful tabs — counter + text field + scroll list. Toggle '
            'Keep-alive vs Rebuild and LTR/RTL to watch state survive (or reset).',
        badge: 'State preservation',
        preview: const _TabThumb(
          labels: ['Accounts', 'Journal', 'Dashboard', 'Team'],
          activeIndex: 1,
          contentKind: _Content.list,
        ),
        screen: const BasicWorkspaceExample(),
      ),
      _Demo(
        title: 'Document management shell',
        subtitle:
            'ERP-style shell: requiredPinned Chart of Accounts (no close/unpin in UI), '
            'dirty Journal Entry with save flow, open-from-row via of(context), '
            'and live onTab* event callbacks.',
        badge: 'requiredPinned · dirty · callbacks',
        preview: const _TabThumb(
          labels: ['Journal', 'Dashboard'],
          activeIndex: 0,
          pinned: true,
          dirty: {0},
          contentKind: _Content.form,
        ),
        screen: const DocumentShellExample(),
      ),
      _Demo(
        title: 'Custom theme + RTL + overflow',
        subtitle:
            'copyWith a warm palette, toggle Dark/Light and LTR/RTL, force overflow, '
            'and configure SuperTabBarPreviewOptions and SuperTabBarLocalizations (EN/AR) live.',
        badge: 'Theming · RTL · Previews · L10n',
        preview: const _TabThumb(
          labels: ['One', 'Two', 'Three', 'Four', 'Five'],
          activeIndex: 2,
          overflow: true,
          warm: true,
          contentKind: _Content.cards,
        ),
        screen: const ThemeRtlOverflowExample(),
      ),
      _Demo(
        title: 'Full component workbench',
        subtitle:
            'The original showcase — pin, drag-reorder, dirty-close guard, '
            'overflow, live hover thumbnails across ERP / Design Studio / Browser themes.',
        badge: 'Original',
        preview: const _TabThumb(
          labels: ['Ledger', 'Journal', 'Store'],
          activeIndex: 1,
          pinned: true,
          preview: true,
          contentKind: _Content.list,
        ),
        screen: const _OriginalDemo(),
      ),
      _Demo(
        title: 'Tab behaviors + callbacks',
        subtitle: 'requiredPinned tabs that cannot be closed or unpinned, '
            'uniqueNormal tabs that deduplicate on re-open, and a live '
            'event log showing all seven direct callbacks.',
        badge: 'v2 · Behaviors · Callbacks',
        preview: const _TabThumb(
          labels: ['Home', 'Settings', 'Dashboard'],
          activeIndex: 2,
          pinned: true,
          contentKind: _Content.list,
        ),
        screen: const TabBehaviorsExample(),
      ),
      _Demo(
        title: 'Compact mode (mobile)',
        subtitle:
            'Strip hidden for phones. A FloatingActionButton opens a full-screen '
            'grid of tab thumbnails — tap to switch, drag to reorder. Back closes '
            'the current tab only when it is not dirty.',
        badge: 'v2.5 · Compact · Switcher · Back',
        preview: const _TabThumb(
          labels: ['Inbox', 'Invoice', 'Store', 'Dashboard'],
          activeIndex: 0,
          dirty: {1},
          contentKind: _Content.cards,
        ),
        screen: const CompactMobileExample(),
      ),
    ];

    return Scaffold(
      backgroundColor: s.bg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1040),
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 44),
              children: [
                // ── hero ──────────────────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            _Mark(),
                            const SizedBox(width: 12),
                            Text('SUPER_TAB_BAR',
                                style: TextStyle(
                                    fontFamily: SuperTabBarThemeData.monoFont,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.8,
                                    color: SuperTabBarThemeData.accent)),
                            const SizedBox(width: 10),
                            _VersionPill(),
                          ]),
                          const SizedBox(height: 16),
                          Text('Browser-style workspace tabs',
                              style: TextStyle(
                                  fontFamily: SuperTabBarThemeData.displayFont,
                                  fontSize: 34,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.8,
                                  height: 1.05,
                                  color: s.fg1)),
                          const SizedBox(height: 12),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 640),
                            child: Text(
                              'Pinned / dirty / closable tabs, drag-to-reorder, '
                              'context menu, overflow dropdown, live hover '
                              'previews, and state-preserving pages. Open any '
                              'example to try it live in Light / Dark and LTR / RTL.',
                              style: TextStyle(
                                  fontFamily: SuperTabBarThemeData.bodyFont,
                                  fontSize: 14.5,
                                  height: 1.6,
                                  color: s.fg3),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _ThemeToggle(dark: dark, onToggle: onToggleTheme),
                  ],
                ),
                const SizedBox(height: 36),
                // ── grid ──────────────────────────────────────
                LayoutBuilder(builder: (context, c) {
                  final cols = c.maxWidth > 720 ? 2 : 1;
                  return GridView.count(
                    crossAxisCount: cols,
                    crossAxisSpacing: 18,
                    mainAxisSpacing: 18,
                    childAspectRatio: 1.42,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      for (var i = 0; i < demos.length; i++)
                        _DemoCard(
                          index: i + 1,
                          demo: demos[i],
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) =>
                                    _BackScaffold(child: demos[i].screen)),
                          ),
                        ),
                    ],
                  );
                }),
                const SizedBox(height: 24),
                Center(
                  child: Text(
                      'MIT © GeniusSystems24 · pure Flutter, zero dependencies',
                      style: TextStyle(
                          fontFamily: SuperTabBarThemeData.monoFont,
                          fontSize: 11,
                          color: s.fg4)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Demo {
  final String title, subtitle, badge;
  final Widget preview;
  final Widget screen;
  const _Demo({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.preview,
    required this.screen,
  });
}

// ── Demo card ─────────────────────────────────────────────────────
class _DemoCard extends StatefulWidget {
  final int index;
  final _Demo demo;
  final VoidCallback onTap;
  const _DemoCard(
      {required this.index, required this.demo, required this.onTap});
  @override
  State<_DemoCard> createState() => _DemoCardState();
}

class _DemoCardState extends State<_DemoCard> {
  bool _h = false;
  @override
  Widget build(BuildContext context) {
    final s = SuperTabBarThemeData.of(context);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: SuperTabBarThemeData.durBase,
          curve: SuperTabBarThemeData.curveStandard,
          transform: _h
              ? (Matrix4.identity()..translate(0.0, -4.0))
              : Matrix4.identity(),
          decoration: BoxDecoration(
            color: s.surface,
            border: Border.all(
                color: _h
                    ? SuperTabBarThemeData.accent.withOpacity(0.55)
                    : s.border),
            borderRadius: BorderRadius.circular(SuperTabBarThemeData.radiusXl),
            boxShadow: _h ? SuperTabBarThemeData.cardShadow : null,
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // preview pane
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(child: widget.demo.preview),
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        width: 24,
                        height: 24,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: s.bg.withOpacity(0.82),
                          borderRadius: BorderRadius.circular(7),
                          border: Border.all(color: s.border),
                        ),
                        child: Text('0${widget.index}',
                            style: TextStyle(
                                fontFamily: SuperTabBarThemeData.monoFont,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: s.fg2)),
                      ),
                    ),
                  ],
                ),
              ),
              // text
              Container(
                decoration: BoxDecoration(
                  color: s.surface,
                  border: Border(top: BorderSide(color: s.border)),
                ),
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                        child: Text(widget.demo.title,
                            style: TextStyle(
                                fontFamily: SuperTabBarThemeData.displayFont,
                                fontSize: 16.5,
                                fontWeight: FontWeight.w700,
                                color: s.fg1)),
                      ),
                      Icon(Icons.arrow_outward,
                          size: 16,
                          color: _h ? SuperTabBarThemeData.accent : s.fg3),
                    ]),
                    const SizedBox(height: 6),
                    Text(widget.demo.subtitle,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontFamily: SuperTabBarThemeData.bodyFont,
                            fontSize: 12.5,
                            height: 1.5,
                            color: s.fg3)),
                    const SizedBox(height: 10),
                    _TagPill(widget.demo.badge),
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

// ════════════════════════════════════════════════════════════
// MINI TAB-STRIP PREVIEW (token-driven; reflects dark/light)
// ════════════════════════════════════════════════════════════
enum _Content { list, form, cards }

class _TabThumb extends StatelessWidget {
  final List<String> labels;
  final int activeIndex;
  final bool pinned;
  final Set<int> dirty;
  final bool overflow;
  final bool preview;
  final bool warm;
  final _Content contentKind;
  const _TabThumb({
    required this.labels,
    required this.activeIndex,
    this.pinned = false,
    this.dirty = const {},
    this.overflow = false,
    this.preview = false,
    this.warm = false,
    this.contentKind = _Content.list,
  });

  @override
  Widget build(BuildContext context) {
    final base = SuperTabBarThemeData.of(context);
    // A warm-tinted variant for the theming demo, else the live theme.
    final s = warm
        ? base.copyWith(
            bg: const Color(0xFFF3EEE7),
            surface: const Color(0xFFFFFFFF),
            inputBg: const Color(0xFFEAE3D9),
            hover: const Color(0xFFEAE3D9),
            border: const Color(0xFFDED7CB),
            fg1: const Color(0xFF231F1A),
            fg3: const Color(0xFF8A8175),
          )
        : base;
    const accent = SuperTabBarThemeData.accent;

    Widget tab(int i) {
      final active = i == activeIndex;
      return Container(
        height: 22,
        constraints: const BoxConstraints(maxWidth: 78),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        margin: EdgeInsets.only(left: i == 0 ? 0 : 3),
        decoration: BoxDecoration(
          color: active ? s.surface : Colors.transparent,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.description_outlined,
              size: 9, color: active ? accent : s.fg3),
          const SizedBox(width: 5),
          Flexible(
            child: Text(labels[i],
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontFamily: SuperTabBarThemeData.bodyFont,
                    fontSize: 9.5,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    color: active ? s.fg1 : s.fg3)),
          ),
          if (dirty.contains(i)) ...[
            const SizedBox(width: 5),
            Container(
                width: 5,
                height: 5,
                decoration: const BoxDecoration(
                    color: SuperTabBarThemeData.warning,
                    shape: BoxShape.circle)),
          ],
        ]),
      );
    }

    return Container(
      color: s.bg,
      child: Column(children: [
        // strip
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
          child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            if (pinned) ...[
              Container(
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: s.surface,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(6)),
                ),
                child: const Icon(Icons.push_pin, size: 9, color: accent),
              ),
              Container(
                  width: 1,
                  height: 14,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  color: s.borderStrong),
            ],
            Expanded(
              child: ClipRect(
                child: Row(
                    children: [for (var i = 0; i < labels.length; i++) tab(i)]),
              ),
            ),
            if (overflow) Icon(Icons.chevron_right, size: 13, color: s.fg3),
            const SizedBox(width: 2),
            Icon(Icons.add, size: 12, color: s.fg3),
            const SizedBox(width: 2),
            Icon(Icons.expand_more, size: 12, color: s.fg3),
          ]),
        ),
        // content surface
        Expanded(
          child: Container(
            margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            decoration: BoxDecoration(
              color: s.surface,
              borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(6), top: Radius.circular(2)),
              border: Border.all(color: s.border),
            ),
            padding: const EdgeInsets.all(11),
            child: _content(s),
          ),
        ),
      ]),
    );
  }

  Widget _content(SuperTabBarThemeData s) {
    Widget bar(double w, {Color? c, double h = 6}) => Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
            color: c ?? s.inputBg, borderRadius: BorderRadius.circular(3)));

    switch (contentKind) {
      case _Content.form:
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          bar(70, c: s.fg1, h: 8),
          const SizedBox(height: 10),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: s.bg,
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: s.border),
              ),
              padding: const EdgeInsets.all(8),
              child: Column(children: [
                bar(double.infinity, h: 5),
                const SizedBox(height: 6),
                bar(double.infinity, h: 5),
                const SizedBox(height: 6),
                bar(120, h: 5),
              ]),
            ),
          ),
        ]);
      case _Content.cards:
        return Column(children: [
          Row(children: [
            for (var i = 0; i < 3; i++) ...[
              if (i > 0) const SizedBox(width: 6),
              Expanded(
                child: Container(
                  height: 26,
                  decoration: BoxDecoration(
                    color: s.bg,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: s.border),
                  ),
                ),
              ),
            ],
          ]),
          const SizedBox(height: 7),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: s.bg,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: s.border),
              ),
            ),
          ),
        ]);
      case _Content.list:
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          bar(70, c: s.fg1, h: 8),
          const SizedBox(height: 9),
          for (var i = 0; i < 4; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(children: [
                bar(26, h: 5),
                const SizedBox(width: 8),
                Expanded(child: bar(double.infinity, h: 5)),
                const SizedBox(width: 8),
                bar(30, c: SuperTabBarThemeData.accent.withOpacity(0.5), h: 5),
              ]),
            ),
        ]);
    }
  }
}

// ── small shared bits ─────────────────────────────────────────────
class _Mark extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: SuperTabBarThemeData.accent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.tab_rounded, size: 17, color: Colors.white),
    );
  }
}

class _VersionPill extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: SuperTabBarThemeData.accent.withOpacity(0.13),
        borderRadius: BorderRadius.circular(999),
        border:
            Border.all(color: SuperTabBarThemeData.accent.withOpacity(0.35)),
      ),
      child: const Text('v2.5.0',
          style: TextStyle(
              fontFamily: SuperTabBarThemeData.monoFont,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: SuperTabBarThemeData.accent)),
    );
  }
}

class _TagPill extends StatelessWidget {
  final String text;
  const _TagPill(this.text);
  @override
  Widget build(BuildContext context) {
    final s = SuperTabBarThemeData.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: s.inputBg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: s.border),
      ),
      child: Text(text,
          style: TextStyle(
              fontFamily: SuperTabBarThemeData.monoFont,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
              color: s.fg3)),
    );
  }
}

class _ThemeToggle extends StatelessWidget {
  final bool dark;
  final ValueChanged<bool> onToggle;
  const _ThemeToggle({required this.dark, required this.onToggle});
  @override
  Widget build(BuildContext context) {
    final s = SuperTabBarThemeData.of(context);
    return GestureDetector(
      onTap: () => onToggle(!dark),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: s.surface,
            border: Border.all(color: s.borderStrong),
            borderRadius: BorderRadius.circular(SuperTabBarThemeData.radiusMd),
          ),
          child: Row(children: [
            Icon(dark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                size: 15, color: s.fg2),
            const SizedBox(width: 8),
            Text(dark ? 'Dark' : 'Light',
                style: TextStyle(
                    fontFamily: SuperTabBarThemeData.bodyFont,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: s.fg1)),
          ]),
        ),
      ),
    );
  }
}

// ── floating "back to demos" wrapper for a pushed screen ──────────
class _BackScaffold extends StatelessWidget {
  final Widget child;
  const _BackScaffold({required this.child});
  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Positioned.fill(child: child),
      Positioned(
        left: 16,
        bottom: 16,
        child: SafeArea(
          child: Material(
            color: Colors.black.withOpacity(0.62),
            borderRadius: BorderRadius.circular(999),
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: () => Navigator.of(context).maybePop(),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.arrow_back, size: 16, color: Colors.white),
                  SizedBox(width: 7),
                  Text('Demos',
                      style: TextStyle(
                          fontFamily: SuperTabBarThemeData.bodyFont,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white)),
                ]),
              ),
            ),
          ),
        ),
      ),
    ]);
  }
}

// ── Wrapper for the original BrowserTabsDemo from the monorepo ────
class _OriginalDemo extends StatefulWidget {
  const _OriginalDemo();
  @override
  State<_OriginalDemo> createState() => _OriginalDemoState();
}

class _OriginalDemoState extends State<_OriginalDemo> {
  bool _light = false;
  @override
  Widget build(BuildContext context) {
    return themed(
      brightness: _light ? Brightness.light : Brightness.dark,
      ext: _light ? SuperTabBarThemeData.light : SuperTabBarThemeData.dark,
      child: BrowserTabsDemo(
        light: _light,
        onToggleTheme: (v) => setState(() => _light = v),
      ),
    );
  }
}
