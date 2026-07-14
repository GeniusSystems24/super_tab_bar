// super_tab_bar · Example 04 — Tab behavior types + event callbacks (v2.5)
// ─────────────────────────────────────────────────────────────────
// Demonstrates the three [SuperTabBehavior] variants introduced in v2:
//
//   requiredPinned — always pinned; no close / unpin / duplicate in UI.
//                   Right-click to confirm: only "Close others" is offered.
//   normal         — standard tab; all operations available.
//   uniqueNormal   — no duplicate; tapping "Open Settings" a second time
//                   activates the existing Settings tab rather than cloning it.
//
// All eight event callbacks are shown in a scrollable log panel at the bottom.

import 'package:flutter/material.dart';
import 'package:super_tab_bar/super_tab_bar.dart';

class TabBehaviorsExample extends StatefulWidget {
  const TabBehaviorsExample({super.key});
  @override
  State<TabBehaviorsExample> createState() => _TabBehaviorsExampleState();
}

class _TabBehaviorsExampleState extends State<TabBehaviorsExample> {
  static const _settingsKey = 'settings';

  late final SuperTabBarController _ctrl;
  final List<_LogEntry> _log = [];
  int _nextId = 10;

  @override
  void initState() {
    super.initState();
    _ctrl = SuperTabBarController(
      tabs: [
        // requiredPinned — always visible, cannot be closed/unpinned from UI
        BrowserTab(
          id: 1,
          title: 'Home',
          pinned: true,
          behavior: SuperTabBehavior.requiredPinned,
          pageBuilder: (ctx, tab) => _BehaviorPage(tab: tab),
        ),
        // uniqueNormal — deduplicates on re-open
        BrowserTab(
          id: 2,
          title: 'Settings',
          behavior: SuperTabBehavior.uniqueNormal,
          uniqueKey: _settingsKey,
          leading: const Icon(Icons.settings_outlined, size: 14),
          pageBuilder: (ctx, tab) => _BehaviorPage(tab: tab),
        ),
        // normal — standard behavior
        BrowserTab(id: 3, title: 'Dashboard',
            pageBuilder: (ctx, tab) => _BehaviorPage(tab: tab)),
        BrowserTab(id: 4, title: 'Accounts',
            pageBuilder: (ctx, tab) => _BehaviorPage(tab: tab)),
      ],
      activeId: 3,
    );

    // Controller-level callbacks for dirty/rename (fire from page content too)
    _ctrl.onDirtyChanged = (id, dirty) =>
        _addLog('onDirtyChanged', 'tab $id → dirty=$dirty');
    _ctrl.onRenamed = (id, title) =>
        _addLog('onRenamed', 'tab $id → "$title"');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _addLog(String event, String detail) {
    setState(() {
      _log.insert(0, _LogEntry(event: event, detail: detail));
      if (_log.length > 40) _log.removeLast();
    });
  }

  void _openSettings() {
    // add() with uniqueKey will select the existing tab if one exists.
    _ctrl.add(
      title: 'Settings',
      behavior: SuperTabBehavior.uniqueNormal,
      uniqueKey: _settingsKey,
      leading: const Icon(Icons.settings_outlined, size: 14),
      pageBuilder: (ctx, tab) => _BehaviorPage(tab: tab),
    );
  }

  void _addNormalTab() {
    _nextId++;
    _ctrl.add(
      title: 'Doc #$_nextId',
      pageBuilder: (ctx, tab) => _BehaviorPage(tab: tab),
    );
  }

  void _markDirty() {
    final id = _ctrl.activeId;
    if (id == null) return;
    _ctrl.setDirty(id, !(_ctrl.tabById(id)?.dirty ?? false));
  }

  @override
  Widget build(BuildContext context) {
    final s = SuperTabBarThemeData.of(context);
    return Scaffold(
      backgroundColor: s.bg,
      appBar: AppBar(
        backgroundColor: s.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: s.fg1),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '04 · Tab behaviors + callbacks',
          style: TextStyle(
            fontFamily: SuperTabBarThemeData.displayFont,
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: s.fg1,
          ),
        ),
      ),
      body: Column(
        children: [
          // ── Controls bar ─────────────────────────────────
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: s.surface,
              border: Border(bottom: BorderSide(color: s.border)),
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _ActionBtn(
                  label: 'Open Settings',
                  subtitle: 'uniqueNormal — deduplicates',
                  icon: Icons.settings_outlined,
                  color: SuperTabBarThemeData.accent,
                  onTap: _openSettings,
                ),
                _ActionBtn(
                  label: 'Add normal tab',
                  subtitle: 'normal — standard',
                  icon: Icons.add_circle_outline,
                  color: SuperTabBarThemeData.success,
                  onTap: _addNormalTab,
                ),
                _ActionBtn(
                  label: 'Toggle dirty',
                  subtitle: 'active tab',
                  icon: Icons.edit_outlined,
                  color: SuperTabBarThemeData.warning,
                  onTap: _markDirty,
                ),
              ],
            ),
          ),
          // ── Behavior legend ──────────────────────────────
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: s.bg,
            child: Wrap(
              spacing: 12,
              runSpacing: 6,
              children: [
                _LegendChip(
                  color: SuperTabBarThemeData.danger,
                  label: 'requiredPinned',
                  desc: 'always pinned — no close / unpin / duplicate in UI',
                ),
                _LegendChip(
                  color: SuperTabBarThemeData.accent,
                  label: 'uniqueNormal',
                  desc: 'no duplicate — re-open selects existing',
                ),
                _LegendChip(
                  color: SuperTabBarThemeData.success,
                  label: 'normal',
                  desc: 'close · duplicate · pin · unpin all available',
                ),
              ],
            ),
          ),
          // ── Tab bar ──────────────────────────────────────
          Expanded(
            flex: 3,
            child: SuperTabBar(
              controller: _ctrl,
              fillContent: true,
              scrollContent: false,
              showChrome: false,
              // v2.5: the + button is only shown when onAddTab is non-null.
              onAddTab: _addNormalTab,
              // ── Direct callbacks ─────────────────────────
              onTabSelected: (id) =>
                  _addLog('onTabSelected', 'id=$id'),
              onTabAdded: (id) =>
                  _addLog('onTabAdded', 'id=$id'),
              onTabClosed: (id) =>
                  _addLog('onTabClosed', 'id=$id'),
              onTabDuplicated: (newId) =>
                  _addLog('onTabDuplicated', 'newId=$newId'),
              onTabPinChanged: (id, pin) =>
                  _addLog('onTabPinChanged', 'id=$id → pinned=$pin'),
              onTabDirtyChanged: (id, dirty) =>
                  _addLog('onTabDirtyChanged', 'id=$id → dirty=$dirty (save-close)'),
              onTabReordered: (from, to) =>
                  _addLog('onTabReordered', 'from=$from → to=$to'),
            ),
          ),
          // ── Event log ────────────────────────────────────
          Container(
            height: 180,
            decoration: BoxDecoration(
              color: s.surface,
              border: Border(top: BorderSide(color: s.border)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: s.border))),
                  child: Row(children: [
                    Icon(Icons.receipt_long_outlined,
                        size: 14, color: s.fg3),
                    const SizedBox(width: 7),
                    Text(
                      'EVENT LOG',
                      style: TextStyle(
                        fontFamily: SuperTabBarThemeData.monoFont,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.9,
                        color: s.fg3,
                      ),
                    ),
                    const Spacer(),
                    if (_log.isNotEmpty)
                      GestureDetector(
                        onTap: () => setState(() => _log.clear()),
                        child: Text(
                          'Clear',
                          style: TextStyle(
                            fontFamily: SuperTabBarThemeData.bodyFont,
                            fontSize: 11,
                            color: SuperTabBarThemeData.accent,
                          ),
                        ),
                      ),
                  ]),
                ),
                Expanded(
                  child: _log.isEmpty
                      ? Center(
                          child: Text(
                            'Interact with the tab bar to see events here.',
                            style: TextStyle(
                              fontFamily: SuperTabBarThemeData.bodyFont,
                              fontSize: 12,
                              color: s.fg4,
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding:
                              const EdgeInsets.symmetric(vertical: 4),
                          itemCount: _log.length,
                          itemBuilder: (_, i) {
                            final e = _log[i];
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 3),
                              child: Row(children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: SuperTabBarThemeData.accent
                                        .withOpacity(0.12),
                                    borderRadius:
                                        BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    e.event,
                                    style: TextStyle(
                                      fontFamily:
                                          SuperTabBarThemeData.monoFont,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: SuperTabBarThemeData.accent,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    e.detail,
                                    style: TextStyle(
                                      fontFamily:
                                          SuperTabBarThemeData.monoFont,
                                      fontSize: 11,
                                      color: s.fg2,
                                    ),
                                  ),
                                ),
                              ]),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tab page showing behavior info ────────────────────────────────
class _BehaviorPage extends StatelessWidget {
  final BrowserTab tab;
  const _BehaviorPage({required this.tab});

  @override
  Widget build(BuildContext context) {
    final s = SuperTabBarThemeData.of(context);
    final ctrl = SuperTabBarController.of(context);
    final (color, label, bullets) = switch (tab.behavior) {
      SuperTabBehavior.requiredPinned => (
          SuperTabBarThemeData.danger,
          'requiredPinned',
          [
            'Always pinned — cannot be unpinned from the UI',
            'No close button or "Close tab" in context menu',
            'Duplicate is hidden in the context menu',
            'Programmatic close via controller.close(id) still works',
          ]
        ),
      SuperTabBehavior.uniqueNormal => (
          SuperTabBarThemeData.accent,
          'uniqueNormal',
          [
            'Can be closed, pinned, and unpinned',
            '"Duplicate tab" is hidden in the context menu',
            'Re-opening with the same uniqueKey activates this tab',
            'Press "Open Settings" again above — it won\'t duplicate',
          ]
        ),
      SuperTabBehavior.normal => (
          SuperTabBarThemeData.success,
          'normal',
          [
            'All operations available: close, duplicate, pin, unpin',
            'Right-click to see the full context menu',
            'Drag to reorder (only for unpinned tabs)',
            'Hover a tab for a live mini-page preview',
          ]
        ),
    };

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Text(
                'SuperTabBehavior.$label',
                style: TextStyle(
                  fontFamily: SuperTabBarThemeData.monoFont,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                tab.title,
                style: TextStyle(
                  fontFamily: SuperTabBarThemeData.displayFont,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: s.fg1,
                ),
              ),
            ),
          ]),
          if (tab.uniqueKey != null) ...[
            const SizedBox(height: 8),
            Text(
              'uniqueKey: "${tab.uniqueKey}"',
              style: TextStyle(
                fontFamily: SuperTabBarThemeData.monoFont,
                fontSize: 11,
                color: s.fg3,
              ),
            ),
          ],
          const SizedBox(height: 20),
          for (final b in bullets)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(top: 5, right: 10),
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      b,
                      style: TextStyle(
                        fontFamily: SuperTabBarThemeData.bodyFont,
                        fontSize: 13,
                        height: 1.5,
                        color: s.fg2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          if (tab.behavior == SuperTabBehavior.normal) ...[
            Row(
              children: [
                _SmallBtn(
                  label: 'Mark dirty',
                  onTap: () => ctrl?.setDirty(tab.id, true),
                ),
                const SizedBox(width: 8),
                _SmallBtn(
                  label: 'Rename',
                  onTap: () => ctrl?.rename(
                      tab.id, '${tab.title} (renamed)'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _SmallBtn extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  const _SmallBtn({required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    final s = SuperTabBarThemeData.of(context);
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border.all(color: s.borderStrong),
            borderRadius:
                BorderRadius.circular(SuperTabBarThemeData.radiusMd),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: SuperTabBarThemeData.bodyFont,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: s.fg1,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Action button ─────────────────────────────────────────────────
class _ActionBtn extends StatefulWidget {
  final String label, subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });
  @override
  State<_ActionBtn> createState() => _ActionBtnState();
}

class _ActionBtnState extends State<_ActionBtn> {
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
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _h
                ? widget.color.withOpacity(0.14)
                : widget.color.withOpacity(0.08),
            border: Border.all(color: widget.color.withOpacity(0.35)),
            borderRadius:
                BorderRadius.circular(SuperTabBarThemeData.radiusMd),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(widget.icon, size: 15, color: widget.color),
            const SizedBox(width: 8),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                widget.label,
                style: TextStyle(
                  fontFamily: SuperTabBarThemeData.bodyFont,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: widget.color,
                ),
              ),
              Text(
                widget.subtitle,
                style: TextStyle(
                  fontFamily: SuperTabBarThemeData.monoFont,
                  fontSize: 10,
                  color: s.fg3,
                ),
              ),
            ]),
          ]),
        ),
      ),
    );
  }
}

// ── Legend chip ───────────────────────────────────────────────────
class _LegendChip extends StatelessWidget {
  final Color color;
  final String label, desc;
  const _LegendChip(
      {required this.color, required this.label, required this.desc});

  @override
  Widget build(BuildContext context) {
    final s = SuperTabBarThemeData.of(context);
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 6),
      Text(
        label,
        style: TextStyle(
          fontFamily: SuperTabBarThemeData.monoFont,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
      const SizedBox(width: 4),
      Text(
        '— $desc',
        style: TextStyle(
          fontFamily: SuperTabBarThemeData.bodyFont,
          fontSize: 11,
          color: s.fg3,
        ),
      ),
    ]);
  }
}

// ── Log entry model ───────────────────────────────────────────────
class _LogEntry {
  final String event, detail;
  _LogEntry({required this.event, required this.detail});
}
