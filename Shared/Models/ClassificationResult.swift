import Foundation

public struct ExtractedFields: Codable, Hashable {
    public var vendor: String?
    public var docType: String?
    public var date: Date?
    public var amount: Decimal?
    public var currency: String?
    public var reference: String?

    public init(vendor: String? = nil,
                docType: String? = nil,
                date: Date? = nil,
                amount: Decimal? = nil,
                currency: String? = nil,
                reference: String? = nil) {
        self.vendor = vendor
        self.docType = docType
        self.date = date
        self.amount = amount
        self.currency = currency
        self.reference = reference
    }
}

public struct ClassificationResult: Codable, Hashable {
    public var destinationRelativePath: String
    public var proposedFilename: String
    public var confidence: Double
    public var rationale: String
    public var fields: ExtractedFields

    public init(destinationRelativePath: String,
                proposedFilename: String,
                confidence: Double,
                rationale: String,
                fields: ExtractedFields) {
        self.destinationRelativePath = destinationRelativePath
        self.proposedFilename = proposedFilename
        self.confidence = confidence
        self.rationale = rationale
        self.fields = fields
    }
}

public struct ClassificationHints: Codable {
    public var path: String
    public var filename: String
    public var confidence: Double
    public var reason: String
}
