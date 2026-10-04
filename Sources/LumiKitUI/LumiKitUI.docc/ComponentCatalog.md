# Components

What each component is for, grouped the way the Example app groups them.

## Display

| Component | Purpose |
|---|---|
| ``LMKBadgeView`` | A count, text, or dot badge; `configure(.count(3))`, `.text("New")`, `.dot` |
| ``LMKBannerView`` | A persistent bar for an ``LMKStatus`` with an optional action and dismiss: inline in a layout, or shown over a screen under its navigation bar with the scroll content inset beneath it |
| ``LMKCardView`` | A surface with presets `.cell`, `.elevated`, `.flat`, `.outlined`, an optional `onTap` (a tappable card names itself to VoiceOver from its content), and a clear `contentView` that clips to the card's concentric curve |
| ``LMKChipView`` | A tag or filter chip (`UIControl`) with filled, tinted, and outlined variants, distinct selected and pressed looks, and a dismiss button; a chip with no handler is display-only and lets touches through |
| ``LMKChipFlowView`` | Chips (or any views) in lines that wrap at the view's width from the leading edge, with `Style.spacing` and `lineSpacing`; its height follows its width, in stacks and self-sizing cells |
| ``LMKFilterChipBar`` | A scrolling chip row with single or multiple selection and an optional "All" chip; the selected chip carries the full tint, and a partial `Style.chip` (a tint alone) keeps the outlined default |
| ``LMKDividerView`` | A hairline separator, horizontal or vertical, with optional dashes |
| ``LMKEmptyStateView`` | Icon, title, message, and up to two actions in full-screen, card, or inline layouts; `configure(_:animated:)` re-binds content, and the action buttons persist across theme passes; bridges to `UIContentUnavailableConfiguration` |
| ``LMKGlassView`` | Liquid Glass on iOS 26, a system-material blur before (`LMKGlassView(variant:)`, or a full `Style`); ``LMKGlassContainerView`` merges nearby glass |
| ``LMKGradientView`` | Linear (axis or angle) and radial gradients |
| ``LMKLoadingStateView`` | An inline or overlay activity indicator with an optional message; hidden until `startLoading()` |
| ``LMKSkeletonView`` | Shimmering placeholders built from lines, circles, and rectangles; ``LMKSkeletonCell`` hosts one in a table |
| ``LMKPageIndicator`` | Page dots with an expanding pill, per-dot hit targets, and RTL layout |
| ``LMKStatusLabel`` | A live inline readout tinted by ``LMKStatus`` |
| ``LMKOverscrollFooterView`` | A footer revealed by overscroll, driven by the scroll view it attaches to |
| ``LMKCheckboxCell`` | A check-off table row built on ``LMKCheckbox``: a tap on the box flips `isDone` and reports it through `onValueChange`; `setDone(_:animated:)` changes it silently |

## Feedback

| Component | Purpose |
|---|---|
| ``LMKToast`` | `show(_ status:_ message:duration:in:completion:)`, `show(LMKToast.Configuration)` for titles, actions, persistence, positions, and queue policies, `showUndo(message:duration:in:status:icon:position:tapToDismiss:haptics:onUndo:onCommit:)` with a countdown ring (a status, a glyph, the bottom edge, and no tap-to-dismiss for a delete snackbar), `dismissAll(in:)`; returns an ``LMKToast/Handle``. With no host the toast sits on the active scene's window, above presented sheets. `onDismiss` fires once for every toast, also for one that never showed (`.programmatic`) or was displaced by `.replace` (`.replaced`) |
| ``LMKTip`` | Onboarding tips centered or pointed at a source view (``LMKTipView/Placement``); a pointed tip follows its source through a resize, never changes the source's own layout, and stays inside the safe area. The tip is a VoiceOver modal: the bubble's content, then the dismiss area, and the escape gesture dismisses |
| ``LMKFloatingButton`` | A draggable, edge-snapping action button with a badge; `show(icon:in:positionKey:onTap:)` returns the instance, `positionKey` remembers the corner, and the button re-places itself when its superview resizes |
| ``LMKAlert`` | Alerts, confirmations (`confirm(...) async`), delete confirmations, countdown confirmations, text input with validation, secure entry, and extra actions after Save (`TextInput.additionalActions`), and typed action sheets |
| ``LMKErrorHandler`` | Severity-based presentation (`info`, `warning`, `error`, `critical`) with an injectable `policy` and automatic logging |
| ``LMKProgressViewController`` | A blocking determinate or indeterminate HUD with terminal states, `observe(_ progress:)`, and Escape (or the VoiceOver escape gesture) for `onCancel`; a `dismiss(completion:)` during the presentation waits for it to land |

