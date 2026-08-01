protocol ResultDelivering: Sendable {
    func deliver(_ text: String) async
}
