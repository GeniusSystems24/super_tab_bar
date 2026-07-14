// super_tab_bar · Example 01 — Basic workspace & state preservation (v2.5)
// ─────────────────────────────────────────────────────────────────
// Goal: prove that state-preservation is real and explain it visually.
//
// Each of the 4 tabs hosts a STATEFUL page containing:
//   • A counter (increment / decrement buttons)
//   • A TextField (free input)
//   • A ListView of 40 items (scrollable)
//
// Switching tabs and coming back should show the same counter value,
// the same text, and the same scroll position — because the default
// IndexedStack keeps every page alive offstage.
//
// The workbench bar at the top lets you:
//   • Toggle Keep-alive (lazyPages: false, default) vs Rebuild (lazyPages: true)
//   • Toggle LTR / RTL
//
// Watch the badge change from "preserved" to "resets" as you flip the toggle.

import 'package:flutter/material.dart';
import 'package:super_tab_bar/super_tab_bar.dart';

class BasicWorkspaceExample extends StatefulWidget {
  const BasicWorkspaceExample({super.key});
  @override
  State<BasicWorkspaceExample> createState() => _BasicWorkspaceExampleState();
}

class _BasicWorkspaceExampleState extends State<BasicWorkspaceExample> {
  bool _rtl = false;
  // lazyPages: false → IndexedStack (state preserved, default)
  // lazyPages: true  → build-on-visit (state resets)
  bool _lazy = false;

  String? _selectedLabel;

  late final SuperTabBarController _ctrl;

  Widget _buildPage(BuildContext ctx, BrowserTab tab) => _StatefulTabPage(
    key: ValueKey('page-${tab.id}-$_lazy'),
    tab: tab,
  );

