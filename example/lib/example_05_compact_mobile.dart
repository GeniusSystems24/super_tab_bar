// super_tab_bar · Example 05 — Compact mode (mobile tab switcher) (v2.5)
// ─────────────────────────────────────────────────────────────────
// Goal: show the phone-friendly compact workflow added in v2.1.
//
//   • SuperTabBar(compact: true)  → the horizontal strip is hidden; only the
//     active page shows, so it fits a narrow phone screen.
//   • A FloatingActionButton opens showSuperTabSwitcher() — a full-screen grid
//     of thumbnail previews of every open tab.
//       – Tap a thumbnail  → jump straight to that tab.
//       – Long-press-drag  → drop one thumbnail on another to reorder.
//       – Close (×)        → close a tab (dirty tabs ask first).
//   • SuperTabBar(closeTabOnBack: true) → the system back gesture closes the
//     current tab, but ONLY when it is not dirty. The "Back" button in the top
//     bar mirrors exactly what the OS back gesture does via that flag.
//
// The whole thing is wrapped in a phone frame so the compact layout is obvious
// on desktop / web as well as on a real device.

import 'package:flutter/material.dart';
import 'package:super_tab_bar/super_tab_bar.dart';

class CompactMobileExample extends StatefulWidget {
  const CompactMobileExample({super.key});
  @override
  State<CompactMobileExample> createState() => _CompactMobileExampleState();
}

class _CompactMobileExampleState extends State<CompactMobileExample> {
  final _ctrl = SuperTabBarController(
    tabs: [
      // v2.5: per-tab pageBuilder; falls back to GLTabPage when null.
      BrowserTab(id: 1, title: 'Inbox',
          pageBuilder: (ctx, tab) => GLTabPage(tab: tab)),
      BrowserTab(id: 2, title: 'Invoice INV-2043', dirty: true,
          pageBuilder: (ctx, tab) => GLTabPage(tab: tab)),
      BrowserTab(id: 3, title: 'Downtown Store',
          pageBuilder: (ctx, tab) => GLTabPage(tab: tab)),
      BrowserTab(id: 4, title: 'Sales Dashboard',
          pageBuilder: (ctx, tab) => GLTabPage(tab: tab)),
      BrowserTab(id: 5, title: 'Team Directory',
          pageBuilder: (ctx, tab) => GLTabPage(tab: tab)),
    ],
    activeId: 1,
  );

