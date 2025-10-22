import Foundation

public protocol RemoteLLMServicing {
    func classify(snippet: String,
                  signals: NLPSignals,
                  candidates: [DirectoryNode],
                  preferences: UserPreferences) async throws -> ClassificationHints
}

public final class OpenAIClient: RemoteLLMServicing {
    private let session: URLSession
    private let keyProvider: () -> String?

    public init(session: URLSession = .shared, keyProvider: @escaping () -> String?) {
        self.session = session
        self.keyProvider = keyProvider
    }

    public func classify(snippet: String,
                         signals: NLPSignals,
                         candidates: [DirectoryNode],
                         preferences: UserPreferences) async throws -> ClassificationHints {
        guard let key = keyProvider() else {
            throw NSError(domain: "OpenAIClient", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing API key"])
        }
        let url = URL(string: "https://api.openai.com/v1/responses")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let payload: [String: Any] = [
            "model": preferences.openAIModel,
            "input": [
                [
                    "role": "system",
                    "content": "You are a document-filing assistant running on device. Follow the user’s rules and folder names. Output strict JSON with keys: `path`, `filename`, `confidence` (0–1), `reason`."
                ],
                [
                    "role": "user",
                    "content": [
                        "text": snippet,
                        "fields": signals.vendorCandidates,
                        "folders": candidates.map { $0.relativePath },
                        "template": preferences.namingTemplate,
                        "systemMessage": preferences.systemMessage
                    ]
                ]
            ]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: payload, options: [])

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw NSError(domain: "OpenAIClient", code: -2, userInfo: [NSLocalizedDescriptionKey: "Unexpected response"])
        }
        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
           let resultText = (json["output"] as? [[String: Any]])?.compactMap({ $0["content"] as? String }).joined(),
           let resultData = resultText.data(using: .utf8) {
            return try JSONDecoder().decode(ClassificationHints.self, from: resultData)
        }
        throw NSError(domain: "OpenAIClient", code: -3, userInfo: [NSLocalizedDescriptionKey: "Malformed response"])
    }
}
