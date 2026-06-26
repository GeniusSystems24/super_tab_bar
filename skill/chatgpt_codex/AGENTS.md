# super_tab_bar - ChatGPT / Codex agent instructions

Use these instructions when asked to build or modify a Flutter UI that needs a
browser-style workspace tab bar using the `super_tab_bar` package.

## Package

```yaml
name: super_tab_bar
version: 2.0.0
import: package:super_tab_bar/super_tab_bar.dart
```

`SuperTabBar`, `SuperTabBarController`, `SuperTabBarScope`, and
`SuperTabBarThemeData` are the primary v2 APIs. The old
`BrowserStyleTabBar*` names remain available as typedef aliases for existing
code.

## When To Use

Apply this skill when the user asks for:

- multi-tab Flutter workspaces or browser-like tab strips
- pinned, closable, dirty, or draggable tabs
- required pinned tabs or unique tabs that should focus instead of duplicate
- live hover previews or disabled/safe previews
- state-preserving tab pages in Flutter
- localized context menus, dirty-close dialogs, or tab controls

## Mandatory Setup

### Add To `pubspec.yaml`

```yaml
dependencies:
  super_tab_bar: ^2.0.0
```

### Register The Theme Extension

```dart
import 'package:super_tab_bar/super_tab_bar.dart';

MaterialApp(
  theme: ThemeData(extensions: const [SuperTabBarThemeData.light]),
  darkTheme: ThemeData(extensions: const [SuperTabBarThemeData.dark]),
)
```

Without this, the widget still renders but falls back to the package preset.

## Core API Cheatsheet

### `BrowserTab`

`BrowserTab` is immutable. Change tab state through `SuperTabBarController`
methods, not by mutating model fields.

| Field | Required | Description |
|---|---|---|
| `id` | yes | Stable unique int. Never reuse after close. |
| `title` | yes | Display string. |
| `kind` | yes | `GLTabKind.ledger/doc/store/chart/user/globe` |
| `dirty` | no | Unsaved dot and close confirmation. Default `false`. |
| `pinned` | no | Icon-only, anchored at the start edge. Default `false`. |
| `behavior` | no | `SuperTabBehavior.normal` by default. |
| `uniqueKey` | no | Deduplication key for `uniqueNormal` tabs. |

### `SuperTabBehavior`

| Behavior | UI Behavior |
|---|---|
| `requiredPinned` | Always pinned; UI hides close, duplicate, and unpin. Programmatic `close` still works. |
| `normal` | Standard close, duplicate, pin, unpin actions. |
| `uniqueNormal` | Close and pin allowed; duplicate hidden. `add` with the same `uniqueKey` focuses the existing tab. |

### `SuperTabBarController`

| Method | Effect |
|---|---|
| `select(id)` | Activate tab. |
| `add(...)` | Append or insert tab; returns affected id. |
| `close(id)` / `forceClose(id)` | Remove tab. |
| `closeOthers(id)` | Close all non-pinned tabs except `id`. |
| `closeToRight(id)` | Close all non-pinned tabs after `id`. |
| `duplicate(id)` | Clone tab if behavior permits; returns new id or `-1`. |
| `togglePin(id)` / `setPinned(id, bool)` | Change pin state. |
| `reorder(fromId, toId)` | Move tab. |
| `setDirty(id, bool)` | Set or clear dirty flag. |
| `rename(id, title)` | Update display title. |
| `mutate(id, updater)` | Replace a tab via `copyWith`. |

Controller callbacks:

```dart
tabs.onDirtyChanged = (id, dirty) {};
tabs.onRenamed = (id, title) {};
```

### `SuperTabBar`

| Prop | Default | Purpose |
|---|---|---|
| `tabsState` | package defaults | Seed state when the widget owns the controller. |
| `controller` | null | External controller. Provide this or `tabsState`. |
| `pageBuilder` | built-in `GLTabPage` | Custom page per tab and hover preview. |
| `showChrome` | `true` | Bordered card shell; `false` is edge-to-edge. |
| `fillContent` | `false` | Page fills all available height. |
| `lazyPages` | `false` | Rebuild on revisit; disables state preservation. |
| `scrollContent` | `true` | Wrap active page in `SingleChildScrollView`. |
| `contentPadding` | `EdgeInsets.all(24)` | Active page padding. |
| `contentBackground` | theme surface | Active page background. |
| `onAddTab` | null | Override the plus button. |
| `localizations` | English | Override user-facing strings; `.en` and `.ar` are built in. |
| `previewOptions` | defaults | Enable/disable hover previews and tune delay/snapshot quality. |

