import Foundation

struct UsageSnapshot: Sendable, Equatable {
    let inputTokensToday: Int
    let outputTokensToday: Int
    let costTodayUSD: Decimal
    let costMonthUSD: Decimal
    let budgetMonthUSD: Decimal
}
