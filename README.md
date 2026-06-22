# super_tab_bar

[![pub package](https://img.shields.io/badge/pub-v1.0.0-4A7CFF.svg)](https://pub.dev/packages/super_tab_bar)
[![flutter](https://img.shields.io/badge/Flutter-%E2%89%A53.10-1DB88A.svg)](https://flutter.dev)
[![style](https://img.shields.io/badge/style-MVC-F97316.svg)](#architecture)
[![license](https://img.shields.io/badge/license-MIT-64748B.svg)](#license)

A browser-style workspace tab bar for Flutter — pinned / dirty / closable tabs,
drag-to-reorder, context menu, overflow dropdown, **live mini-page previews** on
hover, and **state-preserving pages**. Full keyboard navigation + RTL. Zero
third-party dependencies.

<!-- TODO: add demo GIF -->

---

## Features

- 🗂 **Browser-style strip** — active tab merges with the content surface;
  inactive tabs are muted with thin separators.
- 📌 **Pinned tabs** — icon-only, anchored to the start edge, survive
  close-others / close-to-right.
- 💾 **Dirty tabs** — unsaved-changes dot; closing triggers a confirm dialog
  (Discard & close / Save & close / Cancel).
- ↔ **Drag-to-reorder** — drag any unpinned tab; blue indicator marks the drop.
- 📋 **Context menu** — right-click or long-press: close · close others · close
  to the right · duplicate · pin / unpin.
- ⟩ **Overflow** — scroll chevrons + `▾` dropdown list when tabs exceed the
  strip width.
- 👁 **Live mini-page hover preview** — hover-intent (≈ 480 ms) shows a popover
  with the page's **real `RepaintBoundary` capture** — live state, data and
  scroll position, not a stub.
- ♻ **State-preserving pages** — default `IndexedStack` keeps every page
  mounted; scroll, text-field and controller state survives tab switches with
  no rebuild. Opt out with `lazyPages: true`.
- ⌨ **Full keyboard** — `← →` (visual direction, RTL-aware), `Home` / `End`.
- 🌍 **RTL** — strip, chevrons, drag and keyboard all mirror under
  `Directionality(textDirection: TextDirection.rtl, …)`.
- 🔌 **Zero dependencies** — pure Flutter + Material.

---

## Installation

```yaml
dependencies:
  super_tab_bar: ^1.0.0
```

```bash
flutter pub get
```

---

## Setup

Register `BrowserStyleTabBarThemeData` on your `MaterialApp`. The widget falls
back to the dark preset if nothing is registered, but registering both avoids a
one-frame flash on theme switch:

```dart
import 'package:super_tab_bar/super_tab_bar.dart';

MaterialApp(
  theme: ThemeData(
    extensions: const [BrowserStyleTabBarThemeData.light],
  ),
  darkTheme: ThemeData(
    extensions: const [BrowserStyleTabBarThemeData.dark],
  ),
  home: const MyHome(),
);
```

---

## Quick start

### 1 · Zero-config

```dart
const BrowserStyleTabBar();
```

Owns a private controller seeded with a default set of five tabs.

### 2 · Seed your own tabs

```dart
BrowserStyleTabBar(
  tabsState: [
    BrowserTab(id: 1, title: 'Chart of Accounts', kind: GLTabKind.ledger, pinned: true),
    BrowserTab(id: 2, title: 'Journal Entry',      kind: GLTabKind.doc,    dirty: true),
    BrowserTab(id: 3, title: 'Dashboard',           kind: GLTabKind.chart),
  ],
);
```

### 3 · External controller + custom pages

```dart
class _WorkspaceState extends State<Workspace> {
  final _tabs = BrowserStyleTabBarController(
    tabs: [
      BrowserTab(id: 1, title: 'Accounts',       kind: GLTabKind.ledger, pinned: true),
      BrowserTab(id: 2, title: 'Journal Entry',  kind: GLTabKind.doc,    dirty: true),
    ],
    activeId: 2,
  );

  @override
  Widget build(BuildContext context) => BrowserStyleTabBar(
    controller: _tabs,
    pageBuilder: (ctx, tab) => MyPage(tab: tab),
    showChrome: false,  // edge-to-edge in an app shell
    fillContent: true,  // page fills all available height
  );

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }
}
```

---

## `BrowserTab` model

| Field | Type | Default | Description |
|---|---|---|---|
| `id` | `int` | **required** | Stable, unique identity — never reuse. |
| `title` | `String` | **required** | Display text (truncated with tooltip at 200 px). |
| `kind` | `GLTabKind` | **required** | Drives the leading icon and built-in page. |
| `dirty` | `bool` | `false` | Unsaved-changes dot + confirm on close. |
| `pinned` | `bool` | `false` | Icon-only, anchored to the start edge. |

### `GLTabKind` values

| Value | Icon | Built-in page |
|---|---|---|
| `ledger` | `menu_book_outlined` | Chart of Accounts table |
| `doc` | `description_outlined` | Journal entry form |
| `store` | `storefront_outlined` | Branch / storefront detail |
| `chart` | `bar_chart_rounded` | Revenue dashboard |
| `user` | `people_alt_outlined` | Team directory |
| `globe` | `public` | Workspace overview |

---

## State-preserving pages

By default every tab page is **built once and kept mounted** in an
`IndexedStack`. Switching tabs only changes the visible index — pages are never
disposed, so scroll, text-field and controller state all survive:

```dart
// default — state survives switches (IndexedStack):
BrowserStyleTabBar(controller: c, pageBuilder: buildPage);

// opt-out — only the active page exists; resets on revisit:
BrowserStyleTabBar(controller: c, pageBuilder: buildPage, lazyPages: true);
```

Use `lazyPages: true` for cheap, read-only pages that don't need state across
switches.

---

## Embedding options

| Property | Type | Default | Description |
|---|---|---|---|
| `showChrome` | `bool` | `true` | Bordered rounded card. `false` = edge-to-edge. |
| `fillContent` | `bool` | `false` | Page fills all height (`Expanded`). `false` caps at 440 px. |
| `scrollContent` | `bool` | `true` | Wrap page in `SingleChildScrollView`. |
| `contentPadding` | `EdgeInsets` | `all(24)` | Padding around the active page. |
| `contentBackground` | `Color?` | theme `surface` | Content surface background. |
| `onAddTab` | `VoidCallback?` | `null` | Intercept the `+` button. |
| `lazyPages` | `bool` | `false` | Rebuild-on-revisit instead of `IndexedStack`. |

---

## `BrowserStyleTabBarController` API

```dart
final tabs = BrowserStyleTabBarController(tabs: [...], activeId: 2);
```

### Operations

| Method | Description |
|---|---|
| `select(id)` | Activate a tab. |
| `add({title, kind, activate, pinned, at})` | Add a tab; returns its new `id`. |
| `close(id)` | Remove a tab; activates the nearest neighbour. |
| `closeOthers(id)` | Close all non-pinned tabs except `id`. |
| `closeToRight(id)` | Close all non-pinned tabs after `id`. |
| `duplicate(id)` | Clone as the next sibling; activates the copy. |
| `togglePin(id)` | Flip the pinned flag. |
| `setPinned(id, bool)` | Set pinned explicitly. |
| `reorder(fromId, toId)` | Move a tab to the position of another. |
| `setDirty(id, bool)` | Set / clear the unsaved-changes flag. |
| `rename(id, title)` | Change the display title. |
| `mutate(fn)` | Escape hatch — edit inside `fn`, notifies after. |

### Reads

| Property / Method | Type | Description |
|---|---|---|
| `tabs` | `List<BrowserTab>` | All tabs (unmodifiable). |
| `activeId` | `int?` | Active tab id. |
| `activeTab` | `BrowserTab?` | Active tab model. |
| `length` | `int` | Total tab count. |
| `ordered` | `List<BrowserTab>` | Pinned-first visual order. |
| `pinned` / `unpinned` | `List<BrowserTab>` | Filtered lists. |
| `isActive(id)` | `bool` | Whether `id` is the active tab. |
| `tabById(id)` | `BrowserTab?` | Lookup by id. |
| `canCloseOthers(id)` | `bool` | Guard before `closeOthers`. |
| `canCloseRight(id)` | `bool` | Guard before `closeToRight`. |
| `snapshot(id)` | `ui.Image?` | Last captured page thumbnail. |

### `of(context)` and `read(context)`

```dart
// Listening — rebuilds on change. Use in build():
BrowserStyleTabBarController.of(context)?.add(title: 'Detail', kind: GLTabKind.doc);

// Non-listening — use in callbacks / initState:
BrowserStyleTabBarController.read(context)?.setDirty(tabId, true);
```

Both return `null` when called outside a `BrowserStyleTabBar`. Guard every
call: `controller?.method(…)`.

---

## Keyboard reference

Focus the strip (click it or tab to it), then:

| Key | Action |
|---|---|
| `←` / `→` | Previous / next tab (follows layout direction in RTL). |
| `Home` / `End` | First / last tab. |
| `Esc` | Close context menu or tab-list dropdown. |

Right-click or long-press any tab for the full context menu.

---

## Theming

All surfaces live in `BrowserStyleTabBarThemeData` — a `ThemeExtension` with
`.light` and `.dark` presets. Adjust any surface with `copyWith`:

```dart
ThemeData(
  extensions: [
    BrowserStyleTabBarThemeData.light.copyWith(
      bg:      const Color(0xFFF5F3EF),  // warm off-white
      surface: const Color(0xFFFFFFFF),
      border:  const Color(0xFFDDD8D0),
    ),
  ],
)
```

### Instance fields (swap between dark & light)

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

| Constant | Value | Usage |
|---|---|---|
| `accent` | `#4A7CFF` | Active tab, icons, focus ring. |
| `success` | `#1DB88A` | Positive states. |
| `warning` | `#F97316` | Dirty dot. |
| `danger` | `#EF4444` | Discard action. |
| `displayFont` | `'Manrope'` | Headings. |
| `bodyFont` | `'Inter'` | Body text. |
| `monoFont` | `'JetBrainsMono'` | Mono / code. |

---

## RTL

Wrap the widget in `Directionality`:

```dart
Directionality(
  textDirection: TextDirection.rtl,
  child: BrowserStyleTabBar(controller: c, pageBuilder: buildPage),
)
```

What mirrors: pinned anchor stays on start edge, overflow chevrons swap
visual sides, keyboard `←`/`→` always move toward the visual left/right,
drag drop-indicator, tab-list dropdown anchor.

---

## Architecture

```
lib/
├── super_tab_bar.dart          public barrel
└── src/
    ├── models.dart             BrowserTab · GLTabKind · TabPageBuilder
    │                           glTabIcon · glPreviewMeta · kNewTabCycle
    ├── theme.dart              BrowserStyleTabBarThemeData (ThemeExtension)
    ├── controller.dart         BrowserStyleTabBarController (ChangeNotifier)
    │                           BrowserStyleTabBarScope (InheritedNotifier)
    ├── tab_bar.dart            BrowserStyleTabBar widget
    ├── pages.dart              GLTabPage — built-in per-kind pages
    ├── overlays.dart           TabContextMenu · TabListDropdown
    │                           MiniPagePreview · showGLDirtyCloseDialog
    └── key_directions.dart     horizontalStep · arrowGoesInto (RTL helpers)
```

**MVC:** immutable models → `ChangeNotifier` controller (single source of
truth) → thin view → `ThemeExtension`. The controller is exposed to
descendant page content via `BrowserStyleTabBarScope`
(`InheritedNotifier`) so any child can drive the strip.

---

## Gotchas

1. **Stable IDs.** Tab `id`s must be unique and stable. `select`, `reorder`,
   `close`, `setDirty`, `rename` all key on them. Never reuse an id.
2. **`pageBuilder` renders twice.** The same builder fills the active surface
   *and* the scaled hover preview. Keep pages stateless in the builder — put
   side-effects (network, listeners) in page `State`.
3. **State preservation is the default.** Pass `lazyPages: true` only when
   pages should reset on revisit. `IndexedStack` is almost always right for
   a document workspace.
4. **`of(context)` returns null outside a tab bar.** Guard every call:
   `BrowserStyleTabBarController.of(context)?.add(…)`.
5. **Register the theme extension.** Without it the widget falls back to the
   dark preset. One line in `ThemeData.extensions` is all it takes.

---

## Additional information

- **Changelog:** [CHANGELOG.md](CHANGELOG.md)
- **Repository:** https://github.com/geniuslink/super_tab_bar
- **Issues:** https://github.com/geniuslink/super_tab_bar/issues
- **License:** MIT — see [LICENSE](LICENSE)
