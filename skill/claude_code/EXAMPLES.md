# super_tab_bar - professional examples

Realistic, copy-ready recipes. Each assumes the import and
`SuperTabBarThemeData` registration from `SKILL.md`.

## 1. ERP Workspace Shell

State-preserving pages mean a half-filled journal entry survives a tab switch.

```dart
class Workspace extends StatefulWidget {
  const Workspace({super.key});

  @override
  State<Workspace> createState() => _WorkspaceState();
}

class _WorkspaceState extends State<Workspace> {
  final tabs = SuperTabBarController(
    tabs: const [
      BrowserTab(
        id: 1,
        title: 'Chart of Accounts',
        kind: GLTabKind.ledger,
        pinned: true,
        behavior: SuperTabBehavior.requiredPinned,
      ),
      BrowserTab(id: 2, title: 'Journal Entry', kind: GLTabKind.doc, dirty: true),
      BrowserTab(id: 3, title: 'Dashboard', kind: GLTabKind.chart),
    ],
    activeId: 2,
  );

  Widget page(BuildContext context, BrowserTab tab) {
    switch (tab.kind) {
      case GLTabKind.ledger:
        return const ChartOfAccountsPage();
      case GLTabKind.doc:
        return JournalEntryPage(onDirty: (dirty) => tabs.setDirty(tab.id, dirty));
      case GLTabKind.chart:
        return const DashboardPage();
      default:
        return Center(child: Text(tab.title));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SuperTabBar(
      controller: tabs,
      pageBuilder: page,
      showChrome: false,
      fillContent: true,
      onAddTab: () => tabs.add(title: 'New report', kind: GLTabKind.chart),
      onTabClosed: (id) => debugPrint('closed $id'),
      onTabDirtyChanged: (id, dirty) => debugPrint('dirty $id: $dirty'),
    );
  }

  @override
  void dispose() {
    tabs.dispose();
    super.dispose();
  }
}
```

## 2. Open Or Focus A Detail Tab

A row in one page opens a detail tab. Reopening the same row focuses the
existing tab because the tab is `uniqueNormal`.

```dart
class AccountRow extends StatelessWidget {
  const AccountRow({super.key, required this.account});

  final Account account;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(account.name),
      onTap: () {
        SuperTabBarController.of(context)?.add(
          title: account.name,
          kind: GLTabKind.doc,
          behavior: SuperTabBehavior.uniqueNormal,
          uniqueKey: 'account:${account.id}',
        );
      },
    );
  }
}
```

For callbacks or `initState`, use the non-listening variant:

```dart
SuperTabBarController.read(context)?.setDirty(tabId, true);
```

## 3. Dirty-Aware Save, Rename, Pin, And Duplicate

```dart
TextField(onChanged: (_) => tabs.setDirty(tabId, true));

Future<void> save() async {
  await api.post(entry);
  tabs.setDirty(tabId, false);
  tabs.rename(tabId, 'JE-2026-0042');
}

tabs.onDirtyChanged = (id, dirty) => debugPrint('dirty $id: $dirty');
tabs.onRenamed = (id, title) => debugPrint('renamed $id: $title');

tabs.togglePin(tabId);

if (tabs.canCloseOthers(tabId)) {
  tabs.closeOthers(tabId);
}

if (tabs.canCloseRight(tabId)) {
  tabs.closeToRight(tabId);
}

final duplicateId = tabs.duplicate(tabId);
if (duplicateId == -1) {
  debugPrint('Duplicate is not available for this tab behavior.');
}
```

## 4. Arabic RTL Workspace

```dart
class RtlWorkspace extends StatelessWidget {
  const RtlWorkspace({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: SuperTabBar(
        localizations: SuperTabBarLocalizations.ar,
        tabsState: const [
          BrowserTab(
            id: 1,
            title: 'دليل الحسابات',
            kind: GLTabKind.ledger,
            pinned: true,
            behavior: SuperTabBehavior.requiredPinned,
          ),
          BrowserTab(id: 2, title: 'قيد يومية', kind: GLTabKind.doc, dirty: true),
          BrowserTab(id: 3, title: 'لوحة التحكم', kind: GLTabKind.chart),
        ],
      ),
    );
  }
}
```

Under RTL, pinned anchoring, overflow controls, drag indicators, keyboard
movement, and overlay anchors mirror to the visual direction.

## 5. Custom Localization

```dart
const strings = SuperTabBarLocalizations(
  closeTab: 'Close tab',
  closeOtherTabs: 'Close other tabs',
  closeTabsToRight: 'Close tabs to the right',
  duplicateTab: 'Duplicate tab',
  pinTab: 'Pin tab',
  unpinTab: 'Unpin tab',
  newTab: 'New tab',
  showAllTabs: 'Show all tabs',
  scrollForward: 'Scroll tabs forward',
  scrollBack: 'Scroll tabs back',
  noOpenTabs: 'No open tabs - press + to start.',
  openTabsHeader: 'OPEN TABS - {count}',
  discardChangesTitle: 'Discard unsaved changes?',
  cancel: 'Cancel',
  saveAndClose: 'Save and close',
  discardAndClose: 'Discard and close',
);

SuperTabBar(localizations: strings)
```

## 6. Preview Policy For Expensive Or Sensitive Pages

```dart
SuperTabBar(
  controller: tabs,
  pageBuilder: buildExpensivePage,
  previewOptions: SuperTabBarPreviewOptions.disabled,
)
```

```dart
SuperTabBar(
  controller: tabs,
  pageBuilder: buildSensitivePage,
  previewOptions: const SuperTabBarPreviewOptions(
    hoverDelay: Duration(milliseconds: 300),
    snapshotPixelRatio: 0.8,
    fallback: PreviewFallback.blank,
  ),
)
```
