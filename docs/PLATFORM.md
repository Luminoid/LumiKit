# Platform support

LumiKit 1.0 targets iOS 18, iPadOS 18, and Mac Catalyst 18. `LumiKitCore` and `LumiKitDebug` also build natively for macOS 15. The package is built and tested with Xcode 26 (Swift 6.2) and Xcode 27 (Swift 6.4), on the iOS 26 simulator.

## Rules

1. **The floor is iOS 18.** Any API newer than the floor is used behind `if #available(iOS 26, *)` with a fallback that keeps the same LumiKit API on the other branch. A consumer never gates a LumiKit call.
2. **Layout comes from size classes and window bounds**, never from `UIScreen.main`, the device idiom, or the interface orientation. Resizable windows, Slide Over, Stage Manager, and foldable displays all change size at runtime; `LMKDevice.screenSize(for:)`, `LMKScene.observeGeometry(of:onChange:)`, and `LMKDevice.observeScreenSize(of:onChange:)` report those changes.
3. **Safe areas per edge.** Overlays clamp against the leading and trailing insets as well as top and bottom.
4. **Every gated path has a test** that runs the new branch on a current simulator and asserts the fallback's configuration where the fallback can be reached.
5. **Mac Catalyst is a first-class target.** The Example app builds for the Mac idiom (`TARGETED_DEVICE_FAMILY` 1, 2, 6). Pointer effects go through `LMKPointerStyle`, forms and sheets carry key commands, and the two UIKit behaviors that differ under the Mac idiom are handled in the kit: `UISlider` track and thumb tints throw (only `tintColor` is applied), and `UIRefreshControl` subclasses are unsupported (`LMKLottieRefreshControl.install(on:)` returns `nil` and `makeRefreshKeyCommand` offers Command-R instead).

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
| `UISliderTrackConfiguration` (ticks, `neutralValue`) | `LMKSlider.step`, `neutralValue` | no ticks |
| `UISymbolContentTransition` | `LMKButton.Style.animatesSymbolChanges`, `LMKCheckbox` | `setImage` without a transition |
| `UIImage.SymbolConfiguration(variableValueMode:)`, `(colorRenderingMode:)` | `LMKImage.SymbolOptions` | the plain configuration |
| `UISplitViewController.Column.inspector` | `UISplitViewController.lmk_setInspector(_:)`, `lmk_toggleInspector()` | inert |
| `UITraitHDRHeadroomUsageLimit` | photo browser HDR (with `preferredImageDynamicRange` from iOS 17) | SDR |
| `UITraitResolvesNaturalAlignmentWithBaseWritingDirection` | `UIView.lmk_forceLayoutDirection(_:)` | `semanticContentAttribute` only |
| `UIWindowSceneGeometry.isInteractivelyResizing` | `LMKScene.Geometry.isInteractivelyResizing` | always `false` |
| `prefersInterfaceOrientationLocked` | photo browser and crop editor | `supportedInterfaceOrientations` |
| `UIBackgroundExtensionView` | `LMKNavigationBar.backgroundContentView` | a plain host view |

APIs at or below the floor that LumiKit uses without a gate: `UIImageReader` and `UIContentUnavailableConfiguration` (iOS 17), `UITab` and `UISearchTab` (iOS 18), `Mutex` from Synchronization (iOS 18, macOS 15).

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
