import Foundation

struct ModelCatalogEntry: Sendable, Equatable, Identifiable {
    let id: String
    let displayName: String
    let providerID: String
    let inputPricePerMillionUSD: Decimal
    let outputPricePerMillionUSD: Decimal
    let tier: ModelTier
}

enum ModelCatalog {
    static let all: [ModelCatalogEntry] = [
        ModelCatalogEntry(
            id: "gpt-5-mini",
            displayName: "GPT-5 mini",
            providerID: ProviderID.openAI,
            inputPricePerMillionUSD: 0.25,
            outputPricePerMillionUSD: 2.00,
            tier: .standard
        ),
        ModelCatalogEntry(
            id: "gpt-5-nano",
            displayName: "GPT-5 nano",
            providerID: ProviderID.openAI,
            inputPricePerMillionUSD: 0.05,
            outputPricePerMillionUSD: 0.40,
            tier: .economy
        )
    ]

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
