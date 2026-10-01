//
//  QRCodeExample.swift
//  LumiKitExample
//
//  QR Code: Generate QR codes from text.
//

import LumiKitUI
import SnapKit
import UIKit

// MARK: - QR Code

final class QRCodeDetailViewController: DetailViewController {
    private let imageView = UIImageView()
    private let textField = LMKTextField()

    override func setupStackContent() {
        addSectionHeader("Generator")
        textField.placeholder = "Enter text or URL..."
        textField.text = "https://github.com/Luminoid/LumiKit"
        textField.showsClearButton = true
        textField.onTextChange = { [weak self] _ in self?.generateQR() }
        textField.lmk_dismissKeyboardOnReturn()
        stackView.addArrangedSubview(textField)

        let generateButton = LMKButton(title: "Generate QR Code", style: .filled(.primary), target: self, action: #selector(generateQR))
        stackView.addArrangedSubview(generateButton)

        addDivider()
        addSectionHeader("Result")

        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = LMKColor.backgroundSecondary
        imageView.lmk_applyCornerRadius(LMKCornerRadius.medium)
        imageView.snp.makeConstraints { $0.height.equalTo(200) }
        stackView.addArrangedSubview(imageView)

        generateQR()

        addDivider()
        addSectionHeader("Correction Levels")
        let levels: [(String, LMKImage.QRCorrectionLevel)] = [
            ("Low (~7%)", .low),
            ("Medium (~15%)", .medium),
            ("Quartile (~25%)", .quartile),
            ("High (~30%)", .high),
        ]
        let levelRow = UIStackView(lmk_axis: .horizontal, spacing: LMKSpacing.small)
        levelRow.distribution = .fillEqually
        for (name, level) in levels {
            let col = UIStackView(lmk_axis: .vertical, spacing: LMKSpacing.xs)
            col.alignment = .center

            let qrImage = LMKImage.qrCode(from: "LumiKit", size: 80, correctionLevel: level)
            let qrView = UIImageView(image: qrImage)
            qrView.contentMode = .scaleAspectFit
            qrView.snp.makeConstraints { $0.width.height.equalTo(80) }

            let label = UILabel.lmk_make(.small, text: name)
            label.textAlignment = .center

            col.addArrangedSubview(qrView)
            col.addArrangedSubview(label)
            levelRow.addArrangedSubview(col)
        }
        stackView.addArrangedSubview(levelRow)
    }

    @objc private func generateQR() {
        let text = textField.text ?? ""
        imageView.image = LMKImage.qrCode(from: text, size: 200)
    }
}
