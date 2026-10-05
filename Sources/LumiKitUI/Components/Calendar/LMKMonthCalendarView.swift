//
//  LMKMonthCalendarView.swift
//  LumiKit
//
//  A month grid built from row stacks of `LMKCalendarDayCell`s: header with
//  paging chevrons, weekday row, four to six week rows. Selection runs through
//  the pure `LMKCalendarSelection` reducer; month changes are proposed to the
//  host or applied locally; paging slides interactively (see +Paging).
//

import LumiKitCore
import SnapKit
import UIKit

/// A month calendar view.
///
/// ```swift
/// let calendar = LMKMonthCalendarView()
/// calendar.selectionMode = .single
/// calendar.configure(month: .current(), selection: .empty, decorations: dots)
/// calendar.onSelectionChange = { [weak self] selection in self?.showEvents(for: selection) }
/// calendar.onMonthChange = { [weak self] month in self?.loadDecorations(for: month) }
/// ```
///
/// **Ownership of the month.** By default the view pages itself and reports through
/// `onMonthChange`. Set `onMonthChangeRequest` for the stateless contract: the view never
/// repages itself; the host decides and calls `configure(...)` or `setVisibleMonth(_:animated:)`
/// (a swipe that the host ignores snaps back). Selection always runs through the reducer and is
/// reported by `onSelectionChange`; `configure` and `setSelection` overwrite it.
///
/// **Today.** Left to the view (`configure(today: nil)`, the default), the today mark follows
/// the system day (the date on the device's clock in its current time zone, whatever time zone
/// `calendar` lays the grid out in) and moves at midnight, after a clock change, or when the time
/// zone changes. A day the host passes to `configure(today:)` or `setToday(_:)` is pinned until the
/// host passes another.
///
/// **Calendars.** Days and months are Gregorian civil dates whatever `calendar` is: the grid,
/// the keys, and the paging use `calendar.lmk_civilCalendar`, and the title, weekday row, and
/// VoiceOver dates format through `calendar.lmk_civilDisplayCalendar` (the calendar itself when
/// its months are the Gregorian months, as with the Japanese and Buddhist calendars).
///
/// The height is intrinsic (`preferredHeight(for:)`): four to six week rows with
/// `Style.weekRows == .fitMonth`, always six with `.alwaysSix`. Constrain the width only.
public final class LMKMonthCalendarView: UIView, LMKThemeApplying {
    // MARK: - Strings

    /// Process-wide defaults; set at app launch to override.
    public nonisolated(unsafe) static var strings = Strings()

    /// Per-instance strings (default `Self.strings`).
    public var strings: Strings = LMKMonthCalendarView.strings {
        didSet { applyStrings() }
    }

    // MARK: - Public API

    /// The calendar the view was created with (its time zone and first weekday shape the grid).
    public let calendar: Calendar
    public let locale: Locale

    /// Per-instance style; `nil` fields resolve from `theme.monthCalendar`, then the built-in look.
    public var style: Style {
        didSet {
            guard style != oldValue else { return }
            applyTheme(traitCollection.lmkTheme)
        }
    }

    /// Called at the end of every `applyTheme`, for tweaks the style does not cover.
    public var didApplyStyle: ((LMKMonthCalendarView) -> Void)?

    /// The style last resolved against the theme.
    public private(set) var resolvedStyle = Style()

    /// How taps select. Default `.single`; changing it re-renders the marks.
    public var selectionMode: LMKCalendarSelectionMode = .single {
        didSet { guard selectionMode != oldValue else { return }; render() }
    }

    /// Days before this one are disabled and months before it cannot be shown.
    public var minimumDay: LMKCalendarDay? {
        didSet { guard minimumDay != oldValue else { return }; render() }
    }

    /// Days after this one are disabled and months after it cannot be shown.
    public var maximumDay: LMKCalendarDay? {
        didSet { guard maximumDay != oldValue else { return }; render() }
    }

    /// Builds the day cells (a subclass of `LMKCalendarDayCell`); replacing it rebuilds the grid.
    public var dayCellFactory: () -> LMKCalendarDayCell = { LMKCalendarDayCell() } {
        didSet { rebuildCells() }
    }

    /// The month on screen.
    public internal(set) var visibleMonth: LMKCalendarMonth
    /// The day marked as today.
    public private(set) var today: LMKCalendarDay
    /// The current selection.
    public private(set) var selection: LMKCalendarSelection = .empty
    /// The per-day decorations.
    public private(set) var decorations: [LMKCalendarDay: LMKCalendarDayDecoration] = [:]

