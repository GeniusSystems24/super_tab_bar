// super_tab_bar · Example 02 — Document management shell (ERP-style)
// ─────────────────────────────────────────────────────────────────
// Goal: realistic workspace shell demonstrating:
//
//   • Pinned permanent tab (Chart of Accounts — cannot be closed)
//   • Dirty-state flow: Journal Entry form marks the tab dirty on the
//     first keystroke; Save clears dirty + renames the tab to the ref
//   • Open-from-row: rows in the CoA list call
//     BrowserStyleTabBarController.of(context)?.add(...)
//     proving the InheritedNotifier scope works from inside page content
//   • canCloseOthers guard before closeOthers
//   • onAddTab intercept: opens a bottom-sheet to pick the new tab kind

import 'package:flutter/material.dart';
import 'package:super_tab_bar/super_tab_bar.dart';

class DocumentShellExample extends StatefulWidget {
  const DocumentShellExample({super.key});
  @override
  State<DocumentShellExample> createState() =>
      _DocumentShellExampleState();
}

class _DocumentShellExampleState extends State<DocumentShellExample> {
  late final BrowserStyleTabBarController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = BrowserStyleTabBarController(
      tabs: [
        BrowserTab(
            id: 1,
            title: 'Chart of Accounts',
            kind: GLTabKind.ledger,
            pinned: true), // permanent — cannot be closed
        BrowserTab(
            id: 2,
            title: 'New Journal Entry',
            kind: GLTabKind.doc,
            dirty: false),
        BrowserTab(id: 3, title: 'Dashboard', kind: GLTabKind.chart),
      ],
      activeId: 1,
    );
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  // Intercept + button — show a bottom-sheet to pick the tab kind.
  Future<void> _onAddTab() async {
    final kind = await showModalBottomSheet<GLTabKind>(
      context: context,
      builder: (ctx) => _NewTabSheet(),
    );
    if (kind != null) {
      _tabs.add(
        title: _labelFor(kind),
        kind: kind,
      );
    }
  }

  static String _labelFor(GLTabKind k) {
    switch (k) {
      case GLTabKind.ledger:
        return 'New Ledger View';
      case GLTabKind.doc:
        return 'New Journal Entry';
      case GLTabKind.store:
        return 'New Store View';
      case GLTabKind.chart:
        return 'New Dashboard';
      case GLTabKind.user:
        return 'New Team View';
      case GLTabKind.globe:
        return 'New Workspace';
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = BrowserStyleTabBarThemeData.of(context);
    return Scaffold(
      backgroundColor: s.bg,
      appBar: AppBar(
        backgroundColor: s.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: s.fg1),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('02 · Document shell',
            style: TextStyle(
                fontFamily: BrowserStyleTabBarThemeData.displayFont,
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: s.fg1)),
        actions: [
          // Close others — guarded with canCloseOthers
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              onPressed: _tabs.activeId != null &&
                      _tabs.canCloseOthers(_tabs.activeId!)
                  ? () => _tabs.closeOthers(_tabs.activeId!)
                  : null,
              icon: const Icon(Icons.clear_all, size: 16),
              label: const Text('Close others'),
              style: TextButton.styleFrom(foregroundColor: s.fg2),
            ),
          ),
        ],
      ),
      body: BrowserStyleTabBar(
        controller: _tabs,
        pageBuilder: _buildPage,
        showChrome: false,
        fillContent: true,
        scrollContent: false,
        onAddTab: _onAddTab,
      ),
    );
  }

  Widget _buildPage(BuildContext context, BrowserTab tab) {
    switch (tab.kind) {
      case GLTabKind.ledger:
        // Chart of Accounts list — rows open new ledger tabs via of(context)
        return _CoAPage(tab: tab);
      case GLTabKind.doc:
        // Journal Entry form — marks tab dirty on keystroke, save clears it
        return _JournalEntryPage(
          tab: tab,
          onDirty: (dirty) => _tabs.setDirty(tab.id, dirty),
          onSave: (ref) {
            _tabs.setDirty(tab.id, false);
            _tabs.rename(tab.id, ref);
          },
        );
      default:
        return _PlaceholderPage(tab: tab);
    }
  }
}

// ── Chart of Accounts page ────────────────────────────────────────
// Rows call BrowserStyleTabBarController.of(context) to open a new tab.
class _CoAPage extends StatelessWidget {
  final BrowserTab tab;
  const _CoAPage({required this.tab});

  static const _accounts = [
    ('1000', 'Cash on Hand', 'Asset'),
    ('1010', 'Bank — NCB Current', 'Asset'),
    ('1200', 'Accounts Receivable', 'Asset'),
    ('2000', 'Accounts Payable', 'Liability'),
    ('3000', "Owner's Capital", 'Equity'),
    ('4000', 'Sales Revenue', 'Income'),
    ('5000', 'Cost of Goods Sold', 'Expense'),
  ];