## Sheets and pickers

| Component | Purpose |
|---|---|
| ``LMKBottomSheetViewController`` | The base sheet: dimming, drag-to-dismiss that cooperates with an inner scroll view, keyboard avoidance that keeps the sheet below the top safe area, Escape and Command-W, a VoiceOver modal with the escape gesture, `onDismiss(reason)`, and an idempotent `dismiss(reason:completion:)`; a dismissed sheet can be presented again. In a regular width it is capped at `Style.maxWidth` and centered |
| ``LMKActionSheet`` | A sheet of actions with icons, subtitles, checkmarks, custom content, and sub-pages, from an `LMKActionSheet.Configuration` |
| ``LMKEnumPicker`` | Pick one (`T?`) or many (`Set<T>`) cases of an ``LMKEnumSelectable`` type, with search, disabled options, and `onCancel`; the list is as tall as its rows |
| ``LMKDatePicker`` | Single dates, ranges, a calendar range picker, and a date with a note field, each with `onCancel`; under the Mac idiom a wheel style resolves to `.inline` or `.compact` (`Configuration.resolvedPickerStyle(for:)`) |
| ``LMKCalendarRangeSelectionView`` | The calendar range picker's content: a month grid and a summary formatted in the view's calendar, time zone, and `locale`, styled through `Style` and `theme.calendarRangeSelection` |
| ``LMKCardPageViewController`` | A card-embedded page stack with a header, leading and trailing items (glyphs or titled capsules, with roles and badges), and slide navigation; while content is stacked the leading item is Back |
| ``LMKCardPanelViewController`` | A centered floating card in an overlay window or as a modal, `Style.heightRatio` of the available height, Escape and Command-W, a VoiceOver modal; a page reaches its panel through `lmk_cardPanel` |

## Lists

| Component | Purpose |
|---|---|
| ``LMKListRowConfiguration`` | A `UIContentConfiguration` for detail rows: a symbol in a tinted circle, an image, or an async image leading; title, subtitle, detail; disclosure, checkmark, switch, badge, image, or a custom trailing view. `Style.highlighted` and `selected` follow the cell's configuration state; a flipped switch is written back into the cell's configuration before `onValueChange`, so a host that rejects the change re-applies the row with the old value |
| ``LMKListRowContentView`` | The content view that renders it, with `stateBackgroundView` for the highlighted and selected fills |
| ``LMKListTable`` | `makeInsetGrouped()` and friends |
| ``LMKHighlightable`` | The custom cell highlight shared by table and collection cells |

## Navigation and layout

| Component | Purpose |
|---|---|
| ``LMKNavigationBar`` | A custom bar that draws the running OS's chrome (``LMKNavigationBar/Appearance``: Liquid Glass capsules on iOS 26, tinted items over a hairline before), with large and inline titles, a subtitle, identified items (``LMKNavigationBarItem``) with roles, menus, and badges, accessories, a scroll-edge effect, and a background content view; `lmk_setItems` bridges items to the system bar |
| ``LMKNavigationController`` | Keeps the edge-swipe pop gesture when the system bar is hidden and holds it while a transition is in flight; on iOS 26 the content-area pop gesture follows the same rule (`canBeginPopGesture`, re-applied by `updateContentPopGesture()`). ``LMKPopGestureConfiguring`` lets a screen opt out |
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
| ``LMKDetailCardView`` | Renders a card and updates rows, chips, and header controls in place by id; `Style.haptics` gates the long-press haptic |
| ``LMKDetailPageViewController`` | A page of cards diffed by id with Edit and Share items (the host's leading items are left alone) and an edit mode |

The calendar's day and month values (`LMKCalendarDay`, `LMKCalendarMonth` in LumiKitCore) are Gregorian civil dates whatever calendar the view is given: a day keeps its `key` and arithmetic under the Japanese, Buddhist, Chinese, or Hebrew calendar, and the grid shows the Gregorian month. The view formats titles in the supplied calendar when its months are Gregorian months (the Japanese era names, for instance) and in the Gregorian twin otherwise. Day numerals are bare numbers in the locale's numbering system. `configure(today: nil)` (the default) follows the system day and refreshes at midnight; a day passed there or to `setToday(_:)` stays pinned until the next `configure(today: nil)`. Answering `onMonthChangeRequest` with `setVisibleMonth(_:animated:)` applies a month the swipe already shows without a second slide.