    /// Called with the day on every tap of an enabled day, before the selection reducer runs.
    public var onDayTap: ((LMKCalendarDay) -> Void)?
    /// Called after a tap changed the selection (never for `setSelection` / `configure`).
    public var onSelectionChange: ((LMKCalendarSelection) -> Void)?
    /// The stateless contract: set it and the view never repages itself; the host decides.
    public var onMonthChangeRequest: ((LMKCalendarMonth) -> Void)?
    /// Called after the view paged itself (chevrons, swipes, the Today button, `showNextMonth`).
    public var onMonthChange: ((LMKCalendarMonth) -> Void)?
    /// Called when the (tappable) month title is tapped.
    public var onMonthTitleTap: (() -> Void)?
    /// Called when the Today button is tapped; when `nil` the view shows today's month itself.
    public var onTodayTap: (() -> Void)?

    // MARK: - Views

    public let contentStack = UIStackView()
    public let headerView: UIView = LMKSurfaceView()
    public let headerStack = UIStackView()
    public let titleButton = LMKButton(style: .ghost())
    public let previousButton = LMKButton(systemImage: "chevron.backward", style: .iconOnly())
    public let nextButton = LMKButton(systemImage: "chevron.forward", style: .iconOnly())
    public let todayButton = LMKButton(style: .ghost().size(.small))
    public let weekdayRow = UIStackView()
    public private(set) var weekdayLabels: [UILabel] = []
    /// Clips the grid while it slides.
    public let gridContainer = UIView()
    public let gridStack = UIStackView()
    public private(set) var rowStacks: [UIStackView] = []
    public private(set) var dayCells: [LMKCalendarDayCell] = []

    // MARK: - Internal state

    /// The month the grid currently renders (the neighbour during a drag or a pending proposal).
    var renderedMonth: LMKCalendarMonth
    /// Extra rows kept visible during a drag so a 5-row and a 6-row month share a height.
    var minimumRenderedRows = 0
    var currentRowCount = 0
    /// Whether a drag, a settle, or a programmatic slide is in flight.
    var isPaging = false
    /// Whether the finger is down on a drag this gesture began (a settle is `isPaging` alone).
    var isDragging = false
    var dragDirection = 0
    var dragTarget: LMKCalendarMonth?
    /// The outgoing grid image that slides out with the finger.
    var pagingSnapshot: UIView?
    /// The settle or slide in flight, owned so a newer transition can finish it first.
    var pagingAnimator: UIViewPropertyAnimator?
    var pagingCompletion: LMKOnceCompletion?
    /// Bumped by every transition and every cancel: a completion from an older transition is a no-op.
    var pagingGeneration = 0
    /// Bumped whenever the host sets the month (`configure`, `setVisibleMonth`): a proposal the host
    /// answered is not snapped back.
    var hostMonthGeneration = 0
    /// The snap-back after an unanswered proposal, one main-queue turn later.
    var snapBackTask: Task<Void, Never>?
    lazy var panGesture: UIPanGestureRecognizer = {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        pan.delegate = panDelegate
        return pan
    }()

    /// The clock behind the system today. Test hook.
    var currentDate: () -> Date = { Date() }

    private lazy var panDelegate = LMKMonthCalendarPanDelegate(owner: self)
    private var contentInsetsConstraint: Constraint?
    private var headerInsetsConstraint: Constraint?
    private var headerHeightConstraint: Constraint?
    private var weekdayHeightConstraint: Constraint?
    private var rowHeightConstraints: [Constraint] = []
    private var resolvedDayRowHeight: CGFloat = 44
    /// The style's row height, before the decoration floor.
    private var baseDayRowHeight: CGFloat = 44
    private var numeralLineHeight: CGFloat = 0
    private var headerSpacing: CGFloat = 8
    private var weekdaySpacing: CGFloat = 4
    /// Whether the today mark follows the system day (`configure(today: nil)`) or a host-pinned day.
    private var followsSystemToday = true
    /// The header layout the header stack is arranged for; `nil` until the first theme pass.
    private var arrangedHeaderLayout: HeaderLayout?

