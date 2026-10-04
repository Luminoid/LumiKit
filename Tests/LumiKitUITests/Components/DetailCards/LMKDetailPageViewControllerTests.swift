//
//  LMKDetailPageViewControllerTests.swift
//  LumiKit
//

import Testing
import UIKit
@testable import LumiKitUI

@MainActor
struct LMKDetailPageViewControllerTests {
    private class Page: LMKDetailPageViewController {
        var cardModels: [LMKDetailCard] = [
            LMKDetailCard(id: "a", title: "A", rows: [.keyValue(.init(id: "k", key: "K", value: "1"))]),
            LMKDetailCard(id: "b", title: "B"),
        ]

        override func makeCards() -> [LMKDetailCard] {
            cardModels
        }
    }

    private final class BarPage: Page {
        let bar = LMKNavigationBar()
        override var navigationBar: LMKNavigationBar? { bar }
    }

    private func makePage<T: Page>(_ page: T = Page()) -> T {
        page.loadViewIfNeeded()
        page.view.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        page.view.layoutIfNeeded()
        return page
    }

    @Test
    func `Cards render in order with readable width and reload reconciles by id`() throws {
        let page = makePage()
        #expect(page.cards.map(\.id) == ["a", "b"])
        #expect(page.stackView.arrangedSubviews.compactMap { ($0 as? LMKDetailCardView)?.card?.id } == ["a", "b"])
        #expect(page.resolvedStyle.widthMode == .readable)
        let a = try #require(page.cardView(id: "a"))
        #expect(a.accessibilityIdentifier == "a")
        #expect((a.view(forRowID: "k") as? LMKDetailKeyValueRowView)?.valueLabel.text == "1")

        page.cardModels = [
            LMKDetailCard(id: "c", title: "C"),
            LMKDetailCard(id: "a", title: "A", rows: [.keyValue(.init(id: "k", key: "K", value: "2"))]),
        ]
        page.reloadCards()
        #expect(page.cards.map(\.id) == ["c", "a"])
        #expect(page.stackView.arrangedSubviews.compactMap { ($0 as? LMKDetailCardView)?.card?.id } == ["c", "a"])
        #expect(page.cardView(id: "a") === a, "the existing view is reconfigured, not replaced")
        #expect((a.view(forRowID: "k") as? LMKDetailKeyValueRowView)?.valueLabel.text == "2")
        #expect(page.cardView(id: "b") == nil)
        #expect(page.cardViews.count == 2)
    }

    @Test
    func `Hidden cards take no space`() {
        let page = makePage()
        page.cardModels = [LMKDetailCard(id: "a", title: "A"), LMKDetailCard(id: "b", header: .init(title: "B"), isHidden: true)]
        page.reloadCards()
        page.view.layoutIfNeeded()
        #expect(page.cardView(id: "b")?.isHidden == true)
        #expect(page.stackView.arrangedSubviews.count == 2)
    }

    @Test
    func `Edit and Share items go on the system navigation item and the edit flow swaps them`() throws {
        let page = makePage()
        #expect(page.navigationItem.rightBarButtonItems?.isEmpty ?? true)
        var edits = 0
        var shares = 0
        page.onEdit = { edits += 1 }
        page.onShare = { shares += 1 }
        let items = try #require(page.navigationItem.rightBarButtonItems)
        #expect(items.map(\.accessibilityIdentifier) == ["detailPage.edit", "detailPage.share"])
        #expect(items[0].accessibilityLabel == "Edit")
        #expect(items[1].image == UIImage(systemName: "square.and.arrow.up"))
        items[0].primaryAction?.performWithSender(nil, target: nil)
        #expect(edits == 1)

        var saved = 0
        var cancelled = 0
        page.beginEditing(onSave: { saved += 1 }, onCancel: { cancelled += 1 })
        #expect(page.isEditingDetail)
        let editing = try #require(page.navigationItem.rightBarButtonItems)
        #expect(editing.map(\.accessibilityIdentifier) == ["detailPage.cancel", "detailPage.save"])
        #expect(editing[1].title == "Save")
        #expect(editing[1].style == .done)
        let commands = try #require(page.keyCommands)
        #expect(commands.map(\.input) == ["\r", UIKeyCommand.inputEscape])
        #expect(page.canBecomeFirstResponder)
        editing[1].primaryAction?.performWithSender(nil, target: nil)
        #expect(saved == 1)
        #expect(page.isEditingDetail == false)
        #expect(page.navigationItem.rightBarButtonItems?.map(\.accessibilityIdentifier) == ["detailPage.edit", "detailPage.share"])
        #expect(page.keyCommands?.map(\.input) == ["e"], "back to Command-E for Edit")

        page.beginEditing(onSave: { saved += 1 }, onCancel: { cancelled += 1 })
        page.perform(NSSelectorFromString("cancelFromKeyCommand"))
        #expect(cancelled == 1)
        #expect(page.isEditingDetail == false)
        page.endEditing()
        page.onEdit = nil
        #expect(page.navigationItem.rightBarButtonItems?.map(\.accessibilityIdentifier) == ["detailPage.share"])
    }

