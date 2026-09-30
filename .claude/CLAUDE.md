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
├── Makefile                      # lint, check, build, build-catalyst, build-host, test, test-filter, example, docs, migrate
├── Scripts/
│   ├── git-hooks/pre-commit      # SwiftLint --strict + SwiftFormat --lint on staged files; rejects a personal DEVELOPMENT_TEAM
│   ├── migrate-1.0.sh            # 0.x → 1.0 consumer migration (rules below); --print-table renders docs/MIGRATION-1.0.md
│   └── migrate-1.0.rules         # product / path / type / regex / member / filematch / report rules (append-only)
├── docs/                         # MIGRATION-1.0.md (generated tables + recipes), PLATFORM.md, images/
├── Sources/
│   ├── LumiKitCore/              # Concurrency/ Data/ Date/ File/ Localization/ Log/ Validation/ Resources/
│   ├── LumiKitUI/
│   │   ├── DesignSystem/         # LMKTheme (+ store, trait, LMKThemeApplying), Themes/ (category structs), Tokens/, Styles/ (LMKSurfaceStyle)
│   │   ├── Components/           # leaf views + BottomSheet/ Calendar/ DetailCards/ ListRow/ NavigationBar/ Pickers/ TabBar/ Toast/
│   │   ├── Controls/             # LMKButton, Checkbox, RatingControl, SegmentedControl (+Layout, +Gestures), Slider, Switch, TextField, TextView, CopyableLabel, PhotoButton, LMKTextInputStyle
│   │   ├── Alerts/ Animation/ Haptics/ Share/ Utilities/ Extensions/ Localization/ Resources/
│   ├── LumiKitPhoto/             # browser (+CollectionView, +Dismiss, +MacCatalyst, +Style), grid, crop (+Layout, +Gestures, +Resize, +Crop, +Style), coordinator, share preview, metadata
│   ├── LumiKitDebug/             # logger, record, store, history + detail VCs, URLSessionConfiguration+LMKDebug
│   └── LumiKitLottie/            # LMKLottieRefreshControl + Resources/refresh_spinner.json
├── Tests/<Target>Tests/          # mirrors the source folders; Support/ holds LMKThemeTesting and LMKWait; Naming/ checks the naming rules over Sources/
└── Example/                      # XcodeGen project (project.yml); 68 catalog pages in 12 sections (Catalog/ExampleCatalog.swift), one file per page under Examples/<Section>/, + the accessibility sweep runner
```

---

## Rules that bite

1. **Design tokens only.** Never hard-code a color, font, spacing, radius, shadow, or alpha. Text goes through `lmk_apply(_ style: LMKTextStyle)` / `UILabel.lmk_make`, never `.font =`. Components never read `LMKTheme.current` (SwiftLint `no_theme_store_in_components`); they resolve against the `theme` passed to `applyTheme(_:)`.
2. **Naming** (full spec in `CONTRIBUTING.md`, checked by `Tests/LumiKitUITests/Naming`): `LMK` prefix, nested types never repeat it; view controllers end in `ViewController`; namespaces are subject nouns (no `Helper` / `Util` / `Service` / `Manager`); the visual variant enum is `Variant`; `Style` is reserved for the per-component token struct; callbacks are `on<Event>`; `present(from:)` for things that end in `host.present`, `show(in:)` for installed views, `dismiss()` everywhere; `lmk_` on every public extension member of a non-LMK type.
3. **Every component**: nested all-optional `Style: LMKThemeExtension` (embedding `LMKSurfaceStyle` and per-state `LMKControlStateStyle` where relevant) with `merging(_:)` and a slot on `LMKTheme`; nested `Strings` with `LMKLocalized("key")` defaults (keys in all four tables; SwiftLint `no_literal_user_strings`); public structural subviews; `didApplyStyle`; `applyTheme(_:)` as the one place that assigns appearance; `lmk_startApplyingTheme()` last in `init` (views) or in `viewDidLoad` (view controllers).
4. **Controls** honor `isEnabled`, answer a 44pt hit area from `point(inside:with:)` (`lmk_hitTestBounds(minimumSide:)`), scale with Dynamic Type (heights are floors), and check `LMKAnimation.shouldAnimate` before animating.
5. **Concurrency**: UI, Photo, and Lottie use `defaultIsolation: MainActor`; value types (themes, styles, strings, enums) are `nonisolated struct/enum: Sendable`; off-main work is `@concurrent nonisolated static func`; Core has no default isolation and guards shared state with `Mutex`. Store every `Task` and cancel it in `deinit`.
6. **Platform gates**: new-OS APIs behind `if #available(iOS 26, *)` with a same-API fallback (see `docs/PLATFORM.md`); layout from size classes and window bounds, never `UIScreen.main` or the idiom; `UIRefreshControl` subclasses and `UISlider` track tints are guarded under the Mac idiom.
7. **Migration rules are frozen for consumers.** New APIs must match the shape the rules produce; only member reshapes may still be appended to `Scripts/migrate-1.0.rules` (with a `report` recipe), and `--print-table` regenerates the tables in `docs/MIGRATION-1.0.md`.
8. **SwiftFormat strips unused private declarations** on save (`unusedPrivateDeclarations`): land a private helper and its first use in the same edit. Its `isEmpty` rule rewrites `x.count == 0` on any receiver; a non-collection needs its own `isEmpty` or a different expression.

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

