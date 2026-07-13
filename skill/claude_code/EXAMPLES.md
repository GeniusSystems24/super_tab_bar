# super_tab_bar — comprehensive examples (v2.5)

Copy-ready recipes. Each assumes the import and `SuperTabBarThemeData`
registration from `SKILL.md`. **Since v2.5 each `BrowserTab` carries its own
required `pageBuilder` and an optional `icon`** — the shared
`SuperTabBar.pageBuilder` field has been removed.

---

## 1 · ERP workspace shell — `requiredPinned` + callbacks

The canonical production pattern. Chart of Accounts is always pinned and its
close/unpin/duplicate UI is hidden via `SuperTabBehavior.requiredPinned`.
All seven widget callbacks are wired for analytics / sync.

```dart
class ErpWorkspace extends StatefulWidget {
  const ErpWorkspace({super.key});
  @override
  State<ErpWorkspace> createState() => _ErpWorkspaceState();
}

class _ErpWorkspaceState extends State<ErpWorkspace> {
  late final SuperTabBarController _ctrl;

  Widget _page(BuildContext ctx, BrowserTab tab) {
    // Route on the tab's icon (we set it via glTabIcon(kind) at construction).
    final kindFor = {
      glTabIcon(GLTabKind.ledger): GLTabKind.ledger,
      glTabIcon(GLTabKind.doc):    GLTabKind.doc,
      glTabIcon(GLTabKind.chart):  GLTabKind.chart,
    };
    switch (kindFor[tab.icon]) {
      case GLTabKind.ledger: return const ChartOfAccountsPage();
      case GLTabKind.doc:    return JournalEntryPage(tabId: tab.id);
      case GLTabKind.chart:  return const DashboardPage();
      default:               return Center(child: Text(tab.title));
    }
  }

  @override
  void initState() {
    super.initState();
    _ctrl = SuperTabBarController(
      tabs: [
        // requiredPinned — always pinned; UI hides close/unpin/duplicate.
        // Programmatic ctrl.close(id) / forceClose(id) still works.
        BrowserTab(
          id: 1, title: 'Chart of Accounts', icon: glTabIcon(GLTabKind.ledger),
          pinned: true, behavior: SuperTabBehavior.requiredPinned,
          pageBuilder: _page,
        ),
        BrowserTab(
          id: 2, title: 'Journal Entry — Draft',
          icon: glTabIcon(GLTabKind.doc), dirty: true,
          pageBuilder: _page,
        ),
        BrowserTab(
          id: 3, title: 'Dashboard', icon: glTabIcon(GLTabKind.chart),
          pageBuilder: _page,
        ),
      ],
      activeId: 2,
    );
    // Controller-level callbacks fire for changes from page content too:
    _ctrl.onDirtyChanged = (id, dirty) => _sync('dirty', id, dirty);
    _ctrl.onRenamed      = (id, title) => _sync('rename', id, title);
  }

  void _sync(String event, int id, Object value) =>
      debugPrint('[$event] tab $id → $value');

  void _onAddTab() {
    // The (+) button only shows because onAddTab is provided (v2.5).
    _ctrl.add(
      title: 'New Tab ${_ctrl.length + 1}',
      icon: glTabIcon(GLTabKind.doc),
      pageBuilder: _page,
    );
  }

  @override
  Widget build(BuildContext context) => SuperTabBar(
    controller: _ctrl,
    onAddTab: _onAddTab,          // v2.5 — (+) button visible
    showChrome: false,
    fillContent: true,
    scrollContent: false,
    // Widget callbacks fire for UI-initiated events:
    onTabSelected:    (id)       => _sync('selected', id, ''),
    onTabClosed:      (id)       => _sync('closed', id, ''),
    onTabDuplicated:  (newId)    => _sync('duplicated', newId, ''),
    onTabPinChanged:  (id, pin)  => _sync('pin', id, pin),
    onTabDirtyChanged:(id, dirty)=> _sync('dirtyDialog', id, dirty),
    onTabReordered:   (f, t)     => _sync('reorder', f, t),
  );

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
}
```

---

## 2 · `uniqueNormal` — deduplicated singleton tabs

Settings can only be open once. Pressing "Open Settings" a second time
activates the existing tab instead of duplicating it.

