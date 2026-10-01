//
//  LMKFormScaffold.swift
//  LumiKit
//
//  Builders for form screens: a keyboard-aware scroll view, a content stack,
//  a one-call installer with width modes, and header / field-row helpers.
//

import SnapKit
import UIKit

// A namespace of static builders without a theme argument: every read happens when the host builds
// the form, and the pieces it returns carry no `applyTheme(_:)` of their own.
// swiftlint:disable no_global_token_proxies_in_components

/// Static builders for form screens that are not `LMKScrollStackViewController`
/// subclasses: view controllers with their own base class that still want the
/// standard scroll + stack form layout and keyboard behavior.
///
/// ```swift
/// let scrollView = LMKFormScaffold.makeScrollView()
/// let stack = LMKFormScaffold.makeContentStack()
/// LMKFormScaffold.install(scrollView: scrollView, stack: stack, in: view, below: navigationBar, widthMode: .readable)
/// LMKFormScaffold.installHeader(LMKFormScaffold.makeHeaderStack(title: "Profile", subtitle: "Public details"), in: stack)
/// stack.addArrangedSubview(LMKFormScaffold.makeFieldRow(label: "Name", control: nameField))
/// ```
public enum LMKFormScaffold {
    /// How the content stack takes the scroll view's width.
    public nonisolated enum WidthMode: Sendable, Hashable {
        /// Full width inside the safe area and the content insets (the default).
        case tokenInsets
        /// The scroll view's readable content guide (wide iPads and Mac windows keep lines short).
        case readable
        /// Centered in the safe area, at most `maxWidth` wide, never closer than `horizontalInset`
        /// to its edges.
        case capped(maxWidth: CGFloat, horizontalInset: CGFloat)
    }

    // MARK: - Builders

