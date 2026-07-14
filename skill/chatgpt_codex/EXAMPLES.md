# super_tab_bar — comprehensive examples (v2.5)

Copy-ready recipes. Each assumes the import and `SuperTabBarThemeData`
registration from `AGENTS.md`. In v2.5 every `BrowserTab` has a required
`pageBuilder: TabPageBuilder` (`Widget Function(BuildContext, BrowserTab)`).
`BrowserTab.kind` and `SuperTabBar.pageBuilder` were removed.

---

## 1 · ERP workspace — required pageBuilder + requiredPinned + all callbacks

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

  @override
  Widget build(BuildContext context) => SuperTabBar(
    controller: _ctrl,
    showChrome: false, fillContent: true, scrollContent: false,
    onAddTab: () => _ctrl.add(
      title: 'New Tab',
      pageBuilder: (ctx, tab) => Center(child: Text(tab.title)),
    ),
    onTabSelected:    (id)        => debugPrint('selected $id'),
    onTabClosed:      (id)        => debugPrint('closed $id'),
    onTabPinChanged:  (id, pin)   => debugPrint('pin $id=$pin'),
    onTabReordered:   (f, t)      => debugPrint('reorder $f→$t'),
  );

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
}
```

---

## 2 · uniqueNormal — singleton tabs

```dart
void _openSettings() => _ctrl.add(
  title: 'Settings',
  behavior: SuperTabBehavior.uniqueNormal,
  uniqueKey: 'settings',
  pageBuilder: (ctx, tab) => const SettingsPage(),
);

void _openHelp() => _ctrl.add(
  title: 'Help',
  behavior: SuperTabBehavior.uniqueNormal,
  uniqueKey: 'help',
  pageBuilder: (ctx, tab) => const HelpPage(),
);
```

---

## 3 · Dirty-aware save + rename from inside a page

```dart
class JournalEntryPage extends StatefulWidget {
  final int tabId;
  const JournalEntryPage({super.key, required this.tabId});
  @override
  State<JournalEntryPage> createState() => _State();
}
class _State extends State<JournalEntryPage> {
  bool _dirty = false;
  void _touch() {
    if (_dirty) return;
    _dirty = true;
    SuperTabBarController.read(context)?.setDirty(widget.tabId, true);
  }
  Future<void> _save() async {
    final ctrl = SuperTabBarController.read(context);
    _dirty = false;
    ctrl?.setDirty(widget.tabId, false);
    ctrl?.rename(widget.tabId, 'JE-2025-0042');
  }
  @override
  Widget build(BuildContext context) => Column(children: [
    TextField(onChanged: (_) => _touch()),
    ElevatedButton(onPressed: _save, child: const Text('Save')),
  ]);
}
```

---

## 4 · Dynamic add — two patterns

```dart
// Direct — builder knows tab.id at build time:
ctrl.add(
  title: 'Report',
  pageBuilder: (ctx, tab) => ReportPage(tabId: tab.id),
);

// setPageBuilder — when you need the assigned id in the closure:
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
  allowAutoCompact: true, compactWidth: 600,
  useCompactFloatingActionButton: true,
  closeTabOnBack: true, fillContent: true,
  onAddTab: () => ctrl.add(title: 'New',
      pageBuilder: (ctx, tab) => const MyPage()),
)
```

---

## 7 · Manual compact + showSuperTabSwitcher

```dart
SuperTabBar(controller: ctrl, compact: true, closeTabOnBack: true,
            showChrome: false, fillContent: true);

await showSuperTabSwitcher(context, controller: ctrl,
  onCloseTab: (id) {
    if (!ctrl.tabById(id)!.dirty) ctrl.close(id);
  });
```

---

## 8 · Migration from v2.3 → v2.5

```dart
// ── v2.3 (will not compile in v2.5) ─────────────────────────────
BrowserTab(id: 1, title: 'Ledger', kind: GLTabKind.ledger)  // kind removed
SuperTabBar(pageBuilder: (ctx, tab) => MyPage(tab: tab))     // removed

// ── v2.5 ─────────────────────────────────────────────────────────
BrowserTab(
  id: 1, title: 'Ledger',
  pageBuilder: (ctx, tab) => const LedgerPage(), // kind lives in closure
)
// SuperTabBar needs no pageBuilder.
```

---

## 9 · Batch mutations

```dart
ctrl.mutate(() {
  ctrl.setDirty(1, false);
  ctrl.rename(1, 'JE-2025-0042');
  ctrl.setPinned(2, true);
}); // notifyListeners fires once
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

## 10 · Open tab from deep in the tree

```dart
ElevatedButton(
  onPressed: () => SuperTabBarController.read(context)?.add(
    title: 'Child',
    pageBuilder: (ctx, tab) => const ChildPage(),
  ),
  child: const Text('Open child tab'),
)
```
