import Foundation
import AppleIntelligence

@available(iOS 18.4, *)
public protocol FoundationClassifying {
    func classify(document: String,
                  signals: NLPSignals,
                  candidates: [DirectoryNode],
                  preferences: UserPreferences,
                  condensedMetadata: [String: String]) async throws -> ClassificationHints
}

@available(iOS 18.4, *)
public final class FoundationLLMService: FoundationClassifying {
    private let model: AIModel<AITextClassifier>

    public init(configuration: AIModelConfiguration = AIModelConfiguration()) throws {
        self.model = try AIModel(classificationWithIdentifier: "com.apple.archivepilot.classifier", configuration: configuration)
    }

    public func classify(document: String,
                         signals: NLPSignals,
                         candidates: [DirectoryNode],
                         preferences: UserPreferences,
                         condensedMetadata: [String: String]) async throws -> ClassificationHints {
        let systemPrompt = "You are a document-filing assistant running on device. Follow the user’s rules and folder names. Output strict JSON with keys: `path`, `filename`, `confidence` (0–1), `reason`."
        let folders = candidates.map { $0.relativePath }
        let fieldsDict: [String: String] = [
            "vendor": signals.vendorCandidates.first ?? "",
            "docType": signals.docTypeHints.first ?? "",
            "date": signals.detectedDates.last.map { ISO8601DateFormatter().string(from: $0) } ?? "",
            "amount": signals.detectedAmounts.first.map { String(describing: $0.0) } ?? "",
            "currency": signals.detectedAmounts.first?.1 ?? "",
            "reference": signals.referenceTokens.first ?? ""
        ]
        let userPrompt = [
            "text": document.prefix(4000),
            "fields": fieldsDict,
            "systemMessage": preferences.systemMessage,
            "folders": folders,
            "template": preferences.namingTemplate,
            "metadata": condensedMetadata
        ] as NSDictionary

        let input = AITextClassifier.Input(document: String(document.prefix(4000)))
        input.userPrompt = userPrompt
        input.systemPrompt = systemPrompt

        let output = try await model.prediction(from: input)
        guard let json = output.label, let data = json.data(using: .utf8) else {
            throw NSError(domain: "FoundationLLM", code: -1, userInfo: [NSLocalizedDescriptionKey: "No JSON response"])
        }
        let hints = try JSONDecoder().decode(ClassificationHints.self, from: data)
        return hints
    }
}
