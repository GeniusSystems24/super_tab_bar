# super_tab_bar · docs

Reference documentation for the `super_tab_bar` Flutter package.

For the interactive live gallery, open
`../../geniuslink_design_system_flutter/docs/components-browsertabs.html`
in a browser.

---

## Anatomy

```
┌──[📌]────[▶ Journal Entry ●]────[Dashboard ×]────[Trial Balance ×]──[⟩]──[▾]──[+]─┐
│  pinned       active · dirty          inactive                     overflow  list  add │
└─────────────────────────────────────────────────────────────────────────────────────────┘
│                                 content surface                                         │
└─────────────────────────────────────────────────────────────────────────────────────────┘

Legend
  📌  pinned tab — icon-only, anchored to the start edge, survives close-others
  ●   dirty dot  — unsaved changes indicator
  ▶   active     — tab merges with the content surface (no top border gap)
  ×   close btn  — appears on hover or when tab is active
  ⟩   overflow   — scroll chevron, visible when tabs exceed strip width
  ▾   list       — dropdown listing all open tabs
  +   new tab    — calls onAddTab (if set) or controller.add()
```

---

## Tab states

| State | Visual |
|---|---|
| **Active** | Elevated background (`surface`), fg1 label, accent icon, no close button gap. |
| **Inactive** | Transparent bg, fg3 label, fg3 icon, thin separator on start edge. |
| **Hover** | `hover` bg tint, close button appears. |
| **Pinned** | 40 × 36 px — icon only, anchored before the scrolling region. |
| **Dirty** | Unsaved dot (warning orange) replaces close button when not hovering; close button visible on hover — clicking it triggers the confirm dialog. |
| **Dragging** | Ghost feedback chip (0.9 opacity, border); drag target shows a blue 2 px drop indicator on its start edge. |
| **Overflow** | `⟩` chevrons appear on the sides that have hidden tabs; scroll by 220 px per click. |
| **Preview** | Hover for ≈ 480 ms triggers the popover; dismisses when the pointer leaves the tab chip. |
| **Compact** | `compact: true` hides the whole strip; switch tabs from the `SuperTabSwitcher` thumbnail grid. |

---

## Compact mode & tab switcher

On phones, set `compact: true` to hide the strip and drive tab switching from a
full-screen thumbnail grid instead.

| Symbol | Kind | Description |
|---|---|---|
| `SuperTabBar(compact: true)` | Widget flag | Hides the tab strip; shows only the active page. |
| `SuperTabBar(closeTabOnBack: true)` | Widget flag | Back gesture closes the active tab — unless it is dirty. |
| `SuperTabSwitcher` | Widget | Scrollable grid of tab thumbnails; tap to switch, long-press-drag to reorder. |
| `showSuperTabSwitcher` | Function | Opens `SuperTabSwitcher` as a full-screen modal; returns the picked tab id (or `null`). |

Thumbnails reuse the controller's cached page snapshots and fall back to a
scaled live render (or an icon card) when none is available. Reordering drives
`SuperTabBarController.reorder`; the per-thumbnail close button can be routed
through `onCloseTab` for dirty-confirmation.

---

## `BrowserStyleTabBarThemeData` token reference

### Instance fields (lerped between dark ↔ light)

| Field | Dark | Light | Purpose |
|---|---|---|---|
| `bg` | `#111318` | `#F7F8FA` | Strip container / page base. |
| `surface` | `#1E2025` | `#FFFFFF` | Active-tab card / content. |
| `surface2` | `#292D38` | `#FFFFFF` | Nested card. |
| `inputBg` | `#33353A` | `#F1F3F8` | Input fill / close-button hover bg. |
| `hover` | `#2F3540` | `#EEF1F7` | Tab hover tint. |
| `border` | `rgba(67,70,84,.4)` | `#E2E8F0` | Hairline. |
| `borderStrong` | `#434654` | `#C2C6D6` | Solid divider / pop-card edge. |
| `fg1` | `#E2E2E9` | `#0F172A` | Primary text. |
| `fg2` | `#C3C6D7` | `#424754` | Secondary text. |
| `fg3` | `#8D90A0` | `#64748B` | Tertiary / placeholder. |
| `fg4` | `#44474E` | `#C2C6D6` | Disabled / decorative. |

### Brand constants (theme-independent statics)

| Token | Value | Usage |
|---|---|---|
| `accent` | `#4A7CFF` | Active tab, icons, focus ring, drag indicator. |
| `success` | `#1DB88A` | — |
| `warning` | `#F97316` | Dirty dot. |
| `danger` | `#EF4444` | Discard action in confirm dialog. |
| `displayFont` | `'Manrope'` | Headings, tab titles (bold). |
| `bodyFont` | `'Inter'` | Body text, labels. |
| `monoFont` | `'JetBrainsMono'` | Code, tab ids, metadata. |
| `radiusSm` | `4 px` | Segment toggle corners. |
| `radiusMd` | `6 px` | Tab chip top corners. |
| `radiusLg` | `8 px` | Card / pop-card corners. |
| `radiusXl` | `12 px` | Confirm dialog corners. |
| `durFast` | `100 ms` | Hover tints, chevron appearance. |
| `durBase` | `150 ms` | Tab chip bg transition. |
| `durSlow` | `300 ms` | Chevron scroll, dialog appear. |
| `curveStandard` | `Cubic(0.4,0,0.2,1)` | Default ease-in-out. |
| `curveDecelerate` | `Cubic(0,0,0.2,1)` | Enter / appear. |
| `curveEmphasized` | `Cubic(0.2,0,0,1)` | Confirm dialog scale. |

---

## Exported symbols

| Symbol | Kind | Description |
|---|---|---|
| `BrowserStyleTabBar` | Widget | Main tab bar widget. |
| `BrowserStyleTabBarController` | ChangeNotifier | State + operations. |
| `BrowserStyleTabBarScope` | InheritedNotifier | Scope that exposes the controller to descendants. |
| `BrowserStyleTabBarThemeData` | ThemeExtension | All theme tokens. |
| `BrowserTab` | Class | Tab model (`id · title · kind · dirty · pinned`). |
| `GLTabKind` | Enum | `ledger · doc · store · chart · user · globe`. |
| `TabPageBuilder` | Typedef | `Widget Function(BuildContext, BrowserTab)`. |
| `glTabIcon` | Function | `GLTabKind → IconData`. |
| `glPreviewMeta` | Function | `GLTabKind → String` subtitle for the preview header. |
| `kNewTabCycle` | Const | Rotating kind list for the `+` button. |
| `GLTabPage` | Widget | Built-in per-kind page content. |
| `TabContextMenu` | Widget | Right-click context menu overlay. |
| `TabListDropdown` | Widget | `▾` tab list dropdown overlay. |
| `MiniPagePreview` | Widget | Hover-intent mini-page preview popover. |
| `TabMenuItem` | Class | Menu item model. |
| `showGLDirtyCloseDialog` | Function | Animated confirm dialog; returns `'discard'`/`'save'`/`null`. |
| `SuperTabSwitcher` | Widget | Compact-mode thumbnail grid of open tabs. |
| `showSuperTabSwitcher` | Function | Opens the switcher as a full-screen modal; returns the picked tab id. |
