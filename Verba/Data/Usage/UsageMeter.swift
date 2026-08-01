import Foundation

actor UsageMeter: UsageMetering {

    // MARK: Dependencies

    private let preferences: PreferenceStoring
    private let logger: AppLogger

    // MARK: Private properties

    private var defaults: UserDefaults { .standard }
    private let calendar: Calendar

    // MARK: Static

    private static let dayBucketKey = "usage.day.bucket"
    private static let dayInputTokensKey = "usage.day.inputTokens"
    private static let dayOutputTokensKey = "usage.day.outputTokens"
    private static let dayCostKey = "usage.day.costUSD"
    private static let monthBucketKey = "usage.month.bucket"
    private static let monthCostKey = "usage.month.costUSD"

    // MARK: Init

    init(preferences: PreferenceStoring, logger: AppLogger, calendar: Calendar = .current) {
        self.preferences = preferences
        self.logger = logger
        self.calendar = calendar
    }

    // MARK: Public methods

    func record(inputTokens: Int, outputTokens: Int, modelID: String) async {
        rolloverBucketsIfNeeded()

        let cost = Self.cost(inputTokens: inputTokens, outputTokens: outputTokens, modelID: modelID)

        defaults.set(dayInputTokens + inputTokens, forKey: Self.dayInputTokensKey)
        defaults.set(dayOutputTokens + outputTokens, forKey: Self.dayOutputTokensKey)
        defaults.set(NSDecimalNumber(decimal: dayCost + cost), forKey: Self.dayCostKey)
        defaults.set(NSDecimalNumber(decimal: monthCost + cost), forKey: Self.monthCostKey)

        logger.usageRecorded(modelID: modelID, inputTokens: inputTokens, outputTokens: outputTokens)
    }

    func snapshot() async -> UsageSnapshot {
        rolloverBucketsIfNeeded()
        return UsageSnapshot(
            inputTokensToday: dayInputTokens,
            outputTokensToday: dayOutputTokens,
            costTodayUSD: dayCost,
            costMonthUSD: monthCost,
            budgetMonthUSD: preferences.monthlyBudgetUSD
        )
    }

    // MARK: Private methods

    private var dayInputTokens: Int { defaults.integer(forKey: Self.dayInputTokensKey) }
    private var dayOutputTokens: Int { defaults.integer(forKey: Self.dayOutputTokensKey) }

    private var dayCost: Decimal {
        (defaults.object(forKey: Self.dayCostKey) as? NSDecimalNumber)?.decimalValue ?? 0
    }

    private var monthCost: Decimal {
        (defaults.object(forKey: Self.monthCostKey) as? NSDecimalNumber)?.decimalValue ?? 0
    }

    private func rolloverBucketsIfNeeded() {
        let today = Self.dayString(for: Date(), calendar: calendar)
        if defaults.string(forKey: Self.dayBucketKey) != today {
            defaults.set(today, forKey: Self.dayBucketKey)
            defaults.set(0, forKey: Self.dayInputTokensKey)
            defaults.set(0, forKey: Self.dayOutputTokensKey)
            defaults.set(NSDecimalNumber.zero, forKey: Self.dayCostKey)
        }

        let month = Self.monthString(for: Date(), calendar: calendar)
        if defaults.string(forKey: Self.monthBucketKey) != month {
            defaults.set(month, forKey: Self.monthBucketKey)
            defaults.set(NSDecimalNumber.zero, forKey: Self.monthCostKey)
        }
    }

    private static func cost(inputTokens: Int, outputTokens: Int, modelID: String) -> Decimal {
        guard let entry = ModelCatalog.entry(id: modelID) else { return 0 }
        let inputCost = entry.inputPricePerMillionUSD * Decimal(inputTokens) / 1_000_000
        let outputCost = entry.outputPricePerMillionUSD * Decimal(outputTokens) / 1_000_000
        return inputCost + outputCost
    }

    private static func dayString(for date: Date, calendar: Calendar) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return "\(components.year ?? 0)-\(components.month ?? 0)-\(components.day ?? 0)"
    }

    private static func monthString(for date: Date, calendar: Calendar) -> String {
        let components = calendar.dateComponents([.year, .month], from: date)
        return "\(components.year ?? 0)-\(components.month ?? 0)"
    }
}
