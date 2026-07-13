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
- "pinned workspace tab", "required/permanent tab"
- "uniqueNormal tab", "singleton tab", "deduplicated tab"
- "draggable tabs", "live tab preview", "mini page preview on hover"
- state-preserving tab pages in Flutter
- localizable tab bar, Arabic/RTL tab strip
- **per-tab page builder** (v2.5 — each `BrowserTab` carries its own
  `pageBuilder` + optional `icon`)

---

## Breaking changes in v2.5 (migration summary)

1. **`SuperTabBar.pageBuilder` removed.** Each `BrowserTab` carries its own
   required `pageBuilder` (and an optional `icon`).
2. **`BrowserTab.kind` removed.** Use `icon` (`IconData?`) + `pageBuilder`.
   `GLTabKind` is kept as a helper enum for `GLTabPage` and the
   `glTabIcon` / `glPreviewMeta` / `kNewTabCycle` helpers.
3. **`GLTabPage` takes an explicit `kind` parameter** —
   `GLTabPage(tab: tab, kind: GLTabKind.ledger)`.
4. **`SuperTabBarController.add` — `pageBuilder` required, `kind` removed,
   `icon` added.**
5. **`SuperTabBar.onAddTab` controls the (+) button.** When `onAddTab` is
   `null` the (+) button is not rendered and the widget no longer auto-creates
   tabs. `onTabAdded` is no longer fired from the (+) button.

---

## Mandatory setup

### 1 · `pubspec.yaml`

```yaml
dependencies:
  super_tab_bar: ^2.5.0
```

### 2 · Register theme extension

```dart
import 'package:super_tab_bar/super_tab_bar.dart';

MaterialApp(
  theme:     ThemeData(extensions: const [SuperTabBarThemeData.light]),
  darkTheme: ThemeData(extensions: const [SuperTabBarThemeData.dark]),
)
```

Without this the widget uses the dark preset regardless of the app theme.

---

## Core API cheatsheet

### `BrowserTab` *(immutable — never mutate fields directly; v2.5)*

| Field | Required | Type | Description |
|---|---|---|---|
| `id` | ✅ | `int` | Stable unique identity — never reuse. |
| `title` | ✅ | `String` | Display text. |
| `pageBuilder` | ✅ | `TabPageBuilder` | Builds the page content (v2.5 — required). |
| `icon` | — | `IconData?` | Leading chip icon. Use `glTabIcon(GLTabKind.x)` for the legacy set. Default `null` (no icon). |
| `dirty` | — | `bool` | Unsaved dot + confirm on close. Default `false`. |
| `pinned` | — | `bool` | Icon-only, anchored start edge. Default `false`. |
| `behavior` | — | `SuperTabBehavior` | UI guards. Default `normal`. |
| `uniqueKey` | — | `String?` | Dedup key for `uniqueNormal` tabs. |

**Never** write `tab.dirty = true` — use `ctrl.setDirty(id, true)` instead.

> `pageBuilder` is excluded from `==`/`hashCode` — two tabs with different
> builders but matching data fields are considered equal.

### `SuperTabBehavior`

| Value | Close (UI) | Unpin (UI) | Duplicate (UI) | Programmatic close |
|---|---|---|---|---|
| `requiredPinned` | ✗ | ✗ | ✗ | ✓ |
| `normal` | ✓ | ✓ | ✓ | ✓ |
| `uniqueNormal` | ✓ | ✓ | ✗ | ✓ |

### `SuperTabBarController` operations

| Method | Effect |
|---|---|
| `select(id)` | Activate tab. |
| `add({pageBuilder, title, icon, activate, pinned, at, behavior, uniqueKey})` | Add tab; returns id. `pageBuilder` is **required** since v2.5. For `uniqueNormal` with matching `uniqueKey`: activates existing, returns existing id. |
| `close(id)` | Remove; activates neighbour. |
| `forceClose(id)` | Explicit alias for close — use for `requiredPinned` tabs. |
| `closeOthers(id)` | Close all non-pinned except `id`. Guard: `canCloseOthers(id)`. |
| `closeToRight(id)` | Close all non-pinned after `id`. Guard: `canCloseRight(id)`. |
| `duplicate(id)` | Clone as next sibling; returns new id or `-1` if disallowed. `duplicate()` copies `icon` + `pageBuilder` (v2.5). |
| `togglePin(id)` | Flip pinned. No-op for `requiredPinned`. |
| `reorder(fromId, toId)` | Move tab. |
| `setDirty(id, bool)` | Set/clear unsaved flag; fires `onDirtyChanged`. |
| `rename(id, title)` | Update title; fires `onRenamed`. |
| `mutate(fn)` | Batch ops — notifies once on return. |

