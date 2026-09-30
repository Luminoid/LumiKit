//
//  DateFormattingExample.swift
//  LumiKitExample
//
//  Date Formatting: LMKDateFormat styles, ranges, clock times; LMKFormat numbers.
//

import LumiKitCore
import LumiKitUI
import SnapKit
import UIKit

// MARK: - Date Formatting

final class DateFormattingDetailViewController: DetailViewController {
    private let samplesStack = UIStackView(lmk_axis: .vertical, spacing: LMKSpacing.medium)
    private var hourCycle: LMKDateFormat.HourCycle = .system

    override func viewDidLoad() {
        super.viewDidLoad()

        addSectionHeader("LMKDateFormat")
        stack.addArrangedSubview(UILabel.lmk_make(
            .caption,
            text: "Locale-aware date strings through one namespace: styles, ranges, residence spans, relative days, and clock times. "
                + "Every call takes a Context (locale, calendar, time zone, hour cycle); Context.default follows the device until the app replaces it."
        ))

        let cycle = LMKSegmentedControl(items: ["System", "12-hour", "24-hour"])
        cycle.onValueChange = { [weak self] index in
            self?.hourCycle = [.system, .twelveHour, .twentyFourHour][index]
            self?.renderSamples()
        }
        stack.addArrangedSubview(cycle)
        stack.addArrangedSubview(samplesStack)
        renderSamples()

        addDivider()
        addSectionHeader("LMKFormat")
        let numbers = UIStackView(lmk_axis: .vertical, spacing: LMKSpacing.medium)
        numbers.addArrangedSubview(makeRow("number(1234.5)", LMKFormat.number(1234.5)))
        numbers.addArrangedSubview(makeRow("number(1_234_567)", LMKFormat.number(1_234_567)))
        numbers.addArrangedSubview(makeRow("percent(0.756)", LMKFormat.percent(0.756)))
        numbers.addArrangedSubview(makeRow("percent(0.756, 1…1)", LMKFormat.percent(0.756, fractionDigits: 1 ... 1)))
        numbers.addArrangedSubview(makeRow("progressPercent(0.75)", LMKFormat.progressPercent(0.75)))
        stack.addArrangedSubview(numbers)
    }

    private func renderSamples() {
        samplesStack.lmk_removeAllArrangedSubviews()
        let context = LMKDateFormat.Context.default.hourCycle(hourCycle)
        let now = Date()
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: now) ?? now
        let nextWeek = calendar.date(byAdding: .day, value: 7, to: now) ?? now
        let yearsAgo = calendar.date(byAdding: .year, value: -3, to: now) ?? now
        let evening = calendar.date(bySettingHour: 20, minute: 0, second: 0, of: now) ?? now
        let tokyo = TimeZone(identifier: "Asia/Tokyo") ?? .current

        let samples: [(String, String)] = [
            ("string(now)", LMKDateFormat.string(now, context: context)),
            ("string(now, date: .long)", LMKDateFormat.string(now, date: .long, context: context)),
            ("string(now, date: .full, time: .short)", LMKDateFormat.string(now, date: .full, time: .short, context: context)),
            ("string(now, date: .weekdayMonthDay)", LMKDateFormat.string(now, date: .weekdayMonthDay, context: context)),
            ("monthYearString(now)", LMKDateFormat.monthYearString(now, context: context)),
            ("string(now, date: .custom(\"yyyy-MM-dd\"))", LMKDateFormat.string(now, date: .custom(pattern: "yyyy-MM-dd"), context: context)),
            ("rangeLabel(now, nextWeek)", LMKDateFormat.rangeLabel(start: now, end: nextWeek, context: context) ?? ""),
            ("residenceLabel(yearsAgo, nil)", LMKDateFormat.residenceLabel(start: yearsAgo, end: nil, context: context) ?? ""),
            ("relativeDayString(tomorrow)", LMKDateFormat.relativeDayString(tomorrow, context: context)),
            ("relativeDayString(nextWeek)", LMKDateFormat.relativeDayString(nextWeek, context: context)),
            ("clockTime(evening)", LMKDateFormat.clockTime(evening, context: context) ?? ""),
            ("clockTime(now, in Tokyo)", LMKDateFormat.clockTime(now, context: context.timeZone(tokyo)) ?? ""),
            ("dateWithClockTime(evening)", LMKDateFormat.dateWithClockTime(evening, context: context)),
            ("widestClockSample()", LMKDateFormat.widestClockSample(context: context)),
            ("usesTwelveHourClock()", LMKDateFormat.usesTwelveHourClock(context: context) ? "true" : "false"),
            ("weekdaySymbols()", LMKDateFormat.weekdaySymbols(context: context).joined(separator: " ")),
        ]
        for (api, value) in samples {
            samplesStack.addArrangedSubview(makeRow(api, value))
        }
    }

    /// The call above its result. Stacked, because a call and a long date rarely fit side by side,
    /// and two wrapping labels in one row would size each other differently on every layout pass.
    private func makeRow(_ api: String, _ value: String) -> UIStackView {
        let apiLabel = UILabel.lmk_make(.small, text: api, color: LMKColor.textSecondary)
        apiLabel.font = UIFont.monospacedSystemFont(ofSize: apiLabel.font.pointSize, weight: .regular)
        apiLabel.numberOfLines = 0
        let valueLabel = UILabel.lmk_make(.body, text: value)
        valueLabel.numberOfLines = 0
        return UIStackView(lmk_axis: .vertical, spacing: LMKSpacing.xxs, arrangedSubviews: [apiLabel, valueLabel])
    }
}
