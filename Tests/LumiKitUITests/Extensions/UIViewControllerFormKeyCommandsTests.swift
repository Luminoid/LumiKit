//
//  UIViewControllerFormKeyCommandsTests.swift
//  LumiKit
//

import Testing
import UIKit
@testable import LumiKitUI

private final class FormViewController: UIViewController {
    var saveCount = 0
    var cancelCount = 0
    var includesCancel = true

    override var keyCommands: [UIKeyCommand]? {
        lmk_formKeyCommands(save: #selector(saveTapped), cancel: includesCancel ? #selector(cancelTapped) : nil)
    }

    @objc func saveTapped() {
        saveCount += 1
    }

    @objc func cancelTapped() {
        cancelCount += 1
    }
}

@MainActor
struct UIViewControllerFormKeyCommandsTests {
    @Test
    func `Command-Return saves and Escape cancels with localized titles`() throws {
        let vc = FormViewController()
        let commands = try #require(vc.keyCommands)
        #expect(commands.count == 2)
        let save = commands[0]
        #expect(save.input == "\r")
        #expect(save.modifierFlags == .command)
        #expect(save.title == LMKFormKeyCommands.Strings().save)
        #expect(save.action == #selector(FormViewController.saveTapped))
        let cancel = commands[1]
        #expect(cancel.input == UIKeyCommand.inputEscape)
        #expect(cancel.modifierFlags == [])
        #expect(cancel.title == LMKFormKeyCommands.Strings().cancel)
        #expect(cancel.action == #selector(FormViewController.cancelTapped))
    }

    @Test
    func `Nil selectors drop their command`() {
        let vc = FormViewController()
        vc.includesCancel = false
        #expect(vc.keyCommands?.count == 1)
        #expect(vc.keyCommands?.first?.input == "\r")
        #expect(UIViewController().lmk_formKeyCommands(save: nil, cancel: nil).isEmpty)
    }

    @Test
    func `The default cancel dismisses or pops`() {
        let commands = UIViewController().lmk_formKeyCommands(save: nil)
        #expect(commands.count == 1)
        #expect(commands.first?.action == #selector(UIViewController.lmk_cancelFromKeyCommand))

        let root = UIViewController()
        let navigation = UINavigationController(rootViewController: root)
        navigation.loadViewIfNeeded()
        let pushed = UIViewController()
        navigation.pushViewController(pushed, animated: false)
        #expect(navigation.viewControllers.count == 2)
        pushed.lmk_cancelFromKeyCommand()
        #expect(navigation.viewControllers.count == 1)
        root.lmk_cancelFromKeyCommand()
        #expect(navigation.viewControllers.count == 1, "the root stays")
    }

    @Test
    func `Custom strings title the commands`() {
        let strings = LMKFormKeyCommands.Strings(save: "Done", cancel: "Close")
        let commands = UIViewController().lmk_formKeyCommands(save: #selector(UIViewController.lmk_cancelFromKeyCommand), strings: strings)
        #expect(commands.map(\.title) == ["Done", "Close"])
    }
}
