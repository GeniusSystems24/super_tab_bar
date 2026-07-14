---
name: super-tab-bar
description: >
  How to use the super_tab_bar Flutter package (v2.5) — a browser-style workspace
  tab strip. Each tab carries a required `pageBuilder: TabPageBuilder` (`Widget
  Function(BuildContext, BrowserTab)`). BrowserTab.kind was removed in v2.5.
  SuperTabBar.pageBuilder was removed in v2.5. The + button only shows when
  onAddTab is non-null. Use when building or modifying a Flutter multi-tab
  workspace UI with the super_tab_bar package.
---

# super_tab_bar · SuperTabBar — v2.5

A browser-style workspace tab strip. Renders the strip **and** the active page
below it. Keeps every page's state alive across tab switches via `IndexedStack`.

---

## Import & theme setup

```dart
import 'package:super_tab_bar/super_tab_bar.dart';

MaterialApp(
  theme:     ThemeData(extensions: const [SuperTabBarThemeData.light]),
  darkTheme: ThemeData(extensions: const [SuperTabBarThemeData.dark]),
)
```

---

## Quick start

```dart
// External controller + required per-tab page builders (v2.5):
final ctrl = SuperTabBarController(tabs: [
  BrowserTab(
    id: 1, title: 'Accounts',
    pinned: true, behavior: SuperTabBehavior.requiredPinned,
    pageBuilder: (ctx, tab) => const AccountsPage(),
  ),
  BrowserTab(
    id: 2, title: 'Journal', dirty: true,
    pageBuilder: (ctx, tab) => JournalPage(tabId: tab.id),
  ),
  BrowserTab(
    id: 3, title: 'Dashboard',
    pageBuilder: (ctx, tab) => const DashboardPage(),
  ),
]);

SuperTabBar(
  controller: ctrl,
  onAddTab: () => ctrl.add(
    title: 'New Tab',
    pageBuilder: (ctx, tab) => const MyPage(),
  ),
);
```

Provide `tabsState` **or** `controller` — not both.

---

## `BrowserTab` model  *(immutable)*

```dart
BrowserTab({
  required int id,              // stable unique identity — never reuse
  required String title,
  // kind was removed in v2.5 — store it in your pageBuilder closure
  bool dirty    = false,        // unsaved dot + confirm on close
  bool pinned   = false,        // icon-only, anchored start edge
  SuperTabBehavior behavior = SuperTabBehavior.normal,
  String? uniqueKey,            // dedup key for uniqueNormal tabs
  Widget? leading,                     // widget before title (replaces default icon)
  Widget? trailing,                    // widget after title, before close indicator
  required TabPageBuilder pageBuilder, // Widget Function(BuildContext, BrowserTab)
})
```

**`TabPageBuilder`** = `Widget Function(BuildContext context, BrowserTab tab)`

The builder receives the **live tab** at build time — `tab.title` and
`tab.dirty` reflect the current controller state.

Excluded from `operator ==` and `hashCode`.

`BrowserTab` is `@immutable` — **never mutate fields directly**.

---

## `SuperTabBehavior` — per-tab UI guards

| Behavior | Close (UI) | Unpin (UI) | Duplicate (UI) | Programmatic close |
|---|---|---|---|---|
| `requiredPinned` | ✗ hidden | ✗ hidden | ✗ hidden | ✓ always |
| `normal` | ✓ | ✓ | ✓ | ✓ |
| `uniqueNormal` | ✓ | ✓ | ✗ hidden | ✓ |

---

## `SuperTabBarController`

