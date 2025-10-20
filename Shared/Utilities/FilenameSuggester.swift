import Foundation

public enum FilenameSuggester {
    public static func makeFilename(template: String,
                                     fields: ExtractedFields,
                                     originalExtension: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        var filename = template
        if let date = fields.date {
            filename = filename.replacingOccurrences(of: "yyyy-MM-dd", with: formatter.string(from: date))
        }
        if let vendor = fields.vendor {
            filename = filename.replacingOccurrences(of: "Vendor", with: sanitize(vendor))
        }
        if let docType = fields.docType {
            filename = filename.replacingOccurrences(of: "DocType", with: sanitize(docType))
        }
        if let amount = fields.amount {
            filename = filename.replacingOccurrences(of: "Amount", with: NSDecimalNumber(decimal: amount).stringValue)
        }
        if let currency = fields.currency {
            filename = filename.replacingOccurrences(of: "Currency", with: sanitize(currency))
        }
        filename = filename.replacingOccurrences(of: "__", with: "_")
        filename = filename.replacingOccurrences(of: " ", with: "_")
        filename = filename.trimmingCharacters(in: CharacterSet(charactersIn: "._"))
        if filename.isEmpty {
            filename = UUID().uuidString
        }
        let sanitized = sanitize(filename)
        return sanitized.prefix(200) + "." + originalExtension
    }

    private static func sanitize(_ text: String) -> String {
        let invalidCharacters = CharacterSet(charactersIn: "\\/:*?\"<>|")
        return text.components(separatedBy: invalidCharacters).joined(separator: "_")
    }
}