```dart
class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  static const _settingsKey = 'settings';

  final _ctrl = SuperTabBarController(
    tabs: [
      BrowserTab(
        id: 1, title: 'Home', icon: glTabIcon(GLTabKind.globe),
        pinned: true, behavior: SuperTabBehavior.requiredPinned,
        pageBuilder: (ctx, tab) => GLTabPage(tab: tab, kind: GLTabKind.globe),
      ),
      BrowserTab(
        id: 2, title: 'Dashboard', icon: glTabIcon(GLTabKind.chart),
        pageBuilder: (ctx, tab) => GLTabPage(tab: tab, kind: GLTabKind.chart),
      ),
    ],
    activeId: 2,
  );

  // Call from anywhere — add() returns existing id if uniqueKey matches:
  void openSettings() => _ctrl.add(
    title: 'Settings',
    icon: glTabIcon(GLTabKind.user),
    behavior: SuperTabBehavior.uniqueNormal,
    uniqueKey: _settingsKey,
    pageBuilder: (ctx, tab) => SettingsPage(tab: tab),
  );

  @override
  Widget build(BuildContext context) => Column(
    children: [
      TextButton(onPressed: openSettings, child: const Text('Open Settings')),
      Expanded(child: SuperTabBar(
        controller: _ctrl, fillContent: true, showChrome: false,
      )),
    ],
  );

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
}
```

---

## 3 · Dirty-aware save flow — `setDirty` + `rename`

Page content marks its tab dirty on first edit. Saving clears the flag
and renames the tab to the real document reference.

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
    // Use read() — we're in a callback, not build():
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

## 4 · Open a detail tab from inside a page (`of` / `read`)

Rows in a list open linked document tabs. Pages stay reusable because
`of(context)` returns null outside a `SuperTabBar`.

```dart
class AccountRow extends StatelessWidget {
  const AccountRow({super.key, required this.account});
  final Account account;

  @override
  Widget build(BuildContext context) => ListTile(
    title: Text(account.name),
    onTap: () {
      // of() is listening — use in build(). Returns null outside a tab bar.
      SuperTabBarController.of(context)?.add(
        title: account.name,
        icon: glTabIcon(GLTabKind.doc),
        pageBuilder: (ctx, tab) => DetailPage(tab: tab, account: account),
      );
    },
  );
}
```

Use `read(context)` in callbacks, `initState`, or anywhere that must not
trigger a rebuild:

```dart
// In a button onPressed or initState:
SuperTabBarController.read(context)?.setDirty(tabId, true);
```

---

## 5 · Localizations — English + Arabic

```dart
// Built-in Arabic preset:
SuperTabBar(
  controller: _ctrl,
  localizations: SuperTabBarLocalizations.ar,
  // RTL layout:
  // Wrap with Directionality(textDirection: TextDirection.rtl, ...) if needed
)

// Custom language (e.g. French):
SuperTabBar(
  controller: _ctrl,
  localizations: const SuperTabBarLocalizations(
    closeTab: 'Fermer l\'onglet',
    closeOtherTabs: 'Fermer les autres',
    closeTabsToRight: 'Fermer à droite',
    duplicateTab: 'Dupliquer',
    pinTab: 'Épingler', unpinTab: 'Désépingler',
    newTab: 'Nouvel onglet',
    showAllTabs: 'Tous les onglets',
    scrollForward: 'Avancer', scrollBack: 'Reculer',
    noOpenTabs: 'Aucun onglet ouvert.',
    openTabsHeader: 'ONGLETS · {count}',   // {count} substituted automatically
    switcherTitle: 'Onglets ouverts',
    reorderHint: 'Glisser pour réordonner',
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
// Default (480 ms hover delay, 0.6× snapshot ratio, live fallback):
SuperTabBar(controller: _ctrl) // defaults apply automatically

// Disable previews entirely:
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

// Blank surface when no snapshot captured yet (e.g. sensitive content):
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
      tabsState: [
        BrowserTab(
          id: 1, title: 'دليل الحسابات', icon: glTabIcon(GLTabKind.ledger),
          pinned: true, behavior: SuperTabBehavior.requiredPinned,
          pageBuilder: (ctx, tab) => GLTabPage(tab: tab, kind: GLTabKind.ledger),
        ),
        BrowserTab(
          id: 2, title: 'قيد يومية', icon: glTabIcon(GLTabKind.doc), dirty: true,
          pageBuilder: (ctx, tab) => GLTabPage(tab: tab, kind: GLTabKind.doc),
        ),
        BrowserTab(
          id: 3, title: 'لوحة التحكم', icon: glTabIcon(GLTabKind.chart),
          pageBuilder: (ctx, tab) => GLTabPage(tab: tab, kind: GLTabKind.chart),
        ),
        BrowserTab(
          id: 4, title: 'الفروع', icon: glTabIcon(GLTabKind.store),
          pageBuilder: (ctx, tab) => GLTabPage(tab: tab, kind: GLTabKind.store),
        ),
      ],
    ),
  );
}
```

