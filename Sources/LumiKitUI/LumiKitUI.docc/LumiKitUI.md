# ``LumiKitUI``

The design system and component kit: a value-type theme, a `Style` on every component, controls, lists, navigation, feedback, and UIKit extensions.

## Overview

`LumiKitUI` builds on `LumiKitCore` and SnapKit and targets iOS 18, iPadOS 18, and Mac Catalyst 18. Every type is main-actor isolated except the value types that carry configuration (themes, styles, strings), which are `nonisolated` and `Sendable`.

Three ideas run through the whole module:

- **The theme is a value.** ``LMKTheme`` holds every token category and a default `Style` for every component. ``LMKTheme/apply(_:)`` re-renders every window; ``LMKTheme/current`` is readable from any isolation.
- **Appearance lives in a `Style`.** Each component has a nested `Style` whose fields are all optional; `nil` means the theme decides. A shared ``LMKSurfaceStyle`` covers background, corners, border, shadow, and insets, and ``LMKControlStateStyle`` covers pressed, selected, disabled, and focused looks.
- **Content and behavior stay on the instance.** Text, icons, `isEnabled`, `isSelected`, handlers, and durations are properties; presenters end in `present(from:)`, installed views in `show(in:)`, callbacks are `on<Event>` closures.

Start with <doc:GettingStarted>, then <doc:Theming> and <doc:Styling>.

## Topics

### Essentials

- <doc:GettingStarted>
- <doc:Theming>
- <doc:Styling>
- <doc:ComponentCatalog>
- <doc:ControlCatalog>
- <doc:Extensions>
- <doc:Localization>
- <doc:PlatformSupport>
- <doc:Migration-1.0>

### Theme

- ``LMKTheme``
- ``LMKColorTheme``
- ``LMKTypographyTheme``
- ``LMKSpacingTheme``
- ``LMKCornerRadiusTheme``
- ``LMKShadowTheme``
- ``LMKAlphaTheme``
- ``LMKLayoutTheme``
- ``LMKAnimationTheme``
- ``LMKThemeExtension``
- ``LMKThemeExtensions``
- ``LMKThemeApplying``
- ``LMKThemeTrait``
- ``LMKThemeReference``
- ``LMKThemeObservation``

### Tokens

- ``LMKColor``
- ``LMKTypography``
- ``LMKTextStyle``
- ``LMKFontSpec``
- ``LMKSpacing``
- ``LMKCornerRadius``
- ``LMKCornerStyle``
- ``LMKShadow``
- ``LMKShadowStyle``
- ``LMKAlpha``
- ``LMKLayout``

### Styles

- ``LMKSurfaceStyle``
- ``LMKBackgroundStyle``
- ``LMKBorderStyle``
- ``LMKShadowSource``
- ``LMKControlStateStyle``
- ``LMKTextInputStyle``
- ``LMKStatus``
- ``LMKValidationState``

### Controls

- ``LMKButton``
- ``LMKCheckbox``
- ``LMKRatingControl``
- ``LMKSegmentedControl``
- ``LMKSlider``
- ``LMKSwitch``
- ``LMKTextField``
- ``LMKTextView``
- ``LMKSearchBar``
- ``LMKCopyableLabel``
- ``LMKPhotoButton``
- ``LMKActionTile``

### Components

- ``LMKBadgeView``
- ``LMKBannerView``
- ``LMKCardView``
- ``LMKChipView``
- ``LMKChipFlowView``
- ``LMKFilterChipBar``
- ``LMKDividerView``
- ``LMKEmptyStateView``
- ``LMKGlassView``
- ``LMKGlassContainerView``
- ``LMKGradientView``
- ``LMKLoadingStateView``
- ``LMKSkeletonView``
- ``LMKSkeletonCell``
- ``LMKPageIndicator``
- ``LMKStatusLabel``
- ``LMKOverscrollFooterView``
- ``LMKCheckboxCell``

### Feedback and overlays

- ``LMKToast``
- ``LMKToastView``
- ``LMKToast/Configuration``
- ``LMKToast/Handle``
- ``LMKToast/DismissReason``
- ``LMKTip``
- ``LMKTipView``
- ``LMKFloatingButton``
- ``LMKAlert``
- ``LMKCountdownHandle``
- ``LMKErrorHandler``
- ``LMKProgressViewController``

### Sheets and pickers

- ``LMKBottomSheetViewController``
- ``LMKActionSheet``
- ``LMKActionSheetViewController``
- ``LMKActionSheetRowView``
- ``LMKEnumPicker``
- ``LMKEnumPickerViewController``
- ``LMKEnumSelectable``
- ``LMKDatePicker``
- ``LMKCalendarRangeSelectionView``
- ``LMKCardPageViewController``
- ``LMKCardPanelViewController``

### Lists

- ``LMKListRowConfiguration``
- ``LMKListRowContentView``
- ``LMKListTable``
- ``LMKRowPointerEffect``
- ``LMKHighlightable``

### Navigation and layout

- ``LMKNavigationBar``
- ``LMKNavigationBarItem``
- ``LMKNavigationController``
- ``LMKPopGestureConfiguring``
- ``LMKTabBarController``
- ``LMKTab``
- ``LMKTabBarAppearance``
- ``LMKMenu``
- ``LMKSortMenu``
- ``LMKScrollStackViewController``
- ``LMKSegmentedPageViewController``
- ``LMKFormScaffold``
- ``LMKFormKeyCommands``

### Calendar

- ``LMKMonthCalendarView``
- ``LMKCalendarDayCell``
- ``LMKCalendarDayDecoration``

### Detail cards

- ``LMKDetailCard``
- ``LMKDetailCardView``
- ``LMKDetailPageViewController``

### Utilities

- ``LMKAnimation``
- ``LMKHaptics``
- ``LMKDevice``
- ``LMKScene``
- ``LMKSceneGeometryObservation``
- ``LMKImage``
- ``LMKShare``
- ``LMKShareResult``
- ``LMKMarkdownRenderer``
- ``LMKPointerStyle``