UI-behavior guards (used internally; expose in your own UI if needed):
`canCloseFromUi(id)` · `canDuplicateFromUi(id)` · `canTogglePinFromUi(id)`

### `SuperTabBar` key props

| Prop | Default | Purpose |
|---|---|---|
| `tabsState` | — | Seed tabs (widget owns controller). |
| `controller` | — | External controller. Provide one OR `tabsState`. |
| `onAddTab` | `null` | v2.5 · Handler for the `+` button. When `null` the `+` button is not rendered. The widget no longer auto-creates tabs. |
| `showChrome` | `true` | Bordered card (`false` = edge-to-edge). |
| `compact` | `false` | Hide the strip unconditionally. |
| `allowAutoCompact` | `false` | v2.2 · Auto-hide strip when widget width ≤ `compactWidth`. |
| `compactWidth` | `600.0` | v2.2 · Breakpoint (logical px). Phone default. |
| `useCompactFloatingActionButton` | `false` | v2.3 · Built-in FAB in compact mode; opens the switcher. |
| `closeTabOnBack` | `false` | v2.1 · Back closes the active tab — unless it is dirty. |
| `fillContent` | `false` | Page fills all height. |
| `scrollContent` | `true` | Wrap in `SingleChildScrollView`. |
| `contentPadding` | `all(24)` | Padding inside content surface. |
| `lazyPages` | `false` | Rebuild-on-revisit (disables state preservation). |
| `localizations` | `.en` | `SuperTabBarLocalizations` instance. |
| `previewOptions` | defaults | `SuperTabBarPreviewOptions` instance. |
| `onTabSelected` | — | `void Function(int id)` |
| `onTabAdded` | — | `void Function(int id)` — deprecated since v2.5 (not fired by (+)). |
| `onTabClosed` | — | `void Function(int id)` |
| `onTabDuplicated` | — | `void Function(int newId)` |
| `onTabPinChanged` | — | `void Function(int id, bool isPinned)` |
| `onTabDirtyChanged` | — | `void Function(int id, bool isDirty)` — fires from save-close dialog |
| `onTabReordered` | — | `void Function(int fromId, int toId)` |

> **Removed in v2.5.** `SuperTabBar.pageBuilder` — moved to each
> `BrowserTab.pageBuilder` (required).

### Context lookup

```dart
// Listening (use in build()):
SuperTabBarController.of(context)?.add(
  title: 'Detail', icon: glTabIcon(GLTabKind.doc),
  pageBuilder: (ctx, tab) => DetailPage(tab: tab),
);

// Non-listening (use in callbacks / initState):
SuperTabBarController.read(context)?.setDirty(tabId, true);
```

Both return `null` outside a `SuperTabBar` — always guard.

### Localizations

```dart
SuperTabBar(localizations: SuperTabBarLocalizations.ar)   // built-in Arabic
SuperTabBar(localizations: SuperTabBarLocalizations.en)   // default English
// Or pass a fully custom instance with all 16 required fields.
```

### Preview options

```dart
SuperTabBarPreviewOptions.defaults   // 480 ms delay, 0.6× ratio, liveRender
SuperTabBarPreviewOptions.disabled   // turn off previews entirely
const SuperTabBarPreviewOptions(
  hoverDelay: Duration(milliseconds: 250),
  snapshotPixelRatio: 1.0,
  fallback: PreviewFallback.blank,   // or .liveRender
)
```

---

## Patterns

### Pattern A — Zero-config

```dart
const SuperTabBar()
```

Owns a private controller seeded with five demo tabs (each with its own
`pageBuilder` rendering the built-in `GLTabPage` content).

### Pattern B — Seeded tabs (v2.5 — per-tab pageBuilder + icon)

