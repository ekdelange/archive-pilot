import Foundation
import PDFKit
import CoreImage
import Vision
import UniformTypeIdentifiers
import UIKit

public protocol TextExtracting {
    func extractText(from url: URL, type: UTType) async throws -> String
}

public final class TextExtractorService: TextExtracting {
    public enum ExtractionError: Error {
        case unsupportedType
    }

    public init() {}

    public func extractText(from url: URL, type: UTType) async throws -> String {
        switch type {
        case .pdf:
            return try await extractPDF(url: url)
        case .plainText, .utf8PlainText, .text:
            return try String(contentsOf: url)
        case .image, .png, .jpeg:
            return try await extractImage(url: url)
        default:
            guard let string = try? String(contentsOf: url) else {
                throw ExtractionError.unsupportedType
            }
            return string
        }
    }

    private func extractPDF(url: URL) async throws -> String {
        guard let document = PDFDocument(url: url) else { return "" }
        var output = ""
        for index in 0..<document.pageCount {
            guard let page = document.page(at: index) else { continue }
            if let text = page.string, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                output.append(text)
                output.append("\n")
            } else if let cgPage = page.pageRef {
                let image = page.thumbnail(of: CGSize(width: 2048, height: 2048), for: .mediaBox)
                if let recognized = try await recognizeText(in: image) {
                    output.append(recognized)
                    output.append("\n")
                } else {
                    let dataProvider = cgPage.dataProvider
                    let data = dataProvider?.data as Data?
                    if let data {
                        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("png")
                        try data.write(to: tempURL)
                        if let recognized = try await extractImage(url: tempURL) {
                            output.append(recognized)
                            output.append("\n")
                        }
                        try? FileManager.default.removeItem(at: tempURL)
                    }
                }
            }
        }
        return output
    }

    private func extractImage(url: URL) async throws -> String {
        guard let image = CIImage(contentsOf: url) else { return "" }
        if let recognized = try await recognizeText(in: image) {
            return recognized
        }
        return ""
    }

    private func recognizeText(in image: Any) async throws -> String? {
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                let text = request.results?
                    .compactMap { $0 as? VNRecognizedTextObservation }
                    .compactMap { $0.topCandidates(1).first?.string }
                    .joined(separator: "\n") ?? ""
                continuation.resume(returning: text)
            }
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true

            let handler: VNImageRequestHandler
            if let ciImage = image as? CIImage {
                handler = VNImageRequestHandler(ciImage: ciImage)
            } else if let uiImage = image as? UIImage {
                handler = VNImageRequestHandler(cgImage: uiImage.cgImage!)
            } else if let nsImage = image as? CGImage {
                handler = VNImageRequestHandler(cgImage: nsImage)
            } else {
                continuation.resume(returning: nil)
                return
            }

            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try handler.perform([request])
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
