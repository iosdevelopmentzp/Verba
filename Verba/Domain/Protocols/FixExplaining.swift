protocol FixExplaining: Sendable {
    func explainFixes(original: String, corrected: String, notes: [String], language: TextLanguage) async throws -> [FixExplanation]
}
