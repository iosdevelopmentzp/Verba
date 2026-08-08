enum SpeechVoiceQuality: Int, Sendable, Comparable {
    case missing
    case compact
    case enhanced
    case premium

    static func < (lhs: SpeechVoiceQuality, rhs: SpeechVoiceQuality) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
