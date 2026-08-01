import Observation

@MainActor
@Observable
final class MenuBarViewModel {

    // MARK: Dependencies

    private let usageMeter: UsageMetering

    // MARK: Public properties

    private(set) var isOverBudget = false

    // MARK: Init

    init(usageMeter: UsageMetering) {
        self.usageMeter = usageMeter
    }

    // MARK: Public methods

    func refresh() async {
        let snapshot = await usageMeter.snapshot()
        isOverBudget = snapshot.costMonthUSD > snapshot.budgetMonthUSD
    }
}