    static let rowCapacity = 6
    static let columnCount = 7
    /// Built-in metrics behind the `nil` style fields.
    static let defaultWeekdayRowHeight: CGFloat = 24
    static let defaultReservedEdgeBandWidth: CGFloat = 24
    static let defaultCommitFraction: CGFloat = 0.4
    static let defaultFlickVelocity: CGFloat = 300

    /// The formatting context: the calendar's own names when its months are the Gregorian months,
    /// the civil twin's otherwise.
    var dateContext: LMKDateFormat.Context {
        LMKDateFormat.Context(locale: locale, calendar: calendar.lmk_civilDisplayCalendar, timeZone: calendar.timeZone)
    }

    // MARK: - Initialization

    public init(calendar: Calendar = LMKDate.calendar, locale: Locale = .autoupdatingCurrent, style: Style = Style()) {
        var calendar = calendar
        calendar.locale = locale
        self.calendar = calendar
        self.locale = locale
        self.style = style
        var local = calendar
        local.timeZone = .current
        let month = LMKCalendarMonth.current(calendar: local)
        visibleMonth = month
        renderedMonth = month
        today = .today(calendar: local)
        super.init(frame: .zero)
        setupUI()
        rebuildCells()
        NotificationCenter.default.addObserver(self, selector: #selector(handleSignificantTimeChange), name: UIApplication.significantTimeChangeNotification, object: nil)
        lmk_startApplyingTheme()
    }

    override public convenience init(frame: CGRect) {
        // Through the designated initializer: `self.init()` would resolve to `UIView.init()`,
        // which calls `initWithFrame:` and recurses back here until the stack overflows.
        self.init(calendar: LMKDate.calendar, locale: .autoupdatingCurrent, style: Style())
        self.frame = frame
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        snapBackTask?.cancel()
    }

    // MARK: - Setup

    private func setupUI() {
        contentStack.axis = .vertical
        contentStack.alignment = .fill
        addSubview(contentStack)
        contentStack.snp.makeConstraints { make in
            contentInsetsConstraint = make.directionalEdges.equalToSuperview().constraint
        }

        headerStack.axis = .horizontal
        headerStack.alignment = .center
        headerView.addSubview(headerStack)
        headerStack.snp.makeConstraints { make in
            headerInsetsConstraint = make.directionalEdges.equalToSuperview().constraint
        }
        // Sizes along the stack axis sit just below required: a hidden arranged view carries the
        // stack's own hiding constraint, and both must be satisfiable at once.
        headerView.snp.makeConstraints { make in
            headerHeightConstraint = make.height.equalTo(44).priority(999).constraint
        }
        titleButton.contentHorizontalAlignment = .leading
        // The header's spare width belongs to the title (or the spacer): a glyph button that
        // stretched instead would center its chevron away from the edge.
        for button in [previousButton, nextButton, todayButton] {
            button.setContentHuggingPriority(.required, for: .horizontal)
            button.setContentCompressionResistancePriority(.required, for: .horizontal)
        }
        titleButton.onTap = { [weak self] in self?.onMonthTitleTap?() }
        previousButton.onTap = { [weak self] in self?.showPreviousMonth() }
        nextButton.onTap = { [weak self] in self?.showNextMonth() }
        todayButton.onTap = { [weak self] in self?.handleTodayTapped() }

        weekdayRow.axis = .horizontal
        weekdayRow.distribution = .fillEqually
        weekdayRow.snp.makeConstraints { make in
            weekdayHeightConstraint = make.height.equalTo(Self.defaultWeekdayRowHeight).priority(999).constraint
        }
        for _ in 0 ..< Self.columnCount {
            let label = UILabel()
            label.textAlignment = .center
            label.adjustsFontSizeToFitWidth = true
            label.minimumScaleFactor = 0.7
            weekdayLabels.append(label)
            weekdayRow.addArrangedSubview(label)
        }

        gridContainer.clipsToBounds = true
        gridStack.axis = .vertical
        gridStack.alignment = .fill
        gridStack.distribution = .fillEqually
        gridContainer.addSubview(gridStack)
        gridStack.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        for _ in 0 ..< Self.rowCapacity {
            let row = UIStackView()
            row.axis = .horizontal
            row.distribution = .fillEqually
            row.alignment = .fill
            rowStacks.append(row)
            gridStack.addArrangedSubview(row)
            row.snp.makeConstraints { make in
                rowHeightConstraints.append(make.height.equalTo(44).priority(999).constraint)
            }
        }
        gridContainer.addGestureRecognizer(panGesture)
        gridStack.shouldGroupAccessibilityChildren = true

        contentStack.addArrangedSubview(headerView)
        contentStack.addArrangedSubview(weekdayRow)
        contentStack.addArrangedSubview(gridContainer)
        applyStrings()
    }

    private func rebuildCells() {
        for cell in dayCells {
            cell.removeFromSuperview()
        }
        dayCells = []
        for row in rowStacks {
            for _ in 0 ..< Self.columnCount {
                let cell = dayCellFactory()
                cell.onTap = { [weak self] day in self?.handleDayTap(day) }
                row.addArrangedSubview(cell)
                dayCells.append(cell)
            }
        }
        render()
    }

    private func applyStrings() {
        todayButton.title = strings.today
        previousButton.accessibilityLabel = strings.previousMonthAccessibilityLabel
        nextButton.accessibilityLabel = strings.nextMonthAccessibilityLabel
        titleButton.accessibilityHint = resolvedStyle.titleIsTappable ?? false ? strings.monthTitleAccessibilityHint : nil
        render()
    }

    override public func layoutSubviews() {
        super.layoutSubviews()
        lmk_layoutSurfaceIfNeeded()
    }

    override public var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: height(forRows: currentRowCount))
    }

    // MARK: - Theme

    public func applyTheme(_ theme: LMKTheme) {
        resolvedStyle = theme.monthCalendar.merging(style)
        let resolved = resolvedStyle
        let accent = resolved.accent ?? LMKColor.primary
        maximumContentSizeCategory = resolved.maximumContentSizeCategory ?? .extraExtraLarge

        contentInsetsConstraint?.update(inset: resolved.contentInsets ?? .lmk_all(theme.spacing.small))

        // Header
        let layout = resolved.headerLayout ?? .centeredTitle
        headerView.isHidden = layout == .hidden
        let headerSurface = headerView.lmk_apply(surface: resolved.headerSurface, defaults: LMKSurfaceStyle(background: .clear), clipsContent: false)
        headerInsetsConstraint?.update(inset: headerSurface.contentInsets ?? .zero)
        headerHeightConstraint?.update(offset: headerBandHeight(theme: theme))
        headerSpacing = resolved.spacingAfterHeader ?? theme.spacing.small
        contentStack.setCustomSpacing(layout == .hidden ? 0 : headerSpacing, after: headerView)
        // Only a new layout rebuilds the header. A style holding a dynamic color never compares
        // equal to the last one, so a host re-assigning an unchanged look on every reload re-ran
        // this pass each time, and tearing the buttons out and back in laid the header out again
        // even while the calendar was off screen.
        if layout != arrangedHeaderLayout {
            arrangeHeader(layout: layout)
            arrangedHeaderLayout = layout
        }
        let tappable = resolved.titleIsTappable ?? false
        titleButton.isUserInteractionEnabled = tappable
        titleButton.isPointerInteractionEnabled = tappable
        titleButton.accessibilityTraits = tappable ? .button : [.header]
        titleButton.accessibilityHint = tappable ? strings.monthTitleAccessibilityHint : nil
        let titleColor = resolved.titleColor ?? LMKColor.textPrimary
        titleButton.style = LMKButton.Style(
            variant: .ghost,
            surface: LMKSurfaceStyle(contentInsets: .lmk_symmetric(vertical: 0, horizontal: layout == .leadingTitle ? theme.spacing.xs : 0)),
            tintColor: titleColor,
            foregroundColor: titleColor,
            textStyle: resolved.titleTextStyle ?? .h3,
            imagePlacement: .trailing,
            imagePadding: theme.spacing.xs,
            symbolPointSize: theme.layout.symbolAccessory,
            symbolWeight: .semibold,
            pressAnimation: false,
            haptics: false
        ).merging(resolved.navigationButton)
        titleButton.image = tappable ? UIImage(systemName: "chevron.down") : nil
        let chevronStyle = LMKButton.Style.iconOnly().tint(accent).merging(resolved.navigationButton)
        previousButton.style = chevronStyle
        nextButton.style = chevronStyle
        todayButton.style = LMKButton.Style.ghost().size(.small).tint(accent).merging(resolved.todayButton)
        todayButton.isHidden = !(resolved.showsTodayButton ?? false)

        // Weekday row
        let weekdayStyle = resolved.weekdayTextStyle ?? .captionMedium
        weekdayHeightConstraint?.update(offset: weekdayRowHeight(theme: theme))
        weekdaySpacing = resolved.spacingAfterWeekdays ?? theme.spacing.xs
        contentStack.setCustomSpacing(weekdaySpacing, after: weekdayRow)
        let symbols = LMKDateFormat.weekdaySymbols(style: resolved.weekdaySymbolStyle ?? .narrow, context: dateContext)
        let wideSymbols = LMKDateFormat.weekdaySymbols(style: .wide, context: dateContext)
        for (index, label) in weekdayLabels.enumerated() {
            label.lmk_apply(weekdayStyle, color: resolved.weekdayColor ?? LMKColor.textSecondary)
            label.lmk_setText(symbols[lmk_safe: index])
            label.accessibilityLabel = wideSymbols[lmk_safe: index]
        }

        // Grid
        numeralLineHeight = LMKTextMeasurement.lineHeight(of: resolved.numeralEmphasisTextStyle ?? .bodyMedium, traits: traitCollection)
        baseDayRowHeight = max(resolved.dayRowHeight ?? theme.layout.minimumTouchTarget, ceil(numeralLineHeight) + theme.spacing.xs)
        panGesture.isEnabled = (resolved.paging ?? .interactive) != .buttonsOnly

        render()
        didApplyStyle?(self)
    }

    private func arrangeHeader(layout: HeaderLayout) {
        for view in headerStack.arrangedSubviews {
            headerStack.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
        switch layout {
        case .centeredTitle:
            titleButton.contentHorizontalAlignment = .center
            headerStack.spacing = 0
            headerStack.addArrangedSubview(previousButton)
            headerStack.addArrangedSubview(titleButton)
            headerStack.addArrangedSubview(todayButton)
            headerStack.addArrangedSubview(nextButton)
            titleButton.setContentHuggingPriority(.defaultLow, for: .horizontal)
            titleButton.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        case .leadingTitle:
            titleButton.contentHorizontalAlignment = .leading
            headerStack.spacing = 0
            let spacer = UIView()
            spacer.setContentHuggingPriority(.fittingSizeLevel, for: .horizontal)
            headerStack.addArrangedSubview(titleButton)
            headerStack.addArrangedSubview(spacer)
            headerStack.addArrangedSubview(todayButton)
            headerStack.addArrangedSubview(previousButton)
            headerStack.addArrangedSubview(nextButton)
            titleButton.setContentHuggingPriority(.required, for: .horizontal)
            // A stack view caps a wrapping text view at half its width (priority 950), which
            // broke "September 2026" onto two lines with room to spare; 999 outranks the cap
            // and still yields to the required glyph buttons when the header truly runs out.
            titleButton.setContentCompressionResistancePriority(UILayoutPriority(999), for: .horizontal)
        case .hidden:
            break
        }
    }

    // MARK: - Configuration

    /// Sets the whole input in one call (the stateless contract). Cancels a drag or a settle in
    /// flight so a reload landing mid-swipe can never reset the browsing position. A `nil`
    /// `today` follows the system day; a day pins the mark until the next `configure` or `setToday`.
    public func configure(
        month: LMKCalendarMonth,
        today: LMKCalendarDay? = nil,
        selection: LMKCalendarSelection = .empty,
        decorations: [LMKCalendarDay: LMKCalendarDayDecoration] = [:]
    ) {
        hostMonthGeneration += 1
        cancelPagingIfNeeded()
        visibleMonth = month
        renderedMonth = month
        followsSystemToday = today == nil
        self.today = today ?? systemToday()
        self.selection = selection
        self.decorations = decorations
        render()
    }

    /// Replaces the decorations.
    public func setDecorations(_ decorations: [LMKCalendarDay: LMKCalendarDayDecoration]) {
        self.decorations = decorations
        render()
    }

    /// Replaces the selection without reporting it.
    public func setSelection(_ selection: LMKCalendarSelection, animated: Bool = false) {
        self.selection = selection
        if animated, LMKAnimation.shouldAnimate, window != nil {
            UIView.transition(with: gridStack, duration: traitCollection.lmkTheme.animation.fast, options: [.transitionCrossDissolve, .allowUserInteraction]) {
                self.render()
            }
        } else {
            render()
        }
    }

    /// Pins the day marked as today (the view stops following the system day until the next
    /// `configure(today: nil)`).
    public func setToday(_ day: LMKCalendarDay) {
        followsSystemToday = false
        today = day
        render()
    }

    /// Shows `month`, sliding from the right direction when `animated`. Does not report.
    ///
    /// Answering `onMonthChangeRequest` with the proposed month applies it without a second
    /// slide (the swipe already showed it); echoing the month on screen during a drag is ignored.
    public func setVisibleMonth(_ month: LMKCalendarMonth, animated: Bool) {
        guard month != visibleMonth else {
            // The host answered a proposal with the month it already had: snap back now.
            if !isPaging, renderedMonth != visibleMonth { snapBackToVisibleMonth() }
            return
        }
        hostMonthGeneration += 1
        cancelSnapBack()
        if !isPaging, renderedMonth == month {
            visibleMonth = month
            render()
            return
        }
        let direction = month > visibleMonth ? 1 : -1
        cancelPagingIfNeeded()
        if animated {
            slide(to: month, direction: direction, completion: nil)
        } else {
            visibleMonth = month
            renderedMonth = month
            render()
        }
    }

    /// Requests the previous month (through `onMonthChangeRequest` when set).
    public func showPreviousMonth() {
        settlePaging()
        requestMonthChange(to: visibleMonth.adding(months: -1, calendar: calendar), direction: -1)
    }

    /// Requests the next month (through `onMonthChangeRequest` when set).
    public func showNextMonth() {
        settlePaging()
        requestMonthChange(to: visibleMonth.adding(months: 1, calendar: calendar), direction: 1)
    }

    /// Whether `month` may be shown given `minimumDay` / `maximumDay`.
    public func canShow(_ month: LMKCalendarMonth) -> Bool {
        if let minimumDay, month < minimumDay.calendarMonth { return false }
        if let maximumDay, month > maximumDay.calendarMonth { return false }
        return true
    }

    /// The cell showing `day` in the current grid, if any.
    public func cell(for day: LMKCalendarDay) -> LMKCalendarDayCell? {
        dayCells.first { $0.dayState?.day == day && !$0.isHidden && !($0.superview?.isHidden ?? true) }
    }

    /// The height the view wants for `month` at the current style.
    public func preferredHeight(for month: LMKCalendarMonth) -> CGFloat {
        height(forRows: rowCount(for: month))
    }

    // MARK: - Month changes

    /// Applies a month change: proposes it to the host when `onMonthChangeRequest` is set,
    /// else pages (sliding in `direction`) and reports `onMonthChange`. A transition in flight
    /// finishes first, so two quick taps report both months.
    func requestMonthChange(to month: LMKCalendarMonth, direction: Int, animated: Bool = true) {
        settlePaging()
        guard canShow(month), month != visibleMonth else { return }
        if let onMonthChangeRequest {
            onMonthChangeRequest(month)
            return
        }
        if animated {
            slide(to: month, direction: direction) { [weak self] in
                guard let self else { return }
                onMonthChange?(visibleMonth)
            }
        } else {
            visibleMonth = month
            renderedMonth = month
            render()
            onMonthChange?(month)
        }
    }

    /// Called after an interactive swipe settled on `month` (the grid already shows it).
    func finishInteractivePaging(to month: LMKCalendarMonth) {
        guard let onMonthChangeRequest else {
            visibleMonth = month
            renderedMonth = month
            render()
            onMonthChange?(month)
            return
        }
        // The grid keeps showing the proposed month while the host decides; a host that answers
        // one main-queue turn later (a Combine sink) must not see the old month flash by.
        renderedMonth = month
        render()
        let generation = hostMonthGeneration
        onMonthChangeRequest(month)
        guard generation == hostMonthGeneration, renderedMonth != visibleMonth else { return }
        cancelSnapBack()
        snapBackTask = Task { [weak self] in
            guard let self, !Task.isCancelled, generation == hostMonthGeneration else { return }
            snapBackTask = nil
            if !isPaging, renderedMonth != visibleMonth { snapBackToVisibleMonth() }
        }
    }

    /// Re-renders the month the host owns after a proposal it did not take.
    private func snapBackToVisibleMonth() {
        cancelSnapBack()
        renderedMonth = visibleMonth
        render()
    }

    func cancelSnapBack() {
        snapBackTask?.cancel()
        snapBackTask = nil
    }

    private func handleTodayTapped() {
        if let onTodayTap {
            onTodayTap()
        } else {
            settlePaging()
            let month = today.calendarMonth
            requestMonthChange(to: month, direction: month > visibleMonth ? 1 : -1)
        }
    }

    // MARK: - Today

    /// The device's date: a civil day, so it is read in the current time zone even when the grid's
    /// calendar uses another one (a UTC grid keyed by civil dates still marks the user's today).
    private func systemToday() -> LMKCalendarDay {
        var local = calendar
        local.timeZone = .current
        return LMKCalendarDay(currentDate(), calendar: local)
    }

    /// Moves the today mark when the system day changed under a view that follows it.
    @objc func handleSignificantTimeChange() {
        guard followsSystemToday else { return }
        let day = systemToday()
        guard day != today else { return }
        today = day
        render()
    }

    // MARK: - Selection

    private func handleDayTap(_ day: LMKCalendarDay) {
        guard isDayEnabled(day), !isPaging else { return }
        if resolvedStyle.haptics ?? true { LMKHaptics.selection() }
        onDayTap?(day)
        guard selectionMode != .none else { return }
        let next = selection.tapping(day, mode: selectionMode, calendar: calendar)
        guard next != selection else { return }
        selection = next
        render()
        onSelectionChange?(selection)
    }

    private func isDayEnabled(_ day: LMKCalendarDay) -> Bool {
        if let minimumDay, day < minimumDay { return false }
        if let maximumDay, day > maximumDay { return false }
        return decorations[day]?.isEnabled ?? true
    }

    // MARK: - Rendering

    func rowCount(for month: LMKCalendarMonth) -> Int {
        let weeks = month.weeks(in: calendar, rows: resolvedStyle.weekRows ?? .fitMonth).count
        return min(Self.rowCapacity, max(1, weeks))
    }

    /// The header band: the style's height (floored at a touch target) plus the surface's vertical insets.
    private func headerBandHeight(theme: LMKTheme) -> CGFloat {
        let insets = resolvedStyle.headerSurface.contentInsets ?? .zero
        return max(resolvedStyle.headerHeight ?? theme.layout.minimumTouchTarget, theme.layout.minimumTouchTarget) + insets.top + insets.bottom
    }

    private func weekdayRowHeight(theme _: LMKTheme) -> CGFloat {
        let lineHeight = LMKTextMeasurement.lineHeight(of: resolvedStyle.weekdayTextStyle ?? .captionMedium, traits: traitCollection)
        return max(resolvedStyle.weekdayRowHeight ?? Self.defaultWeekdayRowHeight, ceil(lineHeight))
    }

    func height(forRows rows: Int) -> CGFloat {
        let theme = traitCollection.lmkTheme
        let insets = resolvedStyle.contentInsets ?? .lmk_all(theme.spacing.small)
        var height = insets.top + insets.bottom
        if (resolvedStyle.headerLayout ?? .centeredTitle) != .hidden {
            height += headerBandHeight(theme: theme) + headerSpacing
        }
        height += weekdayRowHeight(theme: theme) + weekdaySpacing
        height += CGFloat(rows) * resolvedDayRowHeight
        return height
    }

    /// The row height the numeral and the tallest decoration band in use need: a badge row is
    /// taller than the default row leaves under the numeral, and would spill into the next week
    /// and past the grid's clipped bottom edge. Taken over every decoration the host supplied,
    /// not the visible month's, so paging between months keeps one row height.
    private func fittingDayRowHeight(theme: LMKTheme) -> CGFloat {
        let resolved = resolvedStyle
        let band = decorations.values.reduce(CGFloat(0)) { max($0, LMKCalendarDayCell.decorationBandHeight(for: $1, style: resolved, theme: theme)) }
        guard band > 0 else { return 0 }
        let offset = resolved.numeralCenterOffset ?? LMKCalendarDayCell.defaultNumeralCenterOffset
        let bottomMargin = LMKCalendarDayCell.decorationBottomMargin(style: resolved, theme: theme)
        // The numeral sits `offset` from the row's center, the band hangs `xxs` under it, and the
        // row keeps `bottomMargin` below the band (more than `xxs` when a rounded-rectangle ring
        // strokes the cell's edge): center + offset + numeral / 2 + xxs + band + margin <= height.
        return ceil(2 * (offset + numeralLineHeight / 2 + band + theme.spacing.xxs + bottomMargin))
    }

    /// Re-applies every cell from `renderedMonth`, the selection, and the decorations.
    func render() {
        guard !dayCells.isEmpty else { return }
        let theme = traitCollection.lmkTheme
        let resolved = resolvedStyle
        let rowHeight = max(baseDayRowHeight, fittingDayRowHeight(theme: theme))
        if rowHeight != resolvedDayRowHeight {
            resolvedDayRowHeight = rowHeight
            invalidateIntrinsicContentSize()
        }
        let month = renderedMonth
        let weeks = month.weeks(in: calendar, rows: resolved.weekRows ?? .fitMonth)
        let rows = max(min(Self.rowCapacity, weeks.count), minimumRenderedRows)
        let showsAdjacent = resolved.showsAdjacentMonthDays ?? true
        let selectedRange = selection.selectedRange

        for (rowIndex, row) in rowStacks.enumerated() {
            let visible = rowIndex < rows
            row.isHidden = !visible
            guard visible else { continue }
            for column in 0 ..< Self.columnCount {
                let cell = dayCells[rowIndex * Self.columnCount + column]
                guard let day = weeks[lmk_safe: rowIndex]?[lmk_safe: column] else {
                    cell.apply(state: .init(day: today, numeral: "", isInMonth: false, isEnabled: false), decoration: .none, style: resolved, theme: theme)
                    continue
                }
                let inMonth = month.contains(day)
                let decoration = decorations[day] ?? .none
                let enabled = inMonth && isDayEnabled(day)
                let selected = inMonth && selection.contains(day)
                let position: LMKCalendarDayCell.RangePosition = if !selected {
                    .none
                } else if let selectedRange, selectedRange.lowerBound != selectedRange.upperBound {
                    day == selectedRange.lowerBound ? .start : (day == selectedRange.upperBound ? .end : .middle)
                } else {
                    .single
                }
                // The bare day number in the locale's numbering system: a localized date template
                // would add the locale's day suffix ("21日").
                let numeral = inMonth || showsAdjacent ? LMKFormat.number(day.day, locale: locale) : ""
                let state = LMKCalendarDayCell.DayState(
                    day: day,
                    numeral: numeral,
                    isInMonth: inMonth,
                    isToday: day == today && inMonth,
                    isSelected: selected,
                    rangePosition: position,
                    isEnabled: enabled,
                    accessibilityLabel: accessibilityLabel(for: day)
                )
                cell.apply(state: state, decoration: inMonth ? decoration : .none, style: resolved, theme: theme)
            }
        }
        for constraint in rowHeightConstraints {
            constraint.update(offset: resolvedDayRowHeight)
        }
        if currentRowCount != rows {
            currentRowCount = rows
            invalidateIntrinsicContentSize()
        }
        renderTitle()
        previousButton.isEnabled = canShow(month.adding(months: -1, calendar: calendar))
        nextButton.isEnabled = canShow(month.adding(months: 1, calendar: calendar))
    }

    func renderTitle() {
        titleButton.title = monthTitle(for: renderedMonth)
        titleButton.accessibilityLabel = monthTitle(for: renderedMonth)
    }

    /// The localized title for `month`, in the calendar's own names when its months are the
    /// Gregorian months ("令和8年9月" on a Japanese device), else in the civil calendar's.
    public func monthTitle(for month: LMKCalendarMonth) -> String {
        guard let date = month.date(in: calendar) else { return month.key }
        if let template = resolvedStyle.monthTitleTemplate {
            return LMKDateFormat.formatter(template: template, context: dateContext).string(from: date)
        }
        return LMKDateFormat.monthYearString(date, context: dateContext)
    }

    private func accessibilityLabel(for day: LMKCalendarDay) -> String {
        guard let date = day.date(in: calendar) else { return day.key }
        let text = LMKDateFormat.string(date, date: .full, context: dateContext)
        return day == today ? "\(strings.today), \(text)" : text
    }
}

/// The month pan's delegate, kept off the view's public surface.
final class LMKMonthCalendarPanDelegate: NSObject, UIGestureRecognizerDelegate {
    private weak var owner: LMKMonthCalendarView?

    init(owner: LMKMonthCalendarView) {
        self.owner = owner
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        guard let owner, gestureRecognizer === owner.panGesture else { return true }
        return owner.shouldReceivePanTouch(atX: touch.location(in: owner.gridContainer).x)
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith _: UIGestureRecognizer) -> Bool {
        gestureRecognizer === owner?.panGesture
    }
}
