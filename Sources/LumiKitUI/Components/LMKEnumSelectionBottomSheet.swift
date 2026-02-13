//
//  LMKEnumSelectionBottomSheet.swift
//  LumiKit
//
//  Generic bottom sheet for selecting enum values with icons.
//

import SnapKit
import UIKit

/// Protocol for types that can be displayed in a selection bottom sheet.
public protocol LMKEnumSelectable {
    var displayName: String { get }
    var iconName: String { get }
}

/// Bottom sheet for selecting from a list of `LMKEnumSelectable` options.
@MainActor
public final class LMKEnumSelectionBottomSheet<T: Equatable & LMKEnumSelectable>: UIViewController, UITableViewDataSource, UITableViewDelegate {
    // MARK: - Layout Constants

    private static var rowHeight: CGFloat { 56 }
    private static var buttonHeight: CGFloat { 50 }
    private static var headerHeight: CGFloat { LMKSpacing.xxl + LMKSpacing.xl + LMKSpacing.large }
    private static var footerHeight: CGFloat { LMKSpacing.large + buttonHeight + LMKSpacing.xl }

    // MARK: - Properties

    private let titleText: String
    private let options: [T]
    private let currentSelection: T
    private let onSelect: (T) -> Void
    private let showIcons: Bool

    private var containerBottomConstraint: Constraint?

    private lazy var dimmingView: UIView = {
        let view = UIView()
        view.backgroundColor = LMKColor.black.withAlphaComponent(LMKAlpha.dimmingOverlay)
        view.alpha = 0
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dimmingViewTapped)))
        return view
    }()

    private lazy var containerView: UIView = {
        let view = UIView()
        view.backgroundColor = LMKColor.backgroundPrimary
        view.layer.cornerRadius = 16
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        return view
    }()

    private lazy var dragIndicator: UIView = {
        let view = UIView()
        view.backgroundColor = LMKColor.divider
        view.layer.cornerRadius = 2.5
        return view
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = titleText
        label.font = LMKTypography.h3
        label.textColor = LMKColor.textPrimary
        return label
    }()

    private lazy var tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.delegate = self
        tv.dataSource = self
        tv.register(LMKEnumSelectionCell.self, forCellReuseIdentifier: "LMKEnumSelectionCell")
        tv.separatorStyle = .none
        tv.backgroundColor = .clear
        tv.showsVerticalScrollIndicator = true
        tv.alwaysBounceVertical = false
        return tv
    }()

    private lazy var cancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(LMKAlertPresenter.strings.cancel, for: .normal)
        button.titleLabel?.font = LMKTypography.bodyMedium
        button.setTitleColor(LMKColor.textPrimary, for: .normal)
        button.backgroundColor = LMKColor.backgroundSecondary
        button.layer.cornerRadius = LMKCornerRadius.medium
        button.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        return button
    }()

    public init(title: String, options: [T], currentSelection: T, showIcons: Bool = false, onSelect: @escaping (T) -> Void) {
        self.titleText = title
        self.options = options
        self.currentSelection = currentSelection
        self.showIcons = showIcons
        self.onSelect = onSelect
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    public override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        animateIn()
    }

    private var computedHeight: CGFloat {
        let contentHeight = Self.headerHeight + Self.rowHeight * CGFloat(options.count) + Self.footerHeight
        let maxHeight = UIScreen.main.bounds.height * 0.9
        return min(contentHeight, maxHeight)
    }

    private func setupUI() {
        view.backgroundColor = .clear

        view.addSubview(dimmingView)
        dimmingView.snp.makeConstraints { make in make.edges.equalToSuperview() }

        view.addSubview(containerView)
        let finalHeight = computedHeight
        containerView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(finalHeight)
            containerBottomConstraint = make.bottom.equalToSuperview().offset(finalHeight).constraint
        }

        containerView.addSubview(dragIndicator)
        dragIndicator.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(LMKSpacing.small)
            make.centerX.equalToSuperview()
            make.width.equalTo(40)
            make.height.equalTo(5)
        }

        containerView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(LMKSpacing.xxl)
            make.leading.trailing.equalToSuperview().inset(LMKSpacing.xl)
        }

        containerView.addSubview(cancelButton)
        cancelButton.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(LMKSpacing.xl)
            make.bottom.equalToSuperview().inset(LMKSpacing.xl)
            make.height.equalTo(Self.buttonHeight)
        }

        containerView.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(LMKSpacing.large)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(cancelButton.snp.top).offset(-LMKSpacing.large)
        }
    }

    private func animateIn() {
        containerBottomConstraint?.update(offset: 0)
        let duration = LMKAnimationHelper.shouldAnimate ? LMKAnimationHelper.Duration.modalPresentation : 0
        UIView.animate(withDuration: duration, delay: 0, options: .curveEaseOut) {
            self.view.layoutIfNeeded()
            self.dimmingView.alpha = 1
        }
    }

    private func animateOut(completion: @escaping () -> Void) {
        containerBottomConstraint?.update(offset: computedHeight)
        let duration = LMKAnimationHelper.shouldAnimate ? LMKAnimationHelper.Duration.actionSheet : 0
        UIView.animate(withDuration: duration, delay: 0, options: .curveEaseIn) {
            self.view.layoutIfNeeded()
            self.dimmingView.alpha = 0
        } completion: { _ in completion() }
    }

    @objc private func cancelTapped() { dismissSheet() }
    @objc private func dimmingViewTapped() { dismissSheet() }

    private func dismissSheet() {
        animateOut { [weak self] in
            guard let self else { return }
            self.willMove(toParent: nil)
            self.view.removeFromSuperview()
            self.removeFromParent()
        }
    }

    // MARK: - UITableViewDataSource

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { options.count }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "LMKEnumSelectionCell", for: indexPath) as? LMKEnumSelectionCell else {
            fatalError("Failed to dequeue LMKEnumSelectionCell.")
        }
        let option = options[indexPath.row]
        cell.configure(with: option, isSelected: option == currentSelection, showIcon: showIcons)
        return cell
    }

    // MARK: - UITableViewDelegate

    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { Self.rowHeight }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        onSelect(options[indexPath.row])
        dismissSheet()
    }
}

