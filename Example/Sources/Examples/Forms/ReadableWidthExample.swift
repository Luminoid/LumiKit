//
//  ReadableWidthExample.swift
//  LumiKitExample
//
//  Readable Width & Key Commands: lmk_pinReadableWidth, lmk_readableWidthGuide, lmk_formKeyCommands.
//

import LumiKitUI
import SnapKit
import UIKit

// MARK: - Readable Width & Key Commands

final class ReadableWidthDetailViewController: DetailViewController {
    private let pinnedBlock = UIView()
    private let guideBlock = UIView()
    private let readout = UILabel.lmk_make(.small, color: LMKColor.textSecondary)

    override var keyCommands: [UIKeyCommand]? {
        lmk_formKeyCommands(save: #selector(saveTapped), cancel: #selector(cancelTapped))
    }

    override func setupStackContent() {
        addSectionHeader("lmk_pinReadableWidth")
        stackView.addArrangedSubview(UILabel.lmk_make(
            .caption,
            text: "Content fills narrow screens inside the inset and caps at LMKLayout.readableContentMaxWidth on wide iPads and Mac windows, centered. "
                + "Rotate or resize the window to see the cap kick in."
        ))
        let container = UIView()
        container.backgroundColor = LMKColor.backgroundSecondary
        container.lmk_applyCornerRadius(LMKCornerRadius.medium)
        pinnedBlock.backgroundColor = LMKColor.primary.withAlphaComponent(LMKAlpha.small)
        pinnedBlock.lmk_applyCornerRadius(LMKCornerRadius.small)
        container.addSubview(pinnedBlock)
        pinnedBlock.lmk_pinReadableWidth()
        pinnedBlock.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(LMKSpacing.medium)
            make.height.equalTo(LMKLayout.rowHeightCompact)
        }
        stackView.addArrangedSubview(container)

        addSectionHeader("lmk_readableWidthGuide")
        stackView.addArrangedSubview(UILabel.lmk_make(.caption, text: "The same geometry as a layout guide on any view, for content that keeps its own constraints."))
        let guideHost = UIView()
        guideHost.backgroundColor = LMKColor.backgroundSecondary
        guideHost.lmk_applyCornerRadius(LMKCornerRadius.medium)
        guideBlock.backgroundColor = LMKColor.secondary.withAlphaComponent(LMKAlpha.small)
        guideBlock.lmk_applyCornerRadius(LMKCornerRadius.small)
        guideHost.addSubview(guideBlock)
        guideBlock.snp.makeConstraints { make in
            make.leading.trailing.equalTo(guideHost.lmk_readableWidthGuide)
            make.top.bottom.equalToSuperview().inset(LMKSpacing.medium)
            make.height.equalTo(LMKLayout.rowHeightCompact)
        }
        stackView.addArrangedSubview(guideHost)
        stackView.addArrangedSubview(readout)

        addDivider()
        addSectionHeader("lmk_formKeyCommands")
        stackView.addArrangedSubview(UILabel.lmk_make(
            .caption,
            text: "This page returns lmk_formKeyCommands(save:cancel:) from keyCommands: on an iPad or Mac with a hardware keyboard, "
                + "Command-Return saves and Escape cancels (the discoverability HUD lists both). Cancel defaults to dismissing the screen when no selector is given."
        ))
        stackView.addArrangedSubview(UILabel.lmk_make(
            .caption,
            text: "LMKScene.configureMacWindow(for:minimumSize:maximumSize:hidesTitleBar:) is called from this app's SceneDelegate; it is a no-op on iOS."
        ))
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        readout.lmk_setText("Page width \(Int(view.bounds.width)) pt, pinned block \(Int(pinnedBlock.bounds.width)) pt, guide block \(Int(guideBlock.bounds.width)) pt, "
            + "cap \(Int(LMKLayout.readableContentMaxWidth)) pt")
    }

    @objc private func saveTapped() {
        LMKToast.show(.success, "Saved (Command-Return)", in: self)
    }

    @objc private func cancelTapped() {
        LMKToast.show(.info, "Cancelled (Escape)", in: self)
    }
}