    /// A scroll view for form content: keyboard dismiss on drag and keyboard-overlap avoidance installed.
    ///
    /// - Parameters:
    ///   - keyboardDismissMode: Default `.onDrag`: the drag posts the keyboard-hide
    ///     notification immediately, so the installed adjuster restores its insets in one step.
    ///   - showsEdgeEffects: Whether the iOS 26 scroll edge effects show at the top and bottom
    ///     (default `true`); a form under its own header may not want them.
    public static func makeScrollView(keyboardDismissMode: UIScrollView.KeyboardDismissMode = .onDrag, showsEdgeEffects: Bool = true) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.keyboardDismissMode = keyboardDismissMode
        scrollView.lmk_enableKeyboardAdjustment()
        if #available(iOS 26, *) {
            // The system fades content under bars at both edges; a form under its own header may not want it.
            scrollView.topEdgeEffect.isHidden = !showsEdgeEffects
            scrollView.bottomEdgeEffect.isHidden = !showsEdgeEffects
        }
        return scrollView
    }

    /// A vertical fill-aligned stack for form rows.
    /// - Parameter spacing: Between rows; default `LMKSpacing.large`.
    public static func makeContentStack(spacing: CGFloat = LMKSpacing.large) -> UIStackView {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = spacing
        stack.alignment = .fill
        return stack
    }

    /// A screen header: a heading and an optional caption under it.
    public static func makeHeaderStack(title: String, subtitle: String? = nil) -> UIStackView {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = LMKSpacing.xs
        stack.alignment = .fill
        let titleLabel = UILabel.lmk_make(.h2, text: title)
        titleLabel.accessibilityTraits = .header
        stack.addArrangedSubview(titleLabel)
        if let subtitle {
            stack.addArrangedSubview(UILabel.lmk_make(.caption, text: subtitle, color: LMKColor.textSecondary))
        }
        return stack
    }

    /// Inserts `header` at the top of `stack` with `spacingAfter` under it (default `LMKSpacing.xl`).
    public static func installHeader(_ header: UIView, in stack: UIStackView, spacingAfter: CGFloat? = nil) {
        stack.insertArrangedSubview(header, at: 0)
        stack.setCustomSpacing(spacingAfter ?? LMKSpacing.xl, after: header)
    }

    /// A field caption above a control.
    public static func makeFieldLabel(_ text: String) -> UILabel {
        UILabel.lmk_make(.captionMedium, text: text, color: LMKColor.textSecondary)
    }

    /// A caption over a control, as one row.
    public static func makeFieldRow(label: String, control: UIView, spacing: CGFloat? = nil) -> UIStackView {
        let row = UIStackView()
        row.axis = .vertical
        row.spacing = spacing ?? LMKSpacing.xs
        row.alignment = .fill
        let fieldLabel = makeFieldLabel(label)
        row.addArrangedSubview(fieldLabel)
        row.addArrangedSubview(control)
        control.accessibilityLabel = control.accessibilityLabel ?? label
        return row
    }

    // MARK: - Installation

    /// Installs `scrollView` and `stack` into `view`: the scroll view spans from below
    /// `topAnchorView` (or the view's top) to the bottom safe area, and the stack fills
    /// the scroll content inset by `contentInsets` in `widthMode`.
    ///
    /// - Parameters:
    ///   - scrollView: Added to `view` here; `stack` is added to it. Neither may have a superview yet.
    ///   - stack: Drives the content size; its width is locked to the scroll frame so content only scrolls vertically.
    ///   - view: The host view.
    ///   - topAnchorView: When non-nil, the scroll view's top meets this view's bottom; it must already be in `view`.
    ///   - contentInsets: From the scroll content edges to the stack; `nil` = `LMKSpacing.cardPadding` on all sides.
    ///   - widthMode: How the stack takes the width; default `.tokenInsets`.
    public static func install(
        scrollView: UIScrollView,
        stack: UIStackView,
        in view: UIView,
        below topAnchorView: UIView? = nil,
        contentInsets: NSDirectionalEdgeInsets? = nil,
        widthMode: WidthMode = .tokenInsets
    ) {
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            if let topAnchorView {
                make.top.equalTo(topAnchorView.snp.bottom)
            } else {
                make.top.equalToSuperview()
            }
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide)
        }
        scrollView.addSubview(stack)
        pin(stack, in: scrollView, insets: contentInsets ?? .lmk_all(LMKSpacing.cardPadding), widthMode: widthMode)
        // The stack's sides follow the safe area, not the content edges: the content is exactly as
        // wide as the frame, so the form only scrolls vertically.
        scrollView.contentLayoutGuide.snp.makeConstraints { $0.width.equalTo(scrollView.frameLayoutGuide) }
    }

    /// Pins `stack` inside `container` (a scroll view or its content view) per `widthMode`,
    /// replacing any constraints it made before. The stack's top and bottom drive the content
    /// height; the sides are measured from the container's safe area, so content stays clear of a
    /// floating sidebar (a tab or split view sidebar on iPad and Mac), an inspector, and the
    /// landscape sensor housing, while the scroll view and its background stay full-bleed.
    static func pin(_ stack: UIView, in container: UIView, insets: NSDirectionalEdgeInsets, widthMode: WidthMode) {
        let safeArea = container.safeAreaLayoutGuide
        stack.snp.remakeConstraints { make in
            make.top.equalToSuperview().offset(insets.top)
            make.bottom.equalToSuperview().offset(-insets.bottom)
            switch widthMode {
            case .tokenInsets:
                make.leading.equalTo(safeArea).offset(insets.leading)
                make.trailing.equalTo(safeArea).offset(-insets.trailing)
                // Inside a scroll view the content edges float: the width locks to the frame.
                make.width.equalTo(safeArea).offset(-(insets.leading + insets.trailing))
            case .readable:
                // The readable guide sits inside the layout margins, which already include the safe area.
                make.leading.equalTo(container.readableContentGuide.snp.leading).offset(insets.leading)
                make.trailing.equalTo(container.readableContentGuide.snp.trailing).offset(-insets.trailing)
            case let .capped(maxWidth, horizontalInset):
                make.centerX.equalTo(safeArea)
                make.width.lessThanOrEqualTo(maxWidth)
                make.leading.greaterThanOrEqualTo(safeArea).offset(horizontalInset)
                make.trailing.lessThanOrEqualTo(safeArea).offset(-horizontalInset)
                // Inside a scroll view the content edges float, so the insets alone do not bound
                // the width: the cap against the frame does (as `lmk_pinReadableWidth` carries).
                make.width.lessThanOrEqualTo(safeArea).offset(-horizontalInset * 2)
                // Just below required: a card's internal content-size chains (required hugging
                // on a detail label, wrapped labels) must never win over filling the width.
                make.width.equalTo(safeArea).offset(-horizontalInset * 2).priority(999)
            }
        }
    }
}

// swiftlint:enable no_global_token_proxies_in_components
