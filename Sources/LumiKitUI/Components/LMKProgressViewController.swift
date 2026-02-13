//
//  LMKProgressViewController.swift
//  LumiKit
//
//  Blocking progress view controller for long-running operations.
//

import LumiKitCore
import SnapKit
import UIKit

/// Blocking progress view controller with activity indicator, progress bar, and cancel button.
@MainActor
public final class LMKProgressViewController: UIViewController {
    private static let containerWidth: CGFloat = 280
    private static let activityIndicatorTopOffset: CGFloat = 24
    private static let activityIndicatorToTitleSpacing: CGFloat = 16
    private static let horizontalInsets: CGFloat = 20
    private static let titleToTaskSpacing: CGFloat = 12
    private static let taskToProgressSpacing: CGFloat = 16
    private static let progressBarHeight: CGFloat = 4
    private static let progressToLabelSpacing: CGFloat = 8
    private static let labelToButtonSpacing: CGFloat = 16
    private static let bottomOffset: CGFloat = 24

    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = LMKColor.backgroundPrimary
        view.layer.cornerRadius = LMKCornerRadius.large
        let shadow = LMKShadow.card()
        view.layer.shadowColor = LMKColor.black.cgColor
        view.layer.shadowOpacity = shadow.opacity
        view.layer.shadowOffset = shadow.offset
        view.layer.shadowRadius = shadow.radius
        return view
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = LMKTypography.h3
        label.textColor = LMKColor.textPrimary
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private let taskLabel: UILabel = {
        let label = UILabel()
        label.font = LMKTypography.body
        label.textColor = LMKColor.textSecondary
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private let progressView: UIProgressView = {
        let pv = UIProgressView(progressViewStyle: .default)
        pv.progressTintColor = LMKColor.primary
        pv.trackTintColor = LMKColor.backgroundSecondary
        return pv
    }()

    private let progressLabel: UILabel = {
        let label = UILabel()
        label.font = LMKTypography.caption
        label.textColor = LMKColor.textSecondary
        label.textAlignment = .center
        return label
    }()

    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.color = LMKColor.primary
        indicator.hidesWhenStopped = true
        return indicator
    }()

    private lazy var cancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(LMKAlertPresenter.strings.cancel, for: .normal)
        button.titleLabel?.font = LMKTypography.body
        button.setTitleColor(LMKColor.textSecondary, for: .normal)
        button.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
        return button
    }()

    /// Callback when cancel button is tapped.
    public var onCancel: (() -> Void)?

    public init(title: String) {
        super.init(nibName: nil, bundle: nil)
        titleLabel.text = title
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        view.backgroundColor = LMKColor.black.withAlphaComponent(LMKAlpha.overlay)

        view.addSubview(containerView)
        containerView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalTo(Self.containerWidth)
        }

        containerView.addSubview(activityIndicator)
        activityIndicator.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(Self.activityIndicatorTopOffset)
            make.centerX.equalToSuperview()
        }

        containerView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(activityIndicator.snp.bottom).offset(Self.activityIndicatorToTitleSpacing)
            make.leading.trailing.equalToSuperview().inset(Self.horizontalInsets)
        }

        containerView.addSubview(taskLabel)
        taskLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(Self.titleToTaskSpacing)
            make.leading.trailing.equalToSuperview().inset(Self.horizontalInsets)
        }

        containerView.addSubview(progressView)
        progressView.snp.makeConstraints { make in
            make.top.equalTo(taskLabel.snp.bottom).offset(Self.taskToProgressSpacing)
            make.leading.trailing.equalToSuperview().inset(Self.horizontalInsets)
            make.height.equalTo(Self.progressBarHeight)
        }

        containerView.addSubview(progressLabel)
        progressLabel.snp.makeConstraints { make in
            make.top.equalTo(progressView.snp.bottom).offset(Self.progressToLabelSpacing)
            make.leading.trailing.equalToSuperview().inset(Self.horizontalInsets)
        }

        containerView.addSubview(cancelButton)
        cancelButton.snp.makeConstraints { make in
            make.top.equalTo(progressLabel.snp.bottom).offset(Self.labelToButtonSpacing)
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().offset(-Self.bottomOffset)
        }

        activityIndicator.startAnimating()
    }

    @objc private func cancelButtonTapped() { onCancel?() }

    /// Update progress and current task.
    public func updateProgress(_ progress: Float, task: String) {
        progressView.setProgress(progress, animated: true)
        taskLabel.text = task
        progressLabel.text = LMKFormatHelper.progressPercent(progress)
    }

    /// Update only the progress value.
    public func updateProgress(_ progress: Float) {
        progressView.setProgress(progress, animated: true)
        progressLabel.text = LMKFormatHelper.progressPercent(progress)
    }
}
