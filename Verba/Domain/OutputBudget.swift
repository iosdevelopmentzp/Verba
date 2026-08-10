enum OutputBudget {
    // A translation is roughly as long as its input, so alternatives double the
    // billed output for a result the user rarely reads on a long message.
    static func allowsAlternatives(action: TextAction, characterCount: Int) -> Bool {
        guard action.id == .translate else { return true }
        return characterCount <= InputLimits.softWarn
    }
}
