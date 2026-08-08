enum TextLanguage: String, Sendable, Codable, CaseIterable {
    case english
    case russian
    case ukrainian
    case spanish
    case other

    static let selectable: [TextLanguage] = [.english, .ukrainian, .spanish, .russian]
}
