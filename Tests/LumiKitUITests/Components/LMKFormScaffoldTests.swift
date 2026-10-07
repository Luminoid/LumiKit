//
//  LMKFormScaffoldTests.swift
//  LumiKit
//

import SnapKit
import Testing
import UIKit
@testable import LumiKitUI

@MainActor
struct LMKFormScaffoldTests {
    private func makeHost() -> (UIViewController, UIWindow) {
        let host = UIViewController()
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 375, height: 812))
        window.rootViewController = host
        window.makeKeyAndVisible()
        return (host, window)
    }

    @Test
    func `Builders: scroll view, content stack, header, field label, field row`() {
        let scrollView = LMKFormScaffold.makeScrollView()
        #expect(scrollView.keyboardDismissMode == .onDrag)
        #expect(LMKFormScaffold.makeScrollView(keyboardDismissMode: .interactive).keyboardDismissMode == .interactive)

        let stack = LMKFormScaffold.makeContentStack()
        #expect(stack.axis == .vertical)
        #expect(stack.alignment == .fill)
        #expect(stack.spacing == LMKSpacing.large)
        #expect(LMKFormScaffold.makeContentStack(spacing: LMKSpacing.xl).spacing == LMKSpacing.xl)

        let header = LMKFormScaffold.makeHeaderStack(title: "Profile", subtitle: "Public details")
        #expect(header.arrangedSubviews.count == 2)
        #expect((header.arrangedSubviews.first as? UILabel)?.text == "Profile")
        #expect((header.arrangedSubviews.first as? UILabel)?.accessibilityTraits.contains(.header) == true)
        #expect((header.arrangedSubviews.last as? UILabel)?.lmk_textStyle == .caption)
        #expect(LMKFormScaffold.makeHeaderStack(title: "Only").arrangedSubviews.count == 1)

        let label = LMKFormScaffold.makeFieldLabel("Name")
        #expect(label.text == "Name")
        #expect(label.lmk_textStyle == .captionMedium)

        let field = LMKTextField()
        let row = LMKFormScaffold.makeFieldRow(label: "Email", control: field)
        #expect(row.axis == .vertical)
        #expect(row.arrangedSubviews.count == 2)
        #expect(row.arrangedSubviews.last === field)
        #expect(field.accessibilityLabel == "Email")

        stack.addArrangedSubview(UIView())
        LMKFormScaffold.installHeader(header, in: stack)
        #expect(stack.arrangedSubviews.first === header)
        #expect(stack.customSpacing(after: header) == LMKSpacing.xl)
    }

    @Test
    func `install pins the scroll view from the top (or below an anchor) to the bottom safe area`() {
        let (host, window) = makeHost()
        defer { window.isHidden = true }
        let scrollView = LMKFormScaffold.makeScrollView()
        let stack = LMKFormScaffold.makeContentStack()
        LMKFormScaffold.install(scrollView: scrollView, stack: stack, in: host.view)
        host.view.layoutIfNeeded()
        #expect(scrollView.superview === host.view)
        #expect(stack.superview === scrollView)
        #expect(scrollView.frame.minY == 0)
        #expect(scrollView.frame.width == host.view.bounds.width)
        #expect(scrollView.frame.maxY == host.view.bounds.height - host.view.safeAreaInsets.bottom)

        let other = UIViewController()
        window.rootViewController = other
        let bar = UIView()
        other.view.addSubview(bar)
        bar.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(64)
        }
        let belowScroll = LMKFormScaffold.makeScrollView()
        LMKFormScaffold.install(scrollView: belowScroll, stack: LMKFormScaffold.makeContentStack(), in: other.view, below: bar)
        other.view.layoutIfNeeded()
        #expect(belowScroll.frame.minY == 64)
    }

    @Test
    func `install keeps the stack clear of the side safe areas and the content as wide as the frame`() {
        let (host, window) = makeHost()
        defer { window.isHidden = true }
        host.additionalSafeAreaInsets = UIEdgeInsets(top: 0, left: 100, bottom: 0, right: 20)
        let scrollView = LMKFormScaffold.makeScrollView()
        let stack = LMKFormScaffold.makeContentStack()
        stack.addArrangedSubview(UILabel.lmk_make(.body, text: "Row"))
        LMKFormScaffold.install(scrollView: scrollView, stack: stack, in: host.view)
        host.view.layoutIfNeeded()
        let padding = LMKSpacing.cardPadding
        let frame = stack.convert(stack.bounds, to: host.view)
        #expect(frame.minX == 100 + padding)
        #expect(frame.maxX == host.view.bounds.width - 20 - padding)
        #expect(scrollView.contentSize.width == scrollView.bounds.width, "content never scrolls sideways")
    }

    @Test
    func `install applies token insets by default and honors custom ones`() {
        let (host, window) = makeHost()
        defer { window.isHidden = true }
        let scrollView = LMKFormScaffold.makeScrollView()
        let stack = LMKFormScaffold.makeContentStack()
        stack.addArrangedSubview(UILabel())
        LMKFormScaffold.install(scrollView: scrollView, stack: stack, in: host.view)
        host.view.layoutIfNeeded()
        let padding = LMKSpacing.cardPadding
        #expect(stack.frame.minX == padding)
        #expect(stack.frame.minY == padding)
        #expect(stack.frame.width == host.view.bounds.width - padding * 2)

        let other = UIViewController()
        window.rootViewController = other
        let customScroll = LMKFormScaffold.makeScrollView()
        let customStack = LMKFormScaffold.makeContentStack()
        customStack.addArrangedSubview(UILabel())
        LMKFormScaffold.install(scrollView: customScroll, stack: customStack, in: other.view, contentInsets: NSDirectionalEdgeInsets(top: 4, leading: 8, bottom: 12, trailing: 16))
        other.view.layoutIfNeeded()
        #expect(customStack.frame.minX == 8)
        #expect(customStack.frame.minY == 4)
        #expect(customStack.frame.width == other.view.bounds.width - 8 - 16)
    }

    @Test
    func `Width modes keep the stack readable or capped`() {
        let (host, window) = makeHost()
        defer { window.isHidden = true }
        let scrollView = LMKFormScaffold.makeScrollView()
        let stack = LMKFormScaffold.makeContentStack()
        stack.addArrangedSubview(UILabel())
        LMKFormScaffold.install(scrollView: scrollView, stack: stack, in: host.view, widthMode: .capped(maxWidth: 200, horizontalInset: 10))
        host.view.layoutIfNeeded()
        #expect(stack.frame.width == 200)
        #expect(abs(stack.frame.midX - 375 / 2) < 1)

        let wide = UIViewController()
        window.rootViewController = wide
        let wideScroll = LMKFormScaffold.makeScrollView()
        let wideStack = LMKFormScaffold.makeContentStack()
        wideStack.addArrangedSubview(UILabel())
        LMKFormScaffold.install(scrollView: wideScroll, stack: wideStack, in: wide.view, widthMode: .capped(maxWidth: 1000, horizontalInset: 10))
        wide.view.layoutIfNeeded()
        #expect(wideStack.frame.width == 355)
        // The scroll content edges float, so a required cap against the safe area (a frame-sized
        // guide) is what keeps a content-size chain from widening the stack past the screen.
        let cap = wideScroll.constraints.first {
            $0.firstItem === wideStack && $0.firstAttribute == .width && $0.relation == .lessThanOrEqual
                && $0.secondItem === wideScroll.safeAreaLayoutGuide && $0.secondAttribute == .width
        }
        #expect(cap?.constant == -20)
        #expect(cap?.priority == .required)

        let other = UIViewController()
        window.rootViewController = other
        let readableScroll = LMKFormScaffold.makeScrollView()
        let readableStack = LMKFormScaffold.makeContentStack()
        readableStack.addArrangedSubview(UILabel())
        LMKFormScaffold.install(scrollView: readableScroll, stack: readableStack, in: other.view, widthMode: .readable)
        other.view.layoutIfNeeded()
        let guide = readableScroll.readableContentGuide.layoutFrame
        #expect(readableStack.frame.minX >= guide.minX)
        #expect(readableStack.frame.maxX <= guide.maxX)
    }

    @Test
    func `Readable mode holds still when the page's root layout margins collapse`() {
        // The iOS 26 interactive swipe back zeroes the revealed page's trailing layout margin, and
        // content pinned to the root view's readable guide stretches with it. Both readable paths
        // read their own container's guide, whose margins do not follow the root's.
        let (host, window) = makeHost()
        defer { window.isHidden = true }
        let scrollView = LMKFormScaffold.makeScrollView()
        let stack = LMKFormScaffold.makeContentStack()
        stack.addArrangedSubview(UILabel())
        LMKFormScaffold.install(scrollView: scrollView, stack: stack, in: host.view, widthMode: .readable)
        let page = LMKScrollStackViewController(style: .init(widthMode: .readable))
        host.addChild(page)
        host.view.addSubview(page.view)
        page.view.frame = host.view.bounds
        page.didMove(toParent: host)
        page.stackView.addArrangedSubview(UILabel())
        host.view.layoutIfNeeded()
        let scaffoldFrame = stack.frame
        let pageFrame = page.stackView.frame

        for controller in [host, page] {
            controller.viewRespectsSystemMinimumLayoutMargins = false
            controller.view.directionalLayoutMargins.trailing = 0
        }
        host.view.layoutIfNeeded()
        #expect(host.view.readableContentGuide.layoutFrame.maxX == host.view.bounds.width, "the root guide stretches")
        #expect(stack.frame == scaffoldFrame)
        #expect(page.stackView.frame == pageFrame)
    }

    @Test
    func `The made scroll view grows its inset for the keyboard`() {
        let (host, window) = makeHost()
        defer { window.isHidden = true }
        let scrollView = LMKFormScaffold.makeScrollView()
        let stack = LMKFormScaffold.makeContentStack()
        let field = UITextField()
        stack.addArrangedSubview(field)
        LMKFormScaffold.install(scrollView: scrollView, stack: stack, in: host.view)
        host.view.layoutIfNeeded()
        field.becomeFirstResponder()
        defer { field.resignFirstResponder() }

        NotificationCenter.default.post(
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil,
            userInfo: [
                UIResponder.keyboardFrameEndUserInfoKey: NSValue(cgRect: CGRect(x: 0, y: 812 - 300, width: 375, height: 300)),
                UIResponder.keyboardAnimationDurationUserInfoKey: 0.0,
            ]
        )
        #expect(scrollView.contentInset.bottom > 0)
        NotificationCenter.default.post(name: UIResponder.keyboardWillHideNotification, object: nil, userInfo: [UIResponder.keyboardAnimationDurationUserInfoKey: 0.0])
        #expect(scrollView.contentInset.bottom == 0)
    }
}