```dart
final ctrl = SuperTabBarController(tabs: [...], activeId: 2);

// ── Add ───────────────────────────────────────────────────────────
// pageBuilder is required. Returns the new (or existing) tab id.
ctrl.add(
  title: 'New report',
  activate: true,
  pinned: false,
  at: null,
  behavior: SuperTabBehavior.normal,
  uniqueKey: null,
  leading: null,    // optional
  trailing: null,   // optional
  pageBuilder: (ctx, tab) => const ReportPage(),
);

// setPageBuilder — replace builder after add() (e.g. when id matters):
final id = ctrl.add(title: 'Late bind',
    pageBuilder: (ctx, tab) => const SizedBox());
ctrl.setPageBuilder(id, (ctx, tab) => ReportPage(tabId: id));

// ── Remove ────────────────────────────────────────────────────────
ctrl.close(id);
ctrl.forceClose(id);
ctrl.closeOthers(id);
ctrl.closeToRight(id);

// ── Mutate ────────────────────────────────────────────────────────
ctrl.duplicate(id);
ctrl.togglePin(id);
ctrl.reorder(fromId, toId);
ctrl.setDirty(id, true);
ctrl.rename(id, 'JE-2024-0042');
ctrl.mutate(() { /* batch */ });

// ── Read ──────────────────────────────────────────────────────────
ctrl.tabs; ctrl.activeId; ctrl.activeTab; ctrl.length;
ctrl.ordered; ctrl.pinned; ctrl.tabById(id); ctrl.isActive(id);

// ── Callbacks ─────────────────────────────────────────────────────
ctrl.onDirtyChanged = (id, dirty) { … };
ctrl.onRenamed      = (id, title) { … };

// ── Context lookup ────────────────────────────────────────────────
SuperTabBarController.of(context);    // listening
SuperTabBarController.read(context);  // non-listening
```

---

## `SuperTabBar` widget

```dart
SuperTabBar(
  tabsState: [...],          // seed tabs (widget owns controller)
  controller: ctrl,          // external controller

  // ── Add button — only shown when non-null ────────────────────────
  onAddTab: () => ctrl.add(title: 'New',
      pageBuilder: (ctx, tab) => const MyPage()),

  // ── Shell ────────────────────────────────────────────────────────
  showChrome: true,
  compact: false,
  allowAutoCompact: false,
  compactWidth: 600.0,
  useCompactFloatingActionButton: false,
  closeTabOnBack: false,
  fillContent: false,
  scrollContent: true,
  contentPadding: EdgeInsets.all(24),
  contentBackground: null,
  lazyPages: false,

  // ── Localizations / previews ─────────────────────────────────────
  localizations: SuperTabBarLocalizations.en,
  previewOptions: SuperTabBarPreviewOptions.defaults,

  // ── Callbacks ────────────────────────────────────────────────────
  onTabSelected:    (id)        { },
  onTabAdded:       (id)        { },
  onTabClosed:      (id)        { },
  onTabDuplicated:  (newId)     { },
  onTabPinChanged:  (id, pin)   { },
  onTabDirtyChanged:(id, dirty) { },
  onTabReordered:   (from, to)  { },
)
```

---

## Compact mode & tab switcher

```dart
// Auto-compact with FAB:
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

// Manual compact + external switcher:
SuperTabBar(controller: ctrl, compact: true, closeTabOnBack: true,
            showChrome: false, fillContent: true);

await showSuperTabSwitcher(context, controller: ctrl,
  onCloseTab: (id) { if (!ctrl.tabById(id)!.dirty) ctrl.close(id); });
```

---

## Gotchas

1. **Stable IDs** — Never reuse an id after closing.
2. **pageBuilder called during build** — keep stateless; renders active surface and hover preview.
3. **State-preservation is default** — `lazyPages: true` only for pages that should reset.
4. **`of(context)` returns null outside a tab bar** — guard every call.
5. **Register theme extension** — one line in `ThemeData.extensions`.
6. **`onAddTab` suppresses `onTabAdded`** — widget doesn't know the new id.
7. **`+` button requires `onAddTab`** — supply callback to show it.
8. **`pageBuilder` excluded from `==`/`hashCode`** — tabs compared by data fields.
9. **`BrowserTab.kind` removed (v2.5)** — store kind in your closure if needed.
10. **`SuperTabBar.pageBuilder` removed (v2.5)** — each tab must own its builder.

## Reference

- **Examples:** `EXAMPLES.md` in this folder.
- Source: `lib/src/` — tab_bar · controller · models · theme · localizations · preview_options · overlays · pages · compact
- README: `../../README.md`
- Example app: `../../example/lib/`