    @Test
    func `onEdit adds Command-E, titled for the discoverability HUD, and nil removes it`() throws {
        let page = makePage()
        #expect(page.keyCommands?.isEmpty ?? true)
        #expect(!page.canBecomeFirstResponder)
        var edits = 0
        page.onEdit = { edits += 1 }
        let command = try #require(page.keyCommands?.first)
        #expect(command.input == "e")
        #expect(command.modifierFlags == .command)
        #expect(command.title == "Edit")
        #expect(command.discoverabilityTitle == nil || command.discoverabilityTitle == "Edit")
        #expect(page.canBecomeFirstResponder)
        page.perform(NSSelectorFromString("editFromKeyCommand"))
        #expect(edits == 1)

        page.strings = LMKDetailPageViewController.Strings(edit: "Modify")
        #expect(page.keyCommands?.first?.title == "Modify")

        // While editing, Command-E does nothing and the form commands take over.
        page.beginEditing(onSave: {}, onCancel: {})
        #expect(page.keyCommands?.map(\.input) == ["\r", UIKeyCommand.inputEscape])
        page.perform(NSSelectorFromString("editFromKeyCommand"))
        #expect(edits == 1)
        page.endEditing()

        page.onEdit = nil
        #expect(page.keyCommands?.isEmpty ?? true)
        #expect(!page.canBecomeFirstResponder)
    }

    /// Reads as focused, without taking first responder (which hangs the test host).
    private final class FocusedView: UIView {
        override var isFirstResponder: Bool {
            true
        }
    }

    @Test
    func `Appearing leaves a field elsewhere in the window focused; an edit the user starts takes the keyboard`() {
        let page = makePage()
        page.traitOverrides.userInterfaceIdiom = .pad
        // Set before the page is in a window, so nothing claims first responder here.
        page.onEdit = {}
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 1024, height: 768))
        let searchField = FocusedView()
        window.addSubview(searchField)
        window.isHidden = false
        defer { window.isHidden = true }
        // The host runs viewDidAppear as the view goes in, which is where the page claims.
        window.addSubview(page.view)
        #expect(page.traitCollection.userInterfaceIdiom == .pad)
        #expect(!page.isFirstResponder, "a split view's search field keeps the keyboard")
        #expect(!page.canClaimFirstResponder(overridingFocusElsewhere: false))
        #expect(page.canClaimFirstResponder(overridingFocusElsewhere: true), "an edit the user starts takes it")

        searchField.removeFromSuperview()
        #expect(page.canClaimFirstResponder(overridingFocusElsewhere: false))
        page.view.addSubview(searchField)
        #expect(!page.canClaimFirstResponder(overridingFocusElsewhere: true), "a field inside the page is editing")

        page.traitOverrides.userInterfaceIdiom = .phone
        searchField.removeFromSuperview()
        #expect(!page.canClaimFirstResponder(overridingFocusElsewhere: true), "never on the phone idiom")
    }

    @Test
    func `Bar item updates leave the host's leading items alone`() {
        let page = makePage()
        let close = UIBarButtonItem(systemItem: .close)
        page.navigationItem.leftBarButtonItem = close
        page.onEdit = {}
        page.onShare = {}
        #expect(page.navigationItem.leftBarButtonItem === close)
        page.beginEditing(onSave: {}, onCancel: {})
        #expect(page.navigationItem.leftBarButtonItem === close)
        page.strings = LMKDetailPageViewController.Strings(save: "Done")
        page.endEditing()
        #expect(page.navigationItem.leftBarButtonItem === close)
        page.onEdit = nil
        page.onShare = nil
        #expect(page.navigationItem.rightBarButtonItems == nil)
        #expect(page.navigationItem.leftBarButtonItem === close)
    }

    @Test
    func `With an LMKNavigationBar the items go on the bar, trailing first`() {
        let page = makePage(BarPage())
        page.onEdit = {}
        page.onShare = {}
        #expect(page.detailNavigationBar === page.bar)
        #expect(page.bar.rightItems.map(\.identifier) == ["detailPage.share", "detailPage.edit"])
        page.beginEditing(onSave: {}, onCancel: {})
        #expect(page.bar.rightItems.map(\.identifier) == ["detailPage.save", "detailPage.cancel"])
        #expect(page.bar.rightItems[0].role == .prominent)
        page.strings = LMKDetailPageViewController.Strings(save: "Done")
        #expect(page.bar.rightItems[0].title == "Done")
        page.endEditing()
        #expect(page.navigationItem.rightBarButtonItems?.isEmpty ?? true)
    }

    @Test
    func `cardStyle flows to every card view and scrollToCard targets a card`() {
        let page = makePage()
        page.cardStyle = LMKDetailCardView.Style(rowSpacing: 42)
        #expect(page.cardView(id: "a")?.style.rowSpacing == 42)
        page.cardModels.append(LMKDetailCard(id: "z", title: "Z"))
        page.reloadCards()
        #expect(page.cardView(id: "z")?.style.rowSpacing == 42)
        page.scrollToCard(id: "z", animated: false)
        page.scrollToCard(id: "missing", animated: false)
        #expect(LMKDetailPageViewController.Strings().edit == "Edit")
    }
}
