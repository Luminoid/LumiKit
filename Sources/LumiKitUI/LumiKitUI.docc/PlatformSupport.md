# Platform Support

The floor is iOS 18, iPadOS 18, and Mac Catalyst 18; newer APIs are adopted behind availability checks with fallbacks that keep the same LumiKit API.

## Rules

- Any API newer than iOS 18 is used behind `if #available(iOS 26, *)` inside the kit; a consumer never gates a LumiKit call.
- Layout comes from size classes and window bounds, never `UIScreen.main`, the device idiom, or the interface orientation. ``LMKDevice/screenSize(for:)``, ``LMKScene/observeGeometry(of:onChange:)``, and ``LMKDevice/observeScreenSize(of:onChange:)`` report resizes, folds, and Stage Manager changes.
- Overlays respect the leading and trailing safe-area insets as well as the top and bottom. Content measures its sides from the safe area while backgrounds stay full-bleed: an iOS 26 tab bar or split view sidebar floats over the content beside it (iPad and Mac) and reports itself as that content's leading safe area.
- Mac Catalyst is a first-class target. A system navigation bar lives in the window toolbar and its title is the one the title bar shows, so an app with system navigation bars calls ``LMKScene/configureMacWindow(for:minimumSize:maximumSize:hidesTitleBar:)`` with `hidesTitleBar: false`; ``LMKNavigationController`` restores the toolbar's back button, which a dismissed full-screen presentation drops, and collapses the sidebar of a split view presented over it as that is dismissed (otherwise the toolbar keeps the sidebar's edge and the back button sits a sidebar's width in). The toolbar shows no title view, so ``LMKSegmentedPageViewController`` puts its control in the toolbar's center item group, and a card page pushed onto a stack whose bar shows hands its title and items to the toolbar (``LMKCardPageViewController/usesSystemNavigationBar``). Pointer effects go through ``LMKPointerStyle``, forms and sheets carry key commands, `UISlider` tints are gated (they throw under the Mac idiom), a wheel date picker resolves to `.inline` (date modes) or `.compact` (time) through `LMKDatePicker.Configuration.resolvedPickerStyle(for:)` because a wheel `UIDatePicker` throws there too, the Lottie refresh control declines to install under the Mac idiom and offers a Command-R key command instead, and ``LMKButton`` (with the chip's dismiss button) keeps its iOS look through `preferredBehavioralStyle = .pad`, where the Mac idiom would draw a bare title.

## iOS 26 adoptions

| API | Where | Before iOS 26 |
|---|---|---|
| Liquid Glass (`UIGlassEffect`, `UIGlassContainerEffect`, glass button configurations) | ``LMKGlassView``, ``LMKGlassContainerView``, ``LMKBackgroundStyle/glass(_:tint:)``, `LMKButton.Variant.glass` | A system-material blur; `.tinted` buttons |
| Liquid Glass bar items that share a capsule | ``LMKNavigationBar`` (``LMKNavigationBar/Appearance``) | Tinted items over a hairline |
| Container-concentric corners | ``LMKCornerStyle/concentric(minimum:corners:curve:)``, the corner helpers on `UIView` (capsules and circles stay on the layer's own radius, so a border keeps its width around them) | A fixed radius |
| Scroll-edge effects | ``LMKNavigationBar``, ``LMKFilterChipBar``, ``LMKScrollStackViewController``, ``LMKFormScaffold``, the photo grid (the top edge; the bottom band is opt-in) | No effect |
| Tab bar minimize behavior, bottom accessory, `UISearchTab` activation | ``LMKTabBarController`` | Ignored |
| Navigation subtitles, prominent bar items, bar item badges and identifiers | `UINavigationItem.lmk_setSubtitle`, ``LMKNavigationBarItem/makeBarButtonItem(tintColor:)`` | A two-line title view; `.done` items |
| Slider ticks and neutral value | ``LMKSlider`` | No ticks |
| Symbol content transitions, variable-value and color-rendering modes | ``LMKButton``, ``LMKCheckbox``, ``LMKImage/SymbolOptions`` | Plain image swaps and configurations |
| The content-area pop gesture | ``LMKNavigationController`` applies `canBeginPopGesture` to it (it has no delegate); ``LMKSegmentedPageViewController`` arbitrates its page pan against it | The edge-swipe pop gesture alone |
| Split view inspector column | `UISplitViewController.lmk_setInspector` | Inert |
| HDR headroom trait, orientation lock, background extension views, interactive-resize geometry, the natural-alignment trait | The photo browser and crop editor (the lock is on by default in the crop editor and opt-in through `Style.locksOrientation` in the browser), ``LMKNavigationBar/backgroundContentView``, ``LMKScene/Geometry``, `UIView.lmk_forceLayoutDirection` | SDR; no lock (the host's orientations apply, and on rotation the browser re-aligns its page and the crop editor re-fits its frame); a plain host view; `false`; `semanticContentAttribute` only |

APIs at or below the floor used without a gate: `UIImageReader` and `UIContentUnavailableConfiguration` (iOS 17), `UITab` (iOS 18), `Mutex` (iOS 18).

## Screen size tiers

``LMKDevice/ScreenSize`` classifies by portrait width unless the window is regular in both size classes: `compact` up to 375pt, `regular` up to 402pt, `large` above, `extraLarge` for iPad, Mac, and wide windows. `LMKSpacing.cardPadding` and `cellPaddingVertical` tier regular-by-regular windows by the shortest side. Re-read a tier on a window resize or trait change; the observation helpers do that for you.

## Coming next

iOS 27 APIs (bar minimization behavior, tab sidebar placement, prominent tab identifiers, menu image visibility, and the folding-device interactions in 27.1) follow in a 1.x release with the same gating. Codable themes, a SwiftUI product, and video in the photo browser are also 1.x work.
