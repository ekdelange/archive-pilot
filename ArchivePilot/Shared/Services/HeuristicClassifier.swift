import Foundation

public protocol HeuristicClassifying {
    func classify(text: String,
                  signals: NLPSignals,
                  candidates: [DirectoryNode],
                  rules: [ArchiveRule],
                  template: String,
                  fileExtension: String) -> ClassificationResult?
}

public final class HeuristicClassifier: HeuristicClassifying {
    private let embeddingGenerator: EmbeddingGenerating

    public init(embeddingGenerator: EmbeddingGenerating) {
        self.embeddingGenerator = embeddingGenerator
    }

    public func classify(text: String,
                         signals: NLPSignals,
                         candidates: [DirectoryNode],
                         rules: [ArchiveRule],
                         template: String,
                         fileExtension: String) -> ClassificationResult? {
        if let ruleMatch = applyRules(text: text, rules: rules, template: template, fileExtension: fileExtension) {
            return ruleMatch
        }

        let textEmbedding = embeddingGenerator.embedding(for: text.lowercased())
        var bestScore: Double = 0
        var bestNode: DirectoryNode?
        for node in candidates {
            guard !node.embedding.isEmpty else { continue }
            let score = embeddingGenerator.cosineSimilarity(between: textEmbedding, and: node.embedding)
            if score > bestScore {
                bestScore = score
                bestNode = node
            }
        }

        guard let chosen = bestNode else { return nil }
        let filename = FilenameSuggester.makeFilename(template: template, fields: signals.toFields(), originalExtension: fileExtension.isEmpty ? "pdf" : fileExtension)
        return ClassificationResult(destinationRelativePath: chosen.relativePath,
                                    proposedFilename: filename,
                                    confidence: bestScore,
                                    rationale: "Embedding similarity heuristic",
                                    fields: signals.toFields())
    }

    private func applyRules(text: String, rules: [ArchiveRule], template: String, fileExtension: String) -> ClassificationResult? {
        let sorted = rules.filter { $0.enabled }.sorted { $0.priority > $1.priority }
        for rule in sorted {
            let tokens = rule.when.containsTokens.map { $0.lowercased() }
            let lower = text.lowercased()
            let matchesAll = tokens.allSatisfy { lower.contains($0) }
            if matchesAll {
                let filename = FilenameSuggester.makeFilename(template: rule.then.filenameTemplate ?? template,
                                                              fields: ExtractedFields(),
                                                              originalExtension: "pdf")
                return ClassificationResult(destinationRelativePath: rule.then.destinationRelativePath,
                                            proposedFilename: filename,
                                            confidence: rule.when.minimumConfidence ?? 0.9,
                                            rationale: "Rule \(rule.name) matched",
                                            fields: ExtractedFields())
            }
        }
        return nil
    }
}

private extension NLPSignals {
    func toFields() -> ExtractedFields {
        ExtractedFields(vendor: vendorCandidates.first,
                        docType: docTypeHints.first,
                        date: detectedDates.sorted().last,
                        amount: detectedAmounts.first?.0,
                        currency: detectedAmounts.first?.1,
                        reference: referenceTokens.first)
    }
}
