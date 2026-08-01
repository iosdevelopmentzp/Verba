protocol TextCapturing: Sendable {
    func capture() async throws -> CapturedText?
}
