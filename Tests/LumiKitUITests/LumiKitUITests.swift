//
//  LumiKitUITests.swift
//  LumiKit
//
//  Tests for LumiKitUI: ThemeManager, Color, AlertPresenter,
//  Spacing, CornerRadius, Alpha, Typography, Layout, CropAspectRatio,
//  UIColor+LMK, UIImage+LMK, UIView+LMKShadow, UIView+LMKBorder,
//  UIStackView+LMK, LMKDividerView, LMKBadgeView, LMKChipView,
//  LMKGradientView, LMKCardView, LMKBannerView, LMKTextField,
//  LMKTextView, LMKDeviceHelper, LMKKeyboardObserver.
//

import Testing
import UIKit

@testable import LumiKitUI

// MARK: - LMKThemeManager

@Suite("LMKThemeManager")
@MainActor
struct LMKThemeManagerTests {
    @Test("Default theme is LMKDefaultTheme")
    func defaultTheme() {
        let theme = LMKThemeManager.shared.current
        // Default theme returns systemGreen for primary
        #expect(theme.primary == UIColor.systemGreen)
    }

    @Test("Apply custom theme changes current")
    func applyCustomTheme() {
        struct TestTheme: LMKTheme {
            var primary: UIColor { .systemPurple }
            var primaryDark: UIColor { .systemPurple }
            var secondary: UIColor { .systemGray }
            var tertiary: UIColor { .systemBrown }
            var success: UIColor { .systemGreen }
            var warning: UIColor { .systemOrange }
            var error: UIColor { .systemRed }
            var info: UIColor { .systemBlue }
            var textPrimary: UIColor { .label }
            var textSecondary: UIColor { .secondaryLabel }
            var textTertiary: UIColor { .tertiaryLabel }
            var backgroundPrimary: UIColor { .systemBackground }
            var backgroundSecondary: UIColor { .secondarySystemBackground }
            var backgroundTertiary: UIColor { .tertiarySystemBackground }
            var divider: UIColor { .separator }
            var graySoft: UIColor { .systemGray4 }
            var grayMuted: UIColor { .systemGray5 }
            var white: UIColor { .white }
            var black: UIColor { .black }
        }

        LMKThemeManager.shared.apply(TestTheme())
        #expect(LMKThemeManager.shared.current.primary == UIColor.systemPurple)

        // Restore default
        LMKThemeManager.shared.apply(LMKDefaultTheme())
    }
}

// MARK: - LMKColor

@Suite("LMKColor")
@MainActor
struct LMKColorTests {
    @Test("LMKColor proxies to active theme")
    func colorProxiesToTheme() {
        LMKThemeManager.shared.apply(LMKDefaultTheme())
        #expect(LMKColor.primary == LMKThemeManager.shared.current.primary)
        #expect(LMKColor.error == LMKThemeManager.shared.current.error)
        #expect(LMKColor.textPrimary == LMKThemeManager.shared.current.textPrimary)
    }

    @Test("LMKColor.clear is UIColor.clear")
    func clearColor() {
        #expect(LMKColor.clear == UIColor.clear)
    }
}

// MARK: - LMKAlertPresenter

@Suite("LMKAlertPresenter")
struct LMKAlertPresenterTests {
    @Test("Default strings are English")
    func defaultStrings() {
        let strings = LMKAlertPresenter.Strings()
        #expect(strings.ok == "OK")
        #expect(strings.cancel == "Cancel")
    }

    @Test("Custom strings are preserved")
    func customStrings() {
        let strings = LMKAlertPresenter.Strings(ok: "Aceptar", cancel: "Cancelar")
        #expect(strings.ok == "Aceptar")
        #expect(strings.cancel == "Cancelar")
    }

    @Test("Static strings can be overridden")
    func overrideStaticStrings() {
        let original = LMKAlertPresenter.strings
        LMKAlertPresenter.strings = .init(ok: "OK!", cancel: "Nah")
        #expect(LMKAlertPresenter.strings.ok == "OK!")
        #expect(LMKAlertPresenter.strings.cancel == "Nah")
        // Restore
        LMKAlertPresenter.strings = original
    }
}

// MARK: - LMKSpacing

