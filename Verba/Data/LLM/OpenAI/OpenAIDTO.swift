import Foundation

enum OpenAIRequestBuilder {

    // MARK: Static

    static let schemaName = "verba_result"

    // MARK: Public methods

    static func reasoningEffort(for creativity: Creativity, modelID: String) -> String {
        guard creativity != .creative else { return "low" }
        return ModelCatalog.entry(id: modelID)?.lowestReasoningEffort ?? ModelCatalog.universalReasoningEffort
    }

    static func verbosity(for creativity: Creativity) -> String {
        creativity == .creative ? "medium" : "low"
    }

    static func body(for request: LLMRequest) -> [String: Any] {
        [
            "model": request.modelID,
            "input": [
                ["role": "system", "content": request.systemPrompt],
                ["role": "user", "content": request.userContent]
            ],
            "text": [
                "verbosity": verbosity(for: request.creativity),
                "format": [
                    "type": "json_schema",
                    "name": schemaName,
                    "schema": JSONValue.object(request.jsonSchema).foundationObject,
                    "strict": true
                ]
            ],
            "reasoning": [
                "effort": reasoningEffort(for: request.creativity, modelID: request.modelID)
            ],
            "max_output_tokens": request.maxOutputTokens
        ]
    }
}

struct OpenAIResponseEnvelope: Decodable {
    let output: [OutputItem]
    let usage: Usage?
    let status: String?
    let incompleteDetails: IncompleteDetails?

    var ranOutOfOutputBudget: Bool {
        status == "incomplete" && incompleteDetails?.reason == "max_output_tokens"
    }

    enum CodingKeys: String, CodingKey {
        case output
        case usage
        case status
        case incompleteDetails = "incomplete_details"
    }

    var outputText: String? {
        output
            .first(where: { $0.type == "message" })?
            .content?
            .first(where: { $0.type == "output_text" })?
            .text
    }

    struct OutputItem: Decodable {
        let type: String
        let content: [ContentItem]?
    }

    struct IncompleteDetails: Decodable {
        let reason: String?
    }

    struct ContentItem: Decodable {
        let type: String
        let text: String?
    }

    struct Usage: Decodable {
        let inputTokens: Int
        let outputTokens: Int

        enum CodingKeys: String, CodingKey {
            case inputTokens = "input_tokens"
            case outputTokens = "output_tokens"
        }
    }
}
