//
//  BannerExample.swift
//  LumiKitExample
//
//  Banners: Inline or over a screen, with an action.
//

import LumiKitUI
import UIKit

// MARK: - Banner

final class BannerDetailViewController: DetailViewController {
    override func setupStackContent() {
        addSectionHeader("Inline")
        stackView.addArrangedSubview(UILabel.lmk_make(.caption, text: "Added to a stack, a banner is part of the layout: the rows under it move up when it is dismissed."))
        stackView.addArrangedSubview(makeBanner(.info, "A new version is ready to install.", action: "Update"))
        stackView.addArrangedSubview(makeBanner(.success, "Backup finished a minute ago."))
        let persistent = makeBanner(.warning, "No internet connection", action: "Retry")
        persistent.showsDismissButton = false
        stackView.addArrangedSubview(persistent)
        stackView.addArrangedSubview(makeBanner(.error, "The last three changes could not be saved. They are kept on this device and will be sent again when the server answers."))

        addDivider()
        addSectionHeader("Over the screen")
        stackView.addArrangedSubview(UILabel.lmk_make(
            .caption,
            text: "show(in:) floats the banner under the navigation bar and adds its height to the scroll view's top inset, so the page starts under the banner and scrolls beneath it."
        ))
        let samples: [(String, LMKButton.Role, LMKStatus, String)] = [
            ("Info", .info, .info, "Sync finished on your other devices."),
            ("Warning", .warning, .warning, "Storage is almost full."),
            ("Error", .destructive, .error, "The upload failed. Check your connection and try again."),
            ("Success", .success, .success, "Your changes are saved."),
        ]
        for (name, role, status, message) in samples {
            stackView.addArrangedSubview(LMKButton(title: "Show \(name) Banner", style: .outlined(role)) { [weak self] in
                guard let self else { return }
                makeBanner(status, message, action: "Action").show(in: self)
            })
        }

        addDivider()
        addSectionHeader("Custom style")
        stackView.addArrangedSubview(UILabel.lmk_make(.caption, text: "Style.surface swaps the background, border, corners, and shadow; theme.banner sets them app-wide."))
        let custom = LMKBannerView(status: .neutral, message: "Tinted with the brand color, capsule corners, no border.", style: LMKBannerView.Style(
            surface: LMKSurfaceStyle(
                background: .solid(LMKColor.primary.lmk_composited(over: LMKColor.backgroundPrimary, alpha: LMKAlpha.xs)),
                corners: .capsule,
                border: LMKBorderStyle.hidden
            ),
            messageColor: LMKColor.primary
        ))
        stackView.addArrangedSubview(custom)
    }

    private func makeBanner(_ status: LMKStatus, _ message: String, action: String? = nil) -> LMKBannerView {
        let banner = LMKBannerView(status: status, message: message)
        banner.actionTitle = action
        banner.onAction = { [weak self] in
            guard let self else { return }
            LMKToast.show(.info, "Banner action tapped", in: self)
        }
        return banner
    }
}
