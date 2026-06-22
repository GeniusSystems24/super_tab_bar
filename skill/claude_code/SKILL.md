---
name: super-tab-bar
description: >
  How to use the super_tab_bar Flutter package — a browser-style workspace tab
  strip with pinned/closable/dirty tabs, drag-reorder, context menu, overflow
  dropdown, live mini-page previews, and state-preserving pages. Use when
  building or modifying a Flutter multi-tab workspace UI with the
  `super_tab_bar` package, or wiring a `BrowserStyleTabBarController`.
---

# super_tab_bar · BrowserStyleTabBar

A browser-style workspace tab strip — pinned / closable / dirty tabs,
drag-to-reorder, a context menu, an overflow dropdown, a dirty-close confirm
dialog, and **live mini-page previews** on hover. It renders the strip **and**
the active page below it, and by default **keeps every page's state alive**
across tab switches.

## Import & theme

```dart
import 'package:super_tab_bar/super_tab_bar.dart';

// Register on MaterialApp (falls back to dark if omitted):
ThemeData(extensions: const [BrowserStyleTabBarThemeData.light]); // + .dark
```

## Quick start

```dart
// zero-config — owns a controller with the default tab set:
const BrowserStyleTabBar();

// seed your own tabs:
BrowserStyleTabBar(tabsState: [
  BrowserTab(id: 1, title: 'Chart of Accounts', kind: GLTabKind.ledger, pinned: true),
  BrowserTab(id: 2, title: 'Journal Entry',      kind: GLTabKind.doc,    dirty: true),
  BrowserTab(id: 3, title: 'Dashboard',           kind: GLTabKind.chart),
]);

// external controller + custom pages:
BrowserStyleTabBar(controller: myController, pageBuilder: (ctx, tab) => MyPage(tab));
```

Provide `tabsState` (widget owns a controller) **or** a `controller:`.
`pageBuilder` supplies content for each tab and the hover preview; omit it
for the built-in `GLTabPage` per kind.

## The tab — `BrowserTab`

```dart
BrowserTab({
  required int id,          // stable, unique identity
  required String title,
  required GLTabKind kind,  // ledger · doc · store · chart · user · globe
  bool dirty = false,       // unsaved dot + close-confirm
  bool pinned = false,      // icon-only, anchored to the start edge
});
```

`GLTabKind` drives the leading icon, preview layout and built-in page.
Pinned tabs render icon-only and sort to the start; a `dirty` tab shows
an unsaved dot and triggers a confirm dialog on close.

## State-preserving pages

By default each tab page is **built once and kept mounted** in an
`IndexedStack` — switching preserves scroll, form input and controllers with
no rebuild. Opt into rebuild-on-revisit with `lazyPages: true`.

```dart
BrowserStyleTabBar(controller: c, pageBuilder: buildPage);                  // state survives
BrowserStyleTabBar(controller: c, pageBuilder: buildPage, lazyPages: true); // rebuild each visit
```

## Embedding options

| Property | Default | Description |
|---|---|---|
| `showChrome` | `true` | Bordered rounded card. `false` = edge-to-edge. |
| `fillContent` | `false` | Page fills all height. `false` caps at 440 px. |
| `scrollContent` | `true` | Wrap page in `SingleChildScrollView`. |
| `contentPadding` | `all(24)` | Padding around the active page. |
| `contentBackground` | theme `surface` | Content surface background. |
| `onAddTab` | `null` | Intercept the `+` button. |

## Driving it — `BrowserStyleTabBarController`

```dart
final tabs = BrowserStyleTabBarController(tabs: [...], activeId: 2);

// operations:
tabs.add(title: 'New report', kind: GLTabKind.chart); // → new id; activates
tabs.select(id);
tabs.setDirty(id, true);
tabs.togglePin(id);
tabs.rename(id, 'Q3 Trial Balance');
tabs.duplicate(id);
tabs.reorder(fromId, toId);
tabs.close(id);
tabs.closeOthers(id);   // guard: tabs.canCloseOthers(id)
tabs.closeToRight(id);  // guard: tabs.canCloseRight(id)

// reads:
tabs.tabs; tabs.activeTab; tabs.length; tabs.ordered; // pinned-first

// from inside a page:
BrowserStyleTabBarController.of(context)?.add(title: 'Detail', kind: GLTabKind.doc);
```

Full op set: `select · add · close · closeOthers · closeToRight · duplicate ·
togglePin · setPinned · reorder · setDirty · rename · mutate`.

`of(context)` returns **null** outside a tab bar — guard every call.
`read(context)` is the non-listening variant for callbacks / `initState`.

## Keyboard & pointer

Focus the strip: `← →` move (visual direction, RTL-aware), `Home` / `End`
first / last. Right-click / long-press a tab → context menu (close, close
others, close to the right, duplicate, pin / unpin). Drag a tab to reorder.

## Theming

```dart
// copyWith a preset:
BrowserStyleTabBarThemeData.light.copyWith(
  bg:      const Color(0xFFF5F3EF),
  surface: const Color(0xFFFFFFFF),
  border:  const Color(0xFFDDD8D0),
)
```

Brand constants (static): `accent #4A7CFF` · `success #1DB88A` ·
`warning #F97316` · `danger #EF4444`.

## Gotchas

1. **Stable IDs** — `select`, `reorder`, `close`, `setDirty`, `rename` all key
   on `id`. Never reuse an id.
2. **`pageBuilder` renders twice** — full surface + scaled hover preview. Keep
   it pure; put side-effects in page `State`.
3. **State-preservation is the default** — pass `lazyPages: true` only when
   pages should reset on revisit.
4. **`of(context)` is null outside a tab bar** — guard every call.
5. **Register the theme extension** — without it the widget uses the dark
   preset; one line in `ThemeData.extensions` is all it takes.

## Reference

- **Examples (read first):** `EXAMPLES.md` in this folder.
- Source: `lib/src/` (tab_bar · controller · theme · models · pages · overlays)
- README: `../../README.md`
- Example app: `../../example/lib/`
