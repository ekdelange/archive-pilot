import Foundation
import UniformTypeIdentifiers

@MainActor
public final class ShareFlowViewModel: ObservableObject {
    @Published public private(set) var state: State = .idle
    @Published public var userInstruction: String = ""
    @Published public var classification: ClassificationResult?
    @Published public var errorMessage: String?

    private let pipeline: ClassificationPipelining
    private let bookmarkStore: BookmarkStoring

    public enum State {
        case idle
        case loading
        case ready
        case error(String)
    }

    public init(pipeline: ClassificationPipelining,
                bookmarkStore: BookmarkStoring) {
        self.pipeline = pipeline
        self.bookmarkStore = bookmarkStore
    }

    public func classify(url: URL, type: UTType) async {
        state = .loading
        let bookmarks = bookmarkStore.allKeys().reduce(into: [String: Data]()) { result, key in
            if let data = bookmarkStore.bookmark(for: key) {
                result[key] = data
            }
        }
        let result = await pipeline.classify(url: url, type: type, userInstruction: userInstruction, bookmarks: bookmarks)
        switch result {
        case .success(let value):
            classification = value
            state = .ready
        case .failure(let error):
            state = .error(error.localizedDescription)
            errorMessage = error.localizedDescription
        }
    }
}
