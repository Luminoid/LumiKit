//
//  DatePickerExample.swift
//  LumiKitExample
//
//  Date Picker: Single date, range, calendar range, and notes.
//

import LumiKitCore
import LumiKitUI
import UIKit

// MARK: - Date Picker

final class DatePickerDetailViewController: DetailViewController {
    override func setupStackContent() {
        addSectionHeader("Single Date")
        stackView.addArrangedSubview(UILabel.lmk_make(
            .caption,
            text: "A Configuration picks mode, style, bounds, and the initial date. No bounds here: past and future dates allowed. onCancel reports a dismissal without a choice."
        ))
        let singleButton = LMKButton(title: "Pick a Date", style: .filled(.primary), target: self, action: #selector(showSinglePicker))
        stackView.addArrangedSubview(singleButton)

        addDivider()
        addSectionHeader("Future Date")
        stackView.addArrangedSubview(UILabel.lmk_make(.caption, text: ".future(title:excludingToday:) restricts to future dates, for scheduling."))
        let futureButton = LMKButton(title: "Pick Future Date", style: .filled(.secondary), target: self, action: #selector(showFuturePicker))
        stackView.addArrangedSubview(futureButton)

        addDivider()
        addSectionHeader("Past Date")
        stackView.addArrangedSubview(UILabel.lmk_make(.caption, text: ".past(title:) restricts to past dates, for logging events."))
        let pastButton = LMKButton(title: "Pick Past Date", style: .filled(.secondary), target: self, action: #selector(showPastPicker))
        stackView.addArrangedSubview(pastButton)

        addDivider()
        addSectionHeader("Date Range")
        stackView.addArrangedSubview(UILabel.lmk_make(.caption, text: "Two compact pickers for From / To with live enforcement: the dates keep start before end."))
        let rangeButton = LMKButton(title: "Pick Date Range", style: .filled(.primary), target: self, action: #selector(showRangePicker))
        stackView.addArrangedSubview(rangeButton)

        addDivider()
        addSectionHeader("Calendar Range")
        stackView.addArrangedSubview(UILabel.lmk_make(
            .caption,
            text: "One calendar for the whole range. Tap to set the start, tap again to set the end; once a range exists, any tap resets and starts over."
        ))
        let calendarRangeButton = LMKButton(title: "Pick Calendar Range", style: .filled(.primary), target: self, action: #selector(showCalendarRangePicker))
        stackView.addArrangedSubview(calendarRangeButton)

        addDivider()
        addSectionHeader("Date with Notes")
        stackView.addArrangedSubview(UILabel.lmk_make(.caption, text: "A date picker with a text field above it for context."))
        let notesButton = LMKButton(title: "Pick Date with Notes", style: .filled(.secondary), target: self, action: #selector(showDateWithNotes))
        stackView.addArrangedSubview(notesButton)
    }

    private func format(_ date: Date, style: LMKDateFormat.DateStyle = .long) -> String {
        LMKDateFormat.string(date, date: style)
    }

    @objc private func showSinglePicker() {
        LMKDatePicker.present(LMKDatePicker.Configuration(title: "Select Date", message: "Choose any date"), from: self, onConfirm: { [weak self] date in
            guard let self else { return }
            LMKToast.show(.success, "Selected: \(format(date))", in: self)
        }, onCancel: { [weak self] in
            guard let self else { return }
            LMKToast.show(.info, "Cancelled", in: self)
        })
    }

    @objc private func showFuturePicker() {
        LMKDatePicker.present(.future(title: "Schedule", message: "Choose a future date"), from: self) { [weak self] date in
            guard let self else { return }
            LMKToast.show(.success, "Scheduled: \(format(date))", in: self)
        }
    }

    @objc private func showPastPicker() {
        LMKDatePicker.present(.past(title: "Log Event", message: "When did this happen?"), from: self) { [weak self] date in
            guard let self else { return }
            LMKToast.show(.success, "Logged: \(format(date))", in: self)
        }
    }

    @objc private func showRangePicker() {
        LMKDatePicker.presentRange(from: self, title: "Date Range", message: "Select a start and end date") { [weak self] start, end in
            guard let self else { return }
            LMKToast.show(.success, "\(format(start, style: .medium)) to \(format(end, style: .medium))", in: self)
        }
    }

    @objc private func showCalendarRangePicker() {
        LMKDatePicker.presentCalendarRange(from: self, title: "Calendar Range", message: "Tap to choose a start and end date") { [weak self] start, end in
            guard let self else { return }
            LMKToast.show(.success, "\(format(start, style: .medium)) to \(format(end, style: .medium))", in: self)
        }
    }

    @objc private func showDateWithNotes() {
        LMKDatePicker.presentWithTextField(.past(title: "Add Entry", message: "Pick a date and add a note"), from: self) { [weak self] date, text in
            guard let self else { return }
            LMKToast.show(.success, "\(format(date, style: .medium)): \(text ?? "(no note)")", in: self)
        }
    }
}
