# super_tab_bar

[![pub package](https://img.shields.io/badge/pub-v2.2.0-4A7CFF.svg)](https://pub.dev/packages/super_tab_bar)
[![flutter](https://img.shields.io/badge/Flutter-%E2%89%A53.16-1DB88A.svg)](https://flutter.dev)
[![license](https://img.shields.io/badge/license-MIT-64748B.svg)](#license)

A browser-style workspace tab bar for Flutter — pinned / dirty / closable tabs,
configurable **tab behavior types** (`requiredPinned` · `normal` · `uniqueNormal`),
drag-to-reorder, context menu, overflow dropdown, **live mini-page previews** on
hover, **state-preserving pages**, **localization support**, **direct event
callbacks**, and accessibility semantics. New in 2.1: a mobile **compact mode**
with a draggable thumbnail **tab switcher** and **dirty-aware back navigation**.
RTL throughout. Zero third-party dependencies.

---

## Features

- 🗂 **Browser-style strip** — active tab merges with the content surface.
- 📌 **Pinned tabs** — icon-only, anchored to the start edge.
- 💾 **Dirty tabs** — unsaved-changes dot; close triggers a confirm dialog.
- ↔ **Drag-to-reorder** — drag any unpinned tab; blue indicator marks the drop.
- 📋 **Context menu** — right-click / long-press: close · close others ·
  close to right · duplicate · pin / unpin. Items hidden automatically
  based on `SuperTabBehavior`.
- ⟩ **Overflow** — scroll chevrons + `▾` dropdown list.
- 👁 **Live preview** — hover-intent popover with the page's **real
  `RepaintBoundary` capture** — live state, data and scroll position.
  Fully configurable via `SuperTabBarPreviewOptions`.
- ♻ **State-preserving pages** — `IndexedStack` keeps every page mounted;
  scroll, text-field and controller state survives tab switches. Opt out
  with `lazyPages: true`.
- 🔒 **Tab behavior types** — `requiredPinned` (always pinned, UI-locked),
  `normal` (full operations), `uniqueNormal` (no duplicate, deduplicates on
  re-open by `uniqueKey`).
- 🔔 **Direct callbacks** — `onTabSelected`, `onTabAdded`, `onTabClosed`,
  `onTabDuplicated`, `onTabPinChanged`, `onTabDirtyChanged`,
  `onTabReordered` — no need to listen to the controller for common events.
- 📱 **Compact mode** — hide the strip on phones and switch tabs from a
  full-screen grid of thumbnail previews (`SuperTabSwitcher` /
  `showSuperTabSwitcher`). Tap to switch, **drag a thumbnail to reorder**.
- 📐 **Auto-compact breakpoint** — `allowAutoCompact: true` + `compactWidth`
  switch the widget into compact mode automatically based on its layout width.
  No `MediaQuery` boilerplate needed.
- 🔙 **Dirty-aware back** — `closeTabOnBack` closes the current tab on a back
  gesture, but never a dirty one.
- 🌐 **Localization** — all user-facing strings in `SuperTabBarLocalizations`;
  built-in English and Arabic presets.
- ♿ **Accessibility** — `Semantics` on every tab chip, close button and
  context-menu row.
- 🌍 **RTL** — strip, chevrons, drag, dropdown and switcher all mirror.
- 🔌 **Zero dependencies** — pure Flutter + Material.

---

## Installation

```yaml
dependencies:
  super_tab_bar: ^2.2.0
```

```bash
flutter pub get
```

---

## Setup

Register `SuperTabBarThemeData` on your `MaterialApp`:

```dart
import 'package:super_tab_bar/super_tab_bar.dart';

MaterialApp(
  theme: ThemeData(
    extensions: const [SuperTabBarThemeData.light],
  ),
  darkTheme: ThemeData(
    extensions: const [SuperTabBarThemeData.dark],
  ),
  home: const MyHome(),
);
```

The widget falls back to the dark preset if nothing is registered.

---

## Quick start

### 1 · Zero-config

```dart
const SuperTabBar();
```

Owns a private controller seeded with five demo tabs.

### 2 · External controller + custom pages

```dart
class _WorkspaceState extends State<Workspace> {
  final _ctrl = SuperTabBarController(
    tabs: [
      const BrowserTab(id: 1, title: 'Home', kind: GLTabKind.globe,
          pinned: true, behavior: SuperTabBehavior.requiredPinned),
      const BrowserTab(id: 2, title: 'Settings', kind: GLTabKind.user,
          behavior: SuperTabBehavior.uniqueNormal, uniqueKey: 'settings'),
      const BrowserTab(id: 3, title: 'Dashboard', kind: GLTabKind.chart),
    ],
    activeId: 3,
  );

  @override
  Widget build(BuildContext context) => SuperTabBar(
    controller: _ctrl,
    pageBuilder: (ctx, tab) => MyPage(tab: tab),
    showChrome: false,
    fillContent: true,
    onTabSelected: (id) => debugPrint('selected $id'),
    onTabClosed:   (id) => debugPrint('closed $id'),
  );

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
}
```

---

## Tab behavior types

`SuperTabBehavior` controls which UI actions are visible per tab.

| Behavior | Close (UI) | Unpin (UI) | Duplicate (UI) | Programmatic close |
|---|---|---|---|---|
| `requiredPinned` | ✗ hidden | ✗ hidden | ✗ hidden | ✓ always |
| `normal` | ✓ | ✓ | ✓ | ✓ |
| `uniqueNormal` | ✓ | ✓ | ✗ hidden | ✓ |

### `requiredPinned`

Always pinned. The close button and the "Close tab", "Unpin tab", and
"Duplicate tab" context-menu items are hidden. Users cannot remove or
reposition it. Programmatic removal is always possible:

```dart
// UI-blocked — use programmatic removal:
controller.close(id);       // or
controller.forceClose(id);  // explicit alias, same effect
```

### `normal`

Standard behaviour (default). All operations available.

### `uniqueNormal`

Duplicate is hidden. When `controller.add()` is called with a matching
`uniqueKey`, the existing tab is activated instead of creating a copy:

```dart
// First call — creates the Settings tab:
ctrl.add(
  title: 'Settings', kind: GLTabKind.user,
  behavior: SuperTabBehavior.uniqueNormal, uniqueKey: 'settings',
);

// Second call — selects the existing Settings tab, no new tab:
ctrl.add(
  title: 'Settings', kind: GLTabKind.user,
  behavior: SuperTabBehavior.uniqueNormal, uniqueKey: 'settings',
);
```

---

## `BrowserTab` model

`BrowserTab` is `@immutable` — never mutate its fields directly.
Use the controller's mutation methods.

| Field | Type | Default | Description |
|---|---|---|---|
| `id` | `int` | **required** | Stable unique identity. Never reuse. |
| `title` | `String` | **required** | Display text (truncated + tooltip at 200 px). |
| `kind` | `GLTabKind` | **required** | Drives the leading icon and built-in page. |
| `dirty` | `bool` | `false` | Unsaved-changes dot + confirm on close. |
| `pinned` | `bool` | `false` | Icon-only, anchored to the start edge. |
| `behavior` | `SuperTabBehavior` | `normal` | UI action guards. |
| `uniqueKey` | `String?` | `null` | Deduplication key for `uniqueNormal` tabs. |

---

## Direct event callbacks

Set these on `SuperTabBar` to react to UI-triggered events without
listening to the controller:

```dart
SuperTabBar(
  controller: ctrl,
  onTabSelected:    (id)       => print('selected $id'),
  onTabAdded:       (id)       => print('added $id'),
  onTabClosed:      (id)       => print('closed $id'),
  onTabDuplicated:  (newId)    => print('duplicated → $newId'),
  onTabPinChanged:  (id, pin)  => print('pin $id: $pin'),
  onTabDirtyChanged:(id, dirty)=> print('dirty $id: $dirty'),
  onTabReordered:   (from, to) => print('reorder $from → $to'),
)
```

For `dirty` / `rename` changes that originate in **page content** (i.e.
called via the controller from inside a page widget), set the controller's
own callbacks instead:

```dart
ctrl.onDirtyChanged = (id, dirty) => print('dirty $id: $dirty');
ctrl.onRenamed      = (id, title) => print('renamed $id: "$title"');
```

---

## Localization

All user-facing strings are in `SuperTabBarLocalizations`. Pass a custom
instance to `SuperTabBar.localizations`:

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
    pinTab: 'Pin',
    unpinTab: 'Unpin',
    newTab: 'New tab',
    showAllTabs: 'All tabs',
    scrollForward: 'Forward',
    scrollBack: 'Back',
    noOpenTabs: 'No open tabs.',
    openTabsHeader: 'TABS · {count}',   // {count} is replaced automatically
    switcherTitle: 'Open tabs',
    reorderHint: 'Drag to reorder',
    discardChangesTitle: 'Discard changes?',
    cancel: 'Cancel',
    saveAndClose: 'Save & close',
    discardAndClose: 'Discard & close',
  ),
)
```

Built-in presets: `SuperTabBarLocalizations.en` (default) and `.ar`.

---

## Preview options

```dart
// Disable previews entirely:
SuperTabBar(previewOptions: SuperTabBarPreviewOptions.disabled)

// Faster appear, higher-quality snapshot:
SuperTabBar(
  previewOptions: const SuperTabBarPreviewOptions(
    hoverDelay: Duration(milliseconds: 250),
    snapshotPixelRatio: 1.0,
    fallback: PreviewFallback.blank,  // blank surface when no snapshot yet
  ),
)
```

| Option | Type | Default | Description |
|---|---|---|---|
| `enabled` | `bool` | `true` | Show previews at all. |
| `hoverDelay` | `Duration` | 480 ms | Hover time before popover appears. |
| `snapshotPixelRatio` | `double` | `0.6` | Capture quality (lower = faster). |
| `fallback` | `PreviewFallback` | `liveRender` | Content when no snapshot yet. |

---

## `SuperTabBarController` API

```dart
final ctrl = SuperTabBarController(tabs: [...], activeId: 2);
```

### Mutations

| Method | Description |
|---|---|
| `select(id)` | Activate a tab. |
| `add({title, kind, activate, pinned, at, behavior, uniqueKey})` | Add a tab; returns its id (or the existing id for uniqueNormal dedup). |
| `close(id)` | Remove a tab; activates nearest neighbour. |
| `forceClose(id)` | Explicit alias for `close` — makes intent clear for `requiredPinned` tabs. |
| `closeOthers(id)` | Close all non-pinned tabs except `id`. |
| `closeToRight(id)` | Close all non-pinned tabs after `id`. |
| `duplicate(id)` | Clone as next sibling; returns new id or `-1` if disallowed. |
| `togglePin(id)` | Flip pinned flag (no-op for `requiredPinned`). |
| `setPinned(id, bool)` | Set pinned (no-op for `requiredPinned` when setting false). |
| `reorder(fromId, toId)` | Move a tab to the position of another. |
| `setDirty(id, bool)` | Set / clear the unsaved-changes flag. |
| `rename(id, title)` | Change the display title. |
| `mutate(fn)` | Escape hatch — call multiple ops inside `fn`, notifies once. |

### Reads

| Property / Method | Description |
|---|---|
| `tabs` | All tabs (unmodifiable). |
| `activeId` / `activeTab` | Active tab id and model. |
| `length` | Total tab count. |
| `ordered` | Pinned-first visual order. |
| `pinned` / `unpinned` | Filtered lists. |
| `isActive(id)` | Whether `id` is active. |
| `tabById(id)` | Lookup by id. |
| `canCloseOthers(id)` / `canCloseRight(id)` | Guards for bulk-close operations. |
| `canCloseFromUi(id)` | `false` for `requiredPinned`. |
| `canDuplicateFromUi(id)` | `false` for `requiredPinned` / `uniqueNormal`. |
| `canTogglePinFromUi(id)` | `false` for `requiredPinned`. |
| `snapshot(id)` | Last captured page thumbnail (`ui.Image?`). |

### Controller callbacks

```dart
ctrl.onDirtyChanged = (id, dirty) { … };  // fires from setDirty()
ctrl.onRenamed      = (id, title) { … };  // fires from rename()
```

### `of(context)` / `read(context)`

```dart
// Listening — rebuilds on change. Use in build():
SuperTabBarController.of(context)?.add(title: 'Report', kind: GLTabKind.doc);

// Non-listening — use in callbacks / initState:
SuperTabBarController.read(context)?.setDirty(tabId, true);
```

Both return `null` when called outside a `SuperTabBar`.

---

## Embedding options

| Property | Type | Default | Description |
|---|---|---|---|
| `showChrome` | `bool` | `true` | Bordered rounded card. `false` = edge-to-edge. |
| `compact` | `bool` | `false` | Hide the strip unconditionally. |
| `allowAutoCompact` | `bool` | `false` | v2.2 · Auto-hide strip when widget width ≤ `compactWidth`. |
| `compactWidth` | `double` | `600.0` | v2.2 · Breakpoint (logical px) for `allowAutoCompact`. |
| `closeTabOnBack` | `bool` | `false` | Back closes the active tab unless it is dirty. |
| `fillContent` | `bool` | `false` | Page fills all height (`Expanded`). |
| `scrollContent` | `bool` | `true` | Wrap page in `SingleChildScrollView`. |
| `contentPadding` | `EdgeInsets` | `all(24)` | Padding inside the content surface. |
| `contentBackground` | `Color?` | theme `surface` | Content surface background. |
| `onAddTab` | `VoidCallback?` | `null` | Intercept the `+` button (note: `onTabAdded` won't fire). |
| `lazyPages` | `bool` | `false` | Rebuild-on-revisit instead of `IndexedStack`. |
| `localizations` | `SuperTabBarLocalizations?` | `.en` | Translatable strings. |
| `previewOptions` | `SuperTabBarPreviewOptions?` | defaults | Hover-preview configuration. |

---

## Auto-compact breakpoint (v2.2)

`allowAutoCompact` removes the need to manage `MediaQuery` yourself — the
widget watches its own layout width via `LayoutBuilder` and enters compact mode
automatically:

```dart
SuperTabBar(
  controller: ctrl,
  allowAutoCompact: true,   // auto-switch at compactWidth
  compactWidth: 600,        // default — phones only
  closeTabOnBack: true,
  fillContent: true,
)
```

| `compactWidth` | Covers |
|---|---|
| `600` (default) | All phones |
| `768` | Phones + small tablets |
| `900` | Any mobile device |

The manual `compact: true` flag still works and always takes priority.
`LayoutBuilder` measures the widget's own available width, so it responds
correctly in split-view and multi-window layouts.

---

## Compact mode (mobile)

On small screens the horizontal strip is too wide to be usable. Set
`compact: true` to hide it and switch tabs from a full-screen grid of thumbnail
previews instead.

```dart
// 1 · Hide the strip; show only the active page.
SuperTabBar(
  controller: ctrl,
  compact: true,
  closeTabOnBack: true,   // back closes the current tab (unless dirty)
  showChrome: false,
  fillContent: true,
)

// 2 · Open the switcher from a FloatingActionButton.
FloatingActionButton(
  child: const Icon(Icons.grid_view_rounded),
  onPressed: () async {
    final picked = await showSuperTabSwitcher(context, controller: ctrl);
    if (picked != null) debugPrint('switched to $picked');
  },
)
```

**`showSuperTabSwitcher`** opens a full-screen modal and returns the id of the
tapped tab (or `null` if dismissed). Selecting a thumbnail activates that tab on
the controller and pops the route.

Inside the switcher:

- **Tap** a thumbnail → jump to that tab.
- **Long-press-drag** one thumbnail onto another → reorder
  (`controller.reorder`).
- **Close (×)** → close a tab. Pass `onCloseTab` to run your own
  dirty-confirmation dialog first:

```dart
showSuperTabSwitcher(
  context,
  controller: ctrl,
  pageBuilder: (ctx, tab) => MyPage(tab: tab),  // for live thumbnail fallback
  onCloseTab: (id) async {
    final tab = ctrl.tabById(id)!;
    if (tab.dirty) {
      final r = await showSuperTabDirtyCloseDialog(context, tab);
      if (r == 'discard') ctrl.close(id);
      else if (r == 'save') { ctrl.setDirty(id, false); ctrl.close(id); }
    } else {
      ctrl.close(id);
    }
  },
)
```

Thumbnails reuse the live page snapshots the controller already captures for
hover previews; tabs without a fresh snapshot fall back to a scaled live render
of their page (pass `pageBuilder` so it matches your real content), or a plain
icon card when previews are disabled.

You can also embed `SuperTabSwitcher` directly (e.g. in a bottom sheet) for full
control over presentation.

| Parameter (`showSuperTabSwitcher`) | Type | Default | Description |
|---|---|---|---|
| `controller` | `SuperTabBarController` | **required** | Tabs to show / reorder. |
| `pageBuilder` | `TabPageBuilder?` | `null` | Live thumbnail fallback for snapshot-less tabs. |
| `localizations` | `SuperTabBarLocalizations?` | `.en` | Switcher strings. |
| `crossAxisCount` | `int?` | adaptive | Fixed column count (else responsive). |
| `showCloseButtons` | `bool` | `true` | Per-thumbnail close (×) button. |
| `onCloseTab` | `void Function(int id)?` | `close` | Route the close button through your logic. |

---

## Back navigation

Set `closeTabOnBack: true` so a system back gesture / button closes the active
tab instead of popping the route — **but only when that tab is not dirty**. A
dirty tab is never auto-closed; the back proceeds normally so unsaved work is
never discarded silently.

```dart
SuperTabBar(controller: ctrl, closeTabOnBack: true)
```

| Active tab | Back gesture result |
|---|---|
| not dirty | tab is closed; route stays |
| dirty | tab stays open; back pops the route normally |
| none open | back pops the route normally |

Implemented with `PopScope` (requires Flutter ≥ 3.16). Pairs naturally with
`compact` on mobile.

---

## Keyboard reference

| Key | Action |
|---|---|
| `Esc` | Close context menu or tab-list dropdown. |

> **Removed in 2.1.** The tab-navigation shortcuts (`← →`, `Home` / `End`,
> `Ctrl/Cmd+T`, `Ctrl/Cmd+W`) and the `horizontalStep` / `arrowGoesInto`
> helpers were removed. On mobile, use **compact mode** and the tab switcher.

---

## Theming

```dart
ThemeData(
  extensions: [
    SuperTabBarThemeData.light.copyWith(
      bg:      const Color(0xFFF5F3EF),
      surface: const Color(0xFFFFFFFF),
      border:  const Color(0xFFDDD8D0),
    ),
  ],
)
```

### Instance fields (lerped between dark / light)

| Field | Description |
|---|---|
| `bg` | Strip container / page base. |
| `surface` | Active-tab content / card. |
| `surface2` | Nested card. |
| `inputBg` | Input fill / close-button hover. |
| `hover` | Hover tint. |
| `border` | Hairline divider. |
| `borderStrong` | Solid divider / pop-card edge. |
| `fg1` – `fg4` | Text ramp — primary → disabled. |

### Brand constants (theme-independent)

| Constant | Value |
|---|---|
| `accent` | `#4A7CFF` |
| `success` | `#1DB88A` |
| `warning` | `#F97316` |
| `danger` | `#EF4444` |
| `displayFont` | `'Manrope'` |
| `bodyFont` | `'Inter'` |
| `monoFont` | `'JetBrainsMono'` |

---

## RTL

```dart
Directionality(
  textDirection: TextDirection.rtl,
  child: SuperTabBar(controller: c),
)
```

What mirrors: pinned anchor on start edge, scroll chevrons, drag drop-indicator,
dropdown anchor, and the compact tab switcher.

---

## Architecture

```
lib/
├── super_tab_bar.dart          public barrel
└── src/
    ├── models.dart             BrowserTab (immutable) · SuperTabBehavior
    │                           GLTabKind · TabPageBuilder · helpers
    ├── localizations.dart      SuperTabBarLocalizations (.en · .ar)
    ├── preview_options.dart    SuperTabBarPreviewOptions · PreviewFallback
    ├── theme.dart              SuperTabBarThemeData (ThemeExtension)
    │                           alias: BrowserStyleTabBarThemeData
    ├── controller.dart         SuperTabBarController (ChangeNotifier)
    │                           SuperTabBarScope (InheritedNotifier)
    │                           aliases: BrowserStyleTabBar*
    ├── tab_bar.dart            SuperTabBar widget
    │                           alias: BrowserStyleTabBar
    ├── pages.dart              GLTabPage — built-in per-kind pages
    ├── overlays.dart           TabContextMenu · TabListDropdown
    │                           MiniPagePreview · showSuperTabDirtyCloseDialog
    │                           alias: showGLDirtyCloseDialog
    └── compact.dart            SuperTabSwitcher · showSuperTabSwitcher
                                (mobile thumbnail switcher)
```

---

## Migration from v1 to v2

### 1. Class renames (automatic — typedefs handle this)

All old names still compile. Update at your own pace:

```dart
// v1                              v2
BrowserStyleTabBar          →   SuperTabBar
BrowserStyleTabBarController→   SuperTabBarController
BrowserStyleTabBarScope     →   SuperTabBarScope
BrowserStyleTabBarThemeData →   SuperTabBarThemeData
showGLDirtyCloseDialog      →   showSuperTabDirtyCloseDialog
```

### 2. `BrowserTab` field mutation (compile error if used)

```dart
// v1 — no longer compiles (BrowserTab is now @immutable):
tab.dirty = true;
tab.title = 'New name';
tab.pinned = true;

// v2 — use the controller methods (existed in v1 too):
controller.setDirty(tab.id, true);
controller.rename(tab.id, 'New name');
controller.setPinned(tab.id, true);
```

### 3. `showGLDirtyCloseDialog` signature

The `localizations` parameter is new and optional with a default value,
so existing calls still compile:

```dart
// v1 — still compiles:
await showGLDirtyCloseDialog(context, tab);

// v2 — with localizations:
await showSuperTabDirtyCloseDialog(context, tab,
    localizations: SuperTabBarLocalizations.ar);
```

---

## Gotchas

1. **Stable IDs.** Tab `id`s must be unique and stable. Never reuse an id.
2. **`pageBuilder` is called twice.** The builder fills the active surface
   *and* the scaled hover preview. Keep pages stateless in the builder.
3. **State preservation is the default.** Use `lazyPages: true` only for
   cheap read-only pages that should reset on revisit.
4. **`of(context)` returns null outside a tab bar.** Guard all calls:
   `SuperTabBarController.of(context)?.add(…)`.
5. **Register the theme extension.** One line in `ThemeData.extensions`.
6. **`onAddTab` suppresses `onTabAdded`.** When `onAddTab` is set, the
   widget does not know the new tab's id, so `onTabAdded` cannot fire.

---

## Additional information

- **Changelog:** [CHANGELOG.md](CHANGELOG.md)
- **Repository:** https://github.com/GeniusSystems24/super_tab_bar
- **Issues:** https://github.com/GeniusSystems24/super_tab_bar/issues
- **License:** MIT — see [LICENSE](LICENSE)
