//
//  ButtonsExample.swift
//  LumiKitExample
//
//  Buttons: LMKButton roles, variants, sizes, loading, menus.
//

import LumiKitUI
import SnapKit
import UIKit

// MARK: - Button Role Helpers

private extension LMKButton.Role {
    static let allRoles: [LMKButton.Role] = [.primary, .secondary, .tertiary, .destructive, .warning, .success, .info, .neutral]

    var displayName: String {
        switch self {
        case .primary: "Primary"
        case .secondary: "Secondary"
        case .tertiary: "Tertiary"
        case .destructive: "Destructive"
        case .warning: "Warning"
        case .success: "Success"
        case .info: "Info"
        case .neutral: "Neutral"
        }
    }
}

// MARK: - Buttons

final class ButtonsDetailViewController: DetailViewController {
    /// The simulated work behind the loading buttons; cancelled when the page goes away.
    private var demoTask: Task<Void, Never>?

    isolated deinit {
        demoTask?.cancel()
    }

    override func setupStackContent() {
        addSectionHeader("Filled")
        for role in LMKButton.Role.allRoles {
            let btn = LMKButton(title: role.displayName, style: .filled(role))
            btn.onTap = { [weak self] in
                guard let self else { return }
                LMKToast.show(.success, "Filled \(role.displayName) tapped", in: self)
            }
            stackView.addArrangedSubview(btn)
        }

        addDivider()
        addSectionHeader("Outlined")
        for role in [LMKButton.Role.primary, .secondary, .destructive] {
            let btn = LMKButton(title: role.displayName, style: .outlined(role))
            btn.onTap = { [weak self] in
                guard let self else { return }
                LMKToast.show(.info, "Outlined \(role.displayName) tapped", in: self)
            }
            stackView.addArrangedSubview(btn)
        }

        addDivider()
        addSectionHeader("Ghost (Text-Only)")
        for role in [LMKButton.Role.primary, .destructive] {
            let btn = LMKButton(title: "\(role.displayName) Ghost", style: .ghost(role))
            btn.onTap = { [weak self] in
                guard let self else { return }
                LMKToast.show(.info, "Ghost \(role.displayName) tapped", in: self)
            }
            stackView.addArrangedSubview(btn)
        }

        addDivider()
        addSectionHeader("Icon-Only")
        let iconRow = UIStackView(lmk_axis: .horizontal, spacing: LMKSpacing.medium, alignment: .center)
        let icons: [(String, String, LMKButton.Role)] = [("chevron.left", "Previous", .primary), ("chevron.right", "Next", .primary), ("xmark", "Close", .destructive)]
        for (iconName, label, role) in icons {
            let btn = LMKButton(systemImage: iconName, style: .iconOnly(role))
            // A glyph is not a name: VoiceOver on the Mac idiom derives nothing from the symbol.
            btn.accessibilityLabel = label
            btn.onTap = { [weak self] in
                guard let self else { return }
                LMKToast.show(.info, "\(iconName) tapped", in: self)
            }
            iconRow.addArrangedSubview(btn)
        }
        iconRow.addArrangedSubview(UIView())
        stackView.addArrangedSubview(iconRow)

        addDivider()
        addSectionHeader("Tinted, Glass, and Sizes")
        let variantRow = UIStackView(lmk_axis: .horizontal, spacing: LMKSpacing.small, alignment: .center)
        variantRow.addArrangedSubview(LMKButton(title: "Tinted", style: .tinted()))
        variantRow.addArrangedSubview(LMKButton(title: "Glass", style: .glass()))
        variantRow.addArrangedSubview(LMKButton(title: "Small", style: .filled(.secondary).size(.small)))
        variantRow.addArrangedSubview(LMKButton(title: "Large", style: .filled(.secondary).size(.large)))
        variantRow.addArrangedSubview(UIView())
        stackView.addArrangedSubview(variantRow)

        addDivider()
        addSectionHeader("Custom Surface")
        var boxed = LMKButton.Style.outlined(.info)
        boxed.surface.corners = .fixed(LMKCornerRadius.small)
        boxed.surface.border = .solid(nil, width: 2)
        boxed.surface.shadow = .level(.level2)
        let boxedButton = LMKButton(title: "Square corners, 2pt outline, shadow", style: boxed)
        stackView.addArrangedSubview(boxedButton)
        let disabledButton = LMKButton(title: "Disabled", style: .filled())
        disabledButton.isEnabled = false
        stackView.addArrangedSubview(disabledButton)

        addDivider()
        addSectionHeader("Loading State")
        stackView.addArrangedSubview(UILabel.lmk_make(.caption, text: "isLoading swaps the title for a spinner and absorbs taps until the work is done."))
        let loadingBtn = LMKButton(title: "Tap to Load", style: .filled(.primary))
        loadingBtn.onTap = { [weak self, weak loadingBtn] in
            self?.simulateWork(on: loadingBtn, toast: nil)
        }
        stackView.addArrangedSubview(loadingBtn)
        let alwaysLoading = LMKButton(title: "Loading", style: .outlined(.secondary))
        alwaysLoading.isLoading = true
        stackView.addArrangedSubview(alwaysLoading)

        addDivider()
        addSectionHeader("onTap with a captured button")
        let typedBtn = LMKButton(title: "Button Reference Handler", style: .filled(.primary))
        typedBtn.onTap = { [weak self, weak typedBtn] in
            self?.simulateWork(on: typedBtn, toast: "Async operation complete")
        }
        stackView.addArrangedSubview(typedBtn)

        addDivider()
        addSectionHeader("Press Animation on Any UIControl")
        stackView
            .addArrangedSubview(UILabel.lmk_make(
                .caption,
                text: "`LMKAnimation.animateButtonPressDown/Up` accept any UIControl, so custom tiles reuse the spring press effect. LMKButton adds pointer hover feedback on iPad and Mac."
            ))

        let tile = PressableTileControl()
        tile.onTap = { [weak self] in
            guard let self else { return }
            LMKToast.show(.success, "Custom UIControl tapped", in: self)
        }
        stackView.addArrangedSubview(tile)
    }