RTL mirrors: pinned anchor on visual left, chevrons swap sides,
drag drop-indicator, `▾` dropdown anchor, and the compact tab switcher.

---

## 8 · Custom theming — warm palette

```dart
// In ThemeData.extensions:
SuperTabBarThemeData.light.copyWith(
  bg:           const Color(0xFFFAF7F2),   // warm off-white strip
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
)
```

Static brand constants stay the same: `accent #4A7CFF` · `success #1DB88A` ·
`warning #F97316` · `danger #EF4444`.

---

## 9 · Programmatic removal of a `requiredPinned` tab

The UI hides the close button for `requiredPinned` tabs — but the controller
always allows programmatic removal. Use `forceClose` to make intent explicit:

```dart
// Normal close — works for all behaviors including requiredPinned:
ctrl.close(id);

// Explicit alias — signals at the call site that this is intentional:
ctrl.forceClose(id);

// Example: user confirms in a custom dialog, then removes the tab:
final confirmed = await showDialog<bool>(context: context, builder: (_) => ...);
if (confirmed == true) ctrl.forceClose(homeTabId);
```

---

## 10 · Batch operations with `mutate`

```dart
ctrl.mutate(() {
  ctrl.close(oldId);
  ctrl.add(
    title: 'Monthly Report', icon: glTabIcon(GLTabKind.doc),
    pageBuilder: (ctx, t) => GLTabPage(tab: t, kind: GLTabKind.doc),
  );
  ctrl.add(
    title: 'Q3 Variance', icon: glTabIcon(GLTabKind.chart),
    pageBuilder: (ctx, t) => GLTabPage(tab: t, kind: GLTabKind.chart),
  );
  ctrl.setDirty(reportId, false);
});
```

---

## 11 · Guard-aware bulk close

```dart
// Always guard bulk-close operations before calling:
if (ctrl.canCloseOthers(activeId)) ctrl.closeOthers(activeId);
if (ctrl.canCloseRight(activeId))  ctrl.closeToRight(activeId);

// Disable a button when the operation would be a no-op:
ElevatedButton(
  onPressed: ctrl.canCloseOthers(ctrl.activeId ?? -1)
      ? () => ctrl.closeOthers(ctrl.activeId!)
      : null,
  child: const Text('Close other tabs'),
)
```

---

## 12 · Embedding in a full-screen shell (no chrome)

```dart
Scaffold(
  body: Column(
    children: [
      const MyTopBar(),      // your own app bar
      Expanded(
        child: SuperTabBar(
          controller: _ctrl,
          onAddTab: _addTab,     // v2.5 — (+) button visible
          showChrome: false,    // no card border — blends into Scaffold
          fillContent: true,    // page fills the Expanded area
          scrollContent: false, // page manages its own scroll
          contentPadding: EdgeInsets.zero,
          localizations: _isArabic
              ? SuperTabBarLocalizations.ar
              : SuperTabBarLocalizations.en,
        ),
      ),
    ],
  ),
)
```

---

## 13 · Auto-compact breakpoint (v2.2)

No `MediaQuery` needed — the widget watches its own layout width.

```dart
// Adapts to phone, tablet and desktop in the same tree.
SuperTabBar(
  controller: ctrl,
  allowAutoCompact: true,   // strip hides automatically
  compactWidth: 600,        // ≤ 600 px → compact; > 600 px → full strip
  closeTabOnBack: true,
  showChrome: false,
  fillContent: true,
  // Each tab has its own pageBuilder — no SuperTabBar.pageBuilder (v2.5).
)

// FAB for the switcher (only needed in compact)
if (MediaQuery.of(context).size.width <= 600)
  FloatingActionButton(
    child: const Icon(Icons.grid_view_rounded),
    onPressed: () => showSuperTabSwitcher(context, controller: ctrl),
  )
```

