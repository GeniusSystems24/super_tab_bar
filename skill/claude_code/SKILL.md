---
name: super-tab-bar
description: >
  How to use the super_tab_bar Flutter package (v2.5) — a browser-style workspace
  tab strip with pinned/closable/dirty tabs, configurable behavior types
  (requiredPinned · normal · uniqueNormal), per-tab pageBuilder + optional icon,
  drag-reorder, context menu, overflow dropdown, live mini-page previews,
  state-preserving pages, localization, direct event callbacks, a mobile
  compact-mode thumbnail switcher (SuperTabSwitcher), automatic compact
  breakpoint (allowAutoCompact + compactWidth), dirty-aware back navigation,
  and accessibility semantics. The Add (+) strip button only renders when
  onAddTab is provided. Use when building or modifying a Flutter multi-tab
  workspace UI with the `super_tab_bar` package.
---

# super_tab_bar · SuperTabBar — v2.5

A browser-style workspace tab strip. Renders the strip **and** the active page
below it. By default keeps every page's state alive across tab switches via
`IndexedStack`.

## Breaking changes in v2.5 (migration summary)

1. **`SuperTabBar.pageBuilder` removed.** Each `BrowserTab` carries its own
   required `pageBuilder` (and an optional `icon`).
2. **`BrowserTab.kind` removed.** Use `icon` (`IconData?`) + `pageBuilder`
   directly. `GLTabKind` is kept as a helper enum for the built-in `GLTabPage`
   and the `glTabIcon` / `glPreviewMeta` / `kNewTabCycle` helpers.
3. **`GLTabPage` takes an explicit `kind` parameter** —
   `GLTabPage(tab: tab, kind: GLTabKind.ledger)`.
4. **`SuperTabBarController.add` — `pageBuilder`required, `kind` removed,
   `icon` added.**
5. **`SuperTabBar.onAddTab` controls the (+) button.** When `onAddTab` is
   `null` the (+) button is not rendered and the widget no longer auto-creates
   tabs. `onTabAdded` is no longer fired from the (+) button.

---

## Import & theme setup

```dart
import 'package:super_tab_bar/super_tab_bar.dart';

// Register on MaterialApp — falls back to dark preset if omitted:
MaterialApp(
  theme:     ThemeData(extensions: const [SuperTabBarThemeData.light]),
  darkTheme: ThemeData(extensions: const [SuperTabBarThemeData.dark]),
)
```

---

## Quick start

```dart
// zero-config — private controller, built-in demo tabs:
const SuperTabBar();

// seed your own tabs (each tab carries its own pageBuilder + icon, v2.5):
SuperTabBar(tabsState: [
  BrowserTab(
    id: 1, title: 'Accounts',
    icon: glTabIcon(GLTabKind.ledger), pinned: true,
    pageBuilder: (ctx, tab) => GLTabPage(tab: tab, kind: GLTabKind.ledger),
  ),
  BrowserTab(
    id: 2, title: 'Journal', icon: glTabIcon(GLTabKind.doc), dirty: true,
    pageBuilder: (ctx, tab) => GLTabPage(tab: tab, kind: GLTabKind.doc),
  ),
  BrowserTab(
    id: 3, title: 'Dashboard', icon: glTabIcon(GLTabKind.chart),
    pageBuilder: (ctx, tab) => MyDashboardPage(tab: tab),
  ),
]);

// external controller + per-tab pageBuilder (v2.5):
SuperTabBar(controller: myCtrl, onAddTab: () => myCtrl.add(/* … */));
```

Provide `tabsState` **or** `controller` — not both.

> The shared `SuperTabBar.pageBuilder` field is gone. Page construction lives
> on each `BrowserTab.pageBuilder` (required).

---

## `BrowserTab` model  *(immutable — never mutate fields directly; v2.5)*

```dart
BrowserTab({
  required int id,                  // stable unique identity — never reuse
  required String title,
  required TabPageBuilder pageBuilder, // builds the page content (v2.5 — required)
  IconData? icon,                   // leading chip icon (null = no icon)
  bool dirty    = false,            // unsaved dot + confirm on close
  bool pinned   = false,            // icon-only, anchored start edge
  SuperTabBehavior behavior = SuperTabBehavior.normal,
  String? uniqueKey,               // dedup key for uniqueNormal tabs
});
```

`BrowserTab` is `@immutable` — **never mutate fields directly**. Use the
controller's mutation methods (`setDirty`, `rename`, `setPinned`).

> `pageBuilder` is excluded from `==`/`hashCode` (functions compared by
> identity), so two tabs with different builders but matching data fields are
> considered equal.

### Use the helpers for the legacy icon set

