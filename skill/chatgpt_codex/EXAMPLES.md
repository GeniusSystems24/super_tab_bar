# super_tab_bar - professional examples

Realistic, copy-ready recipes. Each assumes:

```dart
import 'package:super_tab_bar/super_tab_bar.dart';
```

and theme registration with `SuperTabBarThemeData`.

## 1. ERP Workspace Shell

External controller, required pinned home tab, state-preserving custom pages,
direct callbacks, and edge-to-edge shell layout.

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
      onTabReordered: (fromId, toId) => debugPrint('moved $fromId before $toId'),
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

`uniqueNormal` prevents duplicate detail tabs when a row is opened repeatedly.

```dart
class CustomerRow extends StatelessWidget {
  const CustomerRow({super.key, required this.customer});

  final Customer customer;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(customer.name),
      onTap: () {
        SuperTabBarController.of(context)?.add(
          title: customer.name,
          kind: GLTabKind.user,
          behavior: SuperTabBehavior.uniqueNormal,
          uniqueKey: 'customer:${customer.id}',
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

## 3. Dirty-Aware Save, Rename, And Pin

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
if (tabs.canCloseOthers(tabId)) tabs.closeOthers(tabId);
if (tabs.canCloseRight(tabId)) tabs.closeToRight(tabId);

final duplicateId = tabs.duplicate(tabId);
if (duplicateId == -1) {
  debugPrint('This tab behavior does not permit duplication.');
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

Under RTL, keyboard movement, overflow controls, drag indicators, and overlay
anchors mirror to the visual direction.

## 5. Preview Policy For Expensive Pages

Disable previews entirely, or keep them but use blank fallback until a snapshot
exists.

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
    fallback: PreviewFallback.blank,
  ),
)
```
