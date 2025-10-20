import Foundation
import UniformTypeIdentifiers

@MainActor
public final class InboxFlowViewModel: ObservableObject {
    @Published public var inboxItems: [URL] = []
    @Published public var selectedURL: URL?
    @Published public var classification: ClassificationResult?
    @Published public var errorMessage: String?
    @Published public private(set) var state: ShareFlowViewModel.State = .idle

    private let pipeline: ClassificationPipelining
    private let bookmarkStore: BookmarkStoring

    public init(pipeline: ClassificationPipelining, bookmarkStore: BookmarkStoring) {
        self.pipeline = pipeline
        self.bookmarkStore = bookmarkStore
        loadInbox()
    }

    public func loadInbox() {
        let inboxURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let contents = (try? FileManager.default.contentsOfDirectory(at: inboxURL, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])) ?? []
        inboxItems = contents
    }

    public func classifySelected() async {
        guard let url = selectedURL else { return }
        let type = UTType(filenameExtension: url.pathExtension) ?? .data
        state = .loading
        let bookmarks = bookmarkStore.allKeys().reduce(into: [String: Data]()) { result, key in
            if let data = bookmarkStore.bookmark(for: key) {
                result[key] = data
            }
        }
        let result = await pipeline.classify(url: url, type: type, userInstruction: nil, bookmarks: bookmarks)
        switch result {
        case .success(let value):
            classification = value
            state = .ready
        case .failure(let error):
            errorMessage = error.localizedDescription
            state = .error(error.localizedDescription)
        }
    }
}
