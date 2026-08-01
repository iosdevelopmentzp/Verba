protocol ResultCaching: Sendable {
    func value(for key: String) async -> ActionResult?
    func store(_ result: ActionResult, for key: String) async
}