  String _log = 'Tap the grid button to open the switcher.';

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(_onCtrl);
  }

  void _onCtrl() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _ctrl.removeListener(_onCtrl);
    _ctrl.dispose();
    super.dispose();
  }

  // ── Dirty-aware close (shared by the switcher's × and the FAB flow) ──
  Future<void> _closeTab(int id) async {
    final tab = _ctrl.tabById(id);
    if (tab == null) return;
    if (tab.dirty) {
      final r = await showSuperTabDirtyCloseDialog(context, tab);
      if (r == 'discard') {
        _ctrl.close(id);
      } else if (r == 'save') {
        _ctrl.setDirty(id, false);
        _ctrl.close(id);
      }
    } else {
      _ctrl.close(id);
    }
  }

  Future<void> _openSwitcher() async {
    final picked = await showSuperTabSwitcher(
      context,
      controller: _ctrl,
      onCloseTab: _closeTab,
    );
    setState(() {
      _log = picked == null
          ? 'Switcher dismissed — no change.'
          : 'Switched to "${_ctrl.tabById(picked)?.title ?? picked}".';
    });
  }

  // Mirrors what the OS back gesture does automatically via closeTabOnBack.
  void _simulateBack() {
    final t = _ctrl.activeTab;
    if (t == null) {
      Navigator.of(context).maybePop();
      return;
    }
    if (t.dirty) {
      setState(() => _log =
          'Back ignored — "${t.title}" is dirty, so it stays open.');
    } else {
      _ctrl.close(t.id);
      setState(() => _log = 'Back closed "${t.title}" (not dirty).');
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = SuperTabBarThemeData.of(context);
    final active = _ctrl.activeTab;

    return Scaffold(
      backgroundColor: s.bg,
      appBar: AppBar(
        backgroundColor: s.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: s.fg1),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('05 · Compact mode',
            style: TextStyle(
                fontFamily: SuperTabBarThemeData.displayFont,
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: s.fg1)),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            children: [
              _PhoneFrame(
                child: Column(
                  children: [
                    // ── phone top bar ─────────────────────────
                    Container(
                      height: 52,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      color: s.surface,
                      child: Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.arrow_back, size: 20, color: s.fg2),
                            tooltip: 'Back (dirty-aware)',
                            onPressed: _simulateBack,
                          ),
                          Expanded(
                            child: Text(
                              active?.title ?? 'No tabs',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: SuperTabBarThemeData.displayFont,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: s.fg1,
                              ),
                            ),
                          ),
                          if (active != null)
                            _DirtyToggle(
                              dirty: active.dirty,
                              onTap: () =>
                                  _ctrl.setDirty(active.id, !active.dirty),
                            ),
                          _CountPill(count: _ctrl.length),
                          const SizedBox(width: 4),
                        ],
                      ),
                    ),
                    Divider(height: 1, color: s.border),
                    // ── compact tab bar (strip hidden) ────────
                    Expanded(
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: SuperTabBar(
                              controller: _ctrl,
                              compact: true,
                              closeTabOnBack: true,
                              showChrome: false,
                              fillContent: true,
                              scrollContent: true,
                            ),
                          ),
                          Positioned(
                            right: 16,
                            bottom: 16,
                            child: FloatingActionButton(
                              backgroundColor: SuperTabBarThemeData.accent,
                              onPressed: _openSwitcher,
                              tooltip: 'Open tab switcher',
                              child: const Icon(Icons.grid_view_rounded,
                                  color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // ── event log ─────────────────────────────────
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 390),
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: s.surface,
                    borderRadius:
                        BorderRadius.circular(SuperTabBarThemeData.radiusMd),
                    border: Border.all(color: s.border),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline,
                          size: 15, color: SuperTabBarThemeData.accent),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_log,
                            style: TextStyle(
                                fontFamily: SuperTabBarThemeData.bodyFont,
                                fontSize: 12.5,
                                color: s.fg2)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Phone frame ───────────────────────────────────────────────────
class _PhoneFrame extends StatelessWidget {
  final Widget child;
  const _PhoneFrame({required this.child});
  @override
  Widget build(BuildContext context) {
    final s = SuperTabBarThemeData.of(context);
    return Container(
      width: 390,
      height: 720,
      decoration: BoxDecoration(
        color: s.bg,
        borderRadius: BorderRadius.circular(36),
        border: Border.all(color: s.borderStrong, width: 8),
        boxShadow: SuperTabBarThemeData.cardShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

// ── Dirty toggle chip ─────────────────────────────────────────────
class _DirtyToggle extends StatelessWidget {
  final bool dirty;
  final VoidCallback onTap;
  const _DirtyToggle({required this.dirty, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final s = SuperTabBarThemeData.of(context);
    final c = dirty ? SuperTabBarThemeData.warning : s.fg3;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 4),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: c.withOpacity(0.12),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: c.withOpacity(0.4)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: c, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(dirty ? 'Dirty' : 'Clean',
              style: TextStyle(
                  fontFamily: SuperTabBarThemeData.monoFont,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: c)),
        ]),
      ),
    );
  }
}

// ── Count pill ────────────────────────────────────────────────────
class _CountPill extends StatelessWidget {
  final int count;
  const _CountPill({required this.count});
  @override
  Widget build(BuildContext context) {
    final s = SuperTabBarThemeData.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: s.inputBg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: s.border),
      ),
      child: Text('$count tabs',
          style: TextStyle(
              fontFamily: SuperTabBarThemeData.monoFont,
              fontSize: 10.5,
              color: s.fg3)),
    );
  }
}
