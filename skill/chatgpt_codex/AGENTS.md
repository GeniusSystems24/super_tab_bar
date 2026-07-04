# super_tab_bar — ChatGPT / Codex agent instructions (v2.2)

Use these instructions when asked to build or modify a Flutter UI that needs a
**browser-style workspace tab bar** using the `super_tab_bar` package.

---

## Package

```
name:    super_tab_bar
version: 2.1.0
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

---

## Mandatory setup

### 1 · `pubspec.yaml`

```yaml
dependencies:
  super_tab_bar: ^2.2.0
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

### `BrowserTab` *(immutable — never mutate fields directly)*

| Field | Required | Type | Description |
|---|---|---|---|
| `id` | ✅ | `int` | Stable unique identity — never reuse. |
| `title` | ✅ | `String` | Display text. |
| `kind` | ✅ | `GLTabKind` | `ledger·doc·store·chart·user·globe` |
| `dirty` | — | `bool` | Unsaved dot + confirm on close. Default `false`. |
| `pinned` | — | `bool` | Icon-only, anchored start edge. Default `false`. |
| `behavior` | — | `SuperTabBehavior` | UI guards. Default `normal`. |
| `uniqueKey` | — | `String?` | Dedup key for `uniqueNormal` tabs. |

**Never** write `tab.dirty = true` — use `ctrl.setDirty(id, true)` instead.

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
| `add({title, kind, activate, pinned, at, behavior, uniqueKey})` | Add tab; returns id. For `uniqueNormal` with matching `uniqueKey`: activates existing, returns existing id. |
| `close(id)` | Remove; activates neighbour. |
| `forceClose(id)` | Explicit alias for close — use for `requiredPinned` tabs. |
| `closeOthers(id)` | Close all non-pinned except `id`. Guard: `canCloseOthers(id)`. |
| `closeToRight(id)` | Close all non-pinned after `id`. Guard: `canCloseRight(id)`. |
| `duplicate(id)` | Clone as next sibling; returns new id or `-1` if disallowed. |
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
| `pageBuilder` | `null` | Custom page per tab; falls back to `GLTabPage`. |
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
| `onAddTab` | `null` | Intercept `+` button. Note: suppresses `onTabAdded`. |
| `localizations` | `.en` | `SuperTabBarLocalizations` instance. |
| `previewOptions` | defaults | `SuperTabBarPreviewOptions` instance. |
| `onTabSelected` | — | `void Function(int id)` |
| `onTabAdded` | — | `void Function(int id)` |
| `onTabClosed` | — | `void Function(int id)` |
| `onTabDuplicated` | — | `void Function(int newId)` |
| `onTabPinChanged` | — | `void Function(int id, bool isPinned)` |
| `onTabDirtyChanged` | — | `void Function(int id, bool isDirty)` — fires from save-close dialog |
| `onTabReordered` | — | `void Function(int fromId, int toId)` |

### Context lookup

```dart
// Listening (use in build()):
SuperTabBarController.of(context)?.add(title: 'Detail', kind: GLTabKind.doc);

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

### Pattern B — Seeded tabs

```dart
SuperTabBar(tabsState: const [
  BrowserTab(id: 1, title: 'Accounts', kind: GLTabKind.ledger,
      pinned: true, behavior: SuperTabBehavior.requiredPinned),
  BrowserTab(id: 2, title: 'Journal',  kind: GLTabKind.doc, dirty: true),
  BrowserTab(id: 3, title: 'Dashboard',kind: GLTabKind.chart),
])
```

### Pattern C — External controller + dirty flow + callbacks

```dart
class _State extends State<MyShell> {
  late final SuperTabBarController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = SuperTabBarController(
      tabs: const [
        BrowserTab(id: 1, title: 'Home', kind: GLTabKind.globe,
            pinned: true, behavior: SuperTabBehavior.requiredPinned),
        BrowserTab(id: 2, title: 'New Entry', kind: GLTabKind.doc),
      ],
      activeId: 2,
    );
    _ctrl.onDirtyChanged = (id, dirty) => debugPrint('dirty $id: $dirty');
    _ctrl.onRenamed      = (id, title) => debugPrint('rename $id: $title');
  }

  @override
  Widget build(BuildContext ctx) => SuperTabBar(
    controller: _ctrl,
    pageBuilder: (ctx, tab) => tab.kind == GLTabKind.doc
        ? JournalForm(onEdit: () => _ctrl.setDirty(tab.id, true))
        : Center(child: Text(tab.title)),
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
  title: 'Settings', kind: GLTabKind.user,
  behavior: SuperTabBehavior.uniqueNormal, uniqueKey: 'settings',
);
// Second call — activates existing tab, returns existing id, no duplicate:
ctrl.add(
  title: 'Settings', kind: GLTabKind.user,
  behavior: SuperTabBehavior.uniqueNormal, uniqueKey: 'settings',
);
```

### Pattern E — Arabic / RTL

```dart
Directionality(
  textDirection: TextDirection.rtl,
  child: SuperTabBar(
    localizations: SuperTabBarLocalizations.ar,
    tabsState: const [
      BrowserTab(id: 1, title: 'دليل الحسابات', kind: GLTabKind.ledger,
          pinned: true, behavior: SuperTabBehavior.requiredPinned),
      BrowserTab(id: 2, title: 'قيد يومية', kind: GLTabKind.doc),
      BrowserTab(id: 3, title: 'لوحة التحكم', kind: GLTabKind.chart),
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
`pageBuilder` and `onTabClosed` are forwarded to the switcher it opens.

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
  pageBuilder: (ctx, tab) => MyPage(tab: tab),  // live thumbnail fallback
  onCloseTab: (id) => myDirtyAwareClose(id),    // optional
);
```

Inside the switcher: tap a thumbnail to switch · long-press-drag to reorder
(`ctrl.reorder`) · × to close. `SuperTabSwitcher` can also be embedded directly
(e.g. bottom sheet) via `onSelect` / `onDismiss`.

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

**Only breaking change:** direct `BrowserTab` field mutation (`tab.dirty = true`)
no longer compiles. Use `ctrl.setDirty(id, true)`.

---

## Common mistakes

- **Reusing tab ids** — all operations key on `id`. Never reuse after close.
- **Mutating `BrowserTab` fields directly** — `@immutable` since v2. Use controller methods.
- **Forgetting theme extension** — widget falls back to dark preset.
- **Not guarding `of(context)`** — returns null outside a tab bar.
- **Passing both `tabsState` and `controller`** — provide exactly one.
- **Expecting page state to reset** — default `IndexedStack` keeps pages alive. Use `lazyPages: true` to opt out.
- **Setting `onAddTab` and expecting `onTabAdded`** — `onAddTab` suppresses `onTabAdded`.

## Reference

- **Examples:** `EXAMPLES.md` in this folder.
- README: `../../README.md`
- Source: `../../lib/src/`
