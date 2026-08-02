struct SourceText: Sendable, Equatable {
    enum Origin: Sendable, Equatable {
        case pasteboard(isReused: Bool)
        case service
        case manual
        case chained
    }

    let content: String
    let language: TextLanguage
    let origin: Origin
}