- **The floor stays iOS 18 / Mac Catalyst 18.** Built and tested with Xcode 26 (Swift 6.2) and, since 2026-09-27, Xcode 27 (Swift 6.4), on the iOS 26 simulator. Under Swift 6.4 the members of an extension follow the module's MainActor default even when the extended type is nonisolated, so extensions meant to run anywhere (`UIImage`, `LMKTheme` style slots, protocol defaults such as `LMKEnumSelectable`) are `nonisolated extension`s, pinned by `LMKNonisolatedSurfaceTests`; consumer subclasses of the package's controllers declare `isolated deinit`. The adopted iOS 26 APIs, their fallbacks, and the iOS 27 follow-ups (`barMinimizationBehavior`, `sidebar.preferredPlacement`, `prominentTabIdentifier`, `UIHingeInteraction`, reserved regions) are listed in `docs/PLATFORM.md`; iOS 27 APIs are a 1.x follow-up now that Xcode 27 is installed and go behind `#available(iOS 27, *)` the same way.
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
make docs             # xcodebuild docbuild for every target into build/docc
make migrate CONSUMER=../MyApp ARGS=--dry-run
```

Logs land in `build/logs/` (gitignored). Verify a build through the log, not a piped exit code.

### Example sweep

The Example app is the accessibility test bed. Launch arguments: `-lmk-page <title>`, `-lmk-audit`, `-lmk-audit-all`, `-lmk-config <name>`, `-lmk-screenshots <abs dir>`, `-lmk-rtl`, `-lmk-theme example|ocean|default`, `-lmk-live-photo <still> <video>` (the Photo Browser page opens a Live Photo built from the two files; the simulator library has none). `ExampleSweepRunner` pushes every catalog page, runs `ExampleAccessibilityAudit` (truncated, clippedHorizontally, overlap, smallTarget, unlabeled, contrast, fixedFont), writes a PNG per page, prints `AUDIT|config|page|severity|check|path|detail` lines, and exits. Drive the simulator with `xcrun simctl ui <sim> content_size accessibility-extra-extra-extra-large | appearance dark | increase_contrast enabled` and `simctl launch --console-pty --terminate-running-process`; run the Catalyst binary directly after `codesign --force --deep --sign -`. Remaining contrast warnings are brand-color pairs, accepted by design.

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
- **The iOS 18 zoom transition scales the whole presenting screen down and back**, which reads as the page bouncing behind the photo, most of all after a dismiss drag during which that page stood still. The photo browser runs its own transition (`LMKPhotoBrowserZoomAnimator`): one image view travels between the thumbnail and the stage while the stage fades, and the presenter never moves.

## Testing gotchas (xctest host on the simulator)

- `UIControl.sendActions(for:)` delivers nothing: call the handler method or the `on*` closure directly. `UIRefreshControl.isRefreshing` never turns true. UIKit modal `present` / `dismiss` completion blocks never run; components animate with `UIViewPropertyAnimator` and finish teardown through `LMKOnceCompletion`, so tests assert the component's own state.
- `becomeFirstResponder()` on a view controller hangs the main thread; `UIPasteboard.general` blocks forever (`LMKCopyableLabel` writes through an internal hook the test replaces); `UIView.setAnimationsEnabled` is process-global and unsafe across parallel suites.
- Parallel suites can hold the main actor for seconds: poll with `LMKWait.until` instead of a fixed sleep. Trait overrides propagate only inside a window; reading a trait on `traitOverrides` that has no override traps.
- `UITabBarController(tabs:)` builds every tab's controller at load (lazy roots use a placeholder swapped in on first selection); `UIBarButtonItem(image:menu:)` and `UIButton.menu` copy the menu; `UIButton.configurationUpdateHandler` runs only on UIKit's pass, so `LMKButton` resolves state in an `updateConfiguration()` override.
- A weak mock returned from a helper and bound to `_` dies before the assertions: pin it with `withExtendedLifetime`. `#expect(x == 375 - 8 - 16)` types the right side as `Int` against a `CGFloat`: compare against a single literal.
- `Calendar.date(from:)` normalizes overflowed components; ICU inserts U+202F before AM/PM and U+00A0 in some locales; `UIImage.lmk_solidColor` fixtures render at the screen scale.
- UIKit layout: `convenience init(frame:)` must call the designated initializer (never `self.init()`); a `UIContentView` bounded only from below answers an expanded fitting target with an infinite height (add a low-priority hug); a nested `UIStackView`'s hugging priority does not stop the outer stack stretching it (set it on the items); multi-line labels in horizontal stacks need `preferredMaxLayoutWidth` from `layoutSubviews`; `UITableViewCell.contentView` constraints sit at 999. `lmk_adjustedBrightness(by:)` is a multiplier (0.85 darkens 15%), never a delta.
- Mac idiom: `UISlider` track / thumb tints throw `NSInternalInconsistencyException`; AppKit's `_crashOnException` hides the reason, so diagnose with `lldb --batch -o "breakpoint set -n objc_exception_throw" -o "process launch -- <args>" -o "po $x0" -o "bt"`. A window's `semanticContentAttribute` does not flip descendants; RTL previews set `UIView.appearance().semanticContentAttribute` before views exist plus `lmk_forceLayoutDirection` on the window.

---

## Forced dark mode + status bar pattern

View controllers that force dark mode (photo browser, crop editor) do all three: `override var preferredStatusBarStyle { .lightContent }`, `modalPresentationCapturesStatusBarAppearance = true` in `init`, and `overrideUserInterfaceStyle = .dark` in `viewDidLoad`. Inside a `UINavigationController`, override `childForStatusBarStyle` on the container to return `topViewController`.

---

## Adding tokens and components

1. **Token**: add the field to the `LMK*Theme` category struct (defaulted) and the proxy on the token enum; tokens are `nonisolated`.
2. **Component**: follow rule 3 above; add tests (theme change, Dynamic Type, layer re-stamp, behavior), an Example page in the matching catalog section (then `xcodegen generate`), a DocC topic entry in `Sources/LumiKitUI/LumiKitUI.docc/LumiKitUI.md`, and a CHANGELOG line under `[Unreleased]`.
3. **Extension**: `Extensions/` with the `lmk_` prefix, one file per feature area (`UIView+LMKCorners.swift`).
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
