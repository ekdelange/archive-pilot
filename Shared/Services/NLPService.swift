import Foundation
import NaturalLanguage

public struct NLPSignals {
    public var language: String
    public var detectedDates: [Date]
    public var detectedAmounts: [(Decimal, String?)]
    public var vendorCandidates: [String]
    public var docTypeHints: [String]
    public var referenceTokens: [String]
}

public protocol NLProcessing {
    func analyze(text: String) -> NLPSignals
}

public final class NLPService: NLProcessing {
    private let tagger: NLTagger
    private let detector: NSDataDetector
    private let numberFormatter: NumberFormatter

    public init() {
        self.tagger = NLTagger(tagSchemes: [.nameType, .lemma])
        self.detector = try! NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue | NSTextCheckingResult.CheckingType.link.rawValue | NSTextCheckingResult.CheckingType.phoneNumber.rawValue)
        self.numberFormatter = NumberFormatter()
        self.numberFormatter.numberStyle = .decimal
        self.numberFormatter.locale = Locale(identifier: "en_US_POSIX")
    }

    public func analyze(text: String) -> NLPSignals {
        tagger.string = text
        var vendors: Set<String> = []
        var docTypes: Set<String> = []
        var references: Set<String> = []
        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .nameType, options: [.omitWhitespace, .omitPunctuation]) { tag, tokenRange in
            guard let tag else { return true }
            let token = String(text[tokenRange])
            if tag == .organization {
                vendors.insert(token)
            }
            if token.lowercased().contains("invoice") || token.lowercased().contains("receipt") {
                docTypes.insert("Invoice")
            }
            if token.lowercased().contains("contract") {
                docTypes.insert("Contract")
            }
            if token.lowercased().contains("policy") {
                docTypes.insert("Policy")
            }
            if token.lowercased().contains("ref") || token.lowercased().contains("order") {
                references.insert(token)
            }
            return true
        }

        var dates: [Date] = []
        detector.enumerateMatches(in: text, options: [], range: NSRange(location: 0, length: (text as NSString).length)) { result, _, _ in
            if let date = result?.date {
                dates.append(date)
            }
        }

        let amountPattern = try! NSRegularExpression(pattern: "([A-Z]{3})?\\s?([0-9]+[.,][0-9]{2})")
        let nsText = text as NSString
        let matches = amountPattern.matches(in: text, range: NSRange(location: 0, length: nsText.length))
        let amounts: [(Decimal, String?)] = matches.compactMap { match in
            let currencyRange = match.range(at: 1)
            let amountRange = match.range(at: 2)
            let currency = currencyRange.location != NSNotFound ? nsText.substring(with: currencyRange) : nil
            let rawAmount = nsText.substring(with: amountRange).replacingOccurrences(of: ",", with: ".")
            if let value = Decimal(string: rawAmount) {
                return (value, currency)
            }
            return nil
        }

        let language = NLLanguageRecognizer.dominantLanguage(for: text)?.rawValue ?? Locale.current.language.languageCode?.identifier ?? "en"

        return NLPSignals(language: language,
                           detectedDates: dates,
                           detectedAmounts: amounts,
                           vendorCandidates: Array(vendors),
                           docTypeHints: Array(docTypes),
                           referenceTokens: Array(references))
    }
}
