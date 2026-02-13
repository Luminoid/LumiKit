//
//  LMKLoadingStateView.swift
//  LumiKit
//
//  Reusable loading state view component with optional overlay style.
//

import SnapKit
import UIKit

/// Reusable loading state view for displaying loading indicators.
/// Supports inline (clear background) and overlay (dimmed full-screen) styles.
public final class LMKLoadingStateView: UIView {
    private static var activityIndicatorVerticalOffset: CGFloat { -LMKSpacing.xl }

    private let activityIndicator: UIActivityIndicatorView
    private let messageLabel = UILabel()

    /// Create a loading state view.
    /// - Parameters:
    ///   - frame: View frame.
    ///   - overlayStyle: When `true`, uses dimmed background for full-screen overlay.
    public init(frame: CGRect = .zero, overlayStyle: Bool = false) {
        let style: UIActivityIndicatorView.Style = overlayStyle ? .large : .medium
        activityIndicator = UIActivityIndicatorView(style: style)
        super.init(frame: frame)
        backgroundColor = overlayStyle ? LMKColor.backgroundPrimary.withAlphaComponent(LMKAlpha.overlayOpaque) : .clear
        setupUI()
    }

    override public init(frame: CGRect) {
        activityIndicator = UIActivityIndicatorView(style: .medium)
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        activityIndicator = UIActivityIndicatorView(style: .medium)
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        if backgroundColor == nil || backgroundColor == .clear {
            backgroundColor = .clear
        }

        activityIndicator.color = LMKColor.primary
        activityIndicator.hidesWhenStopped = true
        addSubview(activityIndicator)
        activityIndicator.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(Self.activityIndicatorVerticalOffset)
        }

        messageLabel.font = LMKTypography.body
        messageLabel.textColor = LMKColor.textSecondary
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0
        messageLabel.isHidden = true
        addSubview(messageLabel)
        messageLabel.snp.makeConstraints { make in
            make.top.equalTo(activityIndicator.snp.bottom).offset(LMKSpacing.medium)
            make.leading.trailing.equalToSuperview().inset(LMKSpacing.xl)
            make.centerX.equalToSuperview()
        }
    }

    /// Start loading animation.
    public func startLoading(message: String) {
        isHidden = false
        activityIndicator.startAnimating()
        if !message.isEmpty {
            messageLabel.text = message
            messageLabel.isHidden = false
        } else {
            messageLabel.isHidden = true
        }
    }

    /// Stop loading animation.
    public func stopLoading() {
        activityIndicator.stopAnimating()
        isHidden = true
    }

    /// Update the loading message.
    public func updateMessage(_ message: String) {
        messageLabel.text = message
        messageLabel.isHidden = false
    }
}
