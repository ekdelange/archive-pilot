import Foundation
import NaturalLanguage

public protocol EmbeddingGenerating {
    func embedding(for string: String) -> [Double]
    func cosineSimilarity(between lhs: [Double], and rhs: [Double]) -> Double
}

public final class NLEmbeddingGenerator: EmbeddingGenerating {
    private let embedding: NLEmbedding?

    public init() {
        self.embedding = try? NLEmbedding.wordEmbedding(for: .english)
    }

    public func embedding(for string: String) -> [Double] {
        guard let embedding else { return [] }
        let tokens = string.split(separator: " ")
        var accumulator: [Double] = []
        for token in tokens {
            guard let vector = embedding.vector(for: String(token.lowercased())) else { continue }
            if accumulator.isEmpty {
                accumulator = vector
            } else {
                for index in vector.indices {
                    accumulator[index] += vector[index]
                }
            }
        }
        if !accumulator.isEmpty {
            let count = Double(tokens.count)
            for index in accumulator.indices {
                accumulator[index] /= count
            }
        }
        return accumulator
    }

    public func cosineSimilarity(between lhs: [Double], and rhs: [Double]) -> Double {
        guard lhs.count == rhs.count, !lhs.isEmpty else { return 0 }
        var dot: Double = 0
        var lhsNorm: Double = 0
        var rhsNorm: Double = 0
        for index in lhs.indices {
            dot += lhs[index] * rhs[index]
            lhsNorm += lhs[index] * lhs[index]
            rhsNorm += rhs[index] * rhs[index]
        }
        guard lhsNorm > 0, rhsNorm > 0 else { return 0 }
        return dot / (sqrt(lhsNorm) * sqrt(rhsNorm))
    }
}
