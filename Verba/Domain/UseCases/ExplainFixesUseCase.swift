struct ExplainFixesUseCase: Sendable {

    // MARK: Dependencies

    private let explainer: FixExplaining

    // MARK: Init

    init(explainer: FixExplaining) {
        self.explainer = explainer
    }

    // MARK: Public methods

    func execute(original: String, corrected: String, notes: [String], language: TextLanguage) async throws -> [String] {
        try await explainer.explainFixes(original: original, corrected: corrected, notes: notes, language: language)
    }
}
