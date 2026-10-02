# Platform support

LumiKit 1.0 targets iOS 18, iPadOS 18, and Mac Catalyst 18. `LumiKitCore` and `LumiKitDebug` also build natively for macOS 15. The package is built and tested with Xcode 26 (Swift 6.2) and Xcode 27 (Swift 6.4), on the iOS 26 simulator; CI runs the test suite under both.

## Rules

1. **The floor is iOS 18.** Any API newer than the floor is used behind `if #available(iOS 26, *)` with a fallback that keeps the same LumiKit API on the other branch. A consumer never gates a LumiKit call.
2. **Layout comes from size classes and window bounds**, never from `UIScreen.main`, the device idiom, or the interface orientation. Resizable windows, Slide Over, Stage Manager, and foldable displays all change size at runtime; `LMKDevice.screenSize(for:)`, `LMKScene.observeGeometry(of:onChange:)`, and `LMKDevice.observeScreenSize(of:onChange:)` report those changes.
3. **Safe areas per edge.** Overlays clamp against the leading and trailing insets as well as top and bottom, and content measures its sides from the safe area while backgrounds stay full-bleed: an iOS 26 tab bar or split view sidebar floats over the content beside it (iPad and Mac) and reports itself as that content's leading safe area.
4. **Every gated path has a test** that runs the new branch on a current simulator and asserts the fallback's configuration where the fallback can be reached.
5. **Mac Catalyst is a first-class target.** The Example app builds for the Mac idiom (`TARGETED_DEVICE_FAMILY` 1, 2, 6). Pointer effects go through `LMKPointerStyle`, forms and sheets carry key commands, and the UIKit behaviors that differ under the Mac idiom are handled in the kit. A system navigation bar lives in the window toolbar, and its title is the one the title bar shows: an app with system navigation bars calls `LMKScene.configureMacWindow` with `hidesTitleBar: false`, and `LMKNavigationController` restores the toolbar's back button, which a dismissed full-screen presentation drops, and collapses the sidebar of a split view presented over it as that is dismissed (otherwise the toolbar keeps the sidebar's edge and the back button sits a sidebar's width in). The toolbar shows no `titleView`, so `LMKSegmentedPageViewController` puts its control in the toolbar's center item group, and a card page pushed onto a stack whose bar shows hands its title and items to the toolbar instead of drawing a second header. Beyond that: `UISlider` track and thumb tints throw (only `tintColor` is applied); a wheel `UIDatePicker` throws, so `LMKDatePicker` applies `Configuration.resolvedPickerStyle(for:)`, which turns `.wheels` into `.inline` for the date and date-and-time modes and `.compact` for time under the Mac idiom (hosts that build their own picker go through `LMKDatePicker.makePicker(_:)` or the resolver); `UIRefreshControl` subclasses are unsupported (`LMKLottieRefreshControl.install(on:)` returns `nil` and `makeRefreshKeyCommand` offers Command-R instead); and a `UIButton` draws as a bare title, so `LMKButton` and the chip's dismiss button set `preferredBehavioralStyle = .pad` to keep their iOS look. CI builds the Example for the Mac idiom (`make example-catalyst`).

## iOS 26 adoptions