Event callbacks:

```dart
SuperTabBar(
  onTabSelected: (id) {},
  onTabAdded: (id) {},
  onTabClosed: (id) {},
  onTabDuplicated: (newId) {},
  onTabPinChanged: (id, pinned) {},
  onTabDirtyChanged: (id, dirty) {},
  onTabReordered: (fromId, toId) {},
)
```

## Patterns

### Zero-Config Demo

```dart
const SuperTabBar()
```

### Seeded Workspace

```dart
SuperTabBar(
  tabsState: const [
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
)
```

### External Controller And Custom Pages

```dart
class WorkspaceShell extends StatefulWidget {
  const WorkspaceShell({super.key});

  @override
  State<WorkspaceShell> createState() => _WorkspaceShellState();
}

class _WorkspaceShellState extends State<WorkspaceShell> {
  final tabs = SuperTabBarController(
    tabs: const [
      BrowserTab(
        id: 1,
        title: 'Accounts',
        kind: GLTabKind.ledger,
        pinned: true,
        behavior: SuperTabBehavior.requiredPinned,
      ),
      BrowserTab(id: 2, title: 'New Entry', kind: GLTabKind.doc),
    ],
    activeId: 2,
  );

  @override
  Widget build(BuildContext context) {
    return SuperTabBar(
      controller: tabs,
      pageBuilder: (context, tab) => tab.kind == GLTabKind.doc
          ? JournalEntryForm(onEdit: () => tabs.setDirty(tab.id, true))
          : Center(child: Text(tab.title)),
      showChrome: false,
      fillContent: true,
    );
  }

  @override
  void dispose() {
    tabs.dispose();
    super.dispose();
  }
}
```

### Open Or Focus A Unique Tab

```dart
final id = tabs.add(
  title: 'Customer A-100',
  kind: GLTabKind.user,
  behavior: SuperTabBehavior.uniqueNormal,
  uniqueKey: 'customer:A-100',
);
```

Calling `add` again with the same `uniqueKey` activates the existing tab and
returns its id.

### Open A Tab From Page Content

```dart
SuperTabBarController.of(context)?.add(
  title: 'Detail',
  kind: GLTabKind.doc,
);
```

Use `SuperTabBarController.read(context)` for callbacks and `initState`.
Both return null outside a `SuperTabBar`, so always guard calls.

### Localized RTL Workspace

```dart
Directionality(
  textDirection: TextDirection.rtl,
  child: SuperTabBar(
    localizations: SuperTabBarLocalizations.ar,
    tabsState: const [
      BrowserTab(id: 1, title: 'دليل الحسابات', kind: GLTabKind.ledger, pinned: true),
      BrowserTab(id: 2, title: 'قيد يومية', kind: GLTabKind.doc),
    ],
  ),
)
```

### Preview Options

```dart
SuperTabBar(previewOptions: SuperTabBarPreviewOptions.disabled)

SuperTabBar(
  previewOptions: const SuperTabBarPreviewOptions(
    hoverDelay: Duration(milliseconds: 250),
    snapshotPixelRatio: 1.0,
    fallback: PreviewFallback.blank,
  ),
)
```

## Common Mistakes

- Reusing tab `id`s. Operations key on `id`; always allocate a new one.
- Mutating `BrowserTab` fields directly. It is immutable; use controller methods.
- Passing both `tabsState` and `controller`.
- Expecting required pinned tabs to be impossible to close from code. The limit is UI-level.
- Expecting page state to reset. Default `IndexedStack` keeps pages alive; use `lazyPages: true` to opt out.
- Forgetting `SuperTabBarThemeData` in `ThemeData.extensions`.
- Not guarding `SuperTabBarController.of(context)` / `read(context)`.
