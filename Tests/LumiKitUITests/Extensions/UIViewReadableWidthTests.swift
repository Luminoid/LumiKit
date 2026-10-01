//
//  UIViewReadableWidthTests.swift
//  LumiKit
//

import Testing
import UIKit
@testable import LumiKitUI

@MainActor
struct UIViewReadableWidthTests {
    private func layout(containerWidth: CGFloat, maxWidth: CGFloat? = nil, inset: CGFloat? = nil) -> (container: UIView, content: UIView) {
        let container = UIView(frame: CGRect(x: 0, y: 0, width: containerWidth, height: 200))
        let content = UIView()
        container.addSubview(content)
        content.lmk_pinReadableWidth(maxWidth: maxWidth, horizontalInset: inset)
        content.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
        }
        container.layoutIfNeeded()
        return (container, content)
    }

    @Test
    func `Fills a narrow container inside the inset`() {
        let (_, content) = layout(containerWidth: 390)
        #expect(content.frame.minX == LMKSpacing.large)
        #expect(content.frame.width == 390 - LMKSpacing.large * 2)
    }

    @Test
    func `Caps the width and centers on a wide container`() {
        let (_, content) = layout(containerWidth: 1200)
        #expect(content.frame.width == LMKLayout.readableContentMaxWidth)
        #expect(content.frame.midX == 600)
    }

    @Test
    func `Custom cap and inset`() {
        let (_, content) = layout(containerWidth: 500, maxWidth: 300, inset: 40)
        #expect(content.frame.width == 300)
        #expect(content.frame.midX == 250)
        let (_, narrow) = layout(containerWidth: 320, maxWidth: 300, inset: 40)
        #expect(narrow.frame.width == 240)
        #expect(narrow.frame.minX == 40)
    }

    @Test
    func `An explicit container works when the view sits deeper in the hierarchy`() {
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 1000, height: 100))
        let wrapper = UIView()
        container.addSubview(wrapper)
        wrapper.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        let content = UIView()
        wrapper.addSubview(content)
        content.lmk_pinReadableWidth(in: container)
        content.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
        }
        container.layoutIfNeeded()
        #expect(content.frame.width == LMKLayout.readableContentMaxWidth)
    }

    @Test
    func `Wide content inside a scroll view stays within the viewport`() {
        let scrollView = UIScrollView(frame: CGRect(x: 0, y: 0, width: 390, height: 400))
        let stack = UIStackView()
        stack.axis = .vertical
        let label = UILabel()
        label.text = String(repeating: "A long single-line value that wants far more than the screen. ", count: 6)
        stack.addArrangedSubview(label)
        scrollView.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
        }
        stack.lmk_pinReadableWidth(in: scrollView)
        scrollView.layoutIfNeeded()
        #expect(stack.frame.width == 390 - LMKSpacing.large * 2)
        #expect(scrollView.contentSize.width <= 390)
    }

    @Test
    func `Compressible content still fills the width`() {
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 390, height: 200))
        let stack = UIStackView()
        stack.axis = .horizontal
        let title = UILabel()
        title.text = "Title"
        let detail = UILabel()
        detail.text = "3"
        detail.setContentHuggingPriority(.required, for: .horizontal)
        detail.setContentCompressionResistancePriority(.required, for: .horizontal)
        stack.addArrangedSubview(title)
        stack.addArrangedSubview(detail)
        container.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
        }
        stack.lmk_pinReadableWidth()
        container.layoutIfNeeded()
        #expect(stack.frame.width == 390 - LMKSpacing.large * 2)
    }

    @Test
    func `The pin and the guide measure from the safe area, so a sidebar never covers the content`() {
        let host = UIViewController()
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 1000, height: 600))
        window.rootViewController = host
        window.makeKeyAndVisible()
        defer { window.isHidden = true }
        host.additionalSafeAreaInsets = UIEdgeInsets(top: 0, left: 300, bottom: 0, right: 0)
        let content = UIView()
        host.view.addSubview(content)
        content.lmk_pinReadableWidth(maxWidth: 400)
        content.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
        }
        let guide = host.view.lmk_readableWidthGuide
        host.view.layoutIfNeeded()
        // The safe area spans 300...1000.
        #expect(content.frame.width == 400)
        #expect(content.frame.midX == 650)
        #expect(guide.layoutFrame.minX >= 300 + LMKSpacing.large)
        #expect(guide.layoutFrame.midX == 650)
    }

    @Test
    func `The readable width guide is installed once and tracks the view width`() {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 1000, height: 100))
        let guide = view.lmk_readableWidthGuide
        #expect(view.lmk_readableWidthGuide === guide)
        #expect(view.layoutGuides.contains { $0 === guide })
        view.layoutIfNeeded()
        #expect(guide.layoutFrame.width == LMKLayout.readableContentMaxWidth)
        #expect(guide.layoutFrame.midX == 500)

        view.frame.size.width = 360
        view.layoutIfNeeded()
        #expect(guide.layoutFrame.width == 360 - LMKSpacing.large * 2)

        let content = UIView()
        view.addSubview(content)
        content.snp.makeConstraints { make in
            make.leading.trailing.equalTo(guide)
            make.top.bottom.equalToSuperview()
        }
        view.layoutIfNeeded()
        #expect(content.frame == guide.layoutFrame)
    }
}