```dart
BrowserTab(
  id: 1, title: 'Home', icon: glTabIcon(GLTabKind.globe),
  pageBuilder: (ctx, tab) => GLTabPage(tab: tab, kind: GLTabKind.globe),
)
```

`GLTabKind`, `GLTabPage`, `glTabIcon`, `glPreviewMeta`, `kNewTabCycle` are
kept as helpers — pass them explicitly inside your `pageBuilder`.

---

## `SuperTabBehavior` — per-tab UI guards

| Behavior | Close (UI) | Unpin (UI) | Duplicate (UI) | Programmatic close |
|---|---|---|---|---|
| `requiredPinned` | ✗ hidden | ✗ hidden | ✗ hidden | ✓ always |
| `normal` | ✓ | ✓ | ✓ | ✓ |
| `uniqueNormal` | ✓ | ✓ | ✗ hidden | ✓ |

```dart
// Always-pinned tab — UI hides close / unpin / duplicate:
BrowserTab(
  id: 1, title: 'Home', icon: glTabIcon(GLTabKind.globe),
  pinned: true, behavior: SuperTabBehavior.requiredPinned,
  pageBuilder: (ctx, tab) => GLTabPage(tab: tab, kind: GLTabKind.globe),
)

// Deduplicating tab — add() with same key selects existing:
BrowserTab(
  id: 2, title: 'Settings', icon: glTabIcon(GLTabKind.user),
  behavior: SuperTabBehavior.uniqueNormal, uniqueKey: 'settings',
  pageBuilder: (ctx, tab) => SettingsPage(tab: tab),
)
```

---

## `SuperTabBarController` — full API

```dart
final ctrl = SuperTabBarController(tabs: [...], activeId: 2);

// ── Activate ──────────────────────────────────────────────────────
ctrl.select(id);

// ── Add (v2.5 — pageBuilder required, kind removed, icon added) ──
// Returns the new tab's id.
// For uniqueNormal + matching uniqueKey: returns existing id, no new tab.
ctrl.add(
  pageBuilder: (ctx, tab) => MyPage(tab: tab),   // required
  title: 'New report',
  icon: glTabIcon(GLTabKind.chart),              // null = iconless chip
  activate: true,             // default true
  pinned: false,
  at: null,                   // insertion index (null = append)
  behavior: SuperTabBehavior.normal,
  uniqueKey: null,
);

// ── Remove ────────────────────────────────────────────────────────
ctrl.close(id);               // activates nearest neighbour
ctrl.forceClose(id);          // explicit alias — use for requiredPinned tabs
ctrl.closeOthers(id);         // guard: ctrl.canCloseOthers(id)
ctrl.closeToRight(id);        // guard: ctrl.canCloseRight(id)

// ── Mutate ────────────────────────────────────────────────────────
ctrl.duplicate(id);           // returns new id; -1 if disallowed by behavior
                              // duplicate() copies icon + pageBuilder (v2.5)
ctrl.togglePin(id);           // no-op for requiredPinned
ctrl.setPinned(id, true);
ctrl.reorder(fromId, toId);
ctrl.setDirty(id, true);
ctrl.rename(id, 'JE-2024-0042');
ctrl.mutate(() { /* batch ops — notifies once */ });

// ── UI-behavior guards (used internally by the widget) ────────────
ctrl.canCloseFromUi(id);      // false for requiredPinned
ctrl.canDuplicateFromUi(id);  // false for requiredPinned + uniqueNormal
ctrl.canTogglePinFromUi(id);  // false for requiredPinned

// ── Read ──────────────────────────────────────────────────────────
ctrl.tabs;         // unmodifiable list
ctrl.activeId;     // int?
ctrl.activeTab;    // BrowserTab?
ctrl.length;
ctrl.ordered;      // pinned-first visual order
ctrl.pinned;       // filtered list
ctrl.tabById(id);  // BrowserTab?
ctrl.isActive(id); // bool

// ── Controller-level callbacks (fire from page content too) ───────
ctrl.onDirtyChanged = (id, dirty) { … };
ctrl.onRenamed      = (id, title) { … };

// ── Context lookup ────────────────────────────────────────────────
SuperTabBarController.of(context);    // listening; null outside a tab bar
SuperTabBarController.read(context);  // non-listening (callbacks/initState)
```

---

## `SuperTabBar` widget properties (v2.5)