    /// Puts `button` in its loading state for a moment, then restores it (and toasts, if asked).
    private func simulateWork(on button: LMKButton?, toast message: String?) {
        guard let button else { return }
        button.isLoading = true
        demoTask?.cancel()
        demoTask = Task { [weak self, weak button] in
            try? await Task.sleep(for: .seconds(1.5))
            guard !Task.isCancelled else { return }
            button?.isLoading = false
            if let self, let message {
                LMKToast.show(.success, message, in: self)
            }
        }
    }
}

/// Plain `UIControl` tile that reuses `LMKAnimation`'s button press animation.
private final class PressableTileControl: UIControl {
    var onTap: (() -> Void)?

    private lazy var iconView: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "square.grid.2x2"))
        imageView.tintColor = LMKColor.primary
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private lazy var titleLabel = UILabel.lmk_make(.body, text: "Custom Tile Control")

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = LMKColor.backgroundSecondary
        lmk_applyCornerRadius(LMKCornerRadius.medium)
        // A plain UIControl is invisible to VoiceOver until it says what it is.
        isAccessibilityElement = true
        accessibilityTraits = .button
        accessibilityLabel = titleLabel.text

        addSubview(iconView)
        addSubview(titleLabel)
        iconView.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(LMKSpacing.large)
            make.centerY.equalToSuperview()
            make.size.equalTo(LMKLayout.iconMedium)
        }
        // A floor plus top and bottom constraints, so the tile grows with Dynamic Type.
        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconView.snp.trailing).offset(LMKSpacing.medium)
            make.trailing.lessThanOrEqualToSuperview().inset(LMKSpacing.large)
            make.top.bottom.equalToSuperview().inset(LMKSpacing.large)
        }
        snp.makeConstraints { $0.height.greaterThanOrEqualTo(LMKLayout.rowHeightComfortable) }

        addTarget(self, action: #selector(pressDown), for: [.touchDown, .touchDragEnter])
        addTarget(self, action: #selector(pressUp), for: [.touchUpOutside, .touchCancel, .touchDragExit])
        addTarget(self, action: #selector(tapped), for: .touchUpInside)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func pressDown() {
        LMKAnimation.animateButtonPressDown(self)
    }

    @objc private func pressUp() {
        LMKAnimation.animateButtonPressUp(self)
    }

    @objc private func tapped() {
        LMKAnimation.animateButtonPressUp(self)
        onTap?()
    }
}
