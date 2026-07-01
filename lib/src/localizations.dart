// ============================================================
// super_tab_bar — localizations.
//   File: lib/src/localizations.dart
// ============================================================

/// Localizable strings used throughout [SuperTabBar].
///
/// Pass a custom instance to [SuperTabBar.localizations] to translate or
/// override any user-facing text. Built-in presets: [SuperTabBarLocalizations.en]
/// (default) and [SuperTabBarLocalizations.ar].
///
/// ### Custom language example
/// ```dart
/// SuperTabBar(
///   localizations: const SuperTabBarLocalizations(
///     closeTab: 'إغلاق التبويب',
///     closeOtherTabs: 'إغلاق التبويبات الأخرى',
///     closeTabsToRight: 'إغلاق التبويبات على اليمين',
///     duplicateTab: 'تكرار التبويب',
///     pinTab: 'تثبيت التبويب',
///     unpinTab: 'إلغاء تثبيت التبويب',
///     newTab: 'تبويب جديد',
///     showAllTabs: 'عرض جميع التبويبات',
///     scrollForward: 'تمرير للأمام',
///     scrollBack: 'تمرير للخلف',
///     noOpenTabs: 'لا توجد تبويبات — اضغط + للبدء.',
///     openTabsHeader: 'التبويبات المفتوحة · {count}',
///     switcherTitle: 'التبويبات المفتوحة',
///     reorderHint: 'اسحب لإعادة الترتيب',
///     discardChangesTitle: 'تجاهل التغييرات؟',
///     cancel: 'إلغاء',
///     saveAndClose: 'حفظ وإغلاق',
///     discardAndClose: 'تجاهل وإغلاق',
///   ),
/// )
/// ```
class SuperTabBarLocalizations {
  const SuperTabBarLocalizations({
    required this.closeTab,
    required this.closeOtherTabs,
    required this.closeTabsToRight,
    required this.duplicateTab,
    required this.pinTab,
    required this.unpinTab,
    required this.newTab,
    required this.showAllTabs,
    required this.scrollForward,
    required this.scrollBack,
    required this.noOpenTabs,
    required this.openTabsHeader,
    required this.switcherTitle,
    required this.reorderHint,
    required this.discardChangesTitle,
    required this.cancel,
    required this.saveAndClose,
    required this.discardAndClose,
  });

  // ── Context menu ───────────────────────────────────────────
  final String closeTab;
  final String closeOtherTabs;
  final String closeTabsToRight;
  final String duplicateTab;
  final String pinTab;
  final String unpinTab;

  // ── Strip buttons ──────────────────────────────────────────
  final String newTab;
  final String showAllTabs;
  final String scrollForward;
  final String scrollBack;

  // ── Content surface ────────────────────────────────────────
  /// Shown when no tabs are open.
  final String noOpenTabs;

  // ── Tab-list dropdown ──────────────────────────────────────
  /// Header label. Use `{count}` as a placeholder — see [openTabsHeaderFor].
  final String openTabsHeader;

  // ── Compact-mode tab switcher ──────────────────────────────
  /// Title shown at the top of the [SuperTabSwitcher] thumbnail screen.
  final String switcherTitle;

  /// Hint telling users they can drag thumbnails to reorder tabs.
  final String reorderHint;

  // ── Dirty-close dialog ─────────────────────────────────────
  final String discardChangesTitle;
  final String cancel;
  final String saveAndClose;
  final String discardAndClose;

  // ── Derived strings ────────────────────────────────────────
  /// Returns [openTabsHeader] with `{count}` replaced by [count].
  String openTabsHeaderFor(int count) =>
      openTabsHeader.replaceFirst('{count}', '$count');

  /// Returns the body text for the dirty-close confirmation dialog.
  String dirtyTabBody(String tabTitle) =>
      '"$tabTitle" has unsaved changes. Closing it now will lose them.';

  // ── Built-in presets ───────────────────────────────────────

  /// Default English strings.
  static const SuperTabBarLocalizations en = SuperTabBarLocalizations(
    closeTab: 'Close tab',
    closeOtherTabs: 'Close other tabs',
    closeTabsToRight: 'Close tabs to the right',
    duplicateTab: 'Duplicate tab',
    pinTab: 'Pin tab',
    unpinTab: 'Unpin tab',
    newTab: 'New tab',
    showAllTabs: 'Show all tabs',
    scrollForward: 'Scroll tabs forward',
    scrollBack: 'Scroll tabs back',
    noOpenTabs: 'No open tabs — press + to start.',
    openTabsHeader: 'OPEN TABS · {count}',
    switcherTitle: 'Open tabs',
    reorderHint: 'Drag to reorder',
    discardChangesTitle: 'Discard unsaved changes?',
    cancel: 'Cancel',
    saveAndClose: 'Save & close',
    discardAndClose: 'Discard & close',
  );

  /// Arabic (العربية) strings.
  static const SuperTabBarLocalizations ar = SuperTabBarLocalizations(
    closeTab: 'إغلاق التبويب',
    closeOtherTabs: 'إغلاق التبويبات الأخرى',
    closeTabsToRight: 'إغلاق التبويبات على اليمين',
    duplicateTab: 'تكرار التبويب',
    pinTab: 'تثبيت التبويب',
    unpinTab: 'إلغاء تثبيت التبويب',
    newTab: 'تبويب جديد',
    showAllTabs: 'عرض جميع التبويبات',
    scrollForward: 'تمرير التبويبات للأمام',
    scrollBack: 'تمرير التبويبات للخلف',
    noOpenTabs: 'لا توجد تبويبات مفتوحة — اضغط + للبدء.',
    openTabsHeader: 'التبويبات المفتوحة · {count}',
    switcherTitle: 'التبويبات المفتوحة',
    reorderHint: 'اسحب لإعادة الترتيب',
    discardChangesTitle: 'تجاهل التغييرات غير المحفوظة؟',
    cancel: 'إلغاء',
    saveAndClose: 'حفظ وإغلاق',
    discardAndClose: 'تجاهل وإغلاق',
  );
}
