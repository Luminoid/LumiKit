//
//  LMKDetailPageViewController.swift
//  LumiKit
//
//  A scroll-stack page of `LMKDetailCard`s diffed by id: subclasses describe
//  the cards, the page keeps their views across reloads, installs Edit and
//  Share items (and Command-E) on whichever navigation bar it has, and offers
//  an edit mode with Save / Cancel items and key commands.
//

import UIKit

/// A detail page of cards.
///
/// ```swift
/// final class PlantDetailViewController: LMKDetailPageViewController {
///     override func makeCards() -> [LMKDetailCard] { [headerCard, careCard, photosCard] }
///
///     override func viewDidLoad() {
///         super.viewDidLoad()
///         onEdit = { [weak self] in self?.presentEditForm() }
///         onShare = { [weak self] in self?.share() }
///     }
/// }
/// ```
///
/// `reloadCards()` calls `makeCards()` again and reconciles by id: existing card views are
/// reconfigured in place (a photo strip keeps its tiles), new ones are inserted, missing ones
/// removed, and the order follows the new array. Cards with `isHidden` take no space.
open class LMKDetailPageViewController: LMKScrollStackViewController {
    // MARK: - Strings

    public nonisolated struct Strings: Sendable, Equatable {
        public var edit: String
        public var share: String
        public var save: String
        public var cancel: String

        public init(
            edit: String = LMKLocalized("detailPage.edit"),
            share: String = LMKLocalized("detailPage.share"),
            save: String = LMKLocalized("detailPage.save"),
            cancel: String = LMKLocalized("detailPage.cancel")
        ) {
            self.edit = edit
            self.share = share
            self.save = save
            self.cancel = cancel
        }
    }

    /// Process-wide defaults; set at app launch to override.
    public nonisolated(unsafe) static var strings = Strings()

    /// Per-instance strings (default `Self.strings`).
    public var strings: Strings = LMKDetailPageViewController.strings {
        didSet { updateBarItems() }
    }

    // MARK: - Properties

    /// The cards last built by `makeCards()`.
    public private(set) var cards: [LMKDetailCard] = []
    /// The card views by card id.
    public private(set) var cardViews: [String: LMKDetailCardView] = [:]

    /// Per-page card style layered under every card's own.
    public var cardStyle = LMKDetailCardView.Style() {
        didSet {
            for view in cardViews.values {
                view.style = cardStyle
            }
        }
    }

    /// Installs an Edit item (`pencil`) and a Command-E key command (titled `strings.edit` in the
    /// discoverability HUD) that call it; `nil` removes both. On iPad and Mac the page takes first
    /// responder when it appears, unless a field anywhere in the window is editing (a split view's
    /// search field keeps the keyboard), so the command works before anything is focused.
    public var onEdit: (() -> Void)? {
        didSet {
            updateBarItems()
            if onEdit != nil, oldValue == nil {
                claimFirstResponderIfIdle(overridingFocusElsewhere: false)
            }
        }
    }

    /// Installs a Share item (`square.and.arrow.up`) that calls it; `nil` removes the item.
    public var onShare: (() -> Void)? {
        didSet { updateBarItems() }
    }

    /// Whether `beginEditing(onSave:onCancel:)` is in progress.
    public private(set) var isEditingDetail = false

    /// The `LMKNavigationBar` the items go on (`navigationItem` otherwise). Read after `viewDidLoad`.
    public var detailNavigationBar: LMKNavigationBar? {
        navigationBar
    }

    private var onSave: (() -> Void)?
    private var onCancelEditing: (() -> Void)?

    // MARK: - Initialization

    /// Readable width by default.
    override public init(style: LMKScrollStackViewController.Style = LMKScrollStackViewController.Style(widthMode: .readable)) {
        super.init(style: style)
    }

