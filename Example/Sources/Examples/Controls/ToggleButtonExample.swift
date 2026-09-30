//
//  ToggleButtonExample.swift
//  LumiKitExample
//
//  Toggle Button: LMKButton.isToggle with on and off content.
//

import LumiKitUI
import SnapKit
import UIKit

// MARK: - Toggle Button

final class ToggleButtonDetailViewController: DetailViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        addSectionHeader("Basic")
        let toggleButton = LMKButton(title: "Notifications Off", image: UIImage(systemName: "bell.slash"), style: .tinted())
        toggleButton.isToggle = true
        toggleButton.selectedTitle = "Notifications On"
        toggleButton.selectedImage = UIImage(systemName: "bell.fill")
        toggleButton.onValueChange = { [weak self] isOn in
            guard let self else { return }
            LMKToast.show(.info, isOn ? "Notifications on" : "Notifications off", in: self)
        }
        let toggleRow = UIStackView(lmk_axis: .horizontal, alignment: .center, arrangedSubviews: [toggleButton, UIView()])
        stack.addArrangedSubview(toggleRow)
    }
}
