import Foundation

struct ModelCatalogEntry: Sendable, Equatable, Identifiable {
    let id: String
    let displayName: String
    let providerID: String
    let inputPricePerMillionUSD: Decimal
    let outputPricePerMillionUSD: Decimal
    let tier: ModelTier
    // gpt-5.6 rejects "minimal"; gpt-5 nano/mini reject "none". No value is valid for both.
    let lowestReasoningEffort: String
}

enum ModelCatalog {
    static let all: [ModelCatalogEntry] = [
        ModelCatalogEntry(
            id: "gpt-5.6-luna",
            displayName: "GPT-5.6 Luna",
            providerID: ProviderID.openAI,
            inputPricePerMillionUSD: 0.20,
            outputPricePerMillionUSD: 1.20,
            tier: .standard,
            lowestReasoningEffort: "none"
        ),
        ModelCatalogEntry(
            id: "gpt-5.6-terra",
            displayName: "GPT-5.6 Terra",
            providerID: ProviderID.openAI,
            inputPricePerMillionUSD: 2.00,
            outputPricePerMillionUSD: 12.00,
            tier: .standard,
            lowestReasoningEffort: "none"
        ),
        ModelCatalogEntry(
            id: "gpt-5-nano",
            displayName: "GPT-5 nano",
            providerID: ProviderID.openAI,
            inputPricePerMillionUSD: 0.05,
            outputPricePerMillionUSD: 0.40,
            tier: .economy,
            lowestReasoningEffort: "minimal"
        )
    ]

    static let universalReasoningEffort = "low"

    static func entry(id: String) -> ModelCatalogEntry? {
        all.first { $0.id == id }
    }

    static func models(providerID: String) -> [ModelCatalogEntry] {
        all.filter { $0.providerID == providerID }
    }

    static func defaultModel(providerID: String, tier: ModelTier) -> ModelCatalogEntry? {
        all.first { $0.providerID == providerID && $0.tier == tier }
    }
}
