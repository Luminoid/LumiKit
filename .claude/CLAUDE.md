# LumiKit — Claude Code Guide

> Shared Swift Package: design tokens, a value-type theme, styled UIKit components and controls, a photo module, debug tooling, and a Lottie refresh control.
> Swift 6.2, UIKit + SnapKit, iOS 18+ / Mac Catalyst 18+ (`LumiKitCore` and `LumiKitDebug` also build for macOS 15+). iOS 26 APIs ship behind `#available(iOS 26, *)` with fallbacks.

---

## Package overview

| Product | Dependencies | Purpose | Default isolation |
|---|---|---|---|
| **LumiKitCore** | Foundation | `LMKLogger` (+ `LMKLogging`, `LMKLogStore`), `LMKDate`, `LMKDateFormat`, `LMKFormat`, `LMKFile`, `LMKConcurrency`, `LMKURLValidator`, `LMKCalendarDay` / `LMKCalendarMonth` / `LMKCalendarSelection`, String / Collection / NSAttributedString extensions | none (nonisolated) |
| **LumiKitUI** | Core + SnapKit | Tokens and the theme, styles, components, controls, lists, navigation, calendar, detail cards, alerts, toasts, share, haptics, animation, utilities, `lmk_` extensions | `MainActor` |
| **LumiKitPhoto** | Core + UI | Photo browser, grid, crop editor, pick-and-crop coordinator, share preview, `LMKPhotoMetadata` | `MainActor` |
| **LumiKitDebug** | Core + UI (iOS / Catalyst only) | `LMKNetworkLogger` (URLProtocol capture with redaction) + `LMKNetworkHistoryViewController`; compiled only under `LMK_ENABLE_NETWORK_LOGGING` (debug configs) | none |
| **LumiKitLottie** | UI + Lottie | `LMKLottieRefreshControl` with the bundled ring | `MainActor` |

Every product ships `en`, `es`, `zh-Hans`, `zh-Hant` string tables under `Resources/` and a DocC catalog (`<Target>.docc`). The `LumiKitUI` catalog holds the guides: Getting Started, Theming, Styling, Components, Controls, Extensions, Localization, Platform Support, Migration.

---

## Project structure

```
LumiKit/
├── Package.swift                 # five products; LUMIKIT_WARNINGS_AS_ERRORS turns warnings into errors
├── Makefile                      # lint, check, build, build-catalyst, build-host, test, test-filter, example, example-catalyst, docs, migrate
├── Scripts/
│   ├── git-hooks/pre-commit      # SwiftLint --strict + SwiftFormat --lint on staged files (a missing tool fails); rejects a personal DEVELOPMENT_TEAM
│   ├── migrate-1.0.sh            # 0.x → 1.0 consumer migration (--dry-run, --allow-dirty, --force, --docs); --print-table renders docs/MIGRATION-1.0.md
│   └── migrate-1.0.rules         # product / path / type / regex / member / filematch / report rules (frozen; rule 7)
├── docs/                         # MIGRATION-1.0.md (generated tables + recipes), PLATFORM.md, images/
├── Sources/
│   ├── LumiKitCore/              # Concurrency/ Data/ Date/ File/ Localization/ Log/ Validation/ Resources/
│   ├── LumiKitUI/
│   │   ├── DesignSystem/         # LMKTheme (+ store, trait, LMKThemeApplying), Themes/ (category structs), Tokens/, Styles/ (LMKSurfaceStyle, LMKStatus)
│   │   ├── Components/           # leaf views and view controllers + BottomSheet/ (sheet, action sheet) Calendar/ DetailCards/ ListRow/ NavigationBar/ Pickers/ (date, enum, calendar range) TabBar/ Tip/ Toast/
│   │   ├── Controls/             # LMKButton, Checkbox, RatingControl, SegmentedControl (+Layout, +Gestures), Slider, Switch, TextField, TextView, SearchBar, ActionTile, CopyableLabel, PhotoButton, LMKHitExpandingControls, LMKTextInputStyle
│   │   ├── Extensions/           # `Type+LMKFeature.swift`, named for the API they add (UIControl+LMKHitTest, UIScrollView+LMKKeyboardAdjustment, UIView+LMKTextStyle for labels, fields, and text views)
│   │   ├── Alerts/ Animation/ Haptics/ Share/ Utilities/ Localization/ Resources/
│   ├── LumiKitPhoto/             # browser (+CollectionView, +Dismiss, +MacCatalyst, +Style, +Transition), grid (+Gestures, +Style, +DragDrop), crop (+Layout, +Gestures, +Resize, +Crop, +Style), coordinator, share preview, metadata
│   ├── LumiKitDebug/             # logger, record, store, history + detail VCs, URLSessionConfiguration+LMKDebug
│   └── LumiKitLottie/            # LMKLottieRefreshControl + Resources/refresh_spinner.json
├── Tests/<Target>Tests/          # mirrors the source folders (a test file sits in its subject's folder); UI Support/ holds LMKThemeTesting and LMKWait (Photo, Debug, and Lottie carry their own LMKWait); Naming/ checks the naming rules over Sources/
└── Example/                      # XcodeGen project (project.yml); 69 catalog pages in 12 sections (Catalog/ExampleCatalog.swift), one file per page under Examples/<Section>/, + the accessibility sweep runner
```

