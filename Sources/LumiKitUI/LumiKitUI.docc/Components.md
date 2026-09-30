# Components

What each component is for, grouped the way the Example app groups them.

## Display

| Component | Purpose |
|---|---|
| ``LMKBadgeView`` | A count, text, or dot badge; `configure(.count(3))`, `.text("New")`, `.dot` |
| ``LMKBannerView`` | A persistent bar for an ``LMKStatus`` with an optional action and dismiss: inline in a layout, or shown over a screen under its navigation bar with the scroll content inset beneath it |
| ``LMKCardView`` | A surface with presets `.cell`, `.elevated`, `.flat`, `.outlined`, an optional `onTap`, and a `contentView` |
| ``LMKChipView`` | A tag or filter chip (`UIControl`) with filled, tinted, and outlined variants, distinct selected and pressed looks, and a dismiss button |
| ``LMKFilterChipBar`` | A scrolling chip row with single or multiple selection and an optional "All" chip; the selected chip carries the full tint |
| ``LMKDividerView`` | A hairline separator, horizontal or vertical, with optional dashes |
| ``LMKEmptyStateView`` | Icon, title, message, and up to two actions in full-screen, card, or inline layouts; bridges to `UIContentUnavailableConfiguration` |
| ``LMKGlassView`` | Liquid Glass on iOS 26, a system-material blur before; ``LMKGlassContainerView`` merges nearby glass |
| ``LMKGradientView`` | Linear (axis or angle) and radial gradients |
| ``LMKLoadingStateView`` | An inline or overlay activity indicator with an optional message |
| ``LMKSkeletonView`` | Shimmering placeholders built from lines, circles, and rectangles; ``LMKSkeletonCell`` hosts one in a table |
| ``LMKPageIndicator`` | Page dots with an expanding pill, per-dot hit targets, and RTL layout |
| ``LMKStatusLabel`` | A live inline readout tinted by ``LMKStatus`` |
| ``LMKOverscrollFooterView`` | A footer revealed by overscroll, driven by the scroll view it attaches to |
| ``LMKCheckboxCell`` | A check-off table row built on ``LMKCheckbox`` |

## Feedback

| Component | Purpose |
|---|---|
| ``LMKToast`` | `show(_ status:_ message:duration:in:completion:)`, `show(LMKToastConfiguration)` for titles, actions, persistence, positions, and queue policies, `showUndo` with a countdown ring, `dismissAll(in:)`; returns an ``LMKToastHandle`` |
| ``LMKTip`` | Onboarding tips centered or pointed at a source view (``LMKTipView/Placement``) |
| ``LMKFloatingButton`` | A draggable, edge-snapping action button with a badge; `show(icon:in:onTap:)` returns the instance |
| ``LMKAlert`` | Alerts, confirmations (`confirm(...) async`), delete confirmations, countdown confirmations, text input with validation, and typed action sheets |
| ``LMKErrorHandler`` | Severity-based presentation (`info`, `warning`, `error`, `critical`) with an injectable `policy` and automatic logging |
| ``LMKProgressViewController`` | A blocking determinate or indeterminate HUD with terminal states and `observe(_ progress:)` |

## Sheets and pickers

| Component | Purpose |
|---|---|
| ``LMKBottomSheetViewController`` | The base sheet: dimming, drag-to-dismiss that cooperates with an inner scroll view, keyboard avoidance, Escape and Command-W, `onDismiss(reason)` |
| ``LMKActionSheet`` | A sheet of actions with icons, subtitles, checkmarks, custom content, and sub-pages, from an `LMKActionSheet.Configuration` |
| ``LMKEnumPicker`` | Pick one (`T?`) or many (`Set<T>`) cases of an ``LMKEnumSelectable`` type, with search and disabled options |
| ``LMKDatePicker`` | Single dates, ranges, a calendar range picker, and a date with a note field |
| ``LMKCardPageViewController`` | A card-embedded page stack with a header, leading and trailing items, and slide navigation |
| ``LMKCardPanelViewController`` | A centered floating card in an overlay window or as a modal |

## Lists

| Component | Purpose |
|---|---|
| ``LMKListRowConfiguration`` | A `UIContentConfiguration` for detail rows: a symbol in a tinted circle, an image, or an async image leading; title, subtitle, detail; disclosure, checkmark, switch, badge, image, or a custom trailing view |
| ``LMKListRowContentView`` | The content view that renders it |
| ``LMKListTable`` | `makeInsetGrouped()` and friends |
| ``LMKHighlightable`` | The custom cell highlight shared by table and collection cells |

## Navigation and layout

| Component | Purpose |
|---|---|
| ``LMKNavigationBar`` | A custom bar that draws the running OS's chrome (``LMKNavigationBar/Appearance``: Liquid Glass capsules on iOS 26, tinted items over a hairline before), with large and inline titles, a subtitle, identified items (``LMKNavigationBarItem``) with roles, menus, and badges, accessories, a scroll-edge effect, and a background content view; `lmk_setItems` bridges items to the system bar |
| ``LMKNavigationController`` | Keeps the edge-swipe pop gesture when the system bar is hidden; ``LMKPopGestureConfiguring`` lets a screen opt out |
| ``LMKTabBarController`` | Tabs from ``LMKTab`` values with lazy roots, a search tab, badges, reordering, key commands, the iPad sidebar, and the iOS 26 minimize behavior and bottom accessory; ``LMKTabBarAppearance`` for a plain `UITabBar` |
| ``LMKMenu`` | Option menus as native `UIMenu`s from sections: single choices, toggles, sorts, commands, and submenus, rebuilt from the host's state on every open and after each row that keeps the menu open |
| ``LMKSortMenu`` | The sort menu on ``LMKMenu``: sort field, a live direction arrow, a layout section, and further sections |
| ``LMKScrollStackViewController`` | A scrollable vertical stack with width modes, keyboard avoidance, and a hosted navigation bar |
| ``LMKSegmentedPageViewController`` | Segmented tabs paging between child controllers with an interactive pan |
| ``LMKFormScaffold`` | Builders for form screens: scroll view, content stack, header, field rows, width modes |

## Calendar and detail cards

| Component | Purpose |
|---|---|
| ``LMKMonthCalendarView`` | A month grid with single, range, or multiple selection, dots, badges, and glyphs per day (``LMKCalendarDayDecoration``), interactive paging, and a stateless `configure(month:today:selection:decorations:)` contract; subclass ``LMKCalendarDayCell`` for custom cells |
| ``LMKDetailCard`` | A rendering description of a card: header, typed rows, and actions |
| ``LMKDetailCardView`` | Renders a card and updates rows in place by id |
| ``LMKDetailPageViewController`` | A page of cards diffed by id with Edit and Share items and an edit mode |
