# super_tab_bar — ChatGPT / Codex agent instructions

Use these instructions when asked to build or modify a Flutter UI that needs a
**browser-style workspace tab bar** using the `super_tab_bar` package.

---

## Package

```
name:    super_tab_bar
version: 1.0.0
import:  package:super_tab_bar/super_tab_bar.dart
```

## When to use

Apply this skill when the user asks for:
- "multi-tab workspace", "browser-like tabs", "tab strip like Chrome"
- "dirty tab indicator", "unsaved changes tab"
- "pinned workspace tab", "draggable tabs"
- "live tab preview", "mini page preview on hover"
- state-preserving tab pages in Flutter

## Mandatory setup

### 1 · Add to `pubspec.yaml`

```yaml
dependencies:
  super_tab_bar: ^1.0.0
```

### 2 · Register the theme extension

```dart
import 'package:super_tab_bar/super_tab_bar.dart';

MaterialApp(
  theme:     ThemeData(extensions: const [BrowserStyleTabBarThemeData.light]),
  darkTheme: ThemeData(extensions: const [BrowserStyleTabBarThemeData.dark]),
)
```

Without this the widget renders but uses the dark preset regardless of
the app theme.

---

## Core API cheatsheet

### `BrowserTab` model

| Field | Required | Description |
|---|---|---|
| `id` | ✅ | Stable unique int — never reuse. |
| `title` | ✅ | Display string. |
| `kind` | ✅ | `GLTabKind.ledger/doc/store/chart/user/globe` |
| `dirty` | — | Unsaved dot + confirm on close. Default `false`. |
| `pinned` | — | Icon-only, anchored start edge. Default `false`. |

### `BrowserStyleTabBarController` operations

| Method | Effect |
|---|---|
| `select(id)` | Activate tab. |
| `add({title, kind})` | Append tab; returns new `id`. |
| `close(id)` | Remove tab; activates neighbour. |
| `closeOthers(id)` | Close all non-pinned except `id`. |
| `closeToRight(id)` | Close all non-pinned after `id`. |
| `duplicate(id)` | Clone as next sibling; activates copy. |
| `togglePin(id)` | Flip pinned. |
| `reorder(fromId, toId)` | Move tab. |
| `setDirty(id, bool)` | Set/clear unsaved flag. |
| `rename(id, title)` | Update display title. |

### `BrowserStyleTabBar` key props

| Prop | Default | Purpose |
|---|---|---|
| `tabsState` | — | Seed state (widget owns controller). |
| `controller` | — | External controller. Provide one OR tabsState. |
| `pageBuilder` | `null` | Custom page per tab. Falls back to `GLTabPage`. |
| `showChrome` | `true` | Bordered card. `false` = edge-to-edge. |
| `fillContent` | `false` | Page fills all height. |
| `lazyPages` | `false` | Rebuild-on-revisit (disables state preservation). |
| `onAddTab` | `null` | Intercept `+` button. |

---

## Patterns

### Pattern A — Zero-config demo

```dart
const BrowserStyleTabBar()
```

### Pattern B — Seeded workspace

```dart
BrowserStyleTabBar(
  tabsState: [
    BrowserTab(id: 1, title: 'Accounts',       kind: GLTabKind.ledger, pinned: true),
    BrowserTab(id: 2, title: 'Journal Entry',  kind: GLTabKind.doc,    dirty: true),
    BrowserTab(id: 3, title: 'Dashboard',       kind: GLTabKind.chart),
  ],
)
```

### Pattern C — External controller + custom pages + dirty flow

```dart
class _State extends State<MyShell> {
  final _tabs = BrowserStyleTabBarController(
    tabs: [
      BrowserTab(id: 1, title: 'Accounts', kind: GLTabKind.ledger, pinned: true),
      BrowserTab(id: 2, title: 'New Entry', kind: GLTabKind.doc),
    ],
    activeId: 2,
  );

  @override
  Widget build(BuildContext ctx) => BrowserStyleTabBar(
    controller: _tabs,
    pageBuilder: (ctx, tab) => tab.kind == GLTabKind.doc
        ? JournalEntryForm(onEdit: () => _tabs.setDirty(tab.id, true))
        : Center(child: Text(tab.title)),
    showChrome: false,
    fillContent: true,
  );

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }
}
```

### Open a tab from inside a page

```dart
// Returns null outside a BrowserStyleTabBar — always guard:
BrowserStyleTabBarController.of(context)
    ?.add(title: 'Detail', kind: GLTabKind.doc);
```

---

## RTL

```dart
Directionality(
  textDirection: TextDirection.rtl,
  child: BrowserStyleTabBar(...),
)
```

---

## Common mistakes

- Reusing tab `id`s — operations key on `id`; always use a new one.
- Forgetting `ThemeData(extensions: [BrowserStyleTabBarThemeData.light])` —
  widget falls back to dark preset.
- Not guarding `of(context)` — returns null outside a tab bar.
- Passing both `tabsState:` and `controller:` — provide exactly one.
- Expecting page state to reset: the default `IndexedStack` keeps pages
  alive. Use `lazyPages: true` to opt out.
