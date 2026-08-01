import Foundation

enum OpenAIRequestBuilder {

    // MARK: Static

    static let schemaName = "verba_result"

    // MARK: Public methods

    static func body(for request: LLMRequest) -> [String: Any] {
        [
            "model": request.modelID,
            "input": [
                ["role": "system", "content": request.systemPrompt],
                ["role": "user", "content": request.userContent]
            ],
            "text": [
                "verbosity": "low",
                "format": [
                    "type": "json_schema",
                    "name": schemaName,
                    "schema": JSONValue.object(request.jsonSchema).foundationObject,
                    "strict": true
                ]
            ],
            "reasoning": [
                "effort": request.minimalReasoningEffort ? "minimal" : "low"
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
