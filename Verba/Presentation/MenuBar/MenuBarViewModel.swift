import Foundation
import Observation

@MainActor
@Observable
final class MenuBarViewModel {

    // MARK: Dependencies

    private let usageMeter: UsageMetering

    // MARK: Public properties

    private(set) var isOverBudget = false
    private(set) var costToday = "$0.00"
    private(set) var costMonth = "$0.00"

    // MARK: Init

    init(usageMeter: UsageMetering) {
        self.usageMeter = usageMeter
    }

    // MARK: Public methods

    func refresh() async {
        let snapshot = await usageMeter.snapshot()
        isOverBudget = snapshot.costMonthUSD > snapshot.budgetMonthUSD
        costToday = Self.formatted(snapshot.costTodayUSD)
        costMonth = Self.formatted(snapshot.costMonthUSD)
    }

    // MARK: Private methods

    private static func formatted(_ amount: Decimal) -> String {
        amount.formatted(.currency(code: "USD").precision(.fractionLength(2)))
    }
}