  @override
  Widget build(BuildContext context) {
    final s = BrowserStyleTabBarThemeData.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Chart of Accounts',
            style: TextStyle(
                fontFamily: BrowserStyleTabBarThemeData.displayFont,
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: s.fg1)),
        const SizedBox(height: 6),
        Text(
          'Tap "Open ledger" on any row to open a new tab via '
          'BrowserStyleTabBarController.of(context).',
          style: TextStyle(
              fontFamily: BrowserStyleTabBarThemeData.bodyFont,
              fontSize: 13,
              color: s.fg3),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: s.bg,
              border: Border.all(color: s.border),
              borderRadius: BorderRadius.circular(
                  BrowserStyleTabBarThemeData.radiusLg),
            ),
            clipBehavior: Clip.antiAlias,
            child: ListView.separated(
              itemCount: _accounts.length,
              separatorBuilder: (_, __) =>
                  Divider(height: 1, color: s.border),
              itemBuilder: (ctx, i) {
                final a = _accounts[i];
                return ListTile(
                  leading: Text(a.$1,
                      style: TextStyle(
                          fontFamily:
                              BrowserStyleTabBarThemeData.monoFont,
                          fontSize: 12,
                          color: s.fg3)),
                  title: Text(a.$2,
                      style: TextStyle(
                          fontFamily:
                              BrowserStyleTabBarThemeData.bodyFont,
                          fontWeight: FontWeight.w600,
                          color: s.fg1)),
                  subtitle: Text(a.$3,
                      style: TextStyle(
                          fontSize: 11, color: s.fg3)),
                  trailing: TextButton(
                    onPressed: () {
                      // ← This is the key pattern: open a new tab from
                      //   inside page content using the scope accessor.
                      BrowserStyleTabBarController.of(ctx)?.add(
                        title: '${a.$2} — Ledger',
                        kind: GLTabKind.ledger,
                      );
                    },
                    child: const Text('Open ledger'),
                  ),
                );
              },
            ),
          ),
        ),
      ]),
    );
  }
}

// ── Journal Entry form ────────────────────────────────────────────
// Marks the tab dirty on first keystroke; Save clears dirty + renames.
class _JournalEntryPage extends StatefulWidget {
  final BrowserTab tab;
  final ValueChanged<bool> onDirty;
  final ValueChanged<String> onSave;
  const _JournalEntryPage(
      {required this.tab, required this.onDirty, required this.onSave});
  @override
  State<_JournalEntryPage> createState() => _JournalEntryPageState();
}

class _JournalEntryPageState extends State<_JournalEntryPage> {
  final _memo = TextEditingController();
  bool _hasDirtied = false;
  bool _saving = false;

  void _markDirty() {
    if (!_hasDirtied) {
      _hasDirtied = true;
      widget.onDirty(true); // sets the unsaved dot on the tab
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    // Simulate async save
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() => _saving = false);
    // Rename the tab to the document reference + clear dirty
    widget.onSave('JE-2025-${DateTime.now().millisecond}');
    _hasDirtied = false;
  }

  @override
  void dispose() {
    _memo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = BrowserStyleTabBarThemeData.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Text(widget.tab.title,
                style: TextStyle(
                    fontFamily: BrowserStyleTabBarThemeData.displayFont,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: s.fg1)),
          ),
          if (_saving)
            const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: BrowserStyleTabBarThemeData.accent))
          else
            ElevatedButton.icon(
              onPressed: _hasDirtied ? _save : null,
              icon: const Icon(Icons.save_outlined, size: 16),
              label: const Text('Save & rename tab'),
              style: ElevatedButton.styleFrom(
                backgroundColor: BrowserStyleTabBarThemeData.accent,
                foregroundColor: Colors.white,
              ),
            ),
        ]),
        const SizedBox(height: 6),
        Text(
          'Type anything in the memo field — the tab gets a dirty dot. '
          'Press Save to clear the dot and rename the tab to a generated ref.',
          style: TextStyle(
              fontFamily: BrowserStyleTabBarThemeData.bodyFont,
              fontSize: 12.5,
              color: s.fg3),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _memo,
          onChanged: (_) => _markDirty(),
          maxLines: 5,
          style: TextStyle(
              fontFamily: BrowserStyleTabBarThemeData.bodyFont,
              fontSize: 14,
              color: s.fg1),
          decoration: InputDecoration(
            labelText: 'Memo',
            hintText: 'Opening journal entry for FY 2025…',
            filled: true,
            fillColor: s.inputBg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                  BrowserStyleTabBarThemeData.radiusMd),
            ),
          ),
        ),
      ]),
    );
  }
}

// ── Placeholder page ──────────────────────────────────────────────
class _PlaceholderPage extends StatelessWidget {
  final BrowserTab tab;
  const _PlaceholderPage({required this.tab});
  @override
  Widget build(BuildContext context) {
    final s = BrowserStyleTabBarThemeData.of(context);
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(glTabIcon(tab.kind),
            size: 40, color: BrowserStyleTabBarThemeData.accent),
        const SizedBox(height: 12),
        Text(tab.title,
            style: TextStyle(
                fontFamily: BrowserStyleTabBarThemeData.displayFont,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: s.fg1)),
      ]),
    );
  }
}

// ── New tab kind picker (bottom sheet) ────────────────────────────
class _NewTabSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final s = BrowserStyleTabBarThemeData.of(context);
    final kinds = [
      (GLTabKind.doc, 'Journal Entry', Icons.description_outlined),
      (GLTabKind.ledger, 'Ledger View', Icons.menu_book_outlined),
      (GLTabKind.chart, 'Dashboard', Icons.bar_chart_rounded),
      (GLTabKind.user, 'Team', Icons.people_alt_outlined),
      (GLTabKind.store, 'Store', Icons.storefront_outlined),
      (GLTabKind.globe, 'Workspace', Icons.public),
    ];
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: s.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Open new tab',
              style: TextStyle(
                  fontFamily: BrowserStyleTabBarThemeData.displayFont,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: s.fg1)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: kinds.map((k) {
              return GestureDetector(
                onTap: () => Navigator.pop(context, k.$1),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: s.inputBg,
                    border: Border.all(color: s.border),
                    borderRadius: BorderRadius.circular(
                        BrowserStyleTabBarThemeData.radiusMd),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(k.$3,
                        size: 15,
                        color: BrowserStyleTabBarThemeData.accent),
                    const SizedBox(width: 8),
                    Text(k.$2,
                        style: TextStyle(
                            fontFamily:
                                BrowserStyleTabBarThemeData.bodyFont,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: s.fg1)),
                  ]),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
