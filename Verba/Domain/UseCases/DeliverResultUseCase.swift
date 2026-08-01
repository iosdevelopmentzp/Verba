struct DeliverResultUseCase: Sendable {

    // MARK: Dependencies

    private let resultDeliverer: ResultDelivering

    // MARK: Init

    init(resultDeliverer: ResultDelivering) {
        self.resultDeliverer = resultDeliverer
    }

    // MARK: Public methods

    func execute(_ text: String) async {
        await resultDeliverer.deliver(text)
    }
}
