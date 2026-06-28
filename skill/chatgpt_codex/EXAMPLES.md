# super_tab_bar — comprehensive examples (v2)

Copy-ready recipes. Each assumes the import and `SuperTabBarThemeData`
registration from `AGENTS.md`.

---

## 1 · ERP workspace shell — `requiredPinned` + all callbacks

```dart
class ErpWorkspace extends StatefulWidget {
  const ErpWorkspace({super.key});
  @override
  State<ErpWorkspace> createState() => _ErpWorkspaceState();
}

class _ErpWorkspaceState extends State<ErpWorkspace> {
  late final SuperTabBarController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = SuperTabBarController(
      tabs: const [
        // requiredPinned: UI hides close / unpin / duplicate.
        // ctrl.forceClose(id) still works programmatically.
        BrowserTab(
          id: 1, title: 'Chart of Accounts', kind: GLTabKind.ledger,
          pinned: true, behavior: SuperTabBehavior.requiredPinned,
        ),
        BrowserTab(id: 2, title: 'Journal Entry — Draft', kind: GLTabKind.doc, dirty: true),
        BrowserTab(id: 3, title: 'Dashboard', kind: GLTabKind.chart),
      ],
      activeId: 2,
    );
    // Controller callbacks fire for changes from page content too:
    _ctrl.onDirtyChanged = (id, dirty) => _log('dirty', id, dirty);
    _ctrl.onRenamed      = (id, title) => _log('rename', id, title);
  }

  void _log(String event, int id, Object value) =>
      debugPrint('[$event] tab $id → $value');

  Widget _page(BuildContext ctx, BrowserTab tab) => switch (tab.kind) {
    GLTabKind.ledger => const ChartOfAccountsPage(),
    GLTabKind.doc    => JournalEntryPage(tabId: tab.id),
    GLTabKind.chart  => const DashboardPage(),
    _                => Center(child: Text(tab.title)),
  };

  @override
  Widget build(BuildContext context) => SuperTabBar(
    controller: _ctrl,
    pageBuilder: _page,
    showChrome: false,
    fillContent: true,
    scrollContent: false,
    // Direct widget callbacks — fire for UI-initiated events:
    onTabSelected:    (id)       => _log('selected', id, ''),
    onTabAdded:       (id)       => _log('added', id, ''),
    onTabClosed:      (id)       => _log('closed', id, ''),
    onTabDuplicated:  (newId)    => _log('duplicated', newId, ''),
    onTabPinChanged:  (id, pin)  => _log('pin', id, pin),
    onTabDirtyChanged:(id, dirty)=> _log('dirtyDialog', id, dirty),
    onTabReordered:   (f, t)     => _log('reorder', f, t),
  );

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
}
```

---

## 2 · `uniqueNormal` — singleton/deduplicated tab

```dart
class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final _ctrl = SuperTabBarController(
    tabs: const [
      BrowserTab(id: 1, title: 'Home', kind: GLTabKind.globe,
          pinned: true, behavior: SuperTabBehavior.requiredPinned),
      BrowserTab(id: 2, title: 'Dashboard', kind: GLTabKind.chart),
    ],
    activeId: 2,
  );

  // Second call with same uniqueKey selects existing — no duplicate:
  void openSettings() => _ctrl.add(
    title: 'Settings',
    kind: GLTabKind.user,
    behavior: SuperTabBehavior.uniqueNormal,
    uniqueKey: 'settings',
  );

  @override
  Widget build(BuildContext context) => Column(children: [
    TextButton(onPressed: openSettings, child: const Text('Open Settings')),
    Expanded(
      child: SuperTabBar(controller: _ctrl, fillContent: true, showChrome: false),
    ),
  ]);

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
}
```

---

## 3 · Dirty-aware save flow — `setDirty` + `rename`

```dart
class JournalEntryPage extends StatefulWidget {
  final int tabId;
  const JournalEntryPage({super.key, required this.tabId});
  @override
  State<JournalEntryPage> createState() => _JournalEntryPageState();
}

class _JournalEntryPageState extends State<JournalEntryPage> {
  bool _isDirty = false;

  void _markDirty() {
    if (_isDirty) return;
    _isDirty = true;
    // read() — non-listening; use in callbacks, not build():
    SuperTabBarController.read(context)?.setDirty(widget.tabId, true);
  }

  Future<void> _save() async {
    final ctrl = SuperTabBarController.read(context);
    await api.post(entry);
    _isDirty = false;
    ctrl?.setDirty(widget.tabId, false);
    ctrl?.rename(widget.tabId, 'JE-2025-0042');
  }

  @override
  Widget build(BuildContext context) => Column(children: [
    TextField(onChanged: (_) => _markDirty()),
    ElevatedButton(onPressed: _save, child: const Text('Save')),
  ]);
}
```

---

## 4 · Open tab from inside a page — `of` / `read`

```dart
class AccountRow extends StatelessWidget {
  const AccountRow({super.key, required this.account});
  final Account account;

  @override
  Widget build(BuildContext context) => ListTile(
    title: Text(account.name),
    onTap: () {
      // of() returns null outside SuperTabBar — always guard:
      SuperTabBarController.of(context)
          ?.add(title: account.name, kind: GLTabKind.doc);
    },
  );
}
```

---

## 5 · Localizations — Arabic + custom language