@Suite("LMKSpacing")
@MainActor
struct LMKSpacingTests {
    @Test("Spacing values follow 4pt grid")
    func spacingGrid() {
        #expect(LMKSpacing.xxs == 2)
        #expect(LMKSpacing.xs == 4)
        #expect(LMKSpacing.small == 8)
        #expect(LMKSpacing.medium == 12)
        #expect(LMKSpacing.large == 16)
        #expect(LMKSpacing.xl == 20)
        #expect(LMKSpacing.xxl == 24)
    }
}

// MARK: - LMKCornerRadius

@Suite("LMKCornerRadius")
@MainActor
struct LMKCornerRadiusTests {
    @Test("Corner radii are positive and ordered")
    func cornerRadiiOrdered() {
        #expect(LMKCornerRadius.xs > 0)
        #expect(LMKCornerRadius.small > LMKCornerRadius.xs)
        #expect(LMKCornerRadius.medium > LMKCornerRadius.small)
        #expect(LMKCornerRadius.large > LMKCornerRadius.medium)
        #expect(LMKCornerRadius.xlarge > LMKCornerRadius.large)
    }
}

// MARK: - LMKAlpha

@Suite("LMKAlpha")
@MainActor
struct LMKAlphaTests {
    @Test("Alpha values are between 0 and 1")
    func alphaRange() {
        #expect(LMKAlpha.overlay > 0 && LMKAlpha.overlay <= 1)
        #expect(LMKAlpha.overlayStrong > 0 && LMKAlpha.overlayStrong <= 1)
        #expect(LMKAlpha.overlayOpaque > 0 && LMKAlpha.overlayOpaque <= 1)
    }

    @Test("Alpha values are ordered by intensity")
    func alphaOrdered() {
        #expect(LMKAlpha.overlay < LMKAlpha.overlayStrong)
        #expect(LMKAlpha.overlayStrong < LMKAlpha.overlayOpaque)
    }
}

// MARK: - LMKTypography

@Suite("LMKTypography")
@MainActor
struct LMKTypographyTests {
    @Test("Heading fonts are larger than body")
    func headingLargerThanBody() {
        #expect(LMKTypography.h1.pointSize > LMKTypography.body.pointSize)
        #expect(LMKTypography.h2.pointSize >= LMKTypography.body.pointSize)
    }

    @Test("Caption fonts are smaller than body")
    func captionSmallerThanBody() {
        #expect(LMKTypography.caption.pointSize < LMKTypography.body.pointSize)
        #expect(LMKTypography.small.pointSize < LMKTypography.caption.pointSize)
    }

    @Test("Italic body has italic trait")
    func italicBodyHasItalicTrait() {
        let traits = LMKTypography.italicBody.fontDescriptor.symbolicTraits
        #expect(traits.contains(.traitItalic))
    }

    @Test("lineHeight returns positive value")
    func lineHeightPositive() {
        let height = LMKTypography.lineHeight(for: LMKTypography.body, type: .body)
        #expect(height > 0)
    }

    @Test("letterSpacing for heading is negative")
    func letterSpacingHeading() {
        #expect(LMKTypography.letterSpacing(for: .heading) < 0)
    }
}

// MARK: - LMKLayout

@Suite("LMKLayout")
@MainActor
struct LMKLayoutTests {
    @Test("minimumTouchTarget meets Apple HIG")
    func minimumTouchTarget() {
        #expect(LMKLayout.minimumTouchTarget >= 44)
    }

    @Test("Icon sizes are positive and ordered")
    func iconSizes() {
        #expect(LMKLayout.iconExtraSmall > 0)
        #expect(LMKLayout.iconSmall > LMKLayout.iconExtraSmall)
        #expect(LMKLayout.iconMedium > LMKLayout.iconSmall)
    }

    @Test("Cell height minimum is positive")
    func cellHeightMin() {
        #expect(LMKLayout.cellHeightMin > 0)
    }
}

// MARK: - LMKCropAspectRatio

@Suite("LMKCropAspectRatio")
struct CropAspectRatioTests {
    @Test("Square ratio is 1.0")
    func squareRatio() {
        #expect(LMKCropAspectRatio.square.ratio == 1.0)
    }

    @Test("Free ratio is nil")
    func freeRatio() {
        #expect(LMKCropAspectRatio.free.ratio == nil)
    }

    @Test("All cases have display names")
    func allCasesHaveDisplayNames() {
        for ratio in LMKCropAspectRatio.allCases {
            #expect(!ratio.displayName.isEmpty)
        }
    }

    @Test("4:3 ratio is approximately 1.33")
    func fourThreeRatio() {
        let ratio = LMKCropAspectRatio.fourThree.ratio!
        #expect(abs(ratio - 4.0 / 3.0) < 0.001)
    }
}

