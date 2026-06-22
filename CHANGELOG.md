# Changelog

All notable changes to `super_tab_bar` will be documented in this file.
Format based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
versioning follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] — 2026-06-22

### Added

- **`BrowserStyleTabBar`** widget — browser-style workspace tab strip.
  - Active tab merges with the content surface; inactive tabs are muted with
    separators.
  - `showChrome` · `fillContent` · `scrollContent` · `contentPadding` ·
    `contentBackground` · `onAddTab` embedding options.
  - `lazyPages` — opt-out of state-preserving `IndexedStack` (default `false`).

- **`BrowserStyleTabBarController`** (`ChangeNotifier`) — single source of
  truth for tabs, active state and thumbnails.
  - Operations: `select` · `add` · `close` · `closeOthers` · `closeToRight` ·
    `duplicate` · `togglePin` · `setPinned` · `reorder` · `setDirty` ·
    `rename` · `mutate`.
  - Reads: `tabs` · `activeId` · `activeTab` · `length` · `ordered` ·
    `pinned` · `unpinned` · `isActive` · `tabById` · `canCloseOthers` ·
    `canCloseRight` · `snapshot`.
  - `of(context)` (listening) and `read(context)` (non-listening) scope
    accessors — both return `null` outside a `BrowserStyleTabBar`.
  - `BrowserStyleTabBarScope` (`InheritedNotifier`) exposes the controller
    to descendant page content.

- **`BrowserTab`** model — `id` · `title` · `kind` · `dirty` · `pinned`.
- **`GLTabKind`** enum — `ledger` · `doc` · `store` · `chart` · `user` · `globe`.
- **`TabPageBuilder`** typedef — `Widget Function(BuildContext, BrowserTab)`.
- **`glTabIcon(GLTabKind)`** — returns the Material icon for a kind.
- **`glPreviewMeta(GLTabKind)`** — returns the preview subtitle string.
- **`kNewTabCycle`** — rotating kind list for the `+` button.

- **`BrowserStyleTabBarThemeData`** (`ThemeExtension`) — self-contained theme.
  - `.light` and `.dark` presets.
  - Instance fields: `bg` · `surface` · `surface2` · `inputBg` · `hover` ·
    `border` · `borderStrong` · `fg1` – `fg4`.
  - Brand constants: `accent (#4A7CFF)` · `success (#1DB88A)` ·
    `warning (#F97316)` · `danger (#EF4444)` · font families · radii ·
    shadows · motion tokens (`durFast` · `durBase` · `durSlow` ·
    `curveStandard` · `curveDecelerate` · `curveEmphasized`).
  - Full `copyWith` and `lerp`.

- **`GLTabPage`** — built-in content for each `GLTabKind` (ledger table ·
  journal entry form · store detail · revenue dashboard · team directory ·
  workspace overview).

- **Overlays:**
  - `TabContextMenu` — close · close others · close to right · duplicate ·
    pin / unpin; clamps inside the screen.
  - `TabListDropdown` — jump to any open tab; shows pinned/dirty indicators.
  - `MiniPagePreview` — hover-intent (480 ms) popover with a real
    `RepaintBoundary` capture of the page's current state; falls back to a
    live scaled render for tabs not yet visited.
  - `showGLDirtyCloseDialog` — animated confirm dialog for dirty-tab close;
    returns `'discard'` · `'save'` · `null` (cancel).
  - `TabMenuItem` — menu item model (icon · label · hint · danger ·
    disabled · divider).

- **`key_directions.dart`** — RTL-aware keyboard helpers:
  - `horizontalStep(key, dir)` — resolves `←`/`→` to a logical `±1` step.
  - `arrowGoesInto(key, dir)` — `true` when the arrow points toward deeper
    nesting (used by `Tree`-style components).

- **State-preserving pages** via `IndexedStack` + `_KeepAliveTabPage`
  (`AutomaticKeepAliveClientMixin`) — scroll, text-field and controller state
  survives tab switches with no rebuild.

- **Live thumbnail capture** — debounced `RepaintBoundary.toImage` on every
  active-tab change; snapshots stored on the controller.

- **Drag-to-reorder** — `Draggable<int>` / `DragTarget<int>` with a ghost
  feedback chip and a blue drop-indicator.

- **Overflow** — `ScrollController`-measured chevrons + `▾` dropdown list.

- **Keyboard navigation** — `←`/`→`/`Home`/`End`/`Esc` on the focused strip;
  direction-aware under `Directionality`.

- **RTL** — pinned anchor on start edge, chevrons mirror, keyboard follows
  visual direction, dropdown anchor mirrors.

- **Zero third-party dependencies** — pure Flutter + Material.