---

## Rules that bite

1. **Design tokens only.** Never hard-code a color, font, spacing, radius, shadow, or alpha. Text goes through `lmk_apply(_ style: LMKTextStyle)` / `UILabel.lmk_make`, never `.font =`. Components never read `LMKTheme.current` (SwiftLint `no_theme_store_in_components`) and never read the global token proxies `LMKSpacing.*` / `LMKLayout.*` (except `hairline`, `pixelAligned`) / `LMKCornerRadius.*` / `LMKAlpha.*` outside a default argument (SwiftLint `no_global_token_proxies_in_components`, over Components/, Controls/, Alerts/, Photo, and Lottie): keep the constraint handle and set it in `applyTheme(_:)` from the `theme` argument, so a scoped or later theme applies. A namespace with no theme input (static presenters, `LMKFormScaffold`, the `UIListContentConfiguration` helpers) and the window-tiered `LMKSpacing.cardPadding` carry an inline disable with the reason.
2. **Naming** (full spec in `CONTRIBUTING.md`, checked by `Tests/LumiKitUITests/Naming`): `LMK` prefix, nested types never repeat it; view controllers end in `ViewController`; namespaces are subject nouns (no `Helper` / `Util` / `Service` / `Manager`); the visual variant enum is `Variant`; `Style` is reserved for the per-component token struct; callbacks are present-tense `on<Event>` and a value change is `onValueChange` (the naming test rejects `on…ed` and a bare `onChange`); presenters that can be cancelled offer `onCancel`; `present(from:)` for things that end in `host.present`, `show(in:)` for installed views, `dismiss()` everywhere (idempotent, fires `onDismiss` once); `lmk_` on every public extension member of a non-LMK type; a value in pixels is `…PixelSize` and an exact value is never `max…`; every public enum without reference-type or closure payloads is `Sendable` and `Hashable`.
3. **Every component**: nested all-optional `Style: LMKThemeExtension` (embedding `LMKSurfaceStyle`, per-state `LMKControlStateStyle` where relevant, and `haptics: Bool?` when it plays haptics) with `merging(_:)` and a slot on `LMKTheme`; nested `Strings` with `LMKLocalized("key")` defaults (keys in all four tables; SwiftLint `no_literal_user_strings`); public structural subviews; `didApplyStyle`, which always runs last; `applyTheme(_:)` as the one place that assigns appearance; `lmk_startApplyingTheme()` last in `init` (views) or in `viewDidLoad` (view controllers). Open base classes call `open func applyContentTheme(_ theme: LMKTheme)` just before `didApplyStyle`; subclasses style their content there. A public field that does nothing is implemented or removed. Overlays (sheets, panels, tips, progress) are VoiceOver modals: `accessibilityViewIsModal`, `accessibilityPerformEscape()`, a `.screenChanged` post on present.
4. **Controls** honor `isEnabled` the UIKit way in `point(inside:with:)`: hidden answers `false`, disabled answers `bounds.contains(point)` (touches are absorbed, never passed through to the view behind), enabled answers the 44pt area (`lmk_hitTestBounds(minimumSide:)`). They scale with Dynamic Type (heights are floors) and check `LMKAnimation.shouldAnimate` before animating.
5. **Concurrency**: UI, Photo, and Lottie use `defaultIsolation: MainActor`; value types (themes, styles, strings, enums) are `nonisolated struct/enum: Sendable`; off-main work is `@concurrent nonisolated static func`; Core has no default isolation and guards shared state with a lock (`Mutex`, `NSLock` for `LMKDateFormat.strings`). `Type.strings` defaults are `nonisolated(unsafe) static var`, written once at launch. Store every `Task` and cancel it in `deinit`.
6. **Platform gates**: new-OS APIs behind `if #available(iOS 26, *)` with a same-API fallback (see `docs/PLATFORM.md`); layout from size classes and window bounds, never `UIScreen.main` or the idiom; `UIRefreshControl` subclasses and `UISlider` track tints are guarded under the Mac idiom.
7. **Migration rules are frozen for consumers.** Never change an existing rule's output; append a `report` recipe for a 0.x shape the script missed, and a `regex` or `member` rule only for a 0.x symbol no consumer has migrated yet whose rewrite is unambiguous (check the 0.x side with `git show 0.12.0:<path>`). `Scripts/migrate-1.0.sh . --print-table` regenerates the tables in `docs/MIGRATION-1.0.md`. After 1.0.0 a public rename or removal waits for the next major version.
8. **SwiftFormat strips unused private declarations** on save (`unusedPrivateDeclarations`): land a private helper and its first use in the same edit. Its `isEmpty` rule rewrites `x.count == 0` on any receiver; a non-collection needs its own `isEmpty` or a different expression.
9. **Values mean what they say.** `nil` in an optional style field means "the theme decides", so an explicit off is `.square` / `LMKBorderStyle.hidden` / `LMKShadowSource.hidden`, never `.none` (which Swift reads as `nil`). Destructive defaults are off: nothing deletes or overwrites user data unless asked (`deletesAfterShare: false`). `LMKCalendarDay` / `LMKCalendarMonth` are Gregorian civil dates: component math goes through `Calendar.lmk_civilCalendar`, day and month deltas anchor at noon (a daylight-saving change at midnight cannot shift them), and display uses the supplied calendar only when its months are Gregorian.

