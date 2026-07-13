// ============================================================
// super_tab_bar · Tests
//   File: test/super_tab_bar_test.dart
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:super_tab_bar/super_tab_bar.dart';

/// A dummy page builder used by tests that just need *some* content.
Widget _dummyPage(BuildContext _, BrowserTab __) => const SizedBox.shrink();

void main() {
  // ════════════════════════════════════════════════════════
  // BrowserTab immutability
  // ════════════════════════════════════════════════════════
  group('BrowserTab — immutability', () {
    test('all fields are final — copyWith produces a new instance', () {
      final tab = BrowserTab(
        id: 1,
        title: 'Test',
        pageBuilder: _dummyPage,
      );
      final copy = tab.copyWith(title: 'Updated');

      expect(copy.title, 'Updated');
      expect(tab.title, 'Test', reason: 'original must be unchanged');
      expect(identical(tab, copy), isFalse);
    });

    test('copyWith preserves untouched fields', () {
      final tab = BrowserTab(
        id: 1,
        title: 'T',
        icon: Icons.public,
        dirty: true,
        pinned: true,
        behavior: SuperTabBehavior.uniqueNormal,
        uniqueKey: 'k',
        pageBuilder: _dummyPage,
      );
      final copy = tab.copyWith(title: 'New');

      expect(copy.id, 1);
      expect(copy.icon, Icons.public);
      expect(copy.dirty, isTrue);
      expect(copy.pinned, isTrue);
      expect(copy.behavior, SuperTabBehavior.uniqueNormal);
      expect(copy.uniqueKey, 'k');
      expect(copy.pageBuilder, same(_dummyPage));
    });

    test('value equality holds for identical data', () {
      final a = BrowserTab(id: 5, title: 'Same', pageBuilder: _dummyPage);
      final b = BrowserTab(id: 5, title: 'Same', pageBuilder: _dummyPage);
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('value equality fails for different data', () {
      final a = BrowserTab(id: 1, title: 'A', pageBuilder: _dummyPage);
      final b = BrowserTab(id: 2, title: 'A', pageBuilder: _dummyPage);
      expect(a, isNot(equals(b)));
    });

    test('pageBuilder is required and stored (v2.5)', () {
      Widget page(BuildContext _, BrowserTab __) => const Text('p');
      final tab = BrowserTab(
        id: 1,
        title: 'With builder',
        pageBuilder: page,
      );
      expect(tab.pageBuilder, same(page));
      // copyWith without pageBuilder keeps the existing builder.
      final renamed = tab.copyWith(title: 'Renamed');
      expect(renamed.pageBuilder, same(page));
      // copyWith can replace the builder.
      Widget other(BuildContext _, BrowserTab __) => const Text('other');
      final swapped = tab.copyWith(pageBuilder: other);
      expect(swapped.pageBuilder, same(other));
    });

    test('icon defaults to null when not provided', () {
      final tab = BrowserTab(id: 1, title: 'No icon', pageBuilder: _dummyPage);
      expect(tab.icon, isNull);
    });

    test('has no `kind` field anymore (v2.5 — removed)', () {
      // Sanity: BrowserTab no longer accepts `kind`. This is a compile-time
      // guarantee; the test existing & compiling is the assertion.
      final tab = BrowserTab(id: 1, title: 'No kind', pageBuilder: _dummyPage);
      expect(tab.title, 'No kind');
    });
  });

  // ════════════════════════════════════════════════════════
  // SuperTabBehavior — requiredPinned
  // ════════════════════════════════════════════════════════
  group('SuperTabBehavior.requiredPinned', () {
    late SuperTabBarController ctrl;

    setUp(() {
      ctrl = SuperTabBarController(tabs: [
        BrowserTab(
          id: 1,
          title: 'Home',
          icon: Icons.public,
          pinned: true,
          behavior: SuperTabBehavior.requiredPinned,
          pageBuilder: _dummyPage,
        ),
        BrowserTab(id: 2, title: 'Normal', pageBuilder: _dummyPage),
      ], activeId: 2);
    });

    tearDown(() => ctrl.dispose());

    test('canCloseFromUi returns false', () {
      expect(ctrl.canCloseFromUi(1), isFalse);
    });

    test('canDuplicateFromUi returns false', () {
      expect(ctrl.canDuplicateFromUi(1), isFalse);
    });

    test('canTogglePinFromUi returns false', () {
      expect(ctrl.canTogglePinFromUi(1), isFalse);
    });

    test('normal tab has all UI permissions', () {
      expect(ctrl.canCloseFromUi(2), isTrue);
      expect(ctrl.canDuplicateFromUi(2), isTrue);
      expect(ctrl.canTogglePinFromUi(2), isTrue);
    });

    test('setPinned(id, false) is a no-op for requiredPinned', () {
      ctrl.setPinned(1, false);
      expect(ctrl.tabById(1)!.pinned, isTrue);
    });

    test('programmatic close() still works', () {
      ctrl.close(1);
      expect(ctrl.tabById(1), isNull);
      expect(ctrl.length, 1);
    });

    test('forceClose() is equivalent to close()', () {
      ctrl.forceClose(1);
      expect(ctrl.tabById(1), isNull);
    });

    test('duplicate() returns -1', () {
      final result = ctrl.duplicate(1);
      expect(result, -1);
      expect(ctrl.length, 2);
    });

    test('_normalize enforces pinned: true on requiredPinned tabs', () {
      // Construct with pinned: false — controller must normalise to true.
      final c = SuperTabBarController(tabs: [
        BrowserTab(
          id: 99,
          title: 'X',
          pinned: false, // intentionally wrong
          behavior: SuperTabBehavior.requiredPinned,
          pageBuilder: _dummyPage,
        ),
      ]);
      expect(c.tabById(99)!.pinned, isTrue);
      c.dispose();
    });
  });

  // ════════════════════════════════════════════════════════
  // SuperTabBehavior — uniqueNormal
  // ════════════════════════════════════════════════════════
  group('SuperTabBehavior.uniqueNormal', () {
    late SuperTabBarController ctrl;

    setUp(() {
      ctrl = SuperTabBarController(tabs: [
        BrowserTab(id: 1, title: 'Normal', pageBuilder: _dummyPage),
        BrowserTab(
          id: 2,
          title: 'Settings',
          behavior: SuperTabBehavior.uniqueNormal,
          uniqueKey: 'settings',
          pageBuilder: _dummyPage,
        ),
      ], activeId: 1);
    });

    tearDown(() => ctrl.dispose());

    test('canDuplicateFromUi returns false', () {
      expect(ctrl.canDuplicateFromUi(2), isFalse);
    });

    test('canCloseFromUi returns true', () {
      expect(ctrl.canCloseFromUi(2), isTrue);
    });

    test('canTogglePinFromUi returns true', () {
      expect(ctrl.canTogglePinFromUi(2), isTrue);
    });

    test('duplicate() returns -1', () {
      final result = ctrl.duplicate(2);
      expect(result, -1);
      expect(ctrl.length, 2);
    });

    test('add() with same uniqueKey selects existing tab', () {
      final resultId = ctrl.add(
        title: 'Settings',
        behavior: SuperTabBehavior.uniqueNormal,
        uniqueKey: 'settings',
        pageBuilder: _dummyPage,
      );
      expect(resultId, 2);
      expect(ctrl.length, 2, reason: 'no new tab should be created');
      expect(ctrl.activeId, 2, reason: 'existing tab should be selected');
    });

    test('add() with different uniqueKey creates new tab', () {
      final resultId = ctrl.add(
        title: 'Profile',
        behavior: SuperTabBehavior.uniqueNormal,
        uniqueKey: 'profile',
        pageBuilder: _dummyPage,
      );
      expect(resultId, isNot(2));
      expect(ctrl.length, 3);
    });

    test('add() with null uniqueKey always creates new tab', () {
      final resultId = ctrl.add(
        title: 'Settings Copy',
        behavior: SuperTabBehavior.uniqueNormal,
        pageBuilder: _dummyPage,
        // no uniqueKey — dedup does not apply
      );
      expect(ctrl.length, 3);
      expect(resultId, isNot(2));
    });

    test('add() with activate: false does not change activeId', () {
      ctrl.add(
        title: 'Settings',
        behavior: SuperTabBehavior.uniqueNormal,
        uniqueKey: 'settings',
        activate: false,
        pageBuilder: _dummyPage,
      );
      expect(ctrl.activeId, 1);
    });
  });

  // ════════════════════════════════════════════════════════
  // SuperTabBarController — core operations
  // ════════════════════════════════════════════════════════
  group('SuperTabBarController', () {
    late SuperTabBarController ctrl;

    setUp(() {
      ctrl = SuperTabBarController(tabs: [
        BrowserTab(id: 1, title: 'One', pageBuilder: _dummyPage),
        BrowserTab(id: 2, title: 'Two', pageBuilder: _dummyPage),
        BrowserTab(id: 3, title: 'Three', pageBuilder: _dummyPage),
      ], activeId: 1);
    });

    tearDown(() => ctrl.dispose());

    test('select changes activeId', () {
      ctrl.select(2);
      expect(ctrl.activeId, 2);
    });

    test('add creates a tab and returns its id', () {
      final id = ctrl.add(title: 'New', pageBuilder: _dummyPage);
      expect(ctrl.length, 4);
      expect(ctrl.tabById(id)?.title, 'New');
      expect(ctrl.activeId, id);
    });

    test('add with at: inserts at the given index', () {
      ctrl.add(title: 'Inserted', pageBuilder: _dummyPage, at: 1);
      expect(ctrl.tabs[1].title, 'Inserted');
    });

    test('add carries pageBuilder onto the new tab (v2.5)', () {
      Widget page(BuildContext _, BrowserTab __) => const SizedBox();
      final id = ctrl.add(
        title: 'With builder',
        pageBuilder: page,
      );
      expect(ctrl.tabById(id)?.pageBuilder, same(page));
    });

    test('add carries icon onto the new tab (v2.5)', () {
      final id = ctrl.add(
        title: 'With icon',
        icon: Icons.star,
        pageBuilder: _dummyPage,
      );
      expect(ctrl.tabById(id)?.icon, Icons.star);
    });

    test('add requires pageBuilder (v2.5 — no default content)', () {
      // pageBuilder is now required — sanity that it compiles as a named
      // required param is implicit in the other add() tests above.
      final id = ctrl.add(pageBuilder: _dummyPage);
      expect(ctrl.tabById(id), isNotNull);
    });

    test('close removes the tab and selects nearest neighbour', () {
      ctrl.close(1);
      expect(ctrl.tabById(1), isNull);
      expect(ctrl.length, 2);
      expect(ctrl.activeId, 2);
    });

    test('close last tab sets activeId to null', () {
      ctrl.close(1);
      ctrl.close(2);
      ctrl.close(3);
      expect(ctrl.activeId, isNull);
    });

    test('closeOthers removes all non-pinned except id', () {
      ctrl.add(title: 'Extra', pageBuilder: _dummyPage);
      ctrl.closeOthers(1);
      expect(ctrl.length, 1);
      expect(ctrl.tabs.first.id, 1);
    });

    test('closeToRight removes only tabs after id', () {
      ctrl.closeToRight(1);
      expect(ctrl.length, 1);
      expect(ctrl.tabs.first.id, 1);
    });

    test('duplicate creates a copy after the source', () {
      final nid = ctrl.duplicate(1);
      expect(ctrl.length, 4);
      final i = ctrl.tabs.indexWhere((t) => t.id == nid);
      expect(i, 1, reason: 'copy should be at index 1 (right after original)');
      expect(ctrl.tabById(nid)?.title, 'One');
      expect(ctrl.tabById(nid)?.dirty, isFalse);
      expect(ctrl.activeId, nid);
    });

    test('duplicate copies icon and pageBuilder (v2.5)', () {
      Widget page(BuildContext _, BrowserTab __) => const Text('dup');
      final c = SuperTabBarController(tabs: [
        BrowserTab(
          id: 1,
          title: 'Original',
          icon: Icons.ac_unit,
          pageBuilder: page,
        ),
      ], activeId: 1);
      addTearDown(c.dispose);
      final nid = c.duplicate(1);
      expect(c.tabById(nid)?.icon, Icons.ac_unit);
      expect(c.tabById(nid)?.pageBuilder, same(page));
    });

    test('reorder moves a tab', () {
      ctrl.reorder(3, 1);
      expect(ctrl.tabs.first.id, 3);
    });

    test('setDirty updates flag immutably', () {
      ctrl.setDirty(1, true);
      expect(ctrl.tabById(1)!.dirty, isTrue);
      ctrl.setDirty(1, false);
      expect(ctrl.tabById(1)!.dirty, isFalse);
    });

    test('rename updates title immutably', () {
      ctrl.rename(1, 'Renamed');
      expect(ctrl.tabById(1)!.title, 'Renamed');
    });

    test('setDirty fires onDirtyChanged callback', () {
      bool? fired;
      ctrl.onDirtyChanged = (id, dirty) => fired = dirty;
      ctrl.setDirty(1, true);
      expect(fired, isTrue);
    });

    test('rename fires onRenamed callback', () {
      String? firedTitle;
      ctrl.onRenamed = (id, title) => firedTitle = title;
      ctrl.rename(1, 'Test');
      expect(firedTitle, 'Test');
    });

    test('togglePin flips pinned flag immutably', () {
      ctrl.togglePin(1);
      expect(ctrl.tabById(1)!.pinned, isTrue);
      ctrl.togglePin(1);
      expect(ctrl.tabById(1)!.pinned, isFalse);
    });

    test('ordered puts pinned tabs first', () {
      ctrl.setPinned(3, true);
      final order = ctrl.ordered;
      expect(order.first.id, 3);
    });

    test('canCloseOthers is false when all other tabs are pinned', () {
      ctrl.setPinned(2, true);
      ctrl.setPinned(3, true);
      expect(ctrl.canCloseOthers(1), isFalse);
    });
  });

  // ════════════════════════════════════════════════════════
  // SuperTabBarLocalizations
  // ════════════════════════════════════════════════════════
  group('SuperTabBarLocalizations', () {
    test('English defaults are populated', () {
      const loc = SuperTabBarLocalizations.en;
      expect(loc.closeTab, isNotEmpty);
      expect(loc.newTab, isNotEmpty);
      expect(loc.cancel, isNotEmpty);
    });

    test('Arabic defaults are populated', () {
      const loc = SuperTabBarLocalizations.ar;
      expect(loc.closeTab, isNotEmpty);
      expect(loc.newTab, isNotEmpty);
    });

    test('openTabsHeaderFor substitutes count', () {
      const loc = SuperTabBarLocalizations.en;
      expect(loc.openTabsHeaderFor(7), contains('7'));
    });

    test('dirtyTabBody includes the tab title', () {
      const loc = SuperTabBarLocalizations.en;
      expect(loc.dirtyTabBody('My Report'), contains('My Report'));
    });

    test('compact-switcher strings are populated (en + ar)', () {
      expect(SuperTabBarLocalizations.en.switcherTitle, isNotEmpty);
      expect(SuperTabBarLocalizations.en.reorderHint, isNotEmpty);
      expect(SuperTabBarLocalizations.ar.switcherTitle, isNotEmpty);
      expect(SuperTabBarLocalizations.ar.reorderHint, isNotEmpty);
    });
  });

  // ════════════════════════════════════════════════════════
  // SuperTabBarPreviewOptions
  // ════════════════════════════════════════════════════════
  group('SuperTabBarPreviewOptions', () {
    test('defaults preset has expected values', () {
      const opts = SuperTabBarPreviewOptions.defaults;
      expect(opts.enabled, isTrue);
      expect(opts.hoverDelay, const Duration(milliseconds: 480));
      expect(opts.snapshotPixelRatio, 0.6);
      expect(opts.fallback, PreviewFallback.liveRender);
    });

    test('disabled preset has enabled: false', () {
      expect(SuperTabBarPreviewOptions.disabled.enabled, isFalse);
    });

    test('custom options are stored correctly', () {
      const opts = SuperTabBarPreviewOptions(
        enabled: false,
        hoverDelay: Duration(seconds: 1),
        snapshotPixelRatio: 1.0,
        fallback: PreviewFallback.blank,
      );
      expect(opts.enabled, isFalse);
      expect(opts.hoverDelay, const Duration(seconds: 1));
      expect(opts.snapshotPixelRatio, 1.0);
      expect(opts.fallback, PreviewFallback.blank);
    });
  });

  // ════════════════════════════════════════════════════════
  // Widget smoke tests
  // ════════════════════════════════════════════════════════
  group('SuperTabBar widget', () {
    Widget wrap(Widget child) => MaterialApp(
          theme: ThemeData(
              extensions: const [SuperTabBarThemeData.light]),
          home: Scaffold(body: child),
        );

    testWidgets('renders with default controller', (tester) async {
      await tester.pumpWidget(wrap(const SuperTabBar()));
      expect(find.byType(SuperTabBar), findsOneWidget);
    });

    testWidgets('BrowserStyleTabBar alias renders SuperTabBar', (tester) async {
      await tester.pumpWidget(wrap(const BrowserStyleTabBar()));
      expect(find.byType(SuperTabBar), findsOneWidget);
    });

    testWidgets('onTabSelected fires when a tab is tapped', (tester) async {
      final ctrl = SuperTabBarController(tabs: [
        BrowserTab(id: 1, title: 'One', pageBuilder: _dummyPage),
        BrowserTab(id: 2, title: 'Two', pageBuilder: _dummyPage),
      ], activeId: 1);
      addTearDown(ctrl.dispose);

      int? selected;
      await tester.pumpWidget(wrap(
        SuperTabBar(
          controller: ctrl,
          onTabSelected: (id) => selected = id,
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Two'));
      await tester.pump();
      expect(selected, 2);
    });

    testWidgets('tapping + calls onAddTab (v2.5 — no auto-add)',
        (tester) async {
      final ctrl = SuperTabBarController(tabs: [
        BrowserTab(id: 1, title: 'One', pageBuilder: _dummyPage),
      ], activeId: 1);
      addTearDown(ctrl.dispose);

      int addCalls = 0;
      await tester.pumpWidget(wrap(
        SuperTabBar(
          controller: ctrl,
          onAddTab: () => addCalls++,
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();
      expect(addCalls, 1, reason: 'onAddTab should be invoked once');
      // The widget no longer auto-adds — length stays unchanged.
      expect(ctrl.length, 1);
    });

    testWidgets('onTabAdded is not fired from the + button (v2.5)',
        (tester) async {
      final ctrl = SuperTabBarController(tabs: [
        BrowserTab(id: 1, title: 'One', pageBuilder: _dummyPage),
      ], activeId: 1);
      addTearDown(ctrl.dispose);

      int? addedId;
      await tester.pumpWidget(wrap(
        SuperTabBar(
          controller: ctrl,
          onAddTab: () {}, // + button visible
          onTabAdded: (id) => addedId = id, // deprecated — no longer fired
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();
      expect(addedId, isNull,
          reason: 'v2.5: onTabAdded is no longer fired from the + button');
    });

    testWidgets('+ button is hidden when onAddTab is null (v2.5)',
        (tester) async {
      final ctrl = SuperTabBarController(tabs: [
        BrowserTab(id: 1, title: 'One', pageBuilder: _dummyPage),
      ], activeId: 1);
      addTearDown(ctrl.dispose);

      await tester.pumpWidget(wrap(SuperTabBar(
        controller: ctrl,
        // no onAddTab → + button must NOT be rendered
      )));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.add), findsNothing,
          reason: 'v2.5: the + button only shows when onAddTab is provided');
      // ▾ (tab list) is intrinsic and stays visible.
      expect(find.byIcon(Icons.expand_more), findsOneWidget);
    });

    testWidgets('requiredPinned tab appears in pinned region', (tester) async {
      final ctrl = SuperTabBarController(tabs: [
        BrowserTab(
          id: 1,
          title: 'Home',
          icon: Icons.public,
          pinned: true,
          behavior: SuperTabBehavior.requiredPinned,
          pageBuilder: _dummyPage,
        ),
        BrowserTab(id: 2, title: 'Doc', pageBuilder: _dummyPage),
      ], activeId: 2);
      addTearDown(ctrl.dispose);

      await tester.pumpWidget(wrap(SuperTabBar(
        controller: ctrl,
        onAddTab: () {},
      )));
      await tester.pumpAndSettle();
      expect(find.byType(SuperTabBar), findsOneWidget);
      // Home is pinned so it should be in the pinned region (compact chip).
      expect(ctrl.pinned.any((t) => t.id == 1), isTrue);
    });

    testWidgets('custom localizations are used', (tester) async {
      final ctrl = SuperTabBarController(tabs: [
        BrowserTab(id: 1, title: 'Tab', pageBuilder: _dummyPage),
      ], activeId: 1);
      addTearDown(ctrl.dispose);

      await tester.pumpWidget(wrap(
        SuperTabBar(
          controller: ctrl,
          localizations: const SuperTabBarLocalizations(
            closeTab: 'Custom Close',
            closeOtherTabs: 'Custom Close Others',
            closeTabsToRight: 'Custom Close Right',
            duplicateTab: 'Custom Duplicate',
            pinTab: 'Custom Pin',
            unpinTab: 'Custom Unpin',
            newTab: 'Custom New',
            showAllTabs: 'Custom Show All',
            scrollForward: 'Custom Forward',
            scrollBack: 'Custom Back',
            noOpenTabs: 'Custom Empty',
            openTabsHeader: 'TABS · {count}',
            switcherTitle: 'Custom Switcher',
            reorderHint: 'Custom Reorder',
            discardChangesTitle: 'Custom Discard?',
            cancel: 'Custom Cancel',
            saveAndClose: 'Custom Save',
            discardAndClose: 'Custom Discard',
          ),
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.byType(SuperTabBar), findsOneWidget);
    });

    testWidgets('preview disabled prevents capture', (tester) async {
      final ctrl = SuperTabBarController(tabs: [
        BrowserTab(id: 1, title: 'Tab', pageBuilder: _dummyPage),
      ], activeId: 1);
      addTearDown(ctrl.dispose);

      await tester.pumpWidget(wrap(
        SuperTabBar(
          controller: ctrl,
          previewOptions: SuperTabBarPreviewOptions.disabled,
        ),
      ));
      await tester.pumpAndSettle();
      // When disabled, no snapshot is ever captured.
      expect(ctrl.snapshot(1), isNull);
    });

    testWidgets('per-tab pageBuilder renders (v2.5)', (tester) async {
      final ctrl = SuperTabBarController(tabs: [
        BrowserTab(
          id: 1,
          title: 'One',
          pageBuilder: (_, __) => const Text('custom-page-content'),
        ),
      ], activeId: 1);
      addTearDown(ctrl.dispose);

      await tester.pumpWidget(wrap(SuperTabBar(
        controller: ctrl,
        fillContent: true,
        scrollContent: false,
        onAddTab: () {},
      )));
      await tester.pumpAndSettle();
      expect(find.text('custom-page-content'), findsOneWidget);
    });
  });

  // ════════════════════════════════════════════════════════
  // Compact mode & dirty-aware back navigation (v2.1)
  // ════════════════════════════════════════════════════════
  group('SuperTabBar — compact mode & back navigation', () {
    Widget wrap(Widget child) => MaterialApp(
          theme: ThemeData(extensions: const [SuperTabBarThemeData.light]),
          home: Scaffold(body: child),
        );

    SuperTabBarController two({bool dirty = false}) => SuperTabBarController(
          tabs: [
            BrowserTab(
                id: 1,
                title: 'One',
                pageBuilder: (_, __) => const Text('page')),
            BrowserTab(
                id: 2,
                title: 'Two',
                dirty: dirty,
                pageBuilder: (_, __) => const Text('page')),
          ],
          activeId: 2,
        );

    testWidgets('non-compact renders the ▾ tab-list button', (tester) async {
      final ctrl = two();
      addTearDown(ctrl.dispose);
      await tester.pumpWidget(wrap(SuperTabBar(
        controller: ctrl,
        onAddTab: () {}, // + button only shows when onAddTab is non-null
      )));
      await tester.pumpAndSettle();
      // + (new tab) and ▾ (tab list) live in the strip.
      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.byIcon(Icons.expand_more), findsOneWidget);
    });

    testWidgets('compact: true hides the strip', (tester) async {
      final ctrl = two();
      addTearDown(ctrl.dispose);
      await tester.pumpWidget(wrap(SuperTabBar(
        controller: ctrl,
        compact: true,
        onAddTab: () {},
      )));
      await tester.pumpAndSettle();
      // Strip controls are gone; only the active page remains.
      expect(find.byIcon(Icons.add), findsNothing);
      expect(find.byIcon(Icons.expand_more), findsNothing);
      expect(find.text('page'), findsOneWidget);
    });

    testWidgets('closeTabOnBack: false wraps no PopScope', (tester) async {
      final ctrl = two();
      addTearDown(ctrl.dispose);
      await tester.pumpWidget(wrap(SuperTabBar(
        controller: ctrl,
        onAddTab: () {},
      )));
      await tester.pumpAndSettle();
      expect(
        find.descendant(
            of: find.byType(SuperTabBar), matching: find.byType(PopScope)),
        findsNothing,
      );
    });

    testWidgets('closeTabOnBack blocks pop for a clean active tab',
        (tester) async {
      final ctrl = two(); // active tab #2 is clean
      addTearDown(ctrl.dispose);
      await tester.pumpWidget(wrap(SuperTabBar(
        controller: ctrl,
        closeTabOnBack: true,
        onAddTab: () {},
      )));
      await tester.pumpAndSettle();
      final scope = find.descendant(
          of: find.byType(SuperTabBar), matching: find.byType(PopScope));
      expect(scope, findsOneWidget);
      // Clean active tab → we intercept the back (canPop == false).
      expect(tester.widget<PopScope>(scope).canPop, isFalse);
    });

    testWidgets('closeTabOnBack allows pop when the active tab is dirty',
        (tester) async {
      final ctrl = two(dirty: true); // active tab #2 is dirty
      addTearDown(ctrl.dispose);
      await tester.pumpWidget(wrap(SuperTabBar(
        controller: ctrl,
        closeTabOnBack: true,
        onAddTab: () {},
      )));
      await tester.pumpAndSettle();
      final scope = find.descendant(
          of: find.byType(SuperTabBar), matching: find.byType(PopScope));
      // Dirty active tab → never auto-closed → back pops normally (canPop true).
      expect(tester.widget<PopScope>(scope).canPop, isTrue);
    });
  });

  // ════════════════════════════════════════════════════════
  // SuperTabSwitcher / showSuperTabSwitcher (v2.1)
  // ════════════════════════════════════════════════════════
  group('SuperTabSwitcher', () {
    Widget wrap(Widget child) => MaterialApp(
          theme: ThemeData(extensions: const [SuperTabBarThemeData.light]),
          home: Scaffold(body: child),
        );

    // Blank fallback → thumbnails show an icon (or nothing when icon is null),
    // not a live-rendered title, so each tab's title appears exactly once
    // (in the card footer).
    const blankPreview =
        SuperTabBarPreviewOptions(fallback: PreviewFallback.blank);

    SuperTabBarController three() => SuperTabBarController(
          tabs: [
            BrowserTab(id: 1, title: 'One', pageBuilder: _dummyPage),
            BrowserTab(id: 2, title: 'Two', pageBuilder: _dummyPage),
            BrowserTab(id: 3, title: 'Three', pageBuilder: _dummyPage),
          ],
          activeId: 1,
        );

    testWidgets('renders a thumbnail per tab with the switcher title',
        (tester) async {
      final ctrl = three();
      addTearDown(ctrl.dispose);
      await tester.pumpWidget(wrap(SuperTabSwitcher(
        controller: ctrl,
        previewOptions: blankPreview,
      )));
      await tester.pumpAndSettle();
      expect(find.text('Open tabs'), findsOneWidget); // switcherTitle
      expect(find.text('One'), findsOneWidget);
      expect(find.text('Two'), findsOneWidget);
      expect(find.text('Three'), findsOneWidget);
    });

    testWidgets('tapping a thumbnail selects that tab', (tester) async {
      final ctrl = three();
      addTearDown(ctrl.dispose);
      int? picked;
      await tester.pumpWidget(wrap(SuperTabSwitcher(
        controller: ctrl,
        previewOptions: blankPreview,
        onSelect: (id) {
          picked = id;
          ctrl.select(id);
        },
      )));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Three'));
      await tester.pump();
      expect(picked, 3);
      expect(ctrl.activeId, 3);
    });

    testWidgets('onCloseTab fires for the thumbnail close button',
        (tester) async {
      final ctrl = three();
      addTearDown(ctrl.dispose);
      final closed = <int>[];
      await tester.pumpWidget(wrap(SuperTabSwitcher(
        controller: ctrl,
        previewOptions: blankPreview,
        onCloseTab: closed.add,
      )));
      await tester.pumpAndSettle();
      // Thumbnail close buttons carry the localized "Close tab" semantics label;
      // the header dismiss button does not.
      await tester.tap(find.bySemanticsLabel('Close tab').first);
      await tester.pump();
      expect(closed, isNotEmpty);
      expect(closed.first, 1, reason: 'first ordered tab is #1');
    });

    testWidgets('showSuperTabSwitcher returns the picked id and pops',
        (tester) async {
      final ctrl = three();
      addTearDown(ctrl.dispose);
      int? result;
      await tester.pumpWidget(wrap(Builder(
        builder: (ctx) => ElevatedButton(
          onPressed: () async {
            result = await showSuperTabSwitcher(
              ctx,
              controller: ctrl,
              previewOptions: blankPreview,
            );
          },
          child: const Text('open'),
        ),
      )));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('Open tabs'), findsOneWidget);

      await tester.tap(find.text('Two'));
      await tester.pumpAndSettle();
      // Route popped, controller updated, id returned.
      expect(find.text('Open tabs'), findsNothing);
      expect(ctrl.activeId, 2);
      expect(result, 2);
    });
  });
}
