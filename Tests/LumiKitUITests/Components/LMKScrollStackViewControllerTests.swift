//
//  LMKScrollStackViewControllerTests.swift
//  LumiKit
//

import Testing
import UIKit
@testable import LumiKitUI

private final class TestScrollVC: LMKScrollStackViewController {
    var setupCalls = 0

    override func setupStackContent() {
        setupCalls += 1
        stackView.addArrangedSubview(UILabel.lmk_make(.body, text: "Row \(setupCalls)"))
    }
}

private final class NavBarScrollVC: LMKScrollStackViewController {
    private lazy var bar: LMKNavigationBar = {
        let bar = LMKNavigationBar()
        bar.title = "Details"
        return bar
    }()

    override var navigationBar: LMKNavigationBar? { bar }
}

private final class NoKeyboardAdjustmentVC: LMKScrollStackViewController {
    override var installsKeyboardAdjustment: Bool { false }
}

private final class RefreshingVC: LMKScrollStackViewController {
    override func makeRefreshControl() -> UIRefreshControl? {
        UIRefreshControl()
    }
}

@MainActor
struct LMKScrollStackViewControllerTests {
    private func host(_ controller: UIViewController) -> UIWindow {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 375, height: 812))
        window.rootViewController = controller
        window.makeKeyAndVisible()
        controller.loadViewIfNeeded()
        controller.view.layoutIfNeeded()
        return window
    }

    @Test
    func `Default layout: token insets, large spacing, safe-area bottom, drag dismiss`() {
        let controller = TestScrollVC()
        let window = host(controller)
        defer { window.isHidden = true }
        #expect(controller.scrollView.superview === controller.view)
        #expect(controller.contentView.superview === controller.scrollView)
        #expect(controller.stackView.superview === controller.contentView)
        #expect(controller.stackView.axis == .vertical)
        #expect(controller.stackView.alignment == .fill)
        #expect(controller.stackView.spacing == LMKSpacing.large)
        #expect(controller.scrollView.keyboardDismissMode == .onDrag)
        #expect(!controller.scrollView.alwaysBounceVertical)
        #expect(controller.view.backgroundColor === LMKColor.backgroundPrimary)
        #expect(controller.setupCalls == 1)
        let padding = LMKSpacing.cardPadding
        #expect(controller.stackView.frame.minX == padding)
        #expect(controller.stackView.frame.minY == padding)
        #expect(controller.stackView.frame.width == 375 - padding * 2)
        #expect(controller.scrollView.frame.maxY == controller.view.bounds.height - controller.view.safeAreaInsets.bottom)
        #expect(controller.refreshControl == nil)
    }

    @Test
    func `Style controls spacing, insets, scroll behavior, and the bottom anchor`() {
        let controller = TestScrollVC(style: LMKScrollStackViewController.Style(
            stackSpacing: LMKSpacing.xl,
            contentInsets: NSDirectionalEdgeInsets(top: 4, leading: 8, bottom: 12, trailing: 16),
            backgroundColor: .red,
            keyboardDismissMode: .interactive,
            alwaysBounceVertical: true,
            bottomAnchor: .superview
        ))
        let window = host(controller)
        defer { window.isHidden = true }
        #expect(controller.stackView.spacing == LMKSpacing.xl)
        #expect(controller.scrollView.keyboardDismissMode == .interactive)
        #expect(controller.scrollView.alwaysBounceVertical)
        #expect(controller.view.backgroundColor == UIColor.red)
        #expect(controller.stackView.frame.minX == 8)
        #expect(controller.stackView.frame.minY == 4)
        #expect(controller.stackView.frame.width == 351)
        #expect(controller.scrollView.frame.maxY == controller.view.bounds.height)

        controller.style.bottomAnchor = .safeArea
        controller.view.layoutIfNeeded()
        #expect(controller.scrollView.frame.maxY == controller.view.bounds.height - controller.view.safeAreaInsets.bottom)
    }

    @Test
    func `Width modes: readable guide and capped width`() {
        let readable = TestScrollVC(style: LMKScrollStackViewController.Style(widthMode: .readable))
        let window = host(readable)
        defer { window.isHidden = true }
        let guide = readable.contentView.readableContentGuide.layoutFrame
        #expect(readable.stackView.frame.minX >= guide.minX)
        #expect(readable.stackView.frame.maxX <= guide.maxX)

        readable.style.widthMode = .capped(maxWidth: 200, horizontalInset: 10)
        readable.view.layoutIfNeeded()
        #expect(readable.stackView.frame.width == 200)
        #expect(abs(readable.stackView.frame.midX - 375 / 2) < 1)

        readable.style.widthMode = .capped(maxWidth: 1000, horizontalInset: 10)
        readable.view.layoutIfNeeded()
        #expect(readable.stackView.frame.width == 355, "the inset wins once the cap is wider than the host")
    }

    @Test
    func `reloadContent empties the stack and rebuilds it`() {
        let controller = TestScrollVC()
        controller.loadViewIfNeeded()
        #expect(controller.stackView.arrangedSubviews.count == 1)
        controller.reloadContent()
        #expect(controller.setupCalls == 2)
        #expect(controller.stackView.arrangedSubviews.count == 1)
        #expect((controller.stackView.arrangedSubviews.first as? UILabel)?.text == "Row 2")
    }

    @Test
    func `Section headers and dividers`() {
        let controller = TestScrollVC()
        controller.loadViewIfNeeded()
        let header = controller.addSectionHeader("Test Header")
        #expect(header.text == "Test Header")
        #expect(header.accessibilityTraits.contains(.header))
        #expect(header.lmk_textStyle == .h3)
        #expect(controller.stackView.arrangedSubviews.last === header)
        let divider = controller.addDivider()
        #expect(controller.stackView.arrangedSubviews.last === divider)

        controller.style.sectionHeaderColor = .purple
        #expect(header.textColor == UIColor.purple)
    }

    @Test
    func `A custom navigation bar is installed above the scroll view`() throws {
        let controller = NavBarScrollVC()
        let window = host(controller)
        defer { window.isHidden = true }
        let bar = try #require(controller.navigationBar)
        #expect(bar.superview === controller.view)
        #expect(bar.frame.minY == 0)
        #expect(bar.frame.width == controller.view.bounds.width)
        #expect(bar.frame.height > 0)
        #expect(abs(controller.scrollView.frame.minY - bar.frame.maxY) < 0.001)
    }

    @Test
    func `makeRefreshControl installs pull-to-refresh outside the Mac idiom`() {
        let controller = RefreshingVC()
        controller.loadViewIfNeeded()
        if controller.traitCollection.userInterfaceIdiom == .mac {
            #expect(controller.refreshControl == nil)
        } else {
            #expect(controller.refreshControl != nil)
            #expect(controller.scrollView.refreshControl === controller.refreshControl)
        }
    }

    @Test
    func `Keyboard adjustment grows and restores the scroll inset, unless opted out`() {
        let controller = TestScrollVC()
        let window = host(controller)
        defer { window.isHidden = true }
        let field = UITextField()
        controller.stackView.addArrangedSubview(field)
        controller.view.layoutIfNeeded()
        field.becomeFirstResponder()
        defer { field.resignFirstResponder() }

        let keyboardFrame = CGRect(x: 0, y: 812 - 300, width: 375, height: 300)
        let info: [AnyHashable: Any] = [
            UIResponder.keyboardFrameEndUserInfoKey: NSValue(cgRect: keyboardFrame),
            UIResponder.keyboardAnimationDurationUserInfoKey: 0.0,
        ]
        NotificationCenter.default.post(name: UIResponder.keyboardWillChangeFrameNotification, object: nil, userInfo: info)
        #expect(controller.scrollView.contentInset.bottom > 0)
        NotificationCenter.default.post(name: UIResponder.keyboardWillHideNotification, object: nil, userInfo: [UIResponder.keyboardAnimationDurationUserInfoKey: 0.0])
        #expect(controller.scrollView.contentInset.bottom == 0)

        let optedOut = NoKeyboardAdjustmentVC()
        window.rootViewController = optedOut
        optedOut.loadViewIfNeeded()
        let otherField = UITextField()
        optedOut.stackView.addArrangedSubview(otherField)
        optedOut.view.layoutIfNeeded()
        otherField.becomeFirstResponder()
        defer { otherField.resignFirstResponder() }
        NotificationCenter.default.post(name: UIResponder.keyboardWillChangeFrameNotification, object: nil, userInfo: info)
        #expect(optedOut.scrollView.contentInset.bottom == 0)
    }

    @Test
    func `theme.scrollStack supplies app-wide defaults`() {
        var theme = LMKTheme()
        theme.scrollStack = LMKScrollStackViewController.Style(stackSpacing: 33, backgroundColor: .magenta)
        let controller = TestScrollVC()
        let window = LMKThemeTesting.host(controller.view, theme: theme)
        defer { window.isHidden = true }
        controller.applyTheme(theme)
        #expect(controller.stackView.spacing == 33)
        #expect(controller.view.backgroundColor == UIColor.magenta)
    }
}