Or let a single `ValueNotifier` drive the FAB visibility from the same
breakpoint, so it only appears when the strip is actually hidden:

```dart
LayoutBuilder(
  builder: (ctx, c) {
    final isCompact = c.maxWidth <= 600;
    return Stack(
      children: [
        SuperTabBar(
          controller: ctrl,
          allowAutoCompact: true,
          compactWidth: 600,
          fillContent: true,
        ),
        if (isCompact)
          Positioned(
            right: 16, bottom: 16,
            child: FloatingActionButton(
              onPressed: () => showSuperTabSwitcher(ctx, controller: ctrl),
              child: const Icon(Icons.grid_view_rounded),
            ),
          ),
      ],
    );
  },
)
```

---

## 14 · Compact mode — mobile tab switcher (v2.1)

On phones, hide the strip and switch tabs from a full-screen thumbnail grid
opened by a `FloatingActionButton`. `closeTabOnBack` makes the system back
button close the current tab — unless it is dirty.

```dart
class MobileWorkspace extends StatefulWidget {
  const MobileWorkspace({super.key});
  @override
  State<MobileWorkspace> createState() => _MobileWorkspaceState();
}

class _MobileWorkspaceState extends State<MobileWorkspace> {
  final _ctrl = SuperTabBarController(
    tabs: [
      BrowserTab(
        id: 1, title: 'Inbox', icon: glTabIcon(GLTabKind.doc),
        pageBuilder: (ctx, tab) => GLTabPage(tab: tab, kind: GLTabKind.doc),
      ),
      BrowserTab(
        id: 2, title: 'Invoice INV-2043', icon: glTabIcon(GLTabKind.ledger),
        dirty: true,
        pageBuilder: (ctx, tab) =>
            GLTabPage(tab: tab, kind: GLTabKind.ledger),
      ),
      BrowserTab(
        id: 3, title: 'Dashboard', icon: glTabIcon(GLTabKind.chart),
        pageBuilder: (ctx, tab) => GLTabPage(tab: tab, kind: GLTabKind.chart),
      ),
    ],
    activeId: 1,
  );

  // Dirty-aware close, reused by the switcher's × button.
  Future<void> _close(int id) async {
    final tab = _ctrl.tabById(id);
    if (tab == null) return;
    if (tab.dirty) {
      final r = await showSuperTabDirtyCloseDialog(context, tab);
      if (r == 'discard') _ctrl.close(id);
      else if (r == 'save') { _ctrl.setDirty(id, false); _ctrl.close(id); }
    } else {
      _ctrl.close(id);
    }
  }

  Future<void> _openSwitcher() => showSuperTabSwitcher(
    context,
    controller: _ctrl,
    onCloseTab: _close,
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    floatingActionButton: FloatingActionButton(
      onPressed: _openSwitcher,
      child: const Icon(Icons.grid_view_rounded),
    ),
    body: SuperTabBar(
      controller: _ctrl,
      compact: true,          // strip hidden
      closeTabOnBack: true,   // back closes non-dirty active tab
      showChrome: false,
      fillContent: true,
    ),
  );

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
}
```

---

## 15 · Embed the switcher directly (bottom sheet)

`showSuperTabSwitcher` is a full-screen modal; when you want a different
presentation, mount `SuperTabSwitcher` yourself and wire selection/dismiss.

```dart
void openSwitcherSheet(BuildContext context, SuperTabBarController ctrl) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => SizedBox(
      height: MediaQuery.of(ctx).size.height * 0.7,
      child: SuperTabSwitcher(
        controller: ctrl,
        onSelect: (id) {           // tap a thumbnail
          ctrl.select(id);
          Navigator.of(ctx).pop();
        },
        onDismiss: () => Navigator.of(ctx).pop(),
        // v2.5: no pageBuilder param — thumbnails use each tab's
        // BrowserTab.pageBuilder. long-press-drag reordering + close (×)
        // work automatically.
      ),
    ),
  );
}
```