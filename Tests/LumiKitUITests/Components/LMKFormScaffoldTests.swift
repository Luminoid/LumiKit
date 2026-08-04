//
//  LMKFormScaffoldTests.swift
//  LumiKit
//

import SnapKit
import Testing
import UIKit
@testable import LumiKitUI

// MARK: - LMKFormScaffold

@MainActor
struct LMKFormScaffoldTests {
    @Test
    func `makeScrollView defaults to keyboard dismiss on drag`() {
        let scrollView = LMKFormScaffold.makeScrollView()
        #expect(scrollView.keyboardDismissMode == .onDrag)
    }

    @Test
    func `makeScrollView honors a custom keyboard dismiss mode`() {
        let scrollView = LMKFormScaffold.makeScrollView(keyboardDismissMode: .interactive)
        #expect(scrollView.keyboardDismissMode == .interactive)
    }

    @Test
    func `makeContentStack is a vertical fill stack with token spacing`() {
        let stack = LMKFormScaffold.makeContentStack()
        #expect(stack.axis == .vertical)
        #expect(stack.alignment == .fill)
        #expect(stack.spacing == LMKSpacing.large)

        let custom = LMKFormScaffold.makeContentStack(spacing: LMKSpacing.xl)
        #expect(custom.spacing == LMKSpacing.xl)
    }

    @Test
    func `install pins the scroll view from the view top to the bottom safe area`() {
        let host = UIViewController()
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 375, height: 812))
        window.rootViewController = host
        window.makeKeyAndVisible()

        let scrollView = LMKFormScaffold.makeScrollView()
        let stack = LMKFormScaffold.makeContentStack()
        LMKFormScaffold.install(scrollView: scrollView, stack: stack, in: host.view)
        host.view.layoutIfNeeded()

        #expect(scrollView.superview === host.view)
        #expect(stack.superview === scrollView)
        #expect(scrollView.frame.minY == 0)
        #expect(scrollView.frame.width == host.view.bounds.width)
        #expect(scrollView.frame.maxY == host.view.bounds.height - host.view.safeAreaInsets.bottom)
    }

    @Test
    func `install pins the scroll view below the top anchor view`() {
        let host = UIViewController()
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 375, height: 812))
        window.rootViewController = host
        window.makeKeyAndVisible()

        let bar = UIView()
        host.view.addSubview(bar)
        bar.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(64)
        }

        let scrollView = LMKFormScaffold.makeScrollView()
        let stack = LMKFormScaffold.makeContentStack()
        LMKFormScaffold.install(scrollView: scrollView, stack: stack, in: host.view, below: bar)
        host.view.layoutIfNeeded()

        #expect(scrollView.frame.minY == 64)
    }

    @Test
    func `install applies token content insets to the stack`() {
        let host = UIViewController()
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 375, height: 812))
        window.rootViewController = host
        window.makeKeyAndVisible()

        let scrollView = LMKFormScaffold.makeScrollView()
        let stack = LMKFormScaffold.makeContentStack()
        stack.addArrangedSubview(UILabel())
        LMKFormScaffold.install(scrollView: scrollView, stack: stack, in: host.view)
        host.view.layoutIfNeeded()

        let padding = LMKSpacing.cardPadding
        #expect(stack.frame.minX == padding)
        #expect(stack.frame.minY == padding)
        #expect(stack.frame.width == host.view.bounds.width - padding * 2)
    }

    @Test
    func `install honors custom content insets`() {
        let host = UIViewController()
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 375, height: 812))
        window.rootViewController = host
        window.makeKeyAndVisible()

        let scrollView = LMKFormScaffold.makeScrollView()
        let stack = LMKFormScaffold.makeContentStack()
        stack.addArrangedSubview(UILabel())
        let insets = UIEdgeInsets(top: 4, left: 8, bottom: 12, right: 16)
        LMKFormScaffold.install(scrollView: scrollView, stack: stack, in: host.view, contentInsets: insets)
        host.view.layoutIfNeeded()

        #expect(stack.frame.minX == 8)
        #expect(stack.frame.minY == 4)
        #expect(stack.frame.width == host.view.bounds.width - 8 - 16)
    }

    @Test
    func `made scroll view grows its inset for the keyboard`() {
        let host = UIViewController()
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 375, height: 812))
        window.rootViewController = host
        window.makeKeyAndVisible()

        let scrollView = LMKFormScaffold.makeScrollView()
        let stack = LMKFormScaffold.makeContentStack()
        let field = UITextField()
        stack.addArrangedSubview(field)
        LMKFormScaffold.install(scrollView: scrollView, stack: stack, in: host.view)
        host.view.layoutIfNeeded()
        field.becomeFirstResponder()
        defer { field.resignFirstResponder() }

        let keyboardFrame = CGRect(x: 0, y: 812 - 300, width: 375, height: 300)
        NotificationCenter.default.post(
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil,
            userInfo: [
                UIResponder.keyboardFrameEndUserInfoKey: NSValue(cgRect: keyboardFrame),
                UIResponder.keyboardAnimationDurationUserInfoKey: 0.0,
            ]
        )
        #expect(scrollView.contentInset.bottom > 0)

        NotificationCenter.default.post(
            name: UIResponder.keyboardWillHideNotification,
            object: nil,
            userInfo: [UIResponder.keyboardAnimationDurationUserInfoKey: 0.0]
        )
        #expect(scrollView.contentInset.bottom == 0)
    }
}