    // MARK: - Lifecycle

    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if onEdit != nil || isEditingDetail {
            claimFirstResponderIfIdle(overridingFocusElsewhere: isEditingDetail)
        }
    }

    // MARK: - Cards

    /// The cards to show, in order. Called from `viewDidLoad` (via `setupStackContent`) and `reloadCards()`.
    open func makeCards() -> [LMKDetailCard] {
        []
    }

    override open func setupStackContent() {
        reloadCards()
    }

    /// Rebuilds the model with `makeCards()` and reconciles the card views by id.
    public func reloadCards() {
        let newCards = makeCards()
        cards = newCards
        var kept: [String: LMKDetailCardView] = [:]
        for view in stackView.arrangedSubviews where view is LMKDetailCardView {
            stackView.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
        for card in newCards {
            let view = cardViews[card.id] ?? LMKDetailCardView(style: cardStyle)
            view.configure(card)
            view.accessibilityIdentifier = card.id
            kept[card.id] = view
            stackView.addArrangedSubview(view)
        }
        cardViews = kept
    }

    /// The view rendering the card with `id`.
    public func cardView(id: String) -> LMKDetailCardView? {
        cardViews[id]
    }

    /// Scrolls so the card with `id` is visible.
    public func scrollToCard(id: String, animated: Bool = true) {
        guard let view = cardViews[id] else { return }
        scrollTo(view, animated: animated)
    }

    // MARK: - Bar items

    private func updateBarItems() {
        let items: [LMKNavigationBarItem] = if isEditingDetail {
            [
                LMKNavigationBarItem(identifier: "detailPage.cancel", title: strings.cancel) { [weak self] in self?.cancelEditingFromItem() },
                LMKNavigationBarItem(identifier: "detailPage.save", title: strings.save, role: .prominent) { [weak self] in self?.saveFromItem() },
            ]
        } else {
            [
                onEdit.map { edit in LMKNavigationBarItem(identifier: "detailPage.edit", systemName: "pencil", accessibilityLabel: strings.edit, action: edit) },
                onShare.map { share in LMKNavigationBarItem(identifier: "detailPage.share", systemName: "square.and.arrow.up", accessibilityLabel: strings.share, action: share) },
            ].compactMap(\.self)
        }
        if let bar = navigationBar {
            bar.setRightItems(items.reversed())
        } else {
            // Only the trailing side is the page's; a host's leading items (a Close button on a
            // modal) stay where they are.
            navigationItem.rightBarButtonItems = items.isEmpty ? nil : items.map { $0.makeBarButtonItem(tintColor: nil) }
        }
    }

    // MARK: - Editing

    /// Swaps the bar items for Cancel / Save (⌘↩ saves, Esc cancels) until `endEditing()`. On
    /// iPad and Mac the page takes first responder while no field inside has it, so the key
    /// commands work before the user focuses a field.
    public func beginEditing(onSave: @escaping () -> Void, onCancel: @escaping () -> Void) {
        self.onSave = onSave
        onCancelEditing = onCancel
        isEditingDetail = true
        updateBarItems()
        claimFirstResponderIfIdle(overridingFocusElsewhere: true)
    }

    /// Restores the Edit / Share items. The page keeps first responder while `onEdit` is set, for
    /// Command-E.
    public func endEditing() {
        guard isEditingDetail else { return }
        isEditingDetail = false
        onSave = nil
        onCancelEditing = nil
        updateBarItems()
        if isFirstResponder, onEdit == nil {
            resignFirstResponder()
        }
    }

    /// Takes first responder on iPad and Mac (where hardware key commands matter), unless a
    /// field is editing or the page cannot take it. An edit the user started takes the keyboard
    /// from a field elsewhere in the window (`overridingFocusElsewhere`); appearing leaves it there.
    private func claimFirstResponderIfIdle(overridingFocusElsewhere: Bool) {
        guard canClaimFirstResponder(overridingFocusElsewhere: overridingFocusElsewhere) else { return }
        becomeFirstResponder()
    }

    func canClaimFirstResponder(overridingFocusElsewhere: Bool) -> Bool {
        guard traitCollection.userInterfaceIdiom != .phone, let window = viewIfLoaded?.window, canBecomeFirstResponder, !isFirstResponder else { return false }
        return !Self.containsFirstResponder(overridingFocusElsewhere ? view : window)
    }

    private static func containsFirstResponder(_ view: UIView) -> Bool {
        if view.isFirstResponder { return true }
        return view.subviews.contains { containsFirstResponder($0) }
    }

    override open var keyCommands: [UIKeyCommand]? {
        if isEditingDetail {
            return lmk_formKeyCommands(save: #selector(saveFromKeyCommand), cancel: #selector(cancelFromKeyCommand)) + (super.keyCommands ?? [])
        }
        guard onEdit != nil else { return super.keyCommands }
        let edit = UIKeyCommand(title: strings.edit, action: #selector(editFromKeyCommand), input: "e", modifierFlags: .command)
        return [edit] + (super.keyCommands ?? [])
    }

    override open var canBecomeFirstResponder: Bool { isEditingDetail || onEdit != nil || super.canBecomeFirstResponder }

    @objc private func editFromKeyCommand() {
        guard !isEditingDetail else { return }
        onEdit?()
    }

    @objc private func saveFromKeyCommand() {
        saveFromItem()
    }

    @objc private func cancelFromKeyCommand() {
        cancelEditingFromItem()
    }

    private func saveFromItem() {
        let save = onSave
        endEditing()
        save?()
    }

    private func cancelEditingFromItem() {
        let cancel = onCancelEditing
        endEditing()
        cancel?()
    }
}
