// ============================================================
// super_tab_bar · Tests
//   File: test/super_tab_bar_test.dart
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:super_tab_bar/super_tab_bar.dart';

void main() {
  // ════════════════════════════════════════════════════════
  // BrowserTab immutability
  // ════════════════════════════════════════════════════════
  group('BrowserTab — immutability', () {
    test('all fields are final — copyWith produces a new instance', () {
      const tab = BrowserTab(id: 1, title: 'Test', kind: GLTabKind.doc);
      final copy = tab.copyWith(title: 'Updated');

      expect(copy.title, 'Updated');
      expect(tab.title, 'Test', reason: 'original must be unchanged');
      expect(identical(tab, copy), isFalse);
    });

    test('copyWith preserves untouched fields', () {
      const tab = BrowserTab(
        id: 1,
        title: 'T',
        kind: GLTabKind.chart,
        dirty: true,
        pinned: true,
        behavior: SuperTabBehavior.uniqueNormal,
        uniqueKey: 'k',
      );
      final copy = tab.copyWith(title: 'New');

      expect(copy.id, 1);
      expect(copy.kind, GLTabKind.chart);
      expect(copy.dirty, isTrue);
      expect(copy.pinned, isTrue);
      expect(copy.behavior, SuperTabBehavior.uniqueNormal);
      expect(copy.uniqueKey, 'k');
    });

    test('value equality holds for identical data', () {
      const a = BrowserTab(id: 5, title: 'Same', kind: GLTabKind.user);
      const b = BrowserTab(id: 5, title: 'Same', kind: GLTabKind.user);
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('value equality fails for different data', () {
      const a = BrowserTab(id: 1, title: 'A', kind: GLTabKind.doc);
      const b = BrowserTab(id: 2, title: 'A', kind: GLTabKind.doc);
      expect(a, isNot(equals(b)));
    });
  });

  // ════════════════════════════════════════════════════════
  // SuperTabBehavior — requiredPinned
  // ════════════════════════════════════════════════════════
  group('SuperTabBehavior.requiredPinned', () {
    late SuperTabBarController ctrl;

    setUp(() {
      ctrl = SuperTabBarController(tabs: [
        const BrowserTab(
          id: 1,
          title: 'Home',
          kind: GLTabKind.globe,
          pinned: true,
          behavior: SuperTabBehavior.requiredPinned,
        ),
        const BrowserTab(id: 2, title: 'Normal', kind: GLTabKind.doc),
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
        const BrowserTab(
          id: 99,
          title: 'X',
          kind: GLTabKind.globe,
          pinned: false, // intentionally wrong
          behavior: SuperTabBehavior.requiredPinned,
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
        const BrowserTab(id: 1, title: 'Normal', kind: GLTabKind.doc),
        const BrowserTab(
          id: 2,
          title: 'Settings',
          kind: GLTabKind.user,
          behavior: SuperTabBehavior.uniqueNormal,
          uniqueKey: 'settings',
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
        kind: GLTabKind.user,
        behavior: SuperTabBehavior.uniqueNormal,
        uniqueKey: 'settings',
      );
      expect(resultId, 2);
      expect(ctrl.length, 2, reason: 'no new tab should be created');
      expect(ctrl.activeId, 2, reason: 'existing tab should be selected');
    });

    test('add() with different uniqueKey creates new tab', () {
      final resultId = ctrl.add(
        title: 'Profile',
        kind: GLTabKind.user,
        behavior: SuperTabBehavior.uniqueNormal,
        uniqueKey: 'profile',
      );
      expect(resultId, isNot(2));
      expect(ctrl.length, 3);
    });

    test('add() with null uniqueKey always creates new tab', () {
      final resultId = ctrl.add(
        title: 'Settings Copy',
        kind: GLTabKind.user,
        behavior: SuperTabBehavior.uniqueNormal,
        // no uniqueKey — dedup does not apply
      );
      expect(ctrl.length, 3);
      expect(resultId, isNot(2));
    });

    test('add() with activate: false does not change activeId', () {
      ctrl.add(
        title: 'Settings',
        kind: GLTabKind.user,
        behavior: SuperTabBehavior.uniqueNormal,
        uniqueKey: 'settings',
        activate: false,
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
        const BrowserTab(id: 1, title: 'One', kind: GLTabKind.ledger),
        const BrowserTab(id: 2, title: 'Two', kind: GLTabKind.doc),
        const BrowserTab(id: 3, title: 'Three', kind: GLTabKind.chart),
      ], activeId: 1);
    });

    tearDown(() => ctrl.dispose());

    test('select changes activeId', () {
      ctrl.select(2);
      expect(ctrl.activeId, 2);
    });

    test('add creates a tab and returns its id', () {
      final id = ctrl.add(title: 'New', kind: GLTabKind.store);
      expect(ctrl.length, 4);
      expect(ctrl.tabById(id)?.title, 'New');
      expect(ctrl.activeId, id);
    });

    test('add with at: inserts at the given index', () {
      ctrl.add(title: 'Inserted', kind: GLTabKind.doc, at: 1);
      expect(ctrl.tabs[1].title, 'Inserted');
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
      ctrl.add(title: 'Extra', kind: GLTabKind.globe);
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
        const BrowserTab(id: 1, title: 'One', kind: GLTabKind.doc),
        const BrowserTab(id: 2, title: 'Two', kind: GLTabKind.chart),
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

    testWidgets('onTabAdded fires when + is tapped', (tester) async {
      final ctrl = SuperTabBarController(tabs: [
        const BrowserTab(id: 1, title: 'One', kind: GLTabKind.doc),
      ], activeId: 1);
      addTearDown(ctrl.dispose);

      int? addedId;
      await tester.pumpWidget(wrap(
        SuperTabBar(
          controller: ctrl,
          onTabAdded: (id) => addedId = id,
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();
      expect(addedId, isNotNull);
      expect(ctrl.length, 2);
    });

    testWidgets('requiredPinned tab appears in pinned region', (tester) async {
      final ctrl = SuperTabBarController(tabs: [
        const BrowserTab(
          id: 1,
          title: 'Home',
          kind: GLTabKind.globe,
          pinned: true,
          behavior: SuperTabBehavior.requiredPinned,
        ),
        const BrowserTab(id: 2, title: 'Doc', kind: GLTabKind.doc),
      ], activeId: 2);
      addTearDown(ctrl.dispose);

      await tester.pumpWidget(wrap(SuperTabBar(controller: ctrl)));
      await tester.pumpAndSettle();
      expect(find.byType(SuperTabBar), findsOneWidget);
      // Home is pinned so it should be in the pinned region (compact chip).
      expect(ctrl.pinned.any((t) => t.id == 1), isTrue);
    });

    testWidgets('custom localizations are used', (tester) async {
      final ctrl = SuperTabBarController(tabs: [
        const BrowserTab(id: 1, title: 'Tab', kind: GLTabKind.doc),
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
        const BrowserTab(id: 1, title: 'Tab', kind: GLTabKind.doc),
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
  });
}