// MARK: - Selection Cell

@MainActor
final class LMKEnumSelectionCell: UITableViewCell {
    private lazy var iconImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.tintColor = LMKColor.primary
        return iv
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = LMKTypography.body
        label.textColor = LMKColor.textPrimary
        return label
    }()

    private lazy var checkmarkImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(systemName: "checkmark")
        iv.tintColor = LMKColor.primary
        iv.contentMode = .scaleAspectFit
        iv.isHidden = true
        return iv
    }()

    private lazy var containerView: UIView = {
        let view = UIView()
        view.backgroundColor = LMKColor.backgroundSecondary
        view.layer.cornerRadius = LMKCornerRadius.small
        return view
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(containerView)
        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: LMKSpacing.xs, left: LMKSpacing.xl, bottom: LMKSpacing.xs, right: LMKSpacing.xl))
        }

        containerView.addSubview(iconImageView)
        iconImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(LMKSpacing.large)
            make.centerY.equalToSuperview()
            make.height.equalTo(LMKLayout.iconMedium)
            make.width.equalTo(LMKLayout.iconMedium)
        }

        containerView.addSubview(checkmarkImageView)
        checkmarkImageView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(LMKSpacing.large)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(LMKLayout.iconSmall)
        }

        containerView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconImageView.snp.trailing).offset(LMKSpacing.medium)
            make.centerY.equalToSuperview()
            make.trailing.lessThanOrEqualTo(checkmarkImageView.snp.leading).offset(-LMKSpacing.medium)
        }

        iconImageView.isHidden = true
    }

    func configure(with option: some LMKEnumSelectable, isSelected: Bool, showIcon: Bool = false) {
        titleLabel.text = option.displayName
        iconImageView.isHidden = !showIcon

        if showIcon {
            if let assetImage = UIImage(named: option.iconName) {
                iconImageView.image = assetImage
            } else if let sfSymbol = UIImage(systemName: option.iconName) {
                iconImageView.image = sfSymbol
            } else {
                iconImageView.image = UIImage(systemName: "circle.fill")
                iconImageView.tintColor = LMKColor.textSecondary
            }
            iconImageView.tintColor = LMKColor.primary
            iconImageView.snp.updateConstraints { make in make.width.equalTo(LMKLayout.iconMedium) }
            titleLabel.snp.remakeConstraints { make in
                make.leading.equalTo(iconImageView.snp.trailing).offset(LMKSpacing.medium)
                make.centerY.equalToSuperview()
                make.trailing.lessThanOrEqualTo(checkmarkImageView.snp.leading).offset(-LMKSpacing.medium)
            }
        } else {
            iconImageView.snp.updateConstraints { make in make.width.equalTo(0) }
            titleLabel.snp.remakeConstraints { make in
                make.leading.equalToSuperview().offset(LMKSpacing.large)
                make.centerY.equalToSuperview()
                make.trailing.lessThanOrEqualTo(checkmarkImageView.snp.leading).offset(-LMKSpacing.medium)
            }
        }

        checkmarkImageView.isHidden = !isSelected
        if isSelected {
            containerView.backgroundColor = LMKColor.primary.withAlphaComponent(0.1)
            titleLabel.font = LMKTypography.bodyMedium
        } else {
            containerView.backgroundColor = LMKColor.backgroundSecondary
            titleLabel.font = LMKTypography.body
        }
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        let duration = (animated && LMKAnimationHelper.shouldAnimate) ? LMKAnimationHelper.Duration.uiShort : 0
        UIView.animate(withDuration: duration) {
            if highlighted {
                self.containerView.backgroundColor = LMKColor.primary.withAlphaComponent(LMKAlpha.overlayMedium)
            } else {
                self.containerView.backgroundColor = self.checkmarkImageView.isHidden
                    ? LMKColor.backgroundSecondary
                    : LMKColor.primary.withAlphaComponent(LMKAlpha.overlayLight)
            }
        }
    }
}