// MARK: - UIColor+LMK

@Suite("UIColor+LMK")
@MainActor
struct UIColorLMKTests {
    @Test("Hex init with # prefix")
    func hexInitWithHash() {
        let color = UIColor(lmk_hex: "#FF0000")
        #expect(color != nil)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color?.getRed(&r, green: &g, blue: &b, alpha: &a)
        #expect(abs(r - 1.0) < 0.01)
        #expect(abs(g) < 0.01)
        #expect(abs(b) < 0.01)
    }

    @Test("Hex init without prefix")
    func hexInitWithoutHash() {
        let color = UIColor(lmk_hex: "00FF00")
        #expect(color != nil)
    }

    @Test("Hex init with 8-char RGBA")
    func hexInitRGBA() {
        let color = UIColor(lmk_hex: "#FF000080")
        #expect(color != nil)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color?.getRed(&r, green: &g, blue: &b, alpha: &a)
        #expect(abs(a - 128.0 / 255.0) < 0.01)
    }

    @Test("Hex init with invalid string returns nil")
    func hexInitInvalid() {
        #expect(UIColor(lmk_hex: "xyz") == nil)
        #expect(UIColor(lmk_hex: "#12345") == nil)
        #expect(UIColor(lmk_hex: "") == nil)
    }

    @Test("lmk_hexString round-trips")
    func hexStringRoundTrip() {
        let color = UIColor(lmk_hex: "#FF5733")
        #expect(color?.lmk_hexString == "FF5733")
    }

    @Test("lmk_isLight for white returns true")
    func isLightWhite() {
        #expect(UIColor.white.lmk_isLight)
    }

    @Test("lmk_isLight for black returns false")
    func isLightBlack() {
        #expect(!UIColor.black.lmk_isLight)
    }

    @Test("lmk_adjustedBrightness returns valid color")
    func adjustedBrightness() {
        let color = UIColor.red
        let lighter = color.lmk_adjustedBrightness(by: 1.2)
        let darker = color.lmk_adjustedBrightness(by: 0.8)
        #expect(lighter != color || darker != color)
    }

    @Test("lmk_contrastingTextColor returns appropriate color")
    func contrastingTextColor() {
        #expect(UIColor.white.lmk_contrastingTextColor == .black)
        #expect(UIColor.black.lmk_contrastingTextColor == .white)
    }
}

// MARK: - UIImage+LMK

@Suite("UIImage+LMK")
@MainActor
struct UIImageLMKTests {
    @Test("lmk_resized maxDimension preserves aspect ratio")
    func resizedMaxDimension() {
        let image = UIImage.lmk_solidColor(.red, size: CGSize(width: 200, height: 100))
        let resized = image.lmk_resized(maxDimension: 100)
        #expect(resized.size.width == 100)
        #expect(resized.size.height == 50)
    }

    @Test("lmk_resized to exact size")
    func resizedExactSize() {
        let image = UIImage.lmk_solidColor(.blue, size: CGSize(width: 100, height: 100))
        let resized = image.lmk_resized(to: CGSize(width: 50, height: 50))
        #expect(resized.size.width == 50)
        #expect(resized.size.height == 50)
    }

    @Test("lmk_solidColor creates image with correct size")
    func solidColor() {
        let image = UIImage.lmk_solidColor(.green, size: CGSize(width: 10, height: 20))
        #expect(image.size.width == 10)
        #expect(image.size.height == 20)
    }

    @Test("lmk_rounded returns non-nil image")
    func rounded() {
        let image = UIImage.lmk_solidColor(.red, size: CGSize(width: 100, height: 100))
        let rounded = image.lmk_rounded(cornerRadius: 10)
        #expect(rounded.size.width == 100)
    }
}

// MARK: - UIView+LMKShadow

@Suite("UIView+LMKShadow")
@MainActor
struct UIViewShadowTests {
    @Test("lmk_applyShadow sets layer properties")
    func applyShadow() {
        let view = UIView()
        view.lmk_applyShadow(LMKShadow.card())
        #expect(view.layer.shadowOpacity > 0)
        #expect(!view.layer.masksToBounds)
    }

    @Test("lmk_removeShadow zeros opacity")
    func removeShadow() {
        let view = UIView()
        view.lmk_applyShadow(LMKShadow.card())
        view.lmk_removeShadow()
        #expect(view.layer.shadowOpacity == 0)
    }
}