```dart
SuperTabBar(tabsState: [
  BrowserTab(
    id: 1, title: 'Accounts', icon: glTabIcon(GLTabKind.ledger),
    pinned: true, behavior: SuperTabBehavior.requiredPinned,
    pageBuilder: (ctx, tab) => GLTabPage(tab: tab, kind: GLTabKind.ledger),
  ),
  BrowserTab(
    id: 2, title: 'Journal', icon: glTabIcon(GLTabKind.doc), dirty: true,
    pageBuilder: (ctx, tab) => GLTabPage(tab: tab, kind: GLTabKind.doc),
  ),
  BrowserTab(
    id: 3, title: 'Dashboard', icon: glTabIcon(GLTabKind.chart),
    pageBuilder: (ctx, tab) => GLTabPage(tab: tab, kind: GLTabKind.chart),
  ),
])
```

### Pattern C — External controller + per-tab pageBuilder + callbacks

```dart
class _State extends State<MyShell> {
  late final SuperTabBarController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = SuperTabBarController(
      tabs: [
        BrowserTab(
          id: 1, title: 'Home', icon: glTabIcon(GLTabKind.globe),
          pinned: true, behavior: SuperTabBehavior.requiredPinned,
          pageBuilder: (ctx, tab) => Center(child: Text(tab.title)),
        ),
        BrowserTab(
          id: 2, title: 'New Entry', icon: glTabIcon(GLTabKind.doc),
          pageBuilder: (ctx, tab) =>
              JournalForm(onEdit: () => _ctrl.setDirty(tab.id, true)),
        ),
      ],
      activeId: 2,
    );
    _ctrl.onDirtyChanged = (id, dirty) => debugPrint('dirty $id: $dirty');
    _ctrl.onRenamed      = (id, title) => debugPrint('rename $id: $title');
  }

  void _onAddTab() {
    // The (+) button only shows because onAddTab is provided (v2.5).
    _ctrl.add(
      title: 'New Tab', icon: glTabIcon(GLTabKind.doc),
      pageBuilder: (ctx, tab) => Center(child: Text(tab.title)),
    );
  }

  @override
  Widget build(BuildContext ctx) => SuperTabBar(
    controller: _ctrl,
    onAddTab: _onAddTab,           // v2.5 — (+) button visible
    showChrome: false,
    fillContent: true,
    onTabSelected:   (id)      => debugPrint('selected $id'),
    onTabClosed:     (id)      => debugPrint('closed $id'),
    onTabReordered:  (f, t)    => debugPrint('reorder $f→$t'),
  );

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
}
```

### Pattern D — uniqueNormal singleton tab

```dart
// Settings can only be open once:
ctrl.add(
  title: 'Settings', icon: glTabIcon(GLTabKind.user),
  behavior: SuperTabBehavior.uniqueNormal, uniqueKey: 'settings',
  pageBuilder: (ctx, tab) => SettingsPage(tab: tab),
);
// Second call — activates existing tab, returns existing id, no duplicate:
ctrl.add(
  title: 'Settings', icon: glTabIcon(GLTabKind.user),
  behavior: SuperTabBehavior.uniqueNormal, uniqueKey: 'settings',
  pageBuilder: (ctx, tab) => SettingsPage(tab: tab),
);
```

### Pattern E — Arabic / RTL

```dart
Directionality(
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
        id: 2, title: 'قيد يومية', icon: glTabIcon(GLTabKind.doc),
        pageBuilder: (ctx, tab) => GLTabPage(tab: tab, kind: GLTabKind.doc),
      ),
      BrowserTab(
        id: 3, title: 'لوحة التحكم', icon: glTabIcon(GLTabKind.chart),
        pageBuilder: (ctx, tab) => GLTabPage(tab: tab, kind: GLTabKind.chart),
      ),
    ],
  ),
)
```

---

## RTL

```dart
Directionality(textDirection: TextDirection.rtl, child: SuperTabBar(...))
```

Mirrors: pinned anchor, chevrons, drag indicator, `▾` dropdown, compact switcher.

---

## Built-in compact FAB (v2.3)

```dart
// Zero boilerplate — the FAB appears automatically in compact mode.
SuperTabBar(
  controller: ctrl,
  allowAutoCompact: true,
  useCompactFloatingActionButton: true,
  closeTabOnBack: true,
  fillContent: true,
)
```

The FAB is rendered over the content area at the bottom-end corner (RTL-aware).
`onTabClosed` is forwarded to the switcher it opens; thumbnail content comes
from each tab's `BrowserTab.pageBuilder` (v2.5).

## Auto-compact breakpoint (v2.2)

