---
name: super-tab-bar
description: >
  How to use the super_tab_bar Flutter package: a browser-style workspace tab
  strip with pinned/closable/dirty tabs, required pinned tabs, unique tab
  behavior, drag-reorder, context menu, overflow dropdown, live or disabled
  hover previews, localization, callbacks, and state-preserving pages.
---

# super_tab_bar - SuperTabBar

Use `super_tab_bar` to build a browser-style workspace tab strip for Flutter.
It renders the tab strip and the active page surface, keeps pages mounted by
default, and supports pinned, dirty, closable, draggable, unique, and required
pinned tabs.

Primary v2 names:

- `SuperTabBar`
- `SuperTabBarController`
- `SuperTabBarScope`
- `SuperTabBarThemeData`

The legacy `BrowserStyleTabBar*` names remain available as typedef aliases.

## Import And Theme

```dart
import 'package:super_tab_bar/super_tab_bar.dart';

MaterialApp(
  theme: ThemeData(extensions: const [SuperTabBarThemeData.light]),
  darkTheme: ThemeData(extensions: const [SuperTabBarThemeData.dark]),
)
```

## Quick Start

```dart
const SuperTabBar()
```

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

```dart
SuperTabBar(
  controller: myController,
  pageBuilder: (context, tab) => MyPage(tab: tab),
)
```

Provide `tabsState` when the widget owns the controller, or `controller` when
the app owns it. Do not provide both.

## The Tab: `BrowserTab`

```dart
const BrowserTab({
  required int id,
  required String title,
  required GLTabKind kind,
  bool dirty = false,
  bool pinned = false,
  SuperTabBehavior behavior = SuperTabBehavior.normal,
  String? uniqueKey,
});
```

`BrowserTab` is immutable. Use controller methods or `mutate`/`copyWith` to
change tab state.

`GLTabKind` drives the leading icon, preview metadata, and built-in page:
`ledger`, `doc`, `store`, `chart`, `user`, `globe`.

## Tab Behavior

`SuperTabBehavior.requiredPinned`
: Always pinned. The UI hides close, duplicate, and unpin. Programmatic
`close` or `forceClose` still works.

`SuperTabBehavior.normal`
: Standard tab. Close, duplicate, pin, and unpin are available.

`SuperTabBehavior.uniqueNormal`
: Standard tab except duplicate is hidden. When `add` receives the same
non-null `uniqueKey`, the existing tab is selected instead of creating another.

```dart
tabs.add(
  title: 'Customer A-100',
  kind: GLTabKind.user,
  behavior: SuperTabBehavior.uniqueNormal,
  uniqueKey: 'customer:A-100',
);
```

## State-Preserving Pages

By default each tab page is built once and kept mounted in an `IndexedStack`.
Switching tabs preserves scroll position, form input, focus state, and
controllers. Use `lazyPages: true` only when pages should rebuild on revisit.

```dart
SuperTabBar(controller: c, pageBuilder: buildPage);
SuperTabBar(controller: c, pageBuilder: buildPage, lazyPages: true);
```

## Embedding Options

| Property | Default | Description |
|---|---|---|
| `showChrome` | `true` | Bordered rounded card shell; `false` is edge-to-edge. |
| `fillContent` | `false` | Page fills all available height. |
| `scrollContent` | `true` | Wrap active page in `SingleChildScrollView`. |
| `contentPadding` | `EdgeInsets.all(24)` | Padding around active page. |
| `contentBackground` | theme surface | Active page surface background. |
| `onAddTab` | null | Override plus-button behavior. |
| `localizations` | English | Custom user-facing strings; `.en` and `.ar` built in. |
| `previewOptions` | defaults | Enable/disable and tune hover previews. |

## Controller Operations

```dart
final tabs = SuperTabBarController(tabs: [...], activeId: 2);

tabs.add(title: 'New report', kind: GLTabKind.chart);
tabs.select(id);
tabs.setDirty(id, true);
tabs.togglePin(id);
tabs.setPinned(id, true);
tabs.rename(id, 'Q3 Trial Balance');
tabs.duplicate(id);
tabs.reorder(fromId, toId);
tabs.close(id);
tabs.forceClose(id);
tabs.closeOthers(id);
tabs.closeToRight(id);
tabs.mutate(id, (tab) => tab.copyWith(title: 'Updated'));

tabs.tabs;
tabs.activeTab;
tabs.length;
tabs.ordered;
tabs.pinned;
tabs.unpinned;
```

Guard UI-sensitive actions:

```dart
if (tabs.canCloseOthers(id)) tabs.closeOthers(id);
if (tabs.canCloseRight(id)) tabs.closeToRight(id);
if (tabs.canDuplicateFromUi(id)) tabs.duplicate(id);
```

Controller callbacks:

```dart
tabs.onDirtyChanged = (id, dirty) {};
tabs.onRenamed = (id, title) {};
```

From inside a page:

```dart
SuperTabBarController.of(context)?.add(title: 'Detail', kind: GLTabKind.doc);
SuperTabBarController.read(context)?.setDirty(tabId, true);
```

Both return null outside a `SuperTabBar`, so guard calls.

## Event Callbacks

```dart
SuperTabBar(
  controller: tabs,
  onTabSelected: (id) {},
  onTabAdded: (id) {},
  onTabClosed: (id) {},
  onTabDuplicated: (newId) {},
  onTabPinChanged: (id, pinned) {},
  onTabDirtyChanged: (id, dirty) {},
  onTabReordered: (fromId, toId) {},
)
```

## Localizations

Use the built-in Arabic strings:

```dart
Directionality(
  textDirection: TextDirection.rtl,
  child: SuperTabBar(localizations: SuperTabBarLocalizations.ar),
)
```

Or pass a custom `SuperTabBarLocalizations` instance to translate context
menus, dirty-close dialogs, overflow labels, and strip buttons.

## Preview Options

```dart
SuperTabBar(previewOptions: SuperTabBarPreviewOptions.disabled)
```

```dart
SuperTabBar(
  previewOptions: const SuperTabBarPreviewOptions(
    hoverDelay: Duration(milliseconds: 250),
    snapshotPixelRatio: 1.0,
    fallback: PreviewFallback.blank,
  ),
)
```

Use `PreviewFallback.blank` for expensive or sensitive page content.

## Keyboard And Pointer

Focus the strip, then use arrow keys in visual direction, `Home`, and `End`.
Right-click or long-press opens the context menu. Drag tabs to reorder. RTL
mirrors keyboard movement, overflow controls, drag indicators, and overlay
anchors.

## Gotchas

1. Stable IDs are mandatory. Never reuse a closed tab id.
2. `BrowserTab` is immutable. Change state through the controller.
3. `pageBuilder` may be used for the active page and preview fallback; keep it pure.
4. Page state is preserved by default. Use `lazyPages: true` only when desired.
5. Required pinned restrictions are UI-only; code can still close the tab.
6. `of(context)` and `read(context)` return null outside a `SuperTabBar`.
7. Register `SuperTabBarThemeData` in `ThemeData.extensions`.

## Reference

- Examples: `EXAMPLES.md` in this folder.
- Source: `lib/src/`
- README: `../../README.md`
- Example app: `../../example/lib/`
