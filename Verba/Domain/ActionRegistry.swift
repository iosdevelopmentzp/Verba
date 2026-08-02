enum ActionRegistry {
    static let all: [TextAction] = [
        TextAction(
            id: .fixGrammar,
            titleEnglish: "Fix grammar",
            titleRussian: "Исправить грамматику",
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
            titleRussian: "Перефразировать",
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
            titleRussian: "Изменить тон",
            numberKey: 3,
            templateID: "changeTone",
            tier: .standard,
            needsParameters: true,
            supportsExplanation: false,
            supportsDiff: true
        ),
        TextAction(
            id: .translate,
            titleEnglish: "Translate RU⇄EN",
            titleRussian: "Перевести RU⇄EN",
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
            titleRussian: "Сделать человечнее",
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
            titleRussian: "Сделать короче",
            numberKey: 6,
            templateID: "shorten",
            tier: .standard,
            needsParameters: false,
            supportsExplanation: false,
            supportsDiff: true
        )
    ]
}