```dart
// Strip disappears automatically on phones; stays on tablet/desktop.
SuperTabBar(
  controller: ctrl,
  allowAutoCompact: true,  // no MediaQuery needed
  compactWidth: 600,       // phone default; 768 for small tablets
  closeTabOnBack: true,
  fillContent: true,
)
```

`compact: true` always wins. `allowAutoCompact` uses `LayoutBuilder` (widget
width, not screen width) — correct inside split-view.

## Compact mode (v2.1)

For phones: hide the strip and switch tabs from a full-screen thumbnail grid.

```dart
// Hide the strip; back closes the active tab unless dirty.
SuperTabBar(controller: ctrl, compact: true, closeTabOnBack: true,
           showChrome: false, fillContent: true);

// Open the switcher (e.g. from a FloatingActionButton). Returns picked id / null.
final picked = await showSuperTabSwitcher(
  context,
  controller: ctrl,
  onCloseTab: (id) => myDirtyAwareClose(id),    // optional
);
```

> **v2.5.** `showSuperTabSwitcher` no longer takes a `pageBuilder` parameter —
> thumbnail content comes from each tab's `BrowserTab.pageBuilder`. Inside the
> switcher: tap a thumbnail to switch · long-press-drag to reorder
> (`ctrl.reorder`) · × to close. `SuperTabSwitcher` can also be embedded
> directly (e.g. bottom sheet) via `onSelect` / `onDismiss`.

`closeTabOnBack: true` closes the active tab on the system back gesture only
when it is **not** dirty (dirty tabs stay open). Uses `PopScope` (Flutter ≥ 3.16).

---

## Keyboard shortcuts

| Key | Action |
|---|---|
| `Esc` | Close open menu / dropdown |

**Removed in v2.1:** the tab-navigation keys (`← →`, `Home`/`End`,
`Ctrl/Cmd+T`, `Ctrl/Cmd+W`) and `horizontalStep` / `arrowGoesInto`. Use compact
mode + the tab switcher on mobile.

---

## Backward compatibility (v1 → v2)

v1 names are live `typedef` aliases — existing code compiles unchanged.

| v1 | v2 |
|---|---|
| `BrowserStyleTabBar` | `SuperTabBar` |
| `BrowserStyleTabBarController` | `SuperTabBarController` |
| `BrowserStyleTabBarThemeData` | `SuperTabBarThemeData` |
| `BrowserStyleTabBarScope` | `SuperTabBarScope` |
| `showGLDirtyCloseDialog` | `showSuperTabDirtyCloseDialog` |

**v1 → v2 breaking change:** direct `BrowserTab` field mutation
(`tab.dirty = true`) no longer compiles. Use `ctrl.setDirty(id, true)`.

**v2.x → v2.5 breaking changes:**
1. `SuperTabBar.pageBuilder` removed — moved to `BrowserTab.pageBuilder` (required).
2. `BrowserTab.kind` removed — use `icon` + `pageBuilder` directly.
3. `SuperTabBarController.add(kind:)` removed; `pageBuilder` required, `icon` added.
4. The (+) strip button only renders when `SuperTabBar.onAddTab` is provided;
   the widget no longer auto-creates tabs, and `onTabAdded` is no longer fired
   from the (+) button.

---

## Common mistakes

- **Reusing tab ids** — all operations key on `id`. Never reuse after close.
- **Mutating `BrowserTab` fields directly** — `@immutable` since v2. Use controller methods.
- **Forgetting theme extension** — widget falls back to dark preset.
- **Not guarding `of(context)`** — returns null outside a tab bar.
- **Passing both `tabsState` and `controller`** — provide exactly one.
- **Expecting page state to reset** — default `IndexedStack` keeps pages alive. Use `lazyPages: true` to opt out.
- **Expecting the (+) button without `onAddTab` (v2.5)** — the (+) button is
  only rendered when `onAddTab` is provided.
- **Passing `pageBuilder` to `SuperTabBar` (v2.5)** — removed; put it on each
  `BrowserTab` instead.
- **Passing `kind` to `BrowserTab` (v2.5)** — removed; pass `icon`
  (`glTabIcon(GLTabKind.x)`) and `pageBuilder` explicitly.

## Reference

- **Examples:** `EXAMPLES.md` in this folder.
- README: `../../README.md`
- Source: `../../lib/src/`