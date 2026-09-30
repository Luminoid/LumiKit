//
//  QRCodeExample.swift
//  LumiKitExample
//
//  QR Code: Generate QR codes from text.
//

import LumiKitCore
import LumiKitPhoto
import LumiKitUI
import PhotosUI
import SnapKit
import UIKit
import UniformTypeIdentifiers

// MARK: - QR Code

final class QRCodeDetailViewController: DetailViewController {
    private let imageView = UIImageView()
    private let textField = UITextField()

    override func viewDidLoad() {
        super.viewDidLoad()

        addSectionHeader("Generator")
        textField.placeholder = "Enter text or URL..."
        textField.text = "https://github.com/Luminoid/LumiKit"
        textField.borderStyle = .roundedRect
        textField.font = LMKTypography.body
        textField.clearButtonMode = .whileEditing
        textField.addTarget(self, action: #selector(generateQR), for: .editingChanged)
        textField.lmk_dismissKeyboardOnReturn()
        textField.snp.makeConstraints { $0.height.greaterThanOrEqualTo(LMKLayout.minimumTouchTarget) }
        stack.addArrangedSubview(textField)

        let generateButton = LMKButton(title: "Generate QR Code", style: .filled(.primary), target: self, action: #selector(generateQR))
        stack.addArrangedSubview(generateButton)

        addDivider()
        addSectionHeader("Result")

        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = LMKColor.backgroundSecondary
        imageView.layer.cornerRadius = LMKCornerRadius.medium
        imageView.clipsToBounds = true
        imageView.snp.makeConstraints { $0.height.equalTo(200) }
        stack.addArrangedSubview(imageView)

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
        stack.addArrangedSubview(levelRow)
    }

    @objc private func generateQR() {
        let text = textField.text ?? ""
        imageView.image = LMKImage.qrCode(from: text, size: 200)
    }
}