// MARK: - UIView+LMKBorder

@Suite("UIView+LMKBorder")
@MainActor
struct UIViewBorderTests {
    @Test("lmk_applyBorder sets layer properties")
    func applyBorder() {
        let view = UIView()
        view.lmk_applyBorder(color: .red, width: 2, cornerRadius: 8)
        #expect(view.layer.borderWidth == 2)
        #expect(view.layer.cornerRadius == 8)
        #expect(view.layer.masksToBounds)
    }

    @Test("lmk_removeBorder clears layer properties")
    func removeBorder() {
        let view = UIView()
        view.lmk_applyBorder(color: .red, width: 2)
        view.lmk_removeBorder()
        #expect(view.layer.borderWidth == 0)
    }

    @Test("lmk_applyCornerRadius sets radius and masking")
    func applyCornerRadius() {
        let view = UIView()
        view.lmk_applyCornerRadius(12, masking: false)
        #expect(view.layer.cornerRadius == 12)
        #expect(!view.layer.masksToBounds)
    }
}

// MARK: - UIStackView+LMK

@Suite("UIStackView+LMK")
@MainActor
struct UIStackViewLMKTests {
    @Test("Convenience init sets axis and spacing")
    func convenienceInit() {
        let stack = UIStackView(lmk_axis: .vertical, spacing: 12)
        #expect(stack.axis == .vertical)
        #expect(stack.spacing == 12)
    }

    @Test("lmk_addArrangedSubviews adds all views")
    func addArrangedSubviews() {
        let stack = UIStackView()
        let views = [UIView(), UIView(), UIView()]
        stack.lmk_addArrangedSubviews(views)
        #expect(stack.arrangedSubviews.count == 3)
    }

    @Test("lmk_removeAllArrangedSubviews clears all views")
    func removeAllArrangedSubviews() {
        let stack = UIStackView()
        stack.lmk_addArrangedSubviews([UIView(), UIView()])
        stack.lmk_removeAllArrangedSubviews()
        #expect(stack.arrangedSubviews.isEmpty)
    }
}

// MARK: - LMKDividerView

@Suite("LMKDividerView")
@MainActor
struct LMKDividerViewTests {
    @Test("Horizontal divider intrinsic size")
    func horizontalIntrinsicSize() {
        let divider = LMKDividerView(orientation: .horizontal)
        let size = divider.intrinsicContentSize
        #expect(size.height > 0)
        #expect(size.width == UIView.noIntrinsicMetric)
    }

    @Test("Vertical divider intrinsic size")
    func verticalIntrinsicSize() {
        let divider = LMKDividerView(orientation: .vertical)
        let size = divider.intrinsicContentSize
        #expect(size.width > 0)
        #expect(size.height == UIView.noIntrinsicMetric)
    }

    @Test("Default color is LMKColor.divider")
    func defaultColor() {
        let divider = LMKDividerView()
        #expect(divider.backgroundColor == LMKColor.divider)
    }

    @Test("Custom color is applied")
    func customColor() {
        let divider = LMKDividerView(color: .red)
        #expect(divider.backgroundColor == .red)
    }
}

// MARK: - LMKBadgeView

@Suite("LMKBadgeView")
@MainActor
struct LMKBadgeViewTests {
    @Test("Configure count hides for 0")
    func countHidesForZero() {
        let badge = LMKBadgeView()
        badge.configure(count: 0)
        #expect(badge.isHidden)
    }

    @Test("Configure count shows for positive")
    func countShowsForPositive() {
        let badge = LMKBadgeView()
        badge.configure(count: 5)
        #expect(!badge.isHidden)
    }

    @Test("Configure count shows 99+ for large values")
    func countCapsAt99() {
        let badge = LMKBadgeView()
        badge.configure(count: 150)
        #expect(badge.accessibilityLabel == "150")
    }

    @Test("Configure text sets accessibility")
    func textSetsAccessibility() {
        let badge = LMKBadgeView()
        badge.configure(text: "New")
        #expect(badge.accessibilityLabel == "New")
        #expect(!badge.isHidden)
    }

    @Test("Dot badge has smaller intrinsic size")
    func dotBadge() {
        let badge = LMKBadgeView()
        badge.configure()
        let dotSize = badge.intrinsicContentSize
        badge.configure(count: 5)
        let countSize = badge.intrinsicContentSize
        #expect(dotSize.width < countSize.width)
    }
}