---

## Theme and Style pattern

```swift
// A theme is a value; apply re-renders every window (LMKColor.* are dynamic colors on the lmkTheme trait).
extension LMKTheme { static let myApp = LMKTheme(colors: LMKColorTheme(primary: .systemIndigo)) }
LMKTheme.apply(.myApp)
LMKTheme.update { $0.button.variant = .tinted }        // app-wide default for one component
let large = LMKTheme.current.spacing.large            // readable from any isolation

// A component resolves token ← theme.<component> ← instance style, all optional.
public final class LMKChipView: UIControl, LMKThemeApplying {
    public nonisolated struct Style: Sendable, Equatable, LMKThemeExtension { /* variant, tintColor, surface, states… */ }
    public var style = Style() { didSet { applyTheme(traitCollection.lmkTheme) } }
    public var didApplyStyle: ((LMKChipView) -> Void)?
    public func applyTheme(_ theme: LMKTheme) { let resolved = theme.chip.merging(style); /* every appearance assignment here */ didApplyStyle?(self) }
}
```

Tests scope a theme without global mutation: `LMKThemeTesting.traits(for:style:contrast:)` builds a trait collection, `LMKThemeTesting.fit(view, width:)` lays out, `LMKThemeTesting.distinct` is a theme where every value differs from the default. The xctest host has no connected scene, so `LMKTheme.apply` cannot stamp test windows; tests stamp `LMKTheme.currentReference` by hand.

---

## Platform support and availability

- **The floor stays iOS 18 / Mac Catalyst 18.** Built and tested with Xcode 26 (Swift 6.2) and Xcode 27 (Swift 6.4) on the iOS 26 simulator; CI runs the tests in both lanes and builds the Example for iOS and for Mac Catalyst. Under Swift 6.4 the members of an extension follow the module's MainActor default even when the extended type is nonisolated, so extensions meant to run anywhere (`UIImage`, `LMKTheme` style slots, protocol defaults such as `LMKEnumSelectable`) are `nonisolated extension`s, pinned by `LMKNonisolatedSurfaceTests`; consumer subclasses of the package's controllers declare `isolated deinit`. The adopted iOS 26 APIs, their fallbacks, and the iOS 27 follow-ups (`barMinimizationBehavior`, `sidebar.preferredPlacement`, `prominentTabIdentifier`, `UIHingeInteraction`, reserved regions) are listed in `docs/PLATFORM.md`; iOS 27 APIs are a 1.x follow-up now that Xcode 27 is installed and go behind `#available(iOS 27, *)` the same way.
- **Layout from traits and window bounds.** `LMKDevice.screenSize(for:)` (compact ≤375, regular ≤402, large, extraLarge for regular × regular), `LMKSpacing.cardPadding` / `cellPaddingVertical` (shortest side ≤768 / ≤834 / wider), `LMKLayout.hairline(for:)`, `LMKScene.screenScale`; `LMKScene.observeGeometry(of:)` and `LMKDevice.observeScreenSize(of:)` report resizes, folds, and the iOS 26 interactive-resize flag. `lmk_windowOrientation` is for camera / media rotation only.
- **Safe areas per edge**: overlays clamp against `safeAreaInsets.left` / `.right` as well as top / bottom.
- **iOS 27 gates for consuming apps** (LumiKit needs nothing): scene-based lifecycle and a declared launch screen are mandatory with the 27 SDK; `UIApplication.statusBar*` is deprecated for `UIWindowScene.statusBarManager`.

