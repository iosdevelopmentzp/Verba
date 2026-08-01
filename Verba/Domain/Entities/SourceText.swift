struct SourceText: Sendable, Equatable {
    enum Origin: Sendable, Equatable {
        case pasteboard(isReused: Bool)
        case service
        case manual
    }

    let content: String
    let language: TextLanguage
    let origin: Origin
}
