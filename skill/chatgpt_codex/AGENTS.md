# super_tab_bar — ChatGPT / Codex agent instructions (v2.5)

Use these instructions when asked to build or modify a Flutter UI that needs a
**browser-style workspace tab bar** using the `super_tab_bar` package.

---

## Package

```
name:    super_tab_bar
version: 2.5.0
import:  package:super_tab_bar/super_tab_bar.dart
```

## When to use

Apply this skill when the user asks for:
- "multi-tab workspace", "browser-like tabs", "tab strip like Chrome"
- "dirty tab", "unsaved changes indicator"
- "pinned tab", "closable tab", "browser workspace"
- A Flutter app where content lives in switchable named tabs

---

## Theme setup (required)

```dart
MaterialApp(
  theme:     ThemeData(extensions: const [SuperTabBarThemeData.light]),
  darkTheme: ThemeData(extensions: const [SuperTabBarThemeData.dark]),
)
```

---

## Minimal example

```dart
SuperTabBar(
  tabsState: [
    BrowserTab(
      id: 1, title: 'Home',
      pageBuilder: (ctx, tab) => const HomePage(),
    ),
    BrowserTab(
      id: 2, title: 'Report',
      pageBuilder: (ctx, tab) => const ReportPage(),
    ),
  ],
  onAddTab: () {},
)
```

---

## `BrowserTab` model

```dart
BrowserTab({
  required int id,                    // stable unique identity — never reuse
  required String title,
  // NOTE: kind field was removed in v2.5 — do NOT use GLTabKind on BrowserTab
  bool dirty    = false,              // unsaved dot + close confirmation
  bool pinned   = false,              // icon-only, anchored to the start edge
  SuperTabBehavior behavior = SuperTabBehavior.normal,
  String? uniqueKey,                  // dedup key for uniqueNormal tabs
  Widget? leading,                     // widget before title (replaces default icon)
  Widget? trailing,                    // widget after title, before close indicator
  required TabPageBuilder pageBuilder, // Widget Function(BuildContext, BrowserTab)
})
```

**`TabPageBuilder`** = `Widget Function(BuildContext context, BrowserTab tab)`

The builder receives the **live tab** (current `title`/`dirty` state).
It is excluded from `==` and `hashCode`.

---

## `SuperTabBehavior`

| Value | Close | Unpin | Duplicate | Programmatic close |
|---|---|---|---|---|
| `requiredPinned` | hidden | hidden | hidden | ✓ |
| `normal` | ✓ | ✓ | ✓ | ✓ |
| `uniqueNormal` | ✓ | ✓ | hidden | ✓ |

---

## `SuperTabBarController`

```dart
final ctrl = SuperTabBarController(tabs: [...], activeId: 2);

// ── Add ─────────────────────────────────────────── pageBuilder required ──
ctrl.add(
  title: 'New Tab',
  activate: true,
  pinned: false,
  at: null,
  behavior: SuperTabBehavior.normal,
  uniqueKey: null,
  leading: null,    // optional
  trailing: null,   // optional
  pageBuilder: (ctx, tab) => const MyPage(),
);

// Replace builder after add() (when id is captured in closure):
final id = ctrl.add(title: 'Report',
    pageBuilder: (ctx, tab) => const SizedBox());
ctrl.setPageBuilder(id, (ctx, tab) => ReportPage(tabId: id));

// ── Remove ────────────────────────────────────────────────────────
ctrl.close(id); ctrl.forceClose(id); ctrl.closeOthers(id); ctrl.closeToRight(id);

// ── Mutate ────────────────────────────────────────────────────────
ctrl.duplicate(id); ctrl.togglePin(id); ctrl.reorder(fromId, toId);
ctrl.setDirty(id, true); ctrl.rename(id, 'JE-2025-0042');
ctrl.mutate(() { /* batch — notifies once */ });

// ── Read ─────────────────────────────────────────────────────────
ctrl.tabs; ctrl.activeId; ctrl.activeTab; ctrl.length;
ctrl.ordered; ctrl.pinned; ctrl.tabById(id); ctrl.isActive(id);

// ── Lookup ────────────────────────────────────────────────────────
SuperTabBarController.of(context);    // listening
SuperTabBarController.read(context);  // non-listening
```

---

## `SuperTabBar` widget

```dart
SuperTabBar(
  tabsState: [...],     // seed tabs — widget owns controller
  controller: ctrl,     // external controller (omit tabsState)

  // ── Add button — only shown when non-null ────────────────────────
  onAddTab: () => ctrl.add(
    title: 'New',
    pageBuilder: (ctx, tab) => const MyPage(),
  ),

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

  // NOTE: pageBuilder was removed in v2.5 — do NOT use it
)
```

---

## Compact mode

```dart
// Auto breakpoint + FAB:
SuperTabBar(
  controller: ctrl,
  allowAutoCompact: true, compactWidth: 600,
  useCompactFloatingActionButton: true,
  closeTabOnBack: true, fillContent: true,
  onAddTab: () => ctrl.add(title: 'New',
      pageBuilder: (ctx, tab) => const MyPage()),
)

// Manual + external switcher:
await showSuperTabSwitcher(context, controller: ctrl,
  onCloseTab: (id) => ctrl.close(id));
```

---

## Gotchas

1. **Stable IDs** — Never reuse a tab id after closing.
2. **pageBuilder is required** — every BrowserTab must have one; SuperTabBar.pageBuilder was removed.
3. **BrowserTab.kind removed (v2.5)** — do NOT reference `tab.kind`; store kind in your closure.
4. **pageBuilder called during build** — keep stateless; renders both active surface and hover preview.
5. **State-preservation is default** — `lazyPages: true` only for pages that should reset.
6. **`of(context)` returns null outside a tab bar** — guard every call.
7. **Register theme extension** — one line in `ThemeData.extensions`.
8. **`onAddTab` suppresses `onTabAdded`** — widget doesn't know the new id.
9. **`+` button requires `onAddTab`** — supply callback to show it.
10. **Provide `tabsState` OR `controller`** — never both.

---

## Examples

See `EXAMPLES.md` in this folder for full copy-ready recipes.