---

## Build and test

```bash
make check            # SwiftLint --strict + SwiftFormat --lint (the pre-commit hook runs the same on staged files)
make build            # iOS Simulator: platform=iOS Simulator,name=iPhone 17,OS=26.2 (DEST overrides)
make build-catalyst   # platform=macOS,variant=Mac Catalyst
make build-host       # swift build for LumiKitCore + LumiKitDebug (native macOS)
make test             # full package on the simulator; UIKit targets cannot run under `swift test`
make test-filter FILTER=LumiKitUITests/LMKButtonTests      # one suite (or .../method)
make example          # cd Example && xcodegen generate, then build (XcodeGen: -scheme, NEVER -target; regenerate after adding files)
make example-catalyst # the same for the Mac idiom (CI checks the tracked pbxproj against xcodegen generate)
make docs             # xcodebuild docbuild for every target into build/docc; log in build/logs/docs.log (DocC warnings such as an unresolved link fail the build, as in CI)
make migrate CONSUMER=../MyApp ARGS=--dry-run
```

Logs land in `build/logs/` (gitignored). Verify a build through the log, not a piped exit code. The default `DEST` pins the iOS 26.2 runtime; with only Xcode 27 installed, add that runtime or override `DEST`.

### Example sweep

The Example app is the accessibility test bed. Launch arguments: `-lmk-page <title>`, `-lmk-audit`, `-lmk-audit-all`, `-lmk-config <name>`, `-lmk-screenshots <abs dir>`, `-lmk-rtl`, `-lmk-theme example|ocean|default`, `-lmk-live-photo <still> <video>` (the Photo Browser page opens a Live Photo built from the two files; the simulator library has none), `-lmk-tap <title>` (repeatable: after `-lmk-page`, taps the controls with those titles in order, then screenshots and audits what they presented). `ExampleSweepRunner` pushes every catalog page and runs the probes in `ExampleSweepProbes` (37 tap paths into the sheets, pickers, toasts, tips, panels, pushes, tab bar, split view, browser, and crop editor that pages present; the step `@end` scrolls a page to its end, `@dismiss` dismisses the front-most presentation, and `@pop` pops the front-most stack), runs `ExampleAccessibilityAudit` (truncated, clippedHorizontally, overlap, smallTarget, unlabeled, unreachable custom controls, contrast with the text color's alpha composited over the fill, fixedFont; disabled controls are exempt from contrast), writes a PNG per page compositing every window of the scene (a Mac-idiom sheet window is written as `<name>-sheet-window-.png`), prints `AUDIT|config|page|severity|check|path|detail` lines, and exits 0, or 1 when a page reported an error, or 2 for a bad argument. Drive the simulator with `xcrun simctl ui <sim> content_size accessibility-extra-extra-extra-large | appearance dark | increase_contrast enabled` and `simctl launch --console-pty --terminate-running-process`; UIKit logs unsatisfiable constraints only while `_UIConstraintBasedLayoutLogUnsatisfiable` is on, which Xcode's debugger turns on and `simctl launch` does not, so a console sweep passes `-_UIConstraintBasedLayoutLogUnsatisfiable YES` with `SIMCTL_CHILD_OS_ACTIVITY_DT_MODE=YES`; run the Catalyst binary directly after `codesign --force --deep --sign -`. The runner's PNGs draw the view hierarchy only, so Mac window chrome (the toolbar's back button and title, the window controls) is checked with `screencapture -x -o -l <window number>`, the number read from `CGWindowListCopyWindowInfo` by owner name. Remaining contrast warnings are brand-color pairs, accepted by design.

