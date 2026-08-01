import Foundation

struct LLMResponse: Sendable {
    let rawJSON: Data
    let inputTokens: Int
    let outputTokens: Int
    let isTruncated: Bool
}
