# super_tab_bar — comprehensive examples (v2.5)

Copy-ready recipes. Each assumes the import and `SuperTabBarThemeData`
registration from `SKILL.md`.

---

## 1 · ERP workspace shell — required pageBuilder + requiredPinned + callbacks

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
      tabs: [
        BrowserTab(
          id: 1, title: 'Chart of Accounts',
          pinned: true, behavior: SuperTabBehavior.requiredPinned,
          pageBuilder: (ctx, tab) => const ChartOfAccountsPage(),
        ),
        BrowserTab(
          id: 2, title: 'Journal Entry — Draft', dirty: true,
          pageBuilder: (ctx, tab) => JournalEntryPage(tabId: tab.id),
        ),
        BrowserTab(
          id: 3, title: 'Dashboard',
          pageBuilder: (ctx, tab) => const DashboardPage(),
        ),
      ],
      activeId: 2,
    );
    _ctrl.onDirtyChanged = (id, dirty) => debugPrint('dirty $id=$dirty');
    _ctrl.onRenamed      = (id, title) => debugPrint('renamed $id=$title');
  }

  int get _nextId =>
      _ctrl.tabs.fold(0, (m, t) => t.id > m ? t.id : m) + 1;

  @override
  Widget build(BuildContext context) => SuperTabBar(
    controller: _ctrl,
    showChrome: false,
    fillContent: true,
    scrollContent: false,
    onAddTab: () {
      final id = _nextId;
      _ctrl.add(
        title: 'New Tab',
        pageBuilder: (ctx, tab) => Center(child: Text(tab.title)),
      );
    },
    onTabSelected:    (id)        => debugPrint('selected $id'),
    onTabAdded:       (id)        => debugPrint('added $id'),
    onTabClosed:      (id)        => debugPrint('closed $id'),
    onTabDuplicated:  (newId)     => debugPrint('duplicated → $newId'),
    onTabPinChanged:  (id, pin)   => debugPrint('pin $id=$pin'),
    onTabDirtyChanged:(id, dirty) => debugPrint('dirtyDialog $id=$dirty'),
    onTabReordered:   (f, t)      => debugPrint('reorder $f→$t'),
  );

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
}
```

---

## 2 · uniqueNormal — singleton tabs

```dart
final _ctrl = SuperTabBarController(
  tabs: [
    BrowserTab(
      id: 1, title: 'Home',
      pinned: true, behavior: SuperTabBehavior.requiredPinned,
      pageBuilder: (ctx, tab) => const HomePage(),
    ),
  ],
  activeId: 1,
);

void _openSettings() => _ctrl.add(
  title: 'Settings',
  behavior: SuperTabBehavior.uniqueNormal,
  uniqueKey: 'settings',
  pageBuilder: (ctx, tab) => const SettingsPage(),
);
```

---

## 3 · Dirty-aware save + rename from inside a page

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
    SuperTabBarController.read(context)?.setDirty(widget.tabId, true);
  }

  Future<void> _save() async {
    final ctrl = SuperTabBarController.read(context);
    // await api.post(entry);
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

## 4 · Dynamic add — two patterns

```dart
// Pattern A — provide builder directly to add():
ctrl.add(
  title: 'Report',
  pageBuilder: (ctx, tab) => ReportPage(tabId: tab.id),
);

// Pattern B — setPageBuilder after add() (useful when id is captured in closure):
final id = ctrl.add(title: 'Report',
    pageBuilder: (ctx, tab) => const SizedBox()); // placeholder
ctrl.setPageBuilder(id, (ctx, tab) => ReportPage(tabId: id));
```

---

## 5 · RTL + Arabic

```dart
Directionality(
  textDirection: TextDirection.rtl,
  child: SuperTabBar(
    localizations: SuperTabBarLocalizations.ar,
    tabsState: [
      BrowserTab(
        id: 1, title: 'دليل الحسابات',
        pinned: true, behavior: SuperTabBehavior.requiredPinned,
        pageBuilder: (ctx, tab) => const ChartOfAccountsPage(),
      ),
      BrowserTab(
        id: 2, title: 'قيد يومية', dirty: true,
        pageBuilder: (ctx, tab) => JournalEntryPage(tabId: tab.id),
      ),
    ],
    onAddTab: () {},
  ),
)
```

---

## 6 · Compact mobile with FAB

```dart
SuperTabBar(
  controller: ctrl,
  allowAutoCompact: true,
  compactWidth: 600,
  useCompactFloatingActionButton: true,
  closeTabOnBack: true,
  fillContent: true,
  onAddTab: () => ctrl.add(title: 'New',
      pageBuilder: (ctx, tab) => const MyPage()),
)
```

---

## 7 · Manual compact + showSuperTabSwitcher

```dart
SuperTabBar(controller: ctrl, compact: true, closeTabOnBack: true,
            showChrome: false, fillContent: true);

// Open switcher from your own button:
await showSuperTabSwitcher(
  context,
  controller: ctrl,
  onCloseTab: (id) {
    if (!ctrl.tabById(id)!.dirty) ctrl.close(id);
  },
);
```

---

## 8 · Migration from v2.3 → v2.5

```dart
// ── v2.3 (no longer compiles in v2.5) ────────────────────────────
BrowserTab(id: 1, title: 'Ledger', kind: GLTabKind.ledger) // kind removed
SuperTabBar(pageBuilder: (ctx, tab) => MyPage(tab: tab))    // removed

// ── v2.5 ─────────────────────────────────────────────────────────
BrowserTab(
  id: 1, title: 'Ledger',
  pageBuilder: (ctx, tab) => const LedgerPage(), // kind moved into closure
)
// No pageBuilder on SuperTabBar.
```

---

## 9 · Batch mutations

```dart
ctrl.mutate(() {
  ctrl.setDirty(1, false);
  ctrl.rename(1, 'JE-2025-0042');
  ctrl.setPinned(2, true);
});
// notifyListeners fires exactly once
```


---

## · Leading & trailing widgets on the tab chip

```dart
// Custom icon as leading:
BrowserTab(
  id: 1, title: 'Inbox',
  leading: const Icon(Icons.inbox_outlined, size: 14),
  pageBuilder: (ctx, tab) => const InboxPage(),
)

// Unread-count badge as trailing:
BrowserTab(
  id: 2, title: 'Alerts',
  trailing: _Badge(count: 5),
  pageBuilder: (ctx, tab) => const AlertsPage(),
)

// Both together:
BrowserTab(
  id: 3, title: 'Notifications',
  leading:  const Icon(Icons.notifications_outlined, size: 14),
  trailing: _Badge(count: 12),
  pageBuilder: (ctx, tab) => const NotificationsPage(),
)

// Also available on ctrl.add():
ctrl.add(
  title: 'Reports',
  leading:  const Icon(Icons.bar_chart_outlined, size: 14),
  pageBuilder: (ctx, tab) => const ReportsPage(),
);
```

---

## 10 · SuperTabBarScope from deep in the tree

```dart
class OpenChildButton extends StatelessWidget {
  const OpenChildButton({super.key});
  @override
  Widget build(BuildContext context) => ElevatedButton(
    onPressed: () {
      SuperTabBarController.read(context)?.add(
        title: 'Child',
        pageBuilder: (ctx, tab) => const ChildPage(),
      );
    },
    child: const Text('Open child tab'),
  );
}
```
