# super_tab_bar — professional examples

Realistic, copy-ready recipes. Each assumes the import +
`BrowserStyleTabBarThemeData` registration from AGENTS.md.

---

## 1 · ERP workspace shell — external controller + custom `pageBuilder`

State-preserving pages mean a half-filled journal entry survives a tab switch.

```dart
class Workspace extends StatefulWidget {
  const Workspace({super.key});
  @override
  State<Workspace> createState() => _WorkspaceState();
}

class _WorkspaceState extends State<Workspace> {
  final _tabs = BrowserStyleTabBarController(
    tabs: [
      BrowserTab(id: 1, title: 'Chart of Accounts', kind: GLTabKind.ledger, pinned: true),
      BrowserTab(id: 2, title: 'Journal Entry',      kind: GLTabKind.doc,    dirty: true),
      BrowserTab(id: 3, title: 'Dashboard',           kind: GLTabKind.chart),
    ],
    activeId: 2,
  );

  Widget _page(BuildContext ctx, BrowserTab tab) {
    switch (tab.kind) {
      case GLTabKind.ledger: return const ChartOfAccountsPage();
      case GLTabKind.doc:    return JournalEntryPage(
          onDirty: (d) => _tabs.setDirty(tab.id, d));
      case GLTabKind.chart:  return const DashboardPage();
      default:               return Center(child: Text(tab.title));
    }
  }

  @override
  Widget build(BuildContext context) => BrowserStyleTabBar(
    controller: _tabs,
    pageBuilder: _page,
    showChrome: false,
    fillContent: true,
    onAddTab: () => _tabs.add(title: 'New report', kind: GLTabKind.chart),
  );

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }
}
```

---

## 2 · Open a detail tab from page content (`of(context)`)

```dart
class AccountRow extends StatelessWidget {
  const AccountRow({super.key, required this.account});
  final Account account;

  @override
  Widget build(BuildContext context) => ListTile(
    title: Text(account.name),
    onTap: () {
      BrowserStyleTabBarController.of(context)
          ?.add(title: account.name, kind: GLTabKind.doc);
    },
  );
}
```

For callbacks / `initState` use the non-listening variant:

```dart
BrowserStyleTabBarController.read(context)?.setDirty(tabId, true);
```

---

## 3 · Dirty-aware save + rename + pin

```dart
TextField(onChanged: (_) => tabs.setDirty(tabId, true));

Future<void> save() async {
  await api.post(entry);
  tabs.setDirty(tabId, false);
  tabs.rename(tabId, 'JE-2025-0042');
}

tabs.togglePin(tabId);
if (tabs.canCloseOthers(tabId)) tabs.closeOthers(tabId);
if (tabs.canCloseRight(tabId))  tabs.closeToRight(tabId);
tabs.duplicate(tabId);
```

---

## 4 · RTL workspace

```dart
class RtlWorkspace extends StatelessWidget {
  const RtlWorkspace({super.key});
  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: BrowserStyleTabBar(
      tabsState: [
        BrowserTab(id: 1, title: 'دليل الحسابات', kind: GLTabKind.ledger, pinned: true),
        BrowserTab(id: 2, title: 'قيد يومية',      kind: GLTabKind.doc),
        BrowserTab(id: 3, title: 'لوحة التحكم',   kind: GLTabKind.chart),
      ],
    ),
  );
}
```
