# Changelog

All notable changes to `super_tab_bar` are documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
versioning follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [2.2.0] — 2026-07-02

### Added — Automatic compact breakpoint

- **`SuperTabBar(allowAutoCompact: true)`** — the widget watches its own layout
  constraints (via `LayoutBuilder`) and enters compact mode automatically
  whenever the available width is ≤ `compactWidth`. No `MediaQuery` boilerplate
  needed.
- **`SuperTabBar(compactWidth: 600.0)`** — the width threshold in logical pixels.
  Defaults to **600**, which covers all common phone form-factors. Raise to 768
  to include small tablets, or 900 for any mobile device.

```dart
// Strip hides automatically on phones; stays visible on tablets/desktops.
SuperTabBar(
  controller: ctrl,
  allowAutoCompact: true,   // auto-switch at compactWidth
  compactWidth: 600,        // default — phones only
  closeTabOnBack: true,
  fillContent: true,
)
```

  The manual `compact: true` flag still works and takes priority. The two
  approaches can coexist: `compact` forces compact unconditionally while
  `allowAutoCompact` makes it responsive.

### Changed

- `build()` now wraps the inner widget tree in a `LayoutBuilder` to support
  `allowAutoCompact`. No visual change when both flags are `false`.

---

## [2.1.0] — 2026-07-01

Mobile-focused release: a compact tab-switching experience, dirty-aware back
navigation, and the removal of the desktop tab-navigation keyboard shortcuts.

### Added — Compact mode

- **`SuperTabBar(compact: true)`** hides the horizontal tab strip and shows
  only the active page — ideal for narrow phone screens where the full strip
  does not fit.
- **`SuperTabSwitcher`** — a scrollable grid of thumbnail previews of every
  open tab. Tap a thumbnail to jump to that tab; **long-press-drag** one
  thumbnail onto another to reorder (drives `SuperTabBarController.reorder`).
  A per-thumbnail close (×) button removes a tab (routed through your close
  handler so dirty tabs can confirm first).
- **`showSuperTabSwitcher(context, controller: …)`** — opens the switcher as a
  full-screen modal and returns the id of the picked tab (or `null` if
  dismissed). Recommended trigger: a `FloatingActionButton`.

```dart
FloatingActionButton(
  child: const Icon(Icons.grid_view_rounded),
  onPressed: () => showSuperTabSwitcher(context, controller: controller),
)
```

### Added — Dirty-aware back navigation

- **`SuperTabBar(closeTabOnBack: true)`** — a system back gesture / button
  closes the active tab instead of popping the route, **but only when that tab
  is not dirty**. A dirty tab is never auto-closed on back; the pop proceeds
  normally so unsaved work is never discarded silently. Implemented with
  `PopScope` (requires Flutter ≥ 3.16).

### Removed (breaking)

- **Tab-navigation keyboard shortcuts** — `Ctrl/Cmd+T` (new tab),
  `Ctrl/Cmd+W` (close tab) and the `← → Home End` selection keys were removed.
  On mobile, compact mode replaces keyboard switching. `Escape` still dismisses
  an open context menu / tab-list dropdown.
- **`horizontalStep` / `arrowGoesInto`** helpers and `src/key_directions.dart`
  were removed — they existed only to power the tab-navigation keys. Remove any
  imports of these symbols.

### Localizations

- Added `switcherTitle` and `reorderHint` strings (EN + AR presets updated).
  Custom `SuperTabBarLocalizations` instances must supply the two new fields.

### Requirements

- Minimum Flutter bumped to **3.16.0** / Dart **3.2.0** (for `PopScope`).

---

## [2.0.0] — 2026-06-27

### Renamed (with backward-compatible aliases)

Every top-level name has been shortened to match the package name.
Old names remain usable via `typedef` aliases — existing code compiles
without changes.

| v1 name | v2 name | Alias kept? |
|---|---|---|
| `BrowserStyleTabBar` | `SuperTabBar` | ✓ |
| `BrowserStyleTabBarController` | `SuperTabBarController` | ✓ |
| `BrowserStyleTabBarScope` | `SuperTabBarScope` | ✓ |
| `BrowserStyleTabBarThemeData` | `SuperTabBarThemeData` | ✓ |
| `showGLDirtyCloseDialog` | `showSuperTabDirtyCloseDialog` | ✓ |

### Changed (breaking for direct field mutation)

- **`BrowserTab` is now `@immutable`.** Fields `title`, `dirty` and `pinned`
  are now `final`. Code that mutated them directly (e.g. `tab.dirty = true`)
  will not compile. Use the controller's `setDirty`, `rename`, `setPinned`
  methods instead — they already existed in v1 and are unchanged in
  behaviour. The controller internally uses `copyWith` to produce new
  instances.

### Added — `SuperTabBehavior` (tab behavior types)

Three per-tab behavior modes control which UI actions the strip exposes:

```dart
BrowserTab(
  id: 1, title: 'Home', kind: GLTabKind.globe,
  pinned: true,
  behavior: SuperTabBehavior.requiredPinned, // always pinned, no close/unpin/dupe in UI
)

BrowserTab(
  id: 2, title: 'Settings', kind: GLTabKind.user,
  behavior: SuperTabBehavior.uniqueNormal,  // no dupe; re-open selects existing
  uniqueKey: 'settings',
)

BrowserTab(
  id: 3, title: 'Report', kind: GLTabKind.ledger,
  behavior: SuperTabBehavior.normal,        // default: all operations available
)
```

- **`requiredPinned`** — always pinned; UI hides close, unpin and duplicate.
  Programmatic `controller.close(id)` / `forceClose(id)` still works.
- **`normal`** — existing behaviour (no change).
- **`uniqueNormal`** — no duplicate from UI; `controller.add()` with a
  matching `uniqueKey` selects the existing tab instead of creating a copy.

New controller helpers:
- `canCloseFromUi(id)`, `canDuplicateFromUi(id)`, `canTogglePinFromUi(id)`
- `forceClose(id)` — explicit alias for `close(id)` to make programmatic
  removal of required tabs clear at the call site.
- `add()` gains `behavior` and `uniqueKey` parameters.
- `duplicate()` returns `-1` for `requiredPinned` / `uniqueNormal` tabs.
- `setPinned(id, false)` is silently ignored for `requiredPinned` tabs.

### Added — Direct event callbacks on `SuperTabBar`

Users no longer need to listen to the controller for common operations:

```dart
SuperTabBar(
  controller: ctrl,
  onTabSelected:    (id)       { },
  onTabAdded:       (id)       { },
  onTabClosed:      (id)       { },
  onTabDuplicated:  (newId)    { },
  onTabPinChanged:  (id, pin)  { },
  onTabDirtyChanged:(id, dirty){ }, // fires from save-and-close dialog
  onTabReordered:   (from, to) { },
)
```

For dirty / rename changes that originate in **page content**, set the
controller's own callbacks:

```dart
ctrl.onDirtyChanged = (id, dirty) { … };
ctrl.onRenamed      = (id, title) { … };
```

### Added — `SuperTabBarLocalizations`

All user-facing strings are now localizable. Pass to `SuperTabBar.localizations`:

```dart
SuperTabBar(localizations: SuperTabBarLocalizations.ar) // built-in Arabic
```

Built-in presets: `SuperTabBarLocalizations.en` (default), `.ar`.
Custom languages: construct with all required fields.

### Added — `SuperTabBarPreviewOptions`

Configure or disable hover previews:

```dart
// Disable previews entirely:
SuperTabBar(previewOptions: SuperTabBarPreviewOptions.disabled)

// Custom delay + quality:
SuperTabBar(
  previewOptions: SuperTabBarPreviewOptions(
    hoverDelay: Duration(milliseconds: 250),
    snapshotPixelRatio: 1.0,
    fallback: PreviewFallback.blank,
  ),
)
```

`PreviewFallback.liveRender` (default) or `PreviewFallback.blank`.

### Added — Accessibility

- `Semantics(button: true, selected: active, label: …)` on every tab chip.
- `Semantics(button: true, label: 'Close {title}')` on close buttons.
- `Semantics(button: true, enabled: …, label: …)` on context-menu rows.
- `Semantics(label: 'Preview of {title}', excludeSemantics: true)` on
  the hover-preview popover (decorative, excluded from traversal).

### Added — Keyboard shortcuts

| Shortcut | Action |
|---|---|
| `Ctrl/Cmd + T` | Open a new tab |
| `Ctrl/Cmd + W` | Close the active tab (if `canCloseFromUi`) |

Existing shortcuts (`←` `→` `Home` `End` `Esc`) are unchanged.

### Added — Example 04

`example/lib/example_04_tab_behaviors.dart` — live demo of all three
behavior types with an event-log panel showing every callback in real time.

### Added — Tests

`test/super_tab_bar_test.dart` covers:
- `BrowserTab` immutability and value equality.
- `requiredPinned` UI guards and programmatic close.
- `uniqueNormal` deduplication (same / different / null key).
- Controller CRUD: select, add, close, duplicate, reorder, rename, dirty.
- `onDirtyChanged` / `onRenamed` controller callbacks.
- `SuperTabBarLocalizations` string helpers.
- `SuperTabBarPreviewOptions` defaults and custom values.
- Widget smoke tests: render, backward-compat alias, `onTabSelected`,
  `onTabAdded`, custom localizations, preview disabled.

### Fixed

- Repository, homepage, and issue-tracker URLs now point to
  `https://github.com/GeniusSystems24/super_tab_bar`.

---

## [1.0.0] — 2026-06-22

### Added

Initial release — `BrowserStyleTabBar` widget with pinned / dirty /
closable tabs, drag-to-reorder, context menu, overflow dropdown, live
mini-page hover previews, state-preserving pages (`IndexedStack`),
keyboard navigation, and RTL support.