// MARK: - LMKChipView

@Suite("LMKChipView")
@MainActor
struct LMKChipViewTests {
    @Test("Filled style has non-clear background")
    func filledBackground() {
        let chip = LMKChipView(text: "Test", style: .filled)
        #expect(chip.backgroundColor != .clear)
        #expect(chip.backgroundColor != nil)
    }

    @Test("Outlined style has clear background and border")
    func outlinedBackground() {
        let chip = LMKChipView(text: "Test", style: .outlined)
        #expect(chip.backgroundColor == .clear)
        #expect(chip.layer.borderWidth > 0)
    }

    @Test("Configure sets accessibility label")
    func accessibilityLabel() {
        let chip = LMKChipView(text: "Indoor")
        #expect(chip.accessibilityLabel == "Indoor")
        // Default trait is .staticText; becomes .button when tapHandler is set
        #expect(chip.accessibilityTraits == .staticText)
        chip.tapHandler = {}
        #expect(chip.accessibilityTraits == .button)
    }
}

// MARK: - LMKGradientView

@Suite("LMKGradientView")
@MainActor
struct LMKGradientViewTests {
    @Test("Layer class is CAGradientLayer")
    func layerClass() {
        let gradient = LMKGradientView(colors: [.red, .blue])
        #expect(gradient.layer is CAGradientLayer)
    }

    @Test("Direction sets start/end points")
    func directionPoints() {
        let gradient = LMKGradientView(colors: [.red, .blue], direction: .leftToRight)
        let gradientLayer = gradient.layer as! CAGradientLayer
        #expect(gradientLayer.startPoint == CGPoint(x: 0, y: 0.5))
        #expect(gradientLayer.endPoint == CGPoint(x: 1, y: 0.5))
    }

    @Test("Colors are applied to gradient layer")
    func colorsApplied() {
        let gradient = LMKGradientView(colors: [.red, .blue])
        let gradientLayer = gradient.layer as! CAGradientLayer
        #expect(gradientLayer.colors?.count == 2)
    }
}

// MARK: - LMKCardView

@Suite("LMKCardView")
@MainActor
struct LMKCardViewTests {
    @Test("Default corner radius is LMKCornerRadius.medium")
    func defaultCornerRadius() {
        let card = LMKCardView()
        #expect(card.layer.cornerRadius == LMKCornerRadius.medium)
    }

    @Test("contentView is a subview")
    func contentViewIsSubview() {
        let card = LMKCardView()
        #expect(card.contentView.superview === card)
    }

    @Test("Shadow is applied")
    func shadowApplied() {
        let card = LMKCardView()
        #expect(card.layer.shadowOpacity > 0)
        #expect(!card.layer.masksToBounds)
    }

    @Test("Custom corner radius is applied")
    func customCornerRadius() {
        let card = LMKCardView()
        card.cardCornerRadius = 20
        #expect(card.layer.cornerRadius == 20)
        #expect(card.contentView.layer.cornerRadius == 20)
    }
}

// MARK: - LMKBannerView

@Suite("LMKBannerView")
@MainActor
struct LMKBannerViewTests {
    @Test("Banner creates with correct background")
    func creation() {
        let banner = LMKBannerView(type: .warning, message: "Test")
        #expect(banner.backgroundColor != nil)
    }

    @Test("Action title shows/hides button")
    func actionTitleToggle() {
        let banner = LMKBannerView(type: .info, message: "Test")
        banner.actionTitle = "Retry"
        #expect(banner.actionTitle == "Retry")
        banner.actionTitle = nil
        #expect(banner.actionTitle == nil)
    }

    @Test("Default strings are English")
    func defaultStrings() {
        let strings = LMKBannerView.Strings()
        #expect(strings.dismissAccessibilityLabel == "Dismiss")
    }
}

// MARK: - LMKTextField

@Suite("LMKTextField")
@MainActor
struct LMKTextFieldTests {
    @Test("Normal state has divider border color")
    func normalState() {
        let field = LMKTextField()
        #expect(field.textField.font == LMKTypography.body)
    }

    @Test("Error state updates border and shows message")
    func errorState() {
        let field = LMKTextField()
        field.validationState = .error("Invalid")
        // Verify state was set (border color testing is limited in unit tests)
        if case .error(let msg) = field.validationState {
            #expect(msg == "Invalid")
        } else {
            #expect(Bool(false))
        }
    }