```dart
SuperTabBar(
  // ── State ──────────────────────────────────────────────────────
  tabsState: [...],          // seed tabs (widget owns controller)
  controller: ctrl,          // external controller — provide one OR tabsState
  // NOTE: pageBuilder is gone — each BrowserTab carries its own (v2.5).

  // ── Shell ───────────────────────────────────────────────────────
  showChrome: true,          // bordered card (false = edge-to-edge)
  compact: false,            // hide strip unconditionally
  allowAutoCompact: false,   // v2.2 · auto-hide strip when width <= compactWidth
  compactWidth: 600.0,       // v2.2 · breakpoint in logical pixels (phone default)
  useCompactFloatingActionButton: false, // v2.3 · built-in FAB in compact mode
  closeTabOnBack: false,     // v2.1 · back closes active tab unless dirty
  fillContent: false,        // page fills all height (false → 440 px cap)
  scrollContent: true,       // wrap in SingleChildScrollView
  contentPadding: EdgeInsets.all(24),
  contentBackground: null,   // null → theme surface
  lazyPages: false,          // rebuild-on-revisit (disables IndexedStack)
  onAddTab: null,            // v2.5 · + button only shows when provided

  // ── Localizations (v2) ──────────────────────────────────────────
  localizations: SuperTabBarLocalizations.en,  // .ar built-in, or custom

  // ── Preview options (v2) ────────────────────────────────────────
  previewOptions: SuperTabBarPreviewOptions.defaults,
  // or: SuperTabBarPreviewOptions.disabled
  // or: SuperTabBarPreviewOptions(hoverDelay: Duration(milliseconds: 250), ...)

  // ── Direct event callbacks (v2) ─────────────────────────────────
  onTabSelected:    (id)        { },
  onTabAdded:       (id)       { },  // deprecated — not fired by (+) since v2.5
  onTabClosed:      (id)       { },
  onTabDuplicated:  (newId)    { },
  onTabPinChanged:  (id, pin)  { },
  onTabDirtyChanged:(id, dirty){ }, // fires from save-and-close dialog
  onTabReordered:   (from, to) { },
)
```

---

## `SuperTabBarLocalizations`

All user-facing strings are localizable. Pass to `SuperTabBar.localizations`:

```dart
// Built-in Arabic:
SuperTabBar(localizations: SuperTabBarLocalizations.ar)

// Custom language:
SuperTabBar(
  localizations: const SuperTabBarLocalizations(
    closeTab: 'Close tab',
    closeOtherTabs: 'Close others',
    closeTabsToRight: 'Close to right',
    duplicateTab: 'Duplicate',
    pinTab: 'Pin', unpinTab: 'Unpin',
    newTab: 'New tab', showAllTabs: 'All tabs',
    scrollForward: 'Forward', scrollBack: 'Back',
    noOpenTabs: 'No open tabs.',
    openTabsHeader: 'TABS · {count}',  // {count} auto-substituted
    switcherTitle: 'Open tabs',        // v2.1
    reorderHint: 'Drag to reorder',    // v2.1
    discardChangesTitle: 'Discard changes?',
    cancel: 'Cancel',
    saveAndClose: 'Save & close',
    discardAndClose: 'Discard & close',
  ),
)
```

---

## `SuperTabBarPreviewOptions`

```dart
// Default (480 ms delay, 0.6× pixel ratio, live fallback):
SuperTabBarPreviewOptions.defaults

// Disable entirely:
SuperTabBarPreviewOptions.disabled

// Custom:
const SuperTabBarPreviewOptions(
  enabled: true,
  hoverDelay: Duration(milliseconds: 250),
  snapshotPixelRatio: 1.0,
  fallback: PreviewFallback.blank,  // or .liveRender (default)
)
```

---

## Built-in compact FAB (v2.3)

Set `useCompactFloatingActionButton: true` and the widget renders its own FAB
over the content area when in compact mode — no extra `Stack` or
`Scaffold.floatingActionButton` needed:

```dart
SuperTabBar(
  controller: ctrl,
  allowAutoCompact: true,
  useCompactFloatingActionButton: true,
  closeTabOnBack: true,
  fillContent: true,
)
```

`onTabClosed` is forwarded to the switcher automatically; thumbnail content
comes from each tab's `BrowserTab.pageBuilder` (v2.5). The FAB sits at the
bottom-end corner (RTL-aware).

---

## Auto-compact breakpoint (v2.2)

`allowAutoCompact` + `compactWidth` let the widget switch itself into compact
mode without any `MediaQuery` boilerplate:

```dart
SuperTabBar(
  controller: ctrl,
  allowAutoCompact: true, // watches own layout width via LayoutBuilder
  compactWidth: 600,      // phone default; raise to 768 for small tablets
  closeTabOnBack: true,
  fillContent: true,
)
```

| `compactWidth` | Covers |
|---|---|
| `600` (default) | All phones |
| `768` | Phones + small tablets |
| `900` | Any mobile device |

`compact: true` still works and always takes priority.

---

## Compact mode & tab switcher (v2.1)

For phones, hide the strip and switch tabs from a full-screen thumbnail grid.

