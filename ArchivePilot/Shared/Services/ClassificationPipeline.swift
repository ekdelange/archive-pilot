import Foundation
import UniformTypeIdentifiers

public protocol ClassificationPipelining {
    func classify(url: URL,
                  type: UTType,
                  userInstruction: String?,
                  bookmarks: [String: Data]) async -> Result<ClassificationResult, Error>
}

public final class ClassificationPipeline: ClassificationPipelining {
    private let textExtractor: TextExtracting
    private let nlpService: NLProcessing
    private let heuristic: HeuristicClassifying
    private let preferencesStore: PreferencesStoring
    private let rulesStore: RulesStoring
    private let directoryIndexer: DirectoryIndexing
    private let foundationFactory: () throws -> Any
    private let openAIClient: RemoteLLMServicing?

    public init(textExtractor: TextExtracting,
                nlpService: NLProcessing,
                heuristic: HeuristicClassifying,
                preferencesStore: PreferencesStoring,
                rulesStore: RulesStoring,
                directoryIndexer: DirectoryIndexing,
                foundationFactory: @escaping () throws -> Any,
                openAIClient: RemoteLLMServicing?) {
        self.textExtractor = textExtractor
        self.nlpService = nlpService
        self.heuristic = heuristic
        self.preferencesStore = preferencesStore
        self.rulesStore = rulesStore
        self.directoryIndexer = directoryIndexer
        self.foundationFactory = foundationFactory
        self.openAIClient = openAIClient
    }

    public func classify(url: URL,
                         type: UTType,
                         userInstruction: String?,
                         bookmarks: [String: Data]) async -> Result<ClassificationResult, Error> {
        do {
            let text = try await textExtractor.extractText(from: url, type: type)
            let documentText = text + "\n" + (userInstruction ?? "")
            let signals = nlpService.analyze(text: documentText)
            let preferences = preferencesStore.loadPreferences()
            let rules = rulesStore.loadRules()
            let directories = try await directoryIndexer.refreshIndex(from: bookmarks)
            let flat = directoryIndexer.flatten(nodes: directories)

            if #available(iOS 18.4, *), preferences.useAppleIntelligence {
                if let hints = try await attemptFoundation(documentText: documentText,
                                                            signals: signals,
                                                            preferences: preferences,
                                                            candidates: flat) {
                    let fields = signals.toFields()
                    let filename = hints.filename.isEmpty ? FilenameSuggester.makeFilename(template: preferences.namingTemplate, fields: fields, originalExtension: url.pathExtension) : hints.filename
                    let result = ClassificationResult(destinationRelativePath: hints.path,
                                                      proposedFilename: filename,
                                                      confidence: hints.confidence,
                                                      rationale: hints.reason,
                                                      fields: fields)
                    if result.confidence >= preferences.confidenceThreshold {
                        return .success(result)
                    }
                }
            }

            if let heuristicResult = heuristic.classify(text: documentText,
                                                         signals: signals,
                                                         candidates: flat,
                                                         rules: rules,
                                                         template: preferences.namingTemplate,
                                                         fileExtension: url.pathExtension) {
                if heuristicResult.confidence >= preferences.confidenceThreshold {
                    return .success(heuristicResult)
                }
            }

            if preferences.useOpenAI, let openAIClient {
                let hints = try await openAIClient.classify(snippet: String(documentText.prefix(1200)),
                                                            signals: signals,
                                                            candidates: flat,
                                                            preferences: preferences)
                let fields = signals.toFields()
                let filename = hints.filename.isEmpty ? FilenameSuggester.makeFilename(template: preferences.namingTemplate, fields: fields, originalExtension: url.pathExtension) : hints.filename
                let result = ClassificationResult(destinationRelativePath: hints.path,
                                                  proposedFilename: filename,
                                                  confidence: hints.confidence,
                                                  rationale: hints.reason,
                                                  fields: fields)
                return .success(result)
            }

            return .failure(NSError(domain: "ClassificationPipeline", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unable to classify with sufficient confidence"]))
        } catch {
            return .failure(error)
        }
    }

    @available(iOS 18.4, *)
    private func attemptFoundation(documentText: String,
                                   signals: NLPSignals,
                                   preferences: UserPreferences,
                                   candidates: [DirectoryNode]) async throws -> ClassificationHints? {
        guard let service = try foundationFactory() as? FoundationClassifying else { return nil }
        return try await service.classify(document: documentText,
                                          signals: signals,
                                          candidates: candidates,
                                          preferences: preferences,
                                          condensedMetadata: [:])
    }
}

private extension NLPSignals {
    func toFields() -> ExtractedFields {
        ExtractedFields(vendor: vendorCandidates.first,
                        docType: docTypeHints.first,
                        date: detectedDates.last,
                        amount: detectedAmounts.first?.0,
                        currency: detectedAmounts.first?.1,
                        reference: referenceTokens.first)
    }
}
