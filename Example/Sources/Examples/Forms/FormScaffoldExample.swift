//
//  FormScaffoldExample.swift
//  LumiKitExample
//
//  Form Scaffold: LMKFormScaffold: scroll and stack layout with keyboard avoidance.
//

import LumiKitUI
import UIKit

// MARK: - Form Scaffold

/// Deliberately a plain `UIViewController`, not a `DetailViewController`:
/// `LMKFormScaffold` exists for screens outside the
/// `LMKScrollStackViewController` hierarchy that still want the standard
/// scroll + stack form layout and keyboard behavior.
final class FormScaffoldDetailViewController: UIViewController {
    private struct FieldSpec {
        let placeholder: String
        let icon: String?
        let helper: String?
    }

    private static let fieldSpecs: [FieldSpec] = [
        FieldSpec(placeholder: "Full name", icon: "person", helper: nil),
        FieldSpec(placeholder: "Email", icon: "envelope", helper: "We'll never share your email."),
        FieldSpec(placeholder: "Phone", icon: "phone", helper: nil),
        FieldSpec(placeholder: "Street address", icon: "house", helper: nil),
        FieldSpec(placeholder: "City", icon: nil, helper: nil),
        FieldSpec(placeholder: "Postal code", icon: nil, helper: nil),
        FieldSpec(placeholder: "Company", icon: "building.2", helper: nil),
        FieldSpec(placeholder: "Notes", icon: "note.text", helper: "Focus this field: the scroll view lifts it clear of the keyboard."),
    ]

    private let scrollView = LMKFormScaffold.makeScrollView()
    private let contentStack = LMKFormScaffold.makeContentStack()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = LMKColor.backgroundPrimary
        LMKFormScaffold.install(scrollView: scrollView, stack: contentStack, in: view, widthMode: .readable)

        contentStack.addArrangedSubview(UILabel.lmk_make(
            .caption,
            text: "makeScrollView() + makeContentStack() + install(scrollView:stack:in:below:contentInsets:widthMode:) "
                + "build the standard form layout in three calls. Keyboard dismiss on drag and "
                + "keyboard-overlap avoidance come pre-installed; widthMode .readable keeps lines short on wide windows. "
                + "makeHeaderStack, installHeader, and makeFieldRow build the header and captioned rows."
        ))
        LMKFormScaffold.installHeader(LMKFormScaffold.makeHeaderStack(title: "Contact", subtitle: "Shown on your public profile"), in: contentStack)

        for spec in Self.fieldSpecs {
            let field = LMKTextField()
            field.placeholder = spec.placeholder
            if let icon = spec.icon {
                field.leadingIcon = UIImage(systemName: icon)
            }
            if let helper = spec.helper {
                field.helperText = helper
            }
            contentStack.addArrangedSubview(LMKFormScaffold.makeFieldRow(label: spec.placeholder, control: field))
        }
    }
}