```dart
// 1 · Hide the strip; show only the active page.
SuperTabBar(
  controller: ctrl,
  compact: true,
  closeTabOnBack: true,       // back closes the current tab unless dirty
  showChrome: false,
  fillContent: true,
)

// 2 · Open the switcher (e.g. from a FloatingActionButton).
final picked = await showSuperTabSwitcher(
  context,
  controller: ctrl,
  onCloseTab: (id) => myDirtyAwareClose(id),    // optional close routing
);
// picked == tapped tab id (already selected on ctrl), or null if dismissed.
```

Inside the switcher: **tap** a thumbnail to switch · **long-press-drag** one
onto another to reorder (`ctrl.reorder`) · **close (×)** removes a tab. Embed
`SuperTabSwitcher` directly for custom presentation (bottom sheet, etc.).

> **v2.5.** `showSuperTabSwitcher` and `SuperTabSwitcher` no longer take a
> `pageBuilder` parameter. Thumbnail content comes from each tab's
> `BrowserTab.pageBuilder` (the live snapshot fallback); use `glTabIcon` /
> each tab's `icon` for the blank (non-live) fallback.

`showSuperTabSwitcher` params: `controller` (required), `localizations`,
`previewOptions`, `crossAxisCount` (null = responsive), `showCloseButtons`
(default true), `onCloseTab`.

## Back navigation (v2.1)

`closeTabOnBack: true` → a back gesture closes the active tab **only if it is
not dirty**. Dirty tabs stay open and the back pops the route normally. Uses
`PopScope` (Flutter ≥ 3.16).

---

## Keyboard shortcuts

| Key | Action |
|---|---|
| `Esc` | Close context menu / tab-list dropdown |

> **Removed in v2.1:** the tab-navigation shortcuts (`← →`, `Home`/`End`,
> `Ctrl/Cmd+T`, `Ctrl/Cmd+W`) and the `horizontalStep` / `arrowGoesInto`
> helpers. On mobile use compact mode + the tab switcher.

---

## Theming

```dart
SuperTabBarThemeData.light.copyWith(
  bg:      const Color(0xFFF5F3EF),
  surface: const Color(0xFFFFFFFF),
  border:  const Color(0xFFDDD8D0),
)
```

Static brand constants: `accent #4A7CFF` · `success #1DB88A` ·
`warning #F97316` · `danger #EF4444`.

---

## RTL

```dart
Directionality(textDirection: TextDirection.rtl, child: SuperTabBar(...))
```

Mirrors: pinned anchor, chevrons, drag indicator, dropdown, and the compact
tab switcher.

---

## Backward compatibility

v1 names are live `typedef` aliases — existing code compiles unchanged:

| v1 | v2 |
|---|---|
| `BrowserStyleTabBar` | `SuperTabBar` |
| `BrowserStyleTabBarController` | `SuperTabBarController` |
| `BrowserStyleTabBarThemeData` | `SuperTabBarThemeData` |
| `BrowserStyleTabBarScope` | `SuperTabBarScope` |
| `showGLDirtyCloseDialog` | `showSuperTabDirtyCloseDialog` |

**v1 → v2 breaking change:** direct field mutation on `BrowserTab`
(`tab.dirty = true`) no longer compiles. Use `ctrl.setDirty(id, true)`.

**v2.x → v2.5 breaking changes:**
1. `SuperTabBar.pageBuilder` removed — moved to `BrowserTab.pageBuilder` (required).
2. `BrowserTab.kind` removed — use `icon` + `pageBuilder` directly.
3. `SuperTabBarController.add(kind:)` removed; `pageBuilder` required, `icon` added.
4. The (+) strip button only renders when `SuperTabBar.onAddTab` is provided;
   the widget no longer auto-creates tabs, and `onTabAdded` is no longer fired
   from the (+) button.

---

## Gotchas

1. **Stable IDs** — Never reuse a tab id after closing.
2. **`pageBuilder` renders twice** — full surface + scaled hover preview. Keep
   it pure; the same builder is also used for the compact-mode switcher thumbnail.
3. **State-preservation is the default** — use `lazyPages: true` only when pages
   should reset on revisit.
4. **`of(context)` returns null outside a tab bar** — guard every call.
5. **Register the theme extension** — one line in `ThemeData.extensions`.
6. **`+` button requires `onAddTab` (v2.5)** — supply the callback to show the
   button; the widget no longer auto-creates tabs.
7. **`BrowserTab` is immutable** — use controller methods, never direct field
   assignment.
8. **`BrowserTab.pageBuilder` excluded from `==`/`hashCode`** — functions are
   compared by identity, so two tabs with different builders but matching data
   fields are considered equal.

## Reference

- **Comprehensive examples:** `EXAMPLES.md` in this folder.
- Source: `lib/src/` — tab_bar · controller · models · theme · localizations · preview_options · overlays · pages · compact
- README: `../../README.md`
- Example app: `../../example/lib/`