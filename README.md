# super_tab_bar

[![pub package](https://img.shields.io/badge/pub-v2.8.0-0175C2.svg)](https://pub.dev/packages/super_tab_bar)
[![Flutter](https://img.shields.io/badge/Flutter-%E2%89%A53.32.0-02569B.svg)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-%E2%89%A53.8.0-0175C2.svg)](https://dart.dev)
[![license](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

A browser-style workspace tab bar for Flutter applications. It supports pinned, dirty, closable, unique, and required tabs; drag-to-reorder; context menus; overflow navigation; page previews; state-preserving content; responsive compact mode; localization; accessibility; and RTL layouts.

`super_tab_bar` integrates with the [`super_core`](https://pub.dev/packages/super_core) design system and can also derive its appearance from the ambient Material `ColorScheme`.

## Features

- Browser-style horizontal tab strip.
- Pinned and required-pinned tabs.
- Unique tabs identified by a stable `uniqueKey`.
- Unsaved-change indicators and dirty-close confirmation.
- Drag-and-drop tab reordering.
- Context menu for close, close others, close to the right, duplicate, pin, and unpin.
- Overflow scrolling and an open-tabs dropdown.
- Per-tab page builders.
- State-preserving pages through `IndexedStack`.
- Optional lazy page construction.
- Hover previews backed by page snapshots.
- Responsive compact mode with a thumbnail tab switcher.
- Direct callbacks for common user actions.
- Built-in English and Arabic strings.
- Accessibility semantics and RTL support.

## Requirements

| Tool | Minimum version |
|---|---:|
| Dart | `3.8.0` |
| Flutter | `3.32.0` |
| `super_core` | `3.0.0` |

## Installation

Add the package to `pubspec.yaml`:

```yaml
dependencies:
  super_core: ^3.0.0
  super_tab_bar: ^2.8.0
```

Then install the dependencies:

```bash
flutter pub get
```

Import the public library:

```dart
import 'package:super_tab_bar/super_tab_bar.dart';
```

## Application setup

The recommended setup uses `SuperMaterialThemeData` from `super_core`. `SuperTabBarThemeData` is derived automatically from the active palette, brightness, typography, spacing, and motion tokens.

```dart
import 'package:flutter/material.dart';
import 'package:super_core/super_core.dart';
import 'package:super_tab_bar/super_tab_bar.dart';

void main() {
  runApp(const WorkspaceApp());
}

class WorkspaceApp extends StatelessWidget {
  const WorkspaceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: SuperMaterialThemeData.light(
        palette: SuperPalette.purplePalette,
      ),
      darkTheme: SuperMaterialThemeData.dark(
        palette: SuperPalette.purplePalette,
      ),
      themeMode: ThemeMode.system,
      home: const WorkspaceScreen(),
    );
  }
}
```

When `SuperMaterialThemeData` is not present, the component falls back to the current Material `ColorScheme`.

## Quick start

Create and dispose the controller in the same way as other Flutter controllers.

```dart
class WorkspaceScreen extends StatefulWidget {
  const WorkspaceScreen({super.key});

  @override
  State<WorkspaceScreen> createState() => _WorkspaceScreenState();
}

class _WorkspaceScreenState extends State<WorkspaceScreen> {
  late final SuperTabBarController _controller;

  @override
  void initState() {
    super.initState();
    _controller = SuperTabBarController(
      activeId: 2,
      tabs: [
        SuperTab(
          id: 1,
          title: 'Home',
          pinned: true,
          behavior: SuperTabBehavior.requiredPinned,
          leading: const Icon(Icons.home_outlined, size: 16),
          pageBuilder: (context, tab) => const _HomePage(),
        ),
        SuperTab(
          id: 2,
          title: 'Dashboard',
          behavior: SuperTabBehavior.uniqueNormal,
          uniqueKey: 'dashboard',
          leading: const Icon(Icons.dashboard_outlined, size: 16),
          pageBuilder: (context, tab) => const _DashboardPage(),
        ),
      ],
    );
  }

  void _openReport() {
    _controller.add(
      title: 'Report ${_controller.length + 1}',
      leading: const Icon(Icons.description_outlined, size: 16),
      pageBuilder: (context, tab) => _ReportPage(tabId: tab.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SuperTabBar(
          controller: _controller,
          fillContent: true,
          scrollContent: false,
          allowAutoCompact: true,
          compactWidth: 600,
          useCompactFloatingActionButton: true,
          closeTabOnBack: true,
          onAddTab: _openReport,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class _HomePage extends StatelessWidget {
  const _HomePage();

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Home'));
  }
}

class _DashboardPage extends StatelessWidget {
  const _DashboardPage();

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Dashboard'));
  }
}

class _ReportPage extends StatelessWidget {
  const _ReportPage({required this.tabId});

  final int tabId;

  @override
  Widget build(BuildContext context) {
    return Center(child: Text('Report tab: $tabId'));
  }
}
```

The add button is displayed only when `onAddTab` is provided.

## Core concepts

### `SuperTab`

`SuperTab` is an immutable description of one workspace tab.

```dart
SuperTab(
  id: 42,
  title: 'Customer account',
  dirty: false,
  pinned: false,
  behavior: SuperTabBehavior.normal,
  uniqueKey: null,
  leading: const Icon(Icons.person_outline, size: 16),
  trailing: const Badge(label: Text('3')),
  pageBuilder: (context, tab) => CustomerPage(tabId: tab.id),
)
```

| Property | Description |
|---|---|
| `id` | Stable unique identifier. Do not reuse an ID after closing a tab. |
| `title` | Text displayed in the tab strip and overlays. |
| `dirty` | Marks the tab as containing unsaved changes. |
| `pinned` | Anchors the tab at the start of the strip and renders it compactly. |
| `behavior` | Controls the actions exposed by the user interface. |
| `uniqueKey` | Deduplication key used by `uniqueNormal` tabs. |
| `leading` | Optional widget displayed before the title. |
| `trailing` | Optional widget displayed after the title. |
| `pageBuilder` | Required builder for the tab content. |

The `pageBuilder` receives the live `SuperTab` from the controller, so changes to its title and dirty state are reflected on subsequent builds.

### Tab behavior

`SuperTabBehavior` controls which operations are available from the tab user interface.

| Behavior | Close | Duplicate | Pin or unpin | Deduplicate on add |
|---|---:|---:|---:|---:|
| `requiredPinned` | Hidden | Hidden | Hidden | No |
| `normal` | Available | Available | Available | No |
| `uniqueNormal` | Available | Hidden | Available | Yes |

A required-pinned tab is always normalized to `pinned: true`.

Programmatic methods such as `controller.close(id)` are not restricted by these UI rules.

### Unique tabs

Use `uniqueNormal` with a non-null `uniqueKey` when a workspace should contain only one instance of a destination.

```dart
void openSettings(SuperTabBarController controller) {
  controller.add(
    title: 'Settings',
    behavior: SuperTabBehavior.uniqueNormal,
    uniqueKey: 'settings',
    pageBuilder: (context, tab) => const SettingsPage(),
  );
}
```

Calling this method again selects the existing tab and returns its ID instead of creating another tab.

## Controller

`SuperTabBarController` is the source of truth for open tabs, the active tab, ordering, dirty state, titles, and preview snapshots.

### Read state

```dart
final tabs = controller.tabs;
final activeId = controller.activeId;
final activeTab = controller.activeTab;
final pinnedTabs = controller.pinned;
final unpinnedTabs = controller.unpinned;
final visualOrder = controller.ordered;
final reportTab = controller.tabById(reportId);
```

`tabs` is unmodifiable. Change state through controller methods.

### Change state

```dart
controller.select(tabId);
controller.rename(tabId, 'Updated title');
controller.setDirty(tabId, true);
controller.setPinned(tabId, true);
controller.togglePin(tabId);
controller.reorder(sourceId, targetId);
controller.duplicate(tabId);
controller.close(tabId);
controller.closeOthers(tabId);
controller.closeToRight(tabId);
```

Controller close operations are immediate. The built-in dirty confirmation is applied to close actions initiated by `SuperTabBar` itself. Add your own confirmation before calling controller close methods from application code.

### Update a page builder

A page builder is normally supplied when the tab is created. It can also be replaced later:

```dart
final tabId = controller.add(
  title: 'Loading report',
  pageBuilder: (context, tab) => const CircularProgressIndicator(),
);

controller.setPageBuilder(
  tabId,
  (context, tab) => ReportPage(tabId: tab.id),
);
```

`setPageBuilder` takes effect on the next rebuild. Trigger the rebuild through an appropriate controller mutation or application state update.

### Access the controller from a tab page

Every page built by `SuperTabBar` is placed under `SuperTabBarScope`.

```dart
final controller = SuperTabBarController.of(context);
controller?.setDirty(tabId, true);
```

Use the non-listening lookup inside callbacks:

```dart
final controller = SuperTabBarController.read(context);
controller?.rename(tabId, 'Saved report');
```

Both methods return `null` when the widget is not hosted under `SuperTabBar`.

## Dirty tabs

Mark a tab dirty when its page contains unsaved edits:

```dart
SuperTabBarController.read(context)?.setDirty(tabId, true);
```

A dirty tab displays a warning indicator. Closing it from the tab strip or context menu opens the built-in confirmation dialog.

Listen for all dirty-state changes made through the controller:

```dart
controller.onDirtyChanged = (id, isDirty) {
  debugPrint('Tab $id dirty: $isDirty');
};
```

The low-level dialog is also public:

```dart
final result = await showSuperTabDirtyCloseDialog(
  context,
  tab,
  localizations: SuperTabBarLocalizations.en,
);

switch (result) {
  case 'save':
    await saveTab(tab.id);
    controller.setDirty(tab.id, false);
    controller.close(tab.id);
  case 'discard':
    controller.close(tab.id);
  case null:
    break;
}
```

## Page layout and state

### Preserve page state

By default, `SuperTabBar` keeps all pages mounted in an `IndexedStack`. Scroll positions, text fields, focus, and stateful child widgets therefore survive tab changes.

```dart
SuperTabBar(
  controller: controller,
  lazyPages: false,
)
```

Set `lazyPages: true` to build only the active page. This uses less memory but page state is recreated when the user returns to a tab.

### Content sizing

```dart
SuperTabBar(
  controller: controller,
  fillContent: true,
  scrollContent: false,
  contentPadding: const EdgeInsets.all(16),
  contentBackground: Theme.of(context).colorScheme.surface,
)
```

| Property | Behavior |
|---|---|
| `fillContent` | Expands the content surface to the available height. Otherwise the surface is capped at 440 logical pixels. |
| `scrollContent` | Wraps each page in a `SingleChildScrollView`. Disable it when the page manages its own scrolling. |
| `contentPadding` | Padding applied around each page. |
| `contentBackground` | Overrides the content surface color. |
| `showChrome` | Enables or removes the outer border, background, radius, and clipping shell. |

Avoid nesting scroll views. Use `scrollContent: false` for pages containing `ListView`, `GridView`, `CustomScrollView`, or another primary scrollable.

## Responsive compact mode

Compact mode hides the horizontal strip and keeps the active page visible. It is intended for phones and constrained layouts.

### Automatic breakpoint

```dart
SuperTabBar(
  controller: controller,
  fillContent: true,
  allowAutoCompact: true,
  compactWidth: 600,
  useCompactFloatingActionButton: true,
)
```

The widget evaluates its own layout constraints, not the full screen width. This makes it suitable for split views and nested panels.

- `compact: true` forces compact mode.
- `allowAutoCompact: true` enables breakpoint-based switching.
- `compactWidth` defaults to `600` logical pixels.
- `useCompactFloatingActionButton` displays a built-in button that opens the tab switcher.

### Open the switcher manually

```dart
IconButton(
  tooltip: 'Open tabs',
  icon: const Icon(Icons.grid_view_rounded),
  onPressed: () async {
    await showSuperTabSwitcher(
      context,
      controller: controller,
      localizations: SuperTabBarLocalizations.en,
      showCloseButtons: true,
    );
  },
)
```

The switcher returns the selected tab ID, or `null` when dismissed.

### Embed `SuperTabSwitcher`

```dart
SuperTabSwitcher(
  controller: controller,
  crossAxisCount: 3,
  onSelect: controller.select,
  onCloseTab: (id) async {
    final tab = controller.tabById(id);
    if (tab == null) return;

    if (!tab.dirty) {
      controller.close(id);
      return;
    }

    final result = await showSuperTabDirtyCloseDialog(context, tab);
    if (result == 'discard') {
      controller.close(id);
    }
  },
)
```

When `onCloseTab` is supplied, the callback is responsible for closing the tab. When it is omitted, the switcher closes tabs directly when their UI behavior permits it.

## Hover previews

Desktop pointer users can preview a tab without selecting it.

```dart
SuperTabBar(
  controller: controller,
  previewOptions: const SuperTabBarPreviewOptions(
    enabled: true,
    hoverDelay: Duration(milliseconds: 300),
    snapshotPixelRatio: 0.8,
    fallback: PreviewFallback.liveRender,
  ),
)
```

Disable previews when pages contain sensitive content or expensive rendering:

```dart
const SuperTabBarPreviewOptions.disabled
```

`PreviewFallback.blank` shows only a surface when no page snapshot is available. `PreviewFallback.liveRender` builds a scaled fallback page.

## Events

`SuperTabBar` exposes callbacks for actions initiated by its own UI:

```dart
SuperTabBar(
  controller: controller,
  onTabSelected: (id) => debugPrint('Selected $id'),
  onTabClosed: (id) => debugPrint('Closed $id'),
  onTabDuplicated: (newId) => debugPrint('Duplicated as $newId'),
  onTabPinChanged: (id, pinned) {
    debugPrint('Tab $id pinned: $pinned');
  },
  onTabDirtyChanged: (id, dirty) {
    debugPrint('Tab $id dirty: $dirty');
  },
  onTabReordered: (fromId, toId) {
    debugPrint('Moved $fromId to $toId');
  },
)
```

For state changes initiated directly through the controller, use `addListener`, `onDirtyChanged`, or `onRenamed` as appropriate.

## Localization and RTL

The package includes English and Arabic string presets.

```dart
Directionality(
  textDirection: TextDirection.rtl,
  child: SuperTabBar(
    controller: controller,
    localizations: SuperTabBarLocalizations.ar,
  ),
)
```

Create a custom localization object to override all user-facing strings:

```dart
const strings = SuperTabBarLocalizations(
  closeTab: 'Close',
  closeOtherTabs: 'Close others',
  closeTabsToRight: 'Close tabs after this one',
  duplicateTab: 'Duplicate',
  pinTab: 'Pin',
  unpinTab: 'Unpin',
  newTab: 'New tab',
  showAllTabs: 'Show all tabs',
  scrollForward: 'Scroll forward',
  scrollBack: 'Scroll back',
  noOpenTabs: 'No tabs are open.',
  openTabsHeader: 'OPEN TABS · {count}',
  switcherTitle: 'Open tabs',
  reorderHint: 'Drag to reorder',
  discardChangesTitle: 'Discard changes?',
  cancel: 'Cancel',
  saveAndClose: 'Save and close',
  discardAndClose: 'Discard and close',
);
```

The strip, pinned area, dropdown, preview placement, compact FAB, and switcher adapt to the ambient `Directionality`.

## Theming

### Automatic theme resolution

`SuperTabBarThemeData.of(context)` resolves the theme in this order:

1. An explicitly registered `SuperTabBarThemeData` extension.
2. The ambient `SuperMaterialThemeData` from `super_core`.
3. The ambient Material `ColorScheme`.

Read resolved values from the current context:

```dart
final tabTheme = SuperTabBarThemeData.of(context);
final accent = tabTheme.accentColor;
final radius = tabTheme.radiusLarge;
```

### Component override

Register a `SuperTabBarThemeData` extension when this component needs values different from the application design system:

```dart
final baseTheme = SuperMaterialThemeData.light(
  palette: SuperPalette.purplePalette,
);

final tabTheme = SuperTabBarThemeData.fromColorScheme(
  baseTheme.colorScheme,
).copyWith(
  accentColor: Colors.indigo,
  radiusLarge: 12,
  fastDuration: const Duration(milliseconds: 80),
);

final theme = baseTheme.copyWith(
  extensions: [
    ...baseTheme.extensions.values,
    tabTheme,
  ],
);
```

`SuperTabBarThemeData` exposes:

- Surfaces: `bg`, `surface`, `surface2`, `inputBg`, and `hover`.
- Borders: `border` and `borderStrong`.
- Foreground colors: `fg1`, `fg2`, `fg3`, and `fg4`.
- Semantic colors: `accentColor`, `successColor`, `warningColor`, `dangerColor`, and `infoColor`.
- Font families: `displayFontFamily`, `bodyFontFamily`, and `monoFontFamily`.
- Radii: `radiusSmall`, `radiusMedium`, `radiusLarge`, and `radiusExtraLarge`.
- Elevation: `cardShadows` and `popShadows`.
- Motion: durations and animation curves.

## Low-level overlays

The package exports the overlay widgets used internally. They are available for custom workspace interfaces:

- `TabContextMenu` and `TabMenuItem`.
- `TabListDropdown`.
- `MiniPagePreview`.
- `showSuperTabDirtyCloseDialog`.

Most applications should prefer `SuperTabBar`, which coordinates their positioning, dismissal, and controller behavior.

## Built-in helper types

`GLTabKind`, `glTabIcon`, `glPreviewMeta`, and `kNewTabCycle` are optional helpers for applications that need a predefined set of tab categories.

```dart
final kind = GLTabKind.chart;

SuperTab(
  id: 10,
  title: glPreviewMeta(kind),
  leading: Icon(glTabIcon(kind), size: 16),
  pageBuilder: (context, tab) => AnalyticsPage(tabId: tab.id),
)
```

`GLTabPage` is a sample full-size page widget and is not required to use the tab system.

## Public API overview

| API | Purpose |
|---|---|
| `SuperTabBar` | Browser-style tab strip and page host. |
| `SuperTab` | Immutable tab model. |
| `TabPageBuilder` | Per-tab page builder signature. |
| `SuperTabBehavior` | UI operation policy for a tab. |
| `SuperTabBarController` | Tab state and operations. |
| `SuperTabBarScope` | Provides the controller to tab descendants. |
| `SuperTabSwitcher` | Responsive thumbnail grid for compact layouts. |
| `showSuperTabSwitcher` | Opens the switcher as a full-screen route. |
| `SuperTabBarPreviewOptions` | Hover and thumbnail preview configuration. |
| `PreviewFallback` | Fallback behavior when a snapshot is unavailable. |
| `SuperTabBarLocalizations` | User-facing strings. |
| `SuperTabBarThemeData` | Component `ThemeExtension`. |
| `TabContextMenu` | Low-level contextual menu overlay. |
| `TabListDropdown` | Low-level open-tabs dropdown. |
| `MiniPagePreview` | Low-level page preview overlay. |
| `showSuperTabDirtyCloseDialog` | Built-in unsaved-changes dialog. |
| `GLTabKind` and helpers | Optional predefined tab categories. |
| `GLTabPage` | Optional sample page widget. |

Backward-compatible aliases are available for the former `BrowserStyleTabBar` names.

## Flutter usage guidelines

- Own and dispose an external `SuperTabBarController` in a `State` object or dependency-injection scope.
- Use stable, never-reused tab IDs.
- Use `uniqueNormal` and a domain-specific `uniqueKey` for singleton destinations.
- Keep `pageBuilder` focused on constructing the page; place business state in the page controller, view model, or application layer.
- Disable `scrollContent` when a page contains its own scrollable.
- Prefer the default state-preserving mode for forms and workspaces.
- Enable `lazyPages` only after measuring memory or build cost.
- Confirm dirty state before programmatic close operations.
- Avoid placing secrets or sensitive data in previews; disable previews or use `PreviewFallback.blank` when necessary.
- Use `Directionality` and the matching `SuperTabBarLocalizations` preset for RTL interfaces.

## Testing

Inject a controller with deterministic tabs into widget tests:

```dart
final controller = SuperTabBarController(
  activeId: 1,
  tabs: [
    SuperTab(
      id: 1,
      title: 'Home',
      pageBuilder: (context, tab) => const Text('Home content'),
    ),
  ],
);

await tester.pumpWidget(
  MaterialApp(
    home: Scaffold(
      body: SuperTabBar(
        controller: controller,
        fillContent: true,
        scrollContent: false,
      ),
    ),
  ),
);

expect(find.text('Home'), findsOneWidget);
expect(find.text('Home content'), findsOneWidget);
```

Dispose manually created controllers at the end of the test.

## License

This package is distributed under the MIT License. See [LICENSE](LICENSE).
