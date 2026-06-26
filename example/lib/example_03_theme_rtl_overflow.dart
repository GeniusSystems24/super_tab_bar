// super_tab_bar · Example 03 — Custom theme + RTL + overflow + previews + l10n
// ─────────────────────────────────────────────────────────────────
// Goal: demonstrate v2 configuration surface:
//
//   • Three themes (Dark / Light / Warm) via SuperTabBarThemeData.copyWith
//   • LTR / RTL via Directionality
//   • Overflow: add up to 20 tabs to force chevrons and ▾ dropdown
//   • showChrome toggle (card vs edge-to-edge)
//   • SuperTabBarPreviewOptions: On / Off / Instant (0 ms delay)
//   • SuperTabBarLocalizations: English / Arabic built-in presets
//
//   Annotated comments explain every field changed in copyWith.

import 'package:flutter/material.dart';
import 'package:super_tab_bar/super_tab_bar.dart';

class ThemeRtlOverflowExample extends StatefulWidget {
  const ThemeRtlOverflowExample({super.key});
  @override
  State<ThemeRtlOverflowExample> createState() =>
      _ThemeRtlOverflowExampleState();
}

enum _ThemeChoice { dark, light, warm }

class _ThemeRtlOverflowExampleState
    extends State<ThemeRtlOverflowExample> {
  _ThemeChoice _theme = _ThemeChoice.dark;
  bool _rtl = false;
  bool _showChrome = true;
  bool _previewEnabled = true;
  bool _previewInstant = false;
  bool _arabic = false;

  int _nextId = 6;

  late final SuperTabBarController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = SuperTabBarController(
      tabs: const [
        BrowserTab(id: 1, title: 'Accounts', kind: GLTabKind.ledger, pinned: true),
        BrowserTab(id: 2, title: 'Journal Entry', kind: GLTabKind.doc),
        BrowserTab(id: 3, title: 'Dashboard', kind: GLTabKind.chart),
        BrowserTab(id: 4, title: 'Team', kind: GLTabKind.user),
        BrowserTab(id: 5, title: 'Store', kind: GLTabKind.store),
      ],
      activeId: 3,
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  // ── Theme definitions ─────────────────────────────────────────
  static SuperTabBarThemeData _themeData(_ThemeChoice c) {
    switch (c) {
      case _ThemeChoice.dark:
        return SuperTabBarThemeData.dark;

      case _ThemeChoice.light:
        return SuperTabBarThemeData.light;

      case _ThemeChoice.warm:
        // Warm custom theme — every field explained:
        return SuperTabBarThemeData.light.copyWith(
          // bg: the strip container and page base — a warm parchment tone
          bg: const Color(0xFFF7F3EE),
          // surface: active-tab content card — pure white
          surface: const Color(0xFFFFFFFF),
          // surface2: nested card inside the content
          surface2: const Color(0xFFFAF8F5),
          // inputBg: close-button hover / input fill — light warm grey
          inputBg: const Color(0xFFEEE9E2),
          // hover: tab hover tint
          hover: const Color(0xFFEAE4DB),
          // border: hairline dividers
          border: const Color(0xFFDDD7CE),
          // borderStrong: solid dividers / pop-card edge
          borderStrong: const Color(0xFFBBB4A8),
          // fg1–fg4: text ramp — warm dark to warm muted
          fg1: const Color(0xFF1A1714),
          fg2: const Color(0xFF3D3830),
          fg3: const Color(0xFF7A7268),
          fg4: const Color(0xFFBBB4A8),
        );
        // Note: accent, success, warning, danger are STATIC consts on the
        // class — they cannot be changed via copyWith. To use a different
        // accent you would subclass SuperTabBarThemeData or set
        // a custom accent at the app-theme level.
    }
  }

  void _addTab() {
    if (_ctrl.length >= 20) return;
    final kinds = GLTabKind.values;
    _ctrl.add(
      title: 'Tab ${_nextId}',
      kind: kinds[_nextId % kinds.length],
    );
    _nextId++;
  }

  @override
  Widget build(BuildContext context) {
    final themeData = _themeData(_theme);

    // Inject the chosen theme into the subtree so SuperTabBarThemeData.of
    // picks it up — this is the standard ThemeExtension registration pattern.
    return Theme(
      data: Theme.of(context).copyWith(extensions: [themeData]),
      child: Builder(builder: (ctx) {
        final s = SuperTabBarThemeData.of(ctx);
        return Scaffold(
          backgroundColor: s.bg,
          appBar: AppBar(
            backgroundColor: s.surface,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: s.fg1),
              onPressed: () => Navigator.pop(ctx),
            ),
            title: Text('03 · Theme + RTL + overflow',
                style: TextStyle(
                    fontFamily: SuperTabBarThemeData.displayFont,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: s.fg1)),
          ),
          body: Column(children: [
            // ── controls bar ──────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: s.surface,
                border: Border(bottom: BorderSide(color: s.border)),
              ),
              child: Wrap(
                spacing: 10,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  // Theme picker
                  _SegmentedToggle(
                    options: const ['Dark', 'Light', 'Warm ✦'],
                    selected: _theme.index,
                    onChanged: (i) =>
                        setState(() => _theme = _ThemeChoice.values[i]),
                  ),
                  // LTR / RTL
                  _SegmentedToggle(
                    options: const ['LTR', 'RTL'],
                    selected: _rtl ? 1 : 0,
                    onChanged: (i) => setState(() => _rtl = i == 1),
                  ),
                  // showChrome toggle
                  _SegmentedToggle(
                    options: const ['Chrome', 'Edge-to-edge'],
                    selected: _showChrome ? 0 : 1,
                    onChanged: (i) =>
                        setState(() => _showChrome = i == 0),
                  ),
                  // Preview options (v2)
                  _SegmentedToggle(
                    options: const ['Preview On', 'Instant', 'Preview Off'],
                    selected: !_previewEnabled ? 2 : (_previewInstant ? 1 : 0),
                    onChanged: (i) => setState(() {
                      _previewEnabled = i != 2;
                      _previewInstant = i == 1;
                    }),
                  ),
                  // Localizations (v2)
                  _SegmentedToggle(
                    options: const ['EN', 'AR عربي'],
                    selected: _arabic ? 1 : 0,
                    onChanged: (i) => setState(() => _arabic = i == 1),
                  ),
                  // Add tab button
                  GestureDetector(
                    onTap: _addTab,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: SuperTabBarThemeData.accent
                            .withOpacity(0.12),
                        border: Border.all(
                            color: SuperTabBarThemeData.accent
                                .withOpacity(0.4)),
                        borderRadius: BorderRadius.circular(
                            SuperTabBarThemeData.radiusMd),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.add,
                            size: 14,
                            color: SuperTabBarThemeData.accent),
                        const SizedBox(width: 6),
                        Text(
                          'Add tab (${_ctrl.length}/20)',
                          style: const TextStyle(
                              fontFamily:
                                  SuperTabBarThemeData.bodyFont,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: SuperTabBarThemeData.accent),
                        ),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
            // ── theme legend ──────────────────────────────────
            if (_theme == _ThemeChoice.warm)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                color: s.surface,
                child: Text(
                  '✦ Warm theme — '
                  'bg #F7F3EE · surface #FFF · inputBg #EEE9E2 · '
                  'border #DDD7CE · fg1 #1A1714 · fg3 #7A7268',
                  style: TextStyle(
                      fontFamily: SuperTabBarThemeData.monoFont,
                      fontSize: 11,
                      color: s.fg3),
                ),
              ),
            // ── preview / l10n info bar ───────────────────────
            AnimatedContainer(
              duration: SuperTabBarThemeData.durBase,
              height: (!_previewEnabled || _previewInstant || _arabic) ? 30 : 0,
              color: s.surface,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                  color: s.surface,
                  border: Border(bottom: BorderSide(color: s.border))),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(children: [
                  if (_arabic)
                    _InfoChip('SuperTabBarLocalizations.ar',
                        SuperTabBarThemeData.accent),
                  if (_previewInstant)
                    _InfoChip(
                        'SuperTabBarPreviewOptions(hoverDelay: Duration.zero)',
                        SuperTabBarThemeData.success),
                  if (!_previewEnabled)
                    _InfoChip('SuperTabBarPreviewOptions.disabled',
                        SuperTabBarThemeData.danger),
                ]),
              ),
            ),
            // ── tab bar ───────────────────────────────────────
            Expanded(
              child: Directionality(
                textDirection:
                    _rtl ? TextDirection.rtl : TextDirection.ltr,
                child: SuperTabBar(
                  controller: _ctrl,
                  showChrome: _showChrome,
                  fillContent: true,
                  scrollContent: false,
                  // v2: localizations
                  localizations: _arabic
                      ? SuperTabBarLocalizations.ar
                      : SuperTabBarLocalizations.en,
                  // v2: preview options
                  previewOptions: !_previewEnabled
                      ? SuperTabBarPreviewOptions.disabled
                      : _previewInstant
                          ? const SuperTabBarPreviewOptions(
                              hoverDelay: Duration.zero)
                          : SuperTabBarPreviewOptions.defaults,
                ),
              ),
            ),
          ]),
        );
      }),
    );
  }
}

