import Foundation

final class OpenAIClient: LLMClient {

    // MARK: Dependencies

    private let logger: AppLogger?

    // MARK: Public properties

    let providerID = ProviderID.openAI

    // MARK: Private properties

    private let session: URLSession

    // MARK: Static

    private static let endpoint = URL(string: "https://api.openai.com/v1/responses")!
    private static let requestTimeout: TimeInterval = 20

    // MARK: Init

    init(logger: AppLogger? = nil) {
        self.logger = logger

        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = Self.requestTimeout
        configuration.waitsForConnectivity = false
        session = URLSession(configuration: configuration)
    }

    // MARK: Public methods

    func complete(_ request: LLMRequest, apiKey: String) async throws -> LLMResponse {
        var urlRequest = URLRequest(url: Self.endpoint)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            urlRequest.httpBody = try JSONSerialization.data(withJSONObject: OpenAIRequestBuilder.body(for: request))
        } catch {
            throw AppError.unknown
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: urlRequest)
        } catch {
            throw OpenAIErrorMapper.map(networkError: error)
        }

        guard let httpResponse = response as? HTTPURLResponse else { throw AppError.unknown }

        guard (200...299).contains(httpResponse.statusCode) else {
            logger?.llmHTTPStatus(httpResponse.statusCode, byteCount: data.count)
            throw OpenAIErrorMapper.map(
                httpStatus: httpResponse.statusCode,
                retryAfter: Self.retryAfterSeconds(from: httpResponse)
            )
        }

        return try parse(data: data)
    }

    // MARK: Private methods

    private func parse(data: Data) throws -> LLMResponse {
        let envelope: OpenAIResponseEnvelope
        do {
            envelope = try JSONDecoder().decode(OpenAIResponseEnvelope.self, from: data)
        } catch {
            logger?.llmHTTPStatus(200, byteCount: data.count)
            throw AppError.malformedResponse
        }

        let inputTokens = envelope.usage?.inputTokens ?? 0
        let outputTokens = envelope.usage?.outputTokens ?? 0

        guard envelope.ranOutOfOutputBudget == false else {
            return LLMResponse(
                rawJSON: Data(),
                inputTokens: inputTokens,
                outputTokens: outputTokens,
                isTruncated: true
            )
        }

        guard let text = envelope.outputText, let jsonData = text.data(using: .utf8) else {
            throw AppError.malformedResponse
        }

        return LLMResponse(
            rawJSON: jsonData,
            inputTokens: inputTokens,
            outputTokens: outputTokens,
            isTruncated: false
        )
    }

    private static func retryAfterSeconds(from response: HTTPURLResponse) -> TimeInterval? {
        guard let value = response.value(forHTTPHeaderField: "Retry-After") else { return nil }
        return TimeInterval(value)
    }
}