  @override
  void initState() {
    super.initState();
    _ctrl = SuperTabBarController(
      tabs: [
        BrowserTab(id: 1, title: 'Chart of Accounts', pageBuilder: _buildPage),
        BrowserTab(id: 2, title: 'Journal Entry',      pageBuilder: _buildPage),
        BrowserTab(id: 3, title: 'Dashboard',           pageBuilder: _buildPage),
        BrowserTab(id: 4, title: 'Team',                pageBuilder: _buildPage),
      ],
      activeId: 1,
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
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
        title: Text('01 · State preservation',
            style: TextStyle(
                fontFamily: SuperTabBarThemeData.displayFont,
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: s.fg1)),
      ),
      body: Column(
        children: [
          // ── workbench controls ──────────────────────────────
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: s.surface,
              border: Border(bottom: BorderSide(color: s.border)),
            ),
            child: Row(
              children: [
                // Keep-alive / Rebuild toggle
                _SegmentedToggle(
                  options: const ['Keep-alive', 'Rebuild'],
                  selected: _lazy ? 1 : 0,
                  onChanged: (i) => setState(() => _lazy = i == 1),
                ),
                const SizedBox(width: 10),
                // LTR / RTL toggle
                _SegmentedToggle(
                  options: const ['LTR', 'RTL'],
                  selected: _rtl ? 1 : 0,
                  onChanged: (i) => setState(() => _rtl = i == 1),
                ),
                const Spacer(),
                if (_selectedLabel != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: SuperTabBarThemeData.accent.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: SuperTabBarThemeData.accent.withOpacity(0.28)),
                    ),
                    child: Text('onTabSelected · $_selectedLabel',
                        style: const TextStyle(
                          fontFamily: SuperTabBarThemeData.monoFont,
                          fontSize: 10, fontWeight: FontWeight.w700,
                          color: SuperTabBarThemeData.accent)),
                  ),
                // live status badge
                _StatusBadge(lazy: _lazy),
              ],
            ),
          ),
          // ── tab bar ─────────────────────────────────────────
          Expanded(
            child: Directionality(
              textDirection:
                  _rtl ? TextDirection.rtl : TextDirection.ltr,
              child: SuperTabBar(
                controller: _ctrl,
                lazyPages: _lazy,
                fillContent: true,
                scrollContent: false,
                showChrome: false,
                // v2: direct callback
                onTabSelected: (id) => setState(() {
                  _selectedLabel = _ctrl.tabById(id)?.title;
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── The stateful page: counter + text field + scroll list ─────────
// THIS is the state we expect the tab bar to keep alive across switches.
class _StatefulTabPage extends StatefulWidget {
  final BrowserTab tab;
  const _StatefulTabPage({super.key, required this.tab});
  @override
  State<_StatefulTabPage> createState() => _StatefulTabPageState();
}

class _StatefulTabPageState extends State<_StatefulTabPage> {
  int _count = 0;
  final _scroll = ScrollController();
  final _field = TextEditingController();

  @override
  void dispose() {
    _scroll.dispose();
    _field.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = SuperTabBarThemeData.of(context);
    return Padding(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // tab title
          Row(children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: SuperTabBarThemeData.accent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(
                    SuperTabBarThemeData.radiusMd),
              ),
              child: Icon(Icons.tab_outlined,
                  size: 18,
                  color: SuperTabBarThemeData.accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(widget.tab.title,
                  style: TextStyle(
                      fontFamily: SuperTabBarThemeData.displayFont,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: s.fg1)),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: s.inputBg,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: s.border),
              ),
              child: Text('tab #${widget.tab.id}',
                  style: TextStyle(
                      fontFamily: SuperTabBarThemeData.monoFont,
                      fontSize: 11,
                      color: s.fg3)),
            ),
          ]),
          const SizedBox(height: 6),
          Text(
            'Increment the counter, type text, scroll the list — then switch '
            'tabs and come back. With Keep-alive the state survives. '
            'Switch to Rebuild and the same trip resets everything.',
            style: TextStyle(
                fontFamily: SuperTabBarThemeData.bodyFont,
                fontSize: 12.5,
                height: 1.55,
                color: s.fg3),
          ),
          const SizedBox(height: 20),
          // counter + text field row
          Row(children: [
            _Counter(
              value: _count,
              onMinus: () =>
                  setState(() => _count = (_count - 1).clamp(0, 9999)),
              onPlus: () => setState(() => _count++),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: TextField(
                controller: _field,
                style: TextStyle(
                    fontFamily: SuperTabBarThemeData.bodyFont,
                    fontSize: 13,
                    color: s.fg1),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: 'Type here, switch tabs, come back…',
                  hintStyle: TextStyle(color: s.fg4),
                  filled: true,
                  fillColor: s.inputBg,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 12),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: s.border),
                    borderRadius: BorderRadius.circular(
                        SuperTabBarThemeData.radiusMd),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(
                        color: SuperTabBarThemeData.accent,
                        width: 1.5),
                    borderRadius: BorderRadius.circular(
                        SuperTabBarThemeData.radiusMd),
                  ),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 14),
          Text('Scroll position is also preserved:',
              style: TextStyle(
                  fontFamily: SuperTabBarThemeData.bodyFont,
                  fontSize: 12,
                  color: s.fg3)),
          const SizedBox(height: 8),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: s.bg,
                border: Border.all(color: s.border),
                borderRadius: BorderRadius.circular(
                    SuperTabBarThemeData.radiusMd),
              ),
              clipBehavior: Clip.antiAlias,
              child: Scrollbar(
                controller: _scroll,
                child: ListView.separated(
                  controller: _scroll,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemCount: 40,
                  separatorBuilder: (_, __) =>
                      Divider(height: 1, color: s.border),
                  itemBuilder: (_, i) => ListTile(
                    dense: true,
                    leading: Text(
                      '${(i + 1).toString().padLeft(2, '0')}',
                      style: TextStyle(
                          fontFamily:
                              SuperTabBarThemeData.monoFont,
                          fontSize: 12,
                          color: s.fg4),
                    ),
                    title: Text(
                        'Row ${i + 1} · ${widget.tab.title}',
                        style: TextStyle(
                            fontFamily:
                                SuperTabBarThemeData.bodyFont,
                            fontSize: 13,
                            color: s.fg2)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Counter widget ────────────────────────────────────────────────
class _Counter extends StatelessWidget {
  final int value;
  final VoidCallback onMinus, onPlus;
  const _Counter(
      {required this.value, required this.onMinus, required this.onPlus});

  @override
  Widget build(BuildContext context) {
    final s = SuperTabBarThemeData.of(context);
    Widget btn(IconData ic, VoidCallback fn) => GestureDetector(
          onTap: fn,
          child: Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            child: Icon(ic, size: 18, color: s.fg2),
          ),
        );
    return Container(
      decoration: BoxDecoration(
        color: s.inputBg,
        border: Border.all(color: s.border),
        borderRadius: BorderRadius.circular(
            SuperTabBarThemeData.radiusMd),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        btn(Icons.remove_rounded, onMinus),
        Container(width: 1, height: 22, color: s.border),
        SizedBox(
          width: 52,
          child: Text('$value',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontFamily: SuperTabBarThemeData.monoFont,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: SuperTabBarThemeData.accent)),
        ),
        Container(width: 1, height: 22, color: s.border),
        btn(Icons.add_rounded, onPlus),
      ]),
    );
  }
}

// ── Segmented toggle ──────────────────────────────────────────────
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
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
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: active ? Colors.white : s.fg2)),
            ),
          );
        }),
      ),
    );
  }
}

// ── Status badge ──────────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final bool lazy;
  const _StatusBadge({required this.lazy});
  @override
  Widget build(BuildContext context) {
    final c = lazy
        ? SuperTabBarThemeData.warning
        : SuperTabBarThemeData.success;
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: c.withOpacity(0.13),
        border: Border.all(color: c.withOpacity(0.45)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(
            lazy
                ? Icons.refresh_rounded
                : Icons.lock_outline_rounded,
            size: 13,
            color: c),
        const SizedBox(width: 6),
        Text(
            lazy
                ? 'lazyPages: true · resets'
                : 'lazyPages: false · preserved',
            style: TextStyle(
                fontFamily: SuperTabBarThemeData.monoFont,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: c)),
      ]),
    );
  }
}