// ── Info chip ─────────────────────────────────────────────────────
class _InfoChip extends StatelessWidget {
  final String text;
  final Color color;
  const _InfoChip(this.text, this.color);
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.30)),
      ),
      child: Text(text,
          style: TextStyle(
            fontFamily: SuperTabBarThemeData.monoFont,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: color,
          )),
    );
  }
}

// ── Segmented toggle (shared with example 01) ─────────────────────
class _SegmentedToggle extends StatelessWidget {
  final List<String> options;
  final int selected;
  final ValueChanged<int> onChanged;
  const _SegmentedToggle(
      {required this.options,
      required this.selected,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final s = SuperTabBarThemeData.of(context);
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: s.inputBg,
        border: Border.all(color: s.border),
        borderRadius:
            BorderRadius.circular(SuperTabBarThemeData.radiusMd),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(options.length, (i) {
          final active = i == selected;
          return GestureDetector(
            onTap: () => onChanged(i),
            child: AnimatedContainer(
              duration: SuperTabBarThemeData.durFast,
              padding: const EdgeInsets.symmetric(
                  horizontal: 11, vertical: 7),
              decoration: BoxDecoration(
                color: active
                    ? SuperTabBarThemeData.accent
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(
                    SuperTabBarThemeData.radiusSm),
              ),
              child: Text(options[i],
                  style: TextStyle(
                      fontFamily: SuperTabBarThemeData.bodyFont,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: active ? Colors.white : s.fg2)),
            ),
          );
        }),
      ),
    );
  }
}
