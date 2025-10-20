import XCTest
@testable import ArchivePilot

final class ClassificationPipelineTests: XCTestCase {
    func testFilenameSuggesterFillsTemplate() {
        let fields = ExtractedFields(vendor: "Acme", docType: "Invoice", date: Date(timeIntervalSince1970: 0), amount: 129.99, currency: "USD", reference: "123")
        let filename = FilenameSuggester.makeFilename(template: "yyyy-MM-dd__Vendor__DocType__Amount", fields: fields, originalExtension: "pdf")
        XCTAssertTrue(filename.contains("Acme"))
        XCTAssertTrue(filename.contains("Invoice"))
    }

    func testHeuristicClassifierUsesRules() {
        let embedding = MockEmbedding()
        let classifier = HeuristicClassifier(embeddingGenerator: embedding)
        let rule = ArchiveRule(name: "Invoices",
                               when: .init(containsTokens: ["invoice"], metadata: [:], minimumConfidence: 0.9),
                               then: .init(destinationRelativePath: "/Invoices", filenameTemplate: "yyyy__Vendor"),
                               priority: 100,
                               enabled: true)
        let signals = NLPSignals(language: "en", detectedDates: [], detectedAmounts: [], vendorCandidates: [], docTypeHints: [], referenceTokens: [])
        let result = classifier.classify(text: "Invoice", signals: signals, candidates: [], rules: [rule], template: "default", fileExtension: "pdf")
        XCTAssertEqual(result?.destinationRelativePath, "/Invoices")
    }
}

private final class MockEmbedding: EmbeddingGenerating {
    func embedding(for string: String) -> [Double] { [1, 0, 0] }
    func cosineSimilarity(between lhs: [Double], and rhs: [Double]) -> Double { 1 }
}
