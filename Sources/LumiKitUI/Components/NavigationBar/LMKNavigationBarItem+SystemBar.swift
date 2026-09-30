//
//  LMKNavigationBarItem+SystemBar.swift
//  LumiKit
//
//  The bridge from `LMKNavigationBarItem` to the system bars: `UIBarButtonItem`s
//  for a `UINavigationItem` or `UIToolbar`, with the iOS 26 prominent style,
//  shared-background opt-out, transition identifiers, badges, and subtitles.
//

import UIKit

public extension LMKNavigationBarItem {
    /// A `UIBarButtonItem` rendering this item on a system navigation bar or toolbar.
    ///
    /// Maps the glyph or title, `isEnabled`, `accessibilityLabel`, `identifier` (as the
    /// `accessibilityIdentifier`, and on iOS 26 the bar's transition `identifier`), the `menu`
    /// (as the primary action when there is no `action`, else as the long-press menu), the
    /// `badge` (iOS 26 `UIBarButtonItem.Badge`), and the role: `.prominent` uses the iOS 26
    /// prominent style outside the shared glass background (`.done` before 26), `.destructive`
    /// tints with the error color.
    ///
    /// - Parameter tintColor: Tint of a `.plain` item; `nil` = the bar's tint.
    func makeBarButtonItem(tintColor: UIColor? = nil) -> UIBarButtonItem {
        let handler = action
        let primaryAction = handler.map { handler in UIAction { _ in handler() } }
        // A glyph shows alone; the title is the label of a text item (iOS 16 `init(title:image:primaryAction:menu:)`).
        let barItem = UIBarButtonItem(title: image == nil ? title : nil, image: image, primaryAction: primaryAction, menu: menu)
        barItem.isEnabled = isEnabled
        barItem.accessibilityLabel = accessibilityLabel ?? title
        barItem.accessibilityIdentifier = identifier
        barItem.tintColor = tintColor
        switch role {
        case .plain:
            barItem.style = .plain
        case .prominent:
            if #available(iOS 26, *) {
                barItem.style = .prominent
                barItem.hidesSharedBackground = true
            } else {
                barItem.style = .done
            }
        case .destructive:
            barItem.style = .plain
            barItem.tintColor = LMKColor.error
        }
        if #available(iOS 26, *) {
            barItem.identifier = identifier
            barItem.badge = Self.systemBadge(for: badge)
        }
        return barItem
    }

    /// The `UIBarButtonItem.Badge` for `badge` (iOS 26): a count, a text, or an indicator dot.
    @available(iOS 26, *)
    static func systemBadge(for badge: LMKBadgeView.Content?) -> UIBarButtonItem.Badge? {
        switch badge {
        case nil: nil
        case let .count(count): count > 0 ? .count(count) : nil
        case let .text(text): text.isEmpty ? nil : .string(text)
        case .dot: .indicator()
        }
    }
}

public extension UINavigationItem {
    /// Installs `LMKNavigationBarItem`s on the system navigation bar through `makeBarButtonItem(tintColor:)`.
    ///
    /// Both arrays are in leading-to-trailing order (the reverse of UIKit's trailing-first
    /// `rightBarButtonItems`), so a definition reads the way the bar looks.
    func lmk_setItems(leading: [LMKNavigationBarItem] = [], trailing: [LMKNavigationBarItem] = [], tintColor: UIColor? = nil) {
        leftBarButtonItems = leading.isEmpty ? nil : leading.map { $0.makeBarButtonItem(tintColor: tintColor) }
        rightBarButtonItems = trailing.isEmpty ? nil : trailing.reversed().map { $0.makeBarButtonItem(tintColor: tintColor) }
    }

    /// A secondary line under the title: `subtitle` on iOS 26 (the system stacks it under the
    /// title in both inline and large modes); before 26 a two-line `titleView` in the kit's
    /// title and caption styles (large titles cannot carry it, so the inline view is what shows).
    /// `nil` removes it either way.
    func lmk_setSubtitle(_ subtitle: String?) {
        if #available(iOS 26, *) {
            self.subtitle = subtitle
            return
        }
        guard let subtitle, !subtitle.isEmpty else {
            if titleView is LMKTwoLineTitleView { titleView = nil }
            return
        }
        let view = titleView as? LMKTwoLineTitleView ?? LMKTwoLineTitleView()
        view.configure(title: title, subtitle: subtitle)
        titleView = view
    }
}

/// The pre-26 `titleView` behind `UINavigationItem.lmk_setSubtitle(_:)`.
final class LMKTwoLineTitleView: UIView, LMKThemeApplying {
    let titleLabel = UILabel()
    let subtitleLabel = UILabel()
    private let stack = UIStackView()

    init() {
        super.init(frame: .zero)
        stack.axis = .vertical
        stack.alignment = .center
        stack.lmk_addArrangedSubviews([titleLabel, subtitleLabel])
        titleLabel.textAlignment = .center
        subtitleLabel.textAlignment = .center
        addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalToSuperview() }
        isAccessibilityElement = true
        accessibilityTraits = .header
        lmk_startApplyingTheme()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(title: String?, subtitle: String?) {
        titleLabel.lmk_setText(title)
        subtitleLabel.lmk_setText(subtitle)
        subtitleLabel.isHidden = subtitle == nil
        accessibilityLabel = [title, subtitle].compactMap(\.self).joined(separator: ", ")
        invalidateIntrinsicContentSize()
    }

    func applyTheme(_ theme: LMKTheme) {
        titleLabel.lmk_apply(LMKNavigationBar.defaultTitleTextStyle, color: theme.navigationBar.titleColor ?? LMKColor.textPrimary)
        subtitleLabel.lmk_apply(theme.navigationBar.subtitleTextStyle ?? .caption, color: theme.navigationBar.subtitleColor ?? LMKColor.textSecondary)
        invalidateIntrinsicContentSize()
    }

    override var intrinsicContentSize: CGSize {
        stack.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
    }
}