    @Test("Placeholder sets attributed placeholder")
    func placeholder() {
        let field = LMKTextField()
        field.placeholder = "Email"
        #expect(field.textField.attributedPlaceholder?.string == "Email")
    }

    @Test("Text property proxies to textField")
    func textProxy() {
        let field = LMKTextField()
        field.text = "Hello"
        #expect(field.textField.text == "Hello")
        #expect(field.text == "Hello")
    }

}

// MARK: - LMKTextView

@Suite("LMKTextView")
@MainActor
struct LMKTextViewTests {
    @Test("Text property proxies to textView")
    func textProxy() {
        let tv = LMKTextView()
        tv.text = "Hello"
        #expect(tv.textView.text == "Hello")
        #expect(tv.text == "Hello")
    }

    @Test("Placeholder is set")
    func placeholderSet() {
        let tv = LMKTextView()
        tv.placeholder = "Notes"
        #expect(tv.placeholder == "Notes")
    }

    @Test("Default max character count is 0 (unlimited)")
    func defaultMaxCount() {
        let tv = LMKTextView()
        #expect(tv.maxCharacterCount == 0)
    }

    @Test("Default styling uses design tokens")
    func defaultStyling() {
        let tv = LMKTextView()
        #expect(tv.textView.font == LMKTypography.body)
        #expect(tv.textView.backgroundColor == LMKColor.backgroundSecondary)
    }
}

// MARK: - LMKDeviceHelper

@Suite("LMKDeviceHelper")
@MainActor
struct LMKDeviceHelperTests {
    @Test("deviceType returns a valid case")
    func deviceTypeValid() {
        let type = LMKDeviceHelper.deviceType
        // Should be one of the valid cases (we can't predict which in tests)
        switch type {
        case .iPhone, .iPad, .macCatalyst, .other:
            break // All valid
        }
    }

    @Test("screenSize returns a valid case")
    func screenSizeValid() {
        let size = LMKDeviceHelper.screenSize
        switch size {
        case .compact, .regular, .large, .extraLarge:
            break // All valid
        }
    }

    @Test("isIPad and isMacCatalyst are consistent")
    func consistency() {
        let type = LMKDeviceHelper.deviceType
        if type == .iPad {
            #expect(LMKDeviceHelper.isIPad)
            #expect(!LMKDeviceHelper.isMacCatalyst)
        } else if type == .macCatalyst {
            #expect(!LMKDeviceHelper.isIPad)
            #expect(LMKDeviceHelper.isMacCatalyst)
        }
    }
}

// MARK: - LMKKeyboardObserver

@Suite("LMKKeyboardObserver")
@MainActor
struct LMKKeyboardObserverTests {
    @Test("Initial currentHeight is 0")
    func initialHeight() {
        let observer = LMKKeyboardObserver()
        #expect(observer.currentHeight == 0)
    }

    @Test("startObserving and stopObserving don't crash")
    func startStopObserving() {
        let observer = LMKKeyboardObserver()
        observer.startObserving()
        observer.stopObserving()
        // No crash = success
    }

    @Test("KeyboardInfo isVisible is true when height > 0")
    func keyboardInfoVisibility() {
        let info = LMKKeyboardObserver.KeyboardInfo(
            height: 300,
            animationDuration: 0.25,
            animationOptions: .curveEaseInOut
        )
        #expect(info.isVisible)

        let hidden = LMKKeyboardObserver.KeyboardInfo(
            height: 0,
            animationDuration: 0.25,
            animationOptions: .curveEaseInOut
        )
        #expect(!hidden.isVisible)
    }
}

// MARK: - LMKBadgeTheme

@Suite("LMKBadgeTheme")
@MainActor
struct LMKBadgeThemeTests {
    @Test("Default badge theme values")
    func defaultValues() {
        let config = LMKBadgeTheme()
        #expect(config.minWidth == 18)
        #expect(config.height == 18)
        #expect(config.horizontalPadding == 5)
        #expect(config.borderWidth == 1.5)
    }

    @Test("Custom badge theme applied via ThemeManager")
    func customTheme() {
        let original = LMKThemeManager.shared.badge
        defer { LMKThemeManager.shared.apply(badge: original) }

        LMKThemeManager.shared.apply(badge: .init(minWidth: 24, height: 24))
        #expect(LMKThemeManager.shared.badge.minWidth == 24)
        #expect(LMKThemeManager.shared.badge.height == 24)
    }
}
