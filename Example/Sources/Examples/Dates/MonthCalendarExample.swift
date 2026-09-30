//
//  MonthCalendarExample.swift
//  LumiKitExample
//
//  Month Calendar: LMKMonthCalendarView: paging, selection modes, dots, badges, glyphs.
//

import LumiKitCore
import LumiKitUI
import SnapKit
import UIKit

// MARK: - Month Calendar

final class MonthCalendarDetailViewController: DetailViewController {
    private let calendar = LMKMonthCalendarView()
    private let readout = UILabel.lmk_make(.body, text: "Nothing selected")
    private let modeControl = LMKSegmentedControl(items: ["Single", "Range", "Multiple"])
    private var decorations: [LMKCalendarDay: LMKCalendarDayDecoration] = [:]

    override func viewDidLoad() {
        super.viewDidLoad()

        addSectionHeader("LMKMonthCalendarView")
        stack.addArrangedSubview(UILabel.lmk_make(
            .caption,
            text: "Swipe the grid or use the chevrons to page months; the grid follows your finger and settles. "
                + "Taps run through the LMKCalendarSelection reducer in the chosen mode. Dots, badges, and glyphs come from per-day decorations."
        ))
        modeControl.selectedSegmentIndex = 0
        modeControl.onValueChange = { [weak self] index in
            guard let self else { return }
            calendar.selectionMode = [.single, .range, .multiple][index]
            calendar.setSelection(.empty)
            readout.text = "Nothing selected"
        }
        stack.addArrangedSubview(modeControl)

        seedDecorations(for: calendar.visibleMonth)
        calendar.style = LMKMonthCalendarView.Style(showsTodayButton: true)
        calendar.configure(month: .current(), today: .today(), decorations: decorations)
        calendar.onSelectionChange = { [weak self] selection in
            self?.readout.text = self?.describe(selection) ?? ""
        }
        calendar.onMonthChanged = { [weak self] month in
            guard let self else { return }
            seedDecorations(for: month)
            calendar.setDecorations(decorations)
        }
        stack.addArrangedSubview(calendar)
        stack.addArrangedSubview(readout)

        addDivider()
        addSectionHeader("Leading title, ring selection, fixed six rows")
        stack.addArrangedSubview(UILabel.lmk_make(
            .caption,
            text: "A second instance with a leading header (tappable title, Today button), a ring selection, today as a rounded outline, dimmed adjacent days hidden, "
                + "and always six rows so the height never changes."
        ))
        let styled = LMKMonthCalendarView(style: LMKMonthCalendarView.Style(
            accent: LMKColor.info,
            headerLayout: .leadingTitle,
            titleIsTappable: true,
            showsTodayButton: true,
            weekdaySymbolStyle: .abbreviated,
            weekRows: .alwaysSix,
            showsAdjacentMonthDays: false,
            selectionStyle: .ringCircle,
            todayStyle: .ringRoundedRect
        ))
        styled.selectionMode = .range
        styled.configure(month: .current(), today: .today())
        styled.onMonthTitleTapped = { [weak self] in
            guard let self else { return }
            LMKToast.show(.info, "Title tapped: present a month picker here", in: self)
        }
        stack.addArrangedSubview(styled)

        addDivider()
        addSectionHeader("Stateless contract with bounds")
        stack.addArrangedSubview(UILabel.lmk_make(
            .caption,
            text: "onMonthChangeProposed is set, so this calendar never repages itself: the host decides and calls configure. "
                + "Days outside the next 30 days are disabled and months beyond them cannot be shown."
        ))
        let bounded = LMKMonthCalendarView(style: LMKMonthCalendarView.Style(paging: .discrete))
        let today = LMKCalendarDay.today()
        bounded.minimumDay = today
        bounded.maximumDay = today.adding(days: 30)
        bounded.configure(month: .current(), today: today)
        bounded.onMonthChangeProposed = { [weak bounded] month in
            // A host would consult its own state here; this one always agrees.
            bounded?.configure(month: month, today: today)
        }
        stack.addArrangedSubview(bounded)
    }

    private func seedDecorations(for month: LMKCalendarMonth) {
        decorations = [:]
        let days = month.days()
        for (index, day) in days.enumerated() {
            switch index % 7 {
            case 1: decorations[day] = LMKCalendarDayDecoration(dots: [LMKColor.primary], accessibilityValue: "1 event")
            case 3: decorations[day] = LMKCalendarDayDecoration(dots: [LMKColor.primary, LMKColor.info, LMKColor.warning], accessibilityValue: "3 events")
            case 5: decorations[day] = LMKCalendarDayDecoration(badges: [.count(2), .count(1, color: LMKColor.secondary)].compactMap(\.self), accessibilityValue: "2 watered, 1 planned")
            case 6: decorations[day] = LMKCalendarDayDecoration(glyph: UIImage(systemName: "sun.max.fill"), glyphTint: LMKColor.warning)
            default: break
            }
        }
    }

    private func describe(_ selection: LMKCalendarSelection) -> String {
        switch selection {
        case .empty: "Nothing selected"
        case let .single(day): "Selected \(day.key)"
        case let .start(day): "Range from \(day.key)…"
        case let .range(start, end): "Range \(start.key) to \(end.key) (\(start.days(to: end) + 1) days)"
        case let .multiple(days): "\(days.count) days: \(days.sorted().map(\.key).joined(separator: ", "))"
        }
    }
}