```dart
// Built-in Arabic:
SuperTabBar(
  localizations: SuperTabBarLocalizations.ar,
  // Typically pair with RTL:
  // Directionality(textDirection: TextDirection.rtl, child: ...)
)

// Custom (e.g. French):
SuperTabBar(
  localizations: const SuperTabBarLocalizations(
    closeTab: 'Fermer l\'onglet',
    closeOtherTabs: 'Fermer les autres',
    closeTabsToRight: 'Fermer à droite',
    duplicateTab: 'Dupliquer',
    pinTab: 'Épingler',
    unpinTab: 'Désépingler',
    newTab: 'Nouvel onglet',
    showAllTabs: 'Tous les onglets',
    scrollForward: 'Avancer',
    scrollBack: 'Reculer',
    noOpenTabs: 'Aucun onglet ouvert.',
    openTabsHeader: 'ONGLETS · {count}',  // {count} substituted automatically
    discardChangesTitle: 'Abandonner les modifications ?',
    cancel: 'Annuler',
    saveAndClose: 'Enregistrer et fermer',
    discardAndClose: 'Abandonner et fermer',
  ),
)
```

---

## 6 · Preview options

```dart
// Disable entirely (e.g. sensitive data):
SuperTabBar(
  controller: _ctrl,
  previewOptions: SuperTabBarPreviewOptions.disabled,
)

// Fast appear + high-quality snapshot:
SuperTabBar(
  controller: _ctrl,
  previewOptions: const SuperTabBarPreviewOptions(
    hoverDelay: Duration(milliseconds: 200),
    snapshotPixelRatio: 1.0,
    fallback: PreviewFallback.liveRender,
  ),
)

// Blank surface (no live render while snapshot loads):
SuperTabBar(
  controller: _ctrl,
  previewOptions: const SuperTabBarPreviewOptions(
    fallback: PreviewFallback.blank,
  ),
)
```

---

## 7 · RTL workspace — Arabic ERP

```dart
class ArabicWorkspace extends StatelessWidget {
  const ArabicWorkspace({super.key});

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: SuperTabBar(
      localizations: SuperTabBarLocalizations.ar,
      tabsState: const [
        BrowserTab(
          id: 1, title: 'دليل الحسابات', kind: GLTabKind.ledger,
          pinned: true, behavior: SuperTabBehavior.requiredPinned,
        ),
        BrowserTab(id: 2, title: 'قيد يومية', kind: GLTabKind.doc, dirty: true),
        BrowserTab(id: 3, title: 'لوحة التحكم', kind: GLTabKind.chart),
        BrowserTab(id: 4, title: 'الفروع', kind: GLTabKind.store),
      ],
    ),
  );
}
```

---

## 8 · Custom warm theme

```dart
MaterialApp(
  theme: ThemeData(
    extensions: [
      SuperTabBarThemeData.light.copyWith(
        bg:           const Color(0xFFFAF7F2),
        surface:      const Color(0xFFFFFFFF),
        surface2:     const Color(0xFFF5EFE6),
        inputBg:      const Color(0xFFEDE8DF),
        hover:        const Color(0xFFEEE8DE),
        border:       const Color(0xFFDDD6CA),
        borderStrong: const Color(0xFFC4B9AC),
        fg1:          const Color(0xFF2C1810),
        fg2:          const Color(0xFF5C4A38),
        fg3:          const Color(0xFF8C7A68),
        fg4:          const Color(0xFFC4B9AC),
      ),
    ],
  ),
  home: const MyApp(),
)
```

---

## 9 · Programmatic removal of a `requiredPinned` tab

```dart
// forceClose() is semantically identical to close() — it just
// signals at the call site that removing a required tab is intentional:
final confirmed = await showDialog<bool>(
  context: context,
  builder: (_) => AlertDialog(
    title: const Text('Remove Home tab?'),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
      TextButton(onPressed: () => Navigator.pop(context, true),  child: const Text('Remove')),
    ],
  ),
);
if (confirmed == true) ctrl.forceClose(homeTabId);
```

---

## 10 · Full-screen shell (no chrome)

```dart
Scaffold(
  body: Column(
    children: [
      const MyTopAppBar(),
      Expanded(
        child: SuperTabBar(
          controller: _ctrl,
          pageBuilder: _page,
          showChrome: false,
          fillContent: true,
          scrollContent: false,
          contentPadding: EdgeInsets.zero,
          localizations: _isArabic
              ? SuperTabBarLocalizations.ar
              : SuperTabBarLocalizations.en,
          previewOptions: SuperTabBarPreviewOptions.defaults,
          onTabClosed:    (id) => debugPrint('closed $id'),
          onTabReordered: (f, t) => debugPrint('reorder $f→$t'),
        ),
      ),
    ],
  ),
)
```

---

## 11 · Batch operations — `mutate`

```dart
// Perform multiple ops; listeners notified once on completion:
ctrl.mutate(() {
  ctrl.close(staleId);
  ctrl.add(title: 'Monthly Report', kind: GLTabKind.doc);
  ctrl.add(title: 'Q3 Variance',    kind: GLTabKind.chart);
  ctrl.setDirty(draftId, false);
});
```

---

## 12 · Guard-aware bulk-close buttons

```dart
Row(children: [
  ElevatedButton(
    onPressed: ctrl.canCloseOthers(ctrl.activeId ?? -1)
        ? () => ctrl.closeOthers(ctrl.activeId!)
        : null,
    child: const Text('Close others'),
  ),
  const SizedBox(width: 8),
  ElevatedButton(
    onPressed: ctrl.canCloseRight(ctrl.activeId ?? -1)
        ? () => ctrl.closeToRight(ctrl.activeId!)
        : null,
    child: const Text('Close to right'),
  ),
])
```
