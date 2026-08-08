enum ActionRegistry {
    static let all: [TextAction] = [
        TextAction(
            id: .fixGrammar,
            titleEnglish: "Fix grammar",
            numberKey: 1,
            templateID: "fixGrammar",
            tier: .economy,
            needsParameters: false,
            supportsExplanation: true,
            supportsDiff: true
        ),
        TextAction(
            id: .rephrase,
            titleEnglish: "Rephrase",
            numberKey: 2,
            templateID: "rephrase",
            tier: .standard,
            needsParameters: false,
            supportsExplanation: false,
            supportsDiff: true
        ),
        TextAction(
            id: .changeTone,
            titleEnglish: "Change tone",
            numberKey: 3,
            templateID: "changeTone",
            tier: .standard,
            needsParameters: true,
            supportsExplanation: false,
            supportsDiff: true
        ),
        TextAction(
            id: .translate,
            titleEnglish: "Translate",
            numberKey: 4,
            templateID: "translate",
            tier: .economy,
            needsParameters: false,
            supportsExplanation: false,
            supportsDiff: false
        ),
        TextAction(
            id: .humanize,
            titleEnglish: "Humanize",
            numberKey: 5,
            templateID: "humanize",
            tier: .standard,
            needsParameters: true,
            supportsExplanation: false,
            supportsDiff: true
        ),
        TextAction(
            id: .shorten,
            titleEnglish: "Make shorter",
            numberKey: 6,
            templateID: "shorten",
            tier: .standard,
            needsParameters: false,
            supportsExplanation: false,
            supportsDiff: true
        )
    ]
}