| API | Where in LumiKit | Before iOS 26 |
|---|---|---|
| `UIGlassEffect`, `UIGlassContainerEffect` | `LMKGlassView`, `LMKGlassContainerView`, `LMKBackgroundStyle.glass` on every surface, the photo grid toolbar, glass buttons | `UIBlurEffect(.systemMaterial)` |
| `UIButton.Configuration.glass()` and friends | `LMKButton.Variant.glass` | `.tinted` |
| Liquid Glass bar items, neighbours sharing one capsule | `LMKNavigationBar.Style.appearance` (`.automatic` resolves to `.glass`) | `.classic`: tinted items over a hairline |
| `UICornerConfiguration`, container-concentric corners | `LMKCornerStyle.concentric(minimum:)`, `lmk_applyConcentricCorners`, and `lmk_applyCornerStyle(_:asConcentricContainer:)` for the container that publishes its radius. Capsules and circles stay on `layer.cornerRadius`: a published configuration clips subviews along a tighter curve than a border follows | fixed radius |
| `UIScrollEdgeElementContainerInteraction`, `topEdgeEffect` / `bottomEdgeEffect` | `LMKNavigationBar.attachScrollEdgeEffect`, `LMKFilterChipBar`, `LMKScrollStackViewController`, `LMKFormScaffold`, `LMKPhotoGridViewController` (top edge; `Style.showsBottomEdgeEffect` opts into the bottom band) | no-op |
| `tabBarMinimizeBehavior`, `UITabAccessory`, `UISearchTab.automaticallyActivatesSearch` | `LMKTabBarController.Style.minimizesOnScroll`, `setBottomAccessory(_:)`, `automaticallyActivatesSearch` | ignored |
| `UINavigationItem.subtitle` | `UINavigationItem.lmk_setSubtitle(_:)`, `LMKDetailPageViewController` | a two-line title view |
| `UIBarButtonItem.Style.prominent`, `hidesSharedBackground`, `identifier`, `UIBarButtonItem.Badge` | `LMKNavigationBarItem.makeBarButtonItem()`, `UINavigationItem.lmk_setItems(leading:trailing:)` | `.done` style, no badge |
| `UISlider.TrackConfiguration` (ticks, `neutralValue`) | `LMKSlider.step` (ticks when the steps divide the range evenly into at most 50 stops), `neutralValue` | no ticks |
| `UISymbolContentTransition`, `UIImageView.setSymbolImage(_:contentTransition:)` | `LMKButton.Style.animatesSymbolChanges`, `LMKCheckbox`'s glyph swap | `setImage` without a transition |
| `UIImage.SymbolConfiguration(variableValueMode:)`, `(colorRenderingMode:)` | `LMKImage.SymbolOptions` | the plain configuration |
| `UISplitViewController.Column.inspector` | `UISplitViewController.lmk_setInspector(_:)`, `lmk_toggleInspector()` | inert |
| `UITraitHDRHeadroomUsageLimit` | photo browser HDR (with `preferredImageDynamicRange` from iOS 17) | SDR |
| `UITraitResolvesNaturalAlignmentWithBaseWritingDirection` | `UIView.lmk_forceLayoutDirection(_:)` | `semanticContentAttribute` only |
| `UIWindowSceneGeometry.isInteractivelyResizing` | `LMKScene.Geometry.isInteractivelyResizing` | always `false` |
| `prefersInterfaceOrientationLocked` | crop editor (on by default), photo browser (opt-in), both through `Style.locksOrientation` | no lock: the host's orientations apply; on rotation the browser re-aligns its page and the crop editor re-fits its frame |
| `UINavigationController.interactiveContentPopGestureRecognizer` | `LMKNavigationController` enables it from `canBeginPopGesture` (it has no delegate) after every push, pop, and layout pass; `LMKSegmentedPageViewController` makes it wait for its page pan and calls `updateContentPopGesture()` when its page changes | the edge-swipe pop gesture alone |
| `UIBackgroundExtensionView` | `LMKNavigationBar.backgroundContentView` | a plain host view |

APIs at or below the floor that LumiKit uses without a gate: `UIImageReader` and `UIContentUnavailableConfiguration` from iOS 17, `UITab` and `UISearchTab` (iOS 18), `Mutex` from Synchronization (iOS 18, macOS 15).

Two iOS 26 APIs were reviewed and not adopted: `UIView.updateProperties()` (the trait-driven `applyTheme` path already re-renders on the same triggers) and `UIMenuElement.RepeatBehavior` (no LumiKit menu has a repeatable element).

## Verified device classes

- iPhone: portrait width up to 375pt is `LMKDevice.ScreenSize.compact`, up to 402pt `.regular`, wider `.large`.
- iPad, Mac, and any regular-width, regular-height window: `.extraLarge`; `LMKSpacing.cardPadding` and `cellPaddingVertical` tier by the shortest side.
- The tiers are re-read on window resize and trait change, so an iPad window resized to a phone width, a Slide Over pane, or a folding display gets the matching values.

## iOS 27 follow-ups

These need the iOS 27 SDK and land in a 1.x release the same gated way: `navigationItem.barMinimizationBehavior`, `tabBarController.sidebar.preferredPlacement`, `prominentTabIdentifier`, `UIMenuElement.preferredImageVisibility`, and in 27.1 `UIHingeInteraction`, `UIViewReservedRegion`, and `UIArrangementViewController` for folding devices.

Consuming apps built with the iOS 27 SDK must use the scene-based lifecycle and declare a launch screen; `UIApplication.statusBar*` is deprecated in favor of `UIWindowScene.statusBarManager`. LumiKit itself needs nothing for that transition.

## Deferred beyond 1.0

Codable themes (JSON design tokens), a `LumiKitSwiftUI` product, and video in the photo browser.