The sweep and the unit tests cannot touch the screen. Gestures (taps landing on the right view, pinches, drags, long presses, pull to refresh) are verified with a throwaway XCUITest target built over the Example sources, with `simctl io recordVideo` and `ffmpeg` frames for anything that animates. Four of the 1.0 bugs were invisible to everything else: chips that ignored taps on their title, a refresh ring that did not spin, a zoomed photo that panned off the page, and a Live Photo that never loaded. XCUITest waits for the app to go idle before each gesture, so a touch that must land during a transition (the browser's first swipe, undone when the presentation finished) needs raw touch records through XCTest's event synthesizer, one finger per record (the synthesizer's completion block takes `(BOOL, NSError *)`; a block declared with one argument crashes the runner). `XCUIScreen.main.screenshot()` in a loop right after a raw touch gives about ten lossless frames a second with no idle wait. A simulator recording stores no frames while the screen is static and refines color after motion stops: resample to a constant frame rate for timing, and use a loop of `simctl io screenshot` for alpha and tint.

---

## UIKit rules the package learned the hard way

- **A `UIControl` tracks a touch only when it is the hit-test view.** A touch that lands on an interactive subview (any plain `UIView` or `UIStackView`) and reaches the control through the responder chain never fires `touchUpInside`. Subviews of a control are `isUserInteractionEnabled = false`, or the control overrides `hitTest` and returns itself (`LMKChipView`, which still hands its dismiss button the touch). `LMKControlHitTestingTests` checks every custom control.
- **A wrapping label takes its width from constraints, never from its own content.** A label bounded only by `<=` keeps whatever narrow width an early layout pass gave it and wraps one word per line from then on. Put it in a stack with the fixed-width neighbour, or pin both edges.
- **UIKit starts a refresh itself** when a pull crosses the system's distance mid-drag: `isRefreshing` turns true and `.valueChanged` fires without `beginRefreshing()` being called. Anything `beginRefreshing()` starts (the Lottie loop) must start from the `.valueChanged` handler too.
- **A view under a zoom transform is laid out by frame, not by constraints.** Auto Layout and `UIScrollView` zoom disagree about where the view sits, and the layout engine only re-applies a frame when its solution changes. The photo page sets `bounds` and `center` itself, keeps the content area the size of the page, and expresses the photo's travel as content insets.
- **A floating surface is opaque.** A translucent tint over content lets the content show through; composite the tint over the background color (`lmk_composited(over:alpha:)`).
- **A state shades the fill the control shows, not its tint.** A neutral filled button is gray with a label-colored tint; shading the tint for the pressed state came out black. Derive pressed and selected fills from the resting fill with `lmk_stateShade(by:)`, which lightens a fill that is already dark.
- **Selected and pressed looks differ from the resting one by more than a shade of the same fill.** In a row of filled chips a 15% darker fill was the selection. A filled `LMKFilterChipBar` keeps the full tint for the selected chip and washes the others; a press changes the fill, never the alpha of the whole control.
- **`viewDidAppear` does not reposition content.** A zoom presentation takes touches about a second before it reports the appearance, so a swipe can be under way when it arrives: the photo browser re-aligns its page only while the collection view is idle, and applies `initialIndex` once.
- **What a drag fades is its own layer.** Fading a root view fades everything on it. The browser's stage is a separate view under clear pages, and the browser presents over the full screen so there is a screen to show through; a view that must stay solid over a fading background keeps an opaque backing of its own.
- **Small fixed-size views hug their content at required priority** (`LMKBadgeView`): with equal priorities a stack picks who stretches.
- **A view that publishes an iOS 26 `cornerConfiguration`, clips, and has subviews eats its own border at the corners.** UIKit clips the subviews along a tighter curve than the layer border follows, for any published configuration (`.capsule()`, a fixed radius): a 1.5pt outline lost a quarter of its width on a chip's ends, a hairline lost five sixths. Capsules and circles are therefore drawn with `layer.cornerRadius` on every OS and a hidden subview (`LMKCornerTrackingView`) keeps the radius current on resize; `asConcentricContainer` skips a clipping view that already has a border. On iOS 26.x a configuration cannot be taken back once UIKit applied it (restoring the unspecified one leaves square corners; iOS 27 handles it), so the choice is made before publishing, never after.
- **Line widths are whole pixels.** 1.5pt at 3x is 4.5 pixels and Core Animation draws 4 on one edge and 5 on another. Borders and strokes go through `LMKLayout.pixelAligned(_:for:)`.
- **Changing `action.state` (or `image`, `subtitle`) in a handler does not repaint an open menu**: the handler gets a copy. A `.keepsMenuPresented` row repaints by rebuilding the visible menu: `UIContextMenuInteraction.updateVisibleMenu` for a button or a view (the block runs once per visible menu, so an open submenu is matched by its stable identifier), and a fresh menu with the same identifier assigned to `UIBarButtonItem.menu` for a bar button, which has no public interaction (an open submenu collapses to the top level there). The source comes from `action.presentationSourceItem`; `LMKMenu.reloadVisibleMenu(presenting:)` does all of it.
- **A trait handler re-applies what the trait changed, nothing more.** `lmk_apply`'s handler used to re-set the stored text color on every Dynamic Type, layout direction, or theme change, which wiped a `textColor` the host set after `UILabel.lmk_make` (black text on a black swatch). Token colors are dynamic and follow those changes by themselves; the handler re-applies the font and line metrics only.
- **A button whose menu opens on touch is animated by UIKit.** iOS 26 morphs the button into the menu and springs it back on close; `LMKButton`'s press spring on top read as a bounce, so it is off for `showsMenuAsPrimaryAction` buttons unless the style sets `pressAnimation`. The settle on close is UIKit's and stays.
- **A disabled control absorbs touches.** UIKit's own controls answer `bounds.contains(point)` while disabled, so a tap on a disabled button never reaches the row behind it; LumiKit's controls match, and `LMKButton.isLoading` absorbs the same way (it refuses tracking instead of turning interaction off).
- **`UISlider.trackConfiguration = nil` on iOS 26.2 pins the value at the minimum for good**: every later `value` is ignored. `LMKSlider` replaces a published tick configuration with a plain one instead of clearing it.
- **A wheel `UIDatePicker` throws under the Mac idiom.** `LMKDatePicker.Configuration.resolvedPickerStyle(for:)` maps `.wheels` to `.inline` (date modes) or `.compact` (time) there; build pickers through `LMKDatePicker.makePicker(_:)`.
- **The iOS 26 content-area pop gesture has no delegate**, so `gestureRecognizerShouldBegin` never sees it. `LMKNavigationController.updateContentPopGesture()` enables it from `canBeginPopGesture` after every push, pop, and layout pass, and `LMKSegmentedPageViewController` calls it when its page changes.
- **Keyboard frames are in screen coordinates.** Convert `frameEnd` with `window.screen.coordinateSpace.convert(_:to:)`; `view.convert(_:from: nil)` reads it as window coordinates and lifts short in an offset window.
- **A collection view's content size lands after the controller's layout callback.** A height that follows the rows (the enum picker) observes `contentSize` by KVO; a one-shot read in `viewDidLayoutSubviews` stays one pass behind.
- **A flow layout keeps the sizes `sizeForItemAt` gave it across its own bounds-change invalidation.** After a rotation the photo browser lets the collection view consume the bounds change, then invalidates again so pages re-measure. In a right-to-left layout a flow layout mirrors item positions without flipping the coordinate system (`flipsHorizontallyInOppositeLayoutDirection == false`), so offsets and gesture points stay unflipped.
- **A label whose scalable `font` is re-applied on a size change flattens its attributed runs.** Rich text gets its own label that never goes through `lmk_apply` and re-renders from its own trait handler.
- **Hidden arranged subviews keep their size constraints**: `UISV-hiding` is 999.999 on iOS 26.2, so a required height on a hidden row would conflict on an OS where it is lower. Size constraints on views a stack hides sit at 999.
- **UIKit resets `layer.cornerCurve` once a corner configuration is published**: a published configuration draws with UIKit's own curve.
- **ImageIO copies a container through with merged metadata** (`CGImageDestinationCopyImageSource`): pixels, frames, and gain maps stay byte-identical. `kCGImageDestinationDateTime` cannot be combined with `kCGImageDestinationMetadata`, and it leaves a stale `OffsetTimeOriginal` behind.
- **A `URLProtocol` that forwards through its own session** must not re-intercept: mark the forwarded request with a property and give the inner session `protocolClasses = []`. That is what prevents the loop; an `.ephemeral` configuration only drops the app's cookies, cache, and credentials. Report a redirect to the client with `wasRedirectedTo:redirectResponse:` and let the client's session decide. Every `client` call runs on the client thread (the run loop `startLoading` ran on; `stopLoading` arrives there too), never on the inner session's delegate queue. After `wasRedirectedTo`, hold the load's remaining calls: a followed redirect calls `stopLoading` (drop them), a refused one sends the protocol nothing and waits for the 3xx response, body, and finish, so they go out after `redirectDecisionGracePeriod`. A finish that lands after the session decided to follow but before `stopLoading` completes the task with no response, and `URLSession.data(for:)` traps on it (1 in 20 runs of one redirect; every run of 64 concurrent ones). Calls that arrive while the session is still deciding are handled either way. Record a followed redirect's 3xx from the redirect callback: the stop can cancel the inner task before it takes the 3xx as its `response`.
- **The iOS 18 zoom transition scales the whole presenting screen down and back**, which reads as the page bouncing behind the photo, most of all after a dismiss drag during which that page stood still. The photo browser runs its own transition (`LMKPhotoBrowserZoomAnimator`): one image view travels between the thumbnail and the stage while the stage fades, and the presenter never moves.
- **An overlay never constrains the view it points at.** A `.high` constraint from a tip's bubble to its source let the engine stretch the source (a chip whose width only its 250 hugging held) to center the bubble over it. `LMKTipView` reads the source's frame at every layout into a layout guide it owns and anchors the bubble to that.
- **Content measures its sides from the safe area.** An iOS 26 tab bar or split view sidebar floats over the content column and reports itself as that column's leading safe area (220pt for a tab sidebar on the Mac, the primary column's width in a split view). A vertical scroll view's automatic inset adjustment covers only the scrolling axis, so its content view inherits the horizontal safe area: `LMKFormScaffold.pin`, `lmk_pinReadableWidth`, and `lmk_readableWidthGuide` pin to `safeAreaLayoutGuide` (the readable content guide already includes it), and a stack added straight to a scroll view gets `contentLayoutGuide.width == frameLayoutGuide.width` so it never scrolls sideways. A full-screen header (`LMKCardPageViewController`) keeps its surface full-bleed and its items inside the safe area. The safe area also holds still during the iOS 26 interactive swipe back, which drops the revealed page's trailing layout margin to zero for the length of the transition: content pinned to a view controller's layout margins or `readableContentGuide` stretched about 20pt toward the right edge mid-swipe (TripDays, measured on device 2026-10-04). Only the root view's guide moves: a subview that does not preserve its superview's margins keeps its own, so `.readable` (which reads the scroll view's or content view's readable guide) holds still. `LMKFormScaffoldTests` collapses the root's trailing margin and checks both readable paths.
- **Under the Mac idiom a navigation bar is the window toolbar.** The bar is 0pt tall; its back button and title draw in the toolbar, and the title is the title bar's, so `titleVisibility = .hidden` hides every screen's title (`configureMacWindow(hidesTitleBar: false)` for apps with system bars). A dismissed full-screen presentation hands the toolbar back without the back button, so `LMKNavigationController` toggles the top item's `hidesBackButton` in `viewDidAppear`. A dismissed presented `UISplitViewController` leaves the toolbar's sidebar edge at its old primary-column width (the stack's back button and title sit ~300pt in); nothing on the navigation side resets it (bar hide/show, re-rooting the window, behavioral style toggles, title bar toggles, resizes all fail), but collapsing the split's primary column while it is still on screen does, so `LMKNavigationController.viewWillAppear` collapses the sidebar of a presentation being dismissed. A presented `UITabBarController` sidebar does not cause it. With the system bar hidden the window keeps a 32pt top safe area for the window controls. The toolbar shows no `titleView` (a segmented page's control goes in `centerItemGroups`, with `hidesSharedBackground` since it draws its own capsule), and a card page under a visible bar uses that bar instead of its header. Trackpad two-finger swipes reach a pan recognizer only with `allowedScrollTypesMask = .continuous`; to test one without a trackpad, post `CGEvent` pixel scroll events at the window with `scrollWheelEventIsContinuous = 1` and began, changed, and ended phases.
- **Nothing lays out from `init`, and no size starts at a zero that fights a floor.** `layoutIfNeeded()` on a subview lays out from the topmost ancestor that needs it, so the search bar's measuring call solved the whole detached bar at zero width; a stack framed in `layoutSubviews` is solved against its zero frame before the first pass (pin it); a placeholder size pin that `applyTheme` fills in later sits at 999 when the view has its own required minimum (`LMKButton.Style.minimumHeight`), or starts at the real value (the banner's width cap).

## Testing gotchas (xctest host on the simulator)

- `UIControl.sendActions(for:)` delivers nothing: call the handler method or the `on*` closure directly. `UIRefreshControl.isRefreshing` never turns true. UIKit modal `present` / `dismiss` completion blocks never run; components animate with `UIViewPropertyAnimator` and finish teardown through `LMKOnceCompletion`, so tests assert the component's own state.
- `becomeFirstResponder()` on a view controller hangs the main thread (components claim first responder only off the phone idiom and in a window, which keeps tests out of that path); `UIPasteboard.general` blocks forever (`LMKCopyableLabel` writes through an internal hook the test replaces); `UIView.setAnimationsEnabled` is process-global and unsafe across parallel suites, so animated components finish through `UIViewPropertyAnimator` plus `LMKOnceCompletion` and tests wait on the component's own state.
- UIKit keeps a dismissed `UIAlertController` alive in the host: an awaited `LMKAlert.confirm` dismissed with `dismiss(animated: false)` never resumes and hangs the run. Test the release path on the continuation helper (`LMKOnceContinuation`) instead.
- `accessibilityPerformEscapeBlock`'s getter raises `unrecognized selector` in the host. Components answer the escape gesture by overriding `accessibilityPerformEscape()` on a view subclass (the bottom sheet installs one in `loadView`).
- A regular host's `viewDidAppear` fires inside `addSubview` when a child view controller's view is added, so anything reset for a slide-in must be reset before the view goes in.
- An animated push in a window has a `transitionCoordinator` synchronously; the host does run `setMarkedText`, so input-method composition is testable. It has no scenes and cannot scroll, so per-scene and run-loop-mode behavior is correct by construction only.
- Outside a window, updating constraint constants does not flag layout on the superview; call `superview?.setNeedsLayout()` before asserting frames.
- On the simulator `inet_pton` accepts octal IPv4 (`0177.0.0.1` reads as 177.0.0.1), so host-blocklist checks parse the shorthand forms themselves.
- Parallel suites can hold the main actor for seconds: poll with `LMKWait.until` instead of a fixed sleep. Its budget counts polls, not wall-clock time: on the GitHub runners a first render blocks the main thread for 10 s and more, and a wall-clock deadline expired every waiter at once, one turn before the completions they waited for ran (33 failures per lane). Trait overrides propagate only inside a window; reading a trait on `traitOverrides` that has no override traps.
- `UITabBarController(tabs:)` builds every tab's controller at load (lazy roots use a placeholder swapped in on first selection); `UIBarButtonItem(image:menu:)` and `UIButton.menu` copy the menu; `UIButton.configurationUpdateHandler` runs only on UIKit's pass, so `LMKButton` resolves state in an `updateConfiguration()` override.
- A weak mock returned from a helper and bound to `_` dies before the assertions: pin it with `withExtendedLifetime`. `#expect(x == 375 - 8 - 16)` types the right side as `Int` against a `CGFloat`: compare against a single literal.
- `Calendar.date(from:)` normalizes overflowed components; ICU inserts U+202F before AM/PM and U+00A0 in some locales; `UIImage.lmk_solidColor` fixtures render at the screen scale.
- `UIImage.byPreparingThumbnail(ofSize:)` aspect-fits within a size in the image's points: divide a pixel size by the image's scale first.
- UIKit layout: `convenience init(frame:)` must call the designated initializer (never `self.init()`); a `UIContentView` bounded only from below answers an expanded fitting target with an infinite height (add a low-priority hug); a nested `UIStackView`'s hugging priority does not stop the outer stack stretching it (set it on the items); multi-line labels in horizontal stacks need `preferredMaxLayoutWidth` from `layoutSubviews`; `UITableViewCell.contentView` constraints sit at 999. `lmk_adjustedBrightness(by:)` is a multiplier (0.85 darkens 15%), never a delta.
- Mac idiom: `UISlider` track / thumb tints throw `NSInternalInconsistencyException`; AppKit's `_crashOnException` hides the reason, so diagnose with `lldb --batch -o "breakpoint set -n objc_exception_throw" -o "process launch -- <args>" -o "po $x0" -o "bt"`. A window's `semanticContentAttribute` does not flip descendants; RTL previews set `UIView.appearance().semanticContentAttribute` before views exist plus `lmk_forceLayoutDirection` on the window.

---

## Forced dark mode + status bar pattern

View controllers that force dark mode (photo browser, crop editor) do all three: `override var preferredStatusBarStyle { .lightContent }`, `modalPresentationCapturesStatusBarAppearance = true` in `init`, and `overrideUserInterfaceStyle = .dark` in `viewDidLoad`. Inside a `UINavigationController`, override `childForStatusBarStyle` on the container to return `topViewController`.

---

## Adding tokens and components

1. **Token**: add the field to the `LMK*Theme` category struct (defaulted) and the proxy on the token enum; tokens are `nonisolated`.
2. **Component**: follow rule 3 above; controls go in `Controls/`, multi-file families in `Components/<Family>/`; add tests in the mirrored folder (theme change, Dynamic Type, layer re-stamp, behavior, every Style field), an Example page in the matching catalog section (then `xcodegen generate`), a DocC topic entry in `Sources/LumiKitUI/LumiKitUI.docc/LumiKitUI.md`, and a CHANGELOG line under `[Unreleased]`.
3. **Extension**: `Extensions/` with the `lmk_` prefix, one file per feature area named for the type and the API it adds (`UIView+LMKCorners.swift`, `UIScrollView+LMKKeyboardAdjustment.swift`).
4. **String**: a `Strings` field with a `LMKLocalized` default and the key in all four `Localizable.strings` (the localization test checks parity).
5. **After changes**: `make check`, `make build`, `make build-catalyst`, the affected `make test-filter`, and `make example` when the Example changed.

---

## Dependencies

| Library | Version | Product | Purpose |
|---|---|---|---|
| SnapKit | 6.0.0+ | LumiKitUI | Programmatic Auto Layout (never `NSLayoutConstraint` directly) |
| Lottie (lottie-spm) | 4.4.0+ | LumiKitLottie | Pull-to-refresh animation; isolated so other consumers never link it |

---

*Optimized for Claude Code.*
