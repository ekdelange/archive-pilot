import SwiftUI
import UniformTypeIdentifiers

struct ShareView: View {
    @Environment(\.extensionContext) private var extensionContext
    @StateObject private var viewModel: ShareFlowViewModel
    private let bookmarkStore: BookmarkStore
    private let moveService = MoveService()
    let itemURL: URL
    let itemType: UTType
    @State private var showAdjust = false
    @State private var showCompletion = false

    init(itemURL: URL, itemType: UTType) {
        let bookmarkStore = BookmarkStore(suiteName: "group.com.example.archivepilot")
        let preferencesStore = PreferencesStore(appGroup: "group.com.example.archivepilot")
        let rulesStore = RulesStore(appGroup: "group.com.example.archivepilot")
        let embeddingGenerator = NLEmbeddingGenerator()
        let pipeline = ClassificationPipeline(textExtractor: TextExtractorService(),
                                              nlpService: NLPService(),
                                              heuristic: HeuristicClassifier(embeddingGenerator: embeddingGenerator),
                                              preferencesStore: preferencesStore,
                                              rulesStore: rulesStore,
                                              directoryIndexer: DirectoryIndexer(embeddingGenerator: embeddingGenerator),
                                              foundationFactory: {
                                                  if #available(iOS 18.4, *) {
                                                      return try FoundationLLMService()
                                                  } else {
                                                      throw NSError(domain: "FoundationUnavailable", code: -1)
                                                  }
                                              },
                                              openAIClient: OpenAIClient(keyProvider: { preferencesStore.loadPreferences().openAIKeyRef }))
        _viewModel = StateObject(wrappedValue: ShareFlowViewModel(pipeline: pipeline, bookmarkStore: bookmarkStore))
        self.bookmarkStore = bookmarkStore
        self.itemURL = itemURL
        self.itemType = itemType
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("ArchivePilot")
                .font(.title2)
            TextField("Optional instruction", text: $viewModel.userInstruction)
                .textFieldStyle(.roundedBorder)
            Button("Classify") {
                Task { await viewModel.classify(url: itemURL, type: itemType) }
            }
            .buttonStyle(.borderedProminent)

            switch viewModel.state {
            case .idle:
                EmptyView()
            case .loading:
                ProgressView("Classifying…")
            case .ready:
                if let result = viewModel.classification {
                    ResultSummaryView(result: result)
                    HStack {
                        Button("OK") {
                            handleAccept(result: result)
                        }
                        .buttonStyle(.borderedProminent)
                        Button("Adjust…") { showAdjust.toggle() }
                        Button("Cancel") {
                            extensionContext?.cancelRequest(withError: NSError(domain: "UserCancelled", code: 0))
                        }
                    }
                }
            case .error(let message):
                Text(message)
                    .foregroundStyle(.red)
            }

            Spacer()
        }
        .padding()
        .sheet(isPresented: $showAdjust) {
            if let result = viewModel.classification {
                ConfirmProposalView(result: result,
                                    settingsViewModel: SettingsViewModel(preferencesStore: PreferencesStore(appGroup: "group.com.example.archivepilot"),
                                                                         rulesStore: RulesStore(appGroup: "group.com.example.archivepilot"),
                                                                         bookmarkStore: bookmarkStore))
            }
        }
        .alert("Completed", isPresented: $showCompletion) {
            Button("Done") {
                extensionContext?.completeRequest(returningItems: nil)
            }
        } message: {
            Text("File moved to archive")
        }
    }

    private func handleAccept(result: ClassificationResult) {
        guard let targetURL = resolveDestination(relativePath: result.destinationRelativePath) else { return }
        do {
            _ = try moveService.moveItem(at: itemURL, to: targetURL, proposedFilename: result.proposedFilename)
            showCompletion = true
        } catch {
            viewModel.errorMessage = error.localizedDescription
        }
    }

    private func resolveDestination(relativePath: String) -> URL? {
        let keys = bookmarkStore.allKeys()
        guard let firstKey = keys.first, let data = bookmarkStore.bookmark(for: firstKey) else { return nil }
        var isStale = false
        guard let rootURL = try? URL(resolvingBookmarkData: data, options: [.withoutUI, .withSecurityScope], relativeTo: nil, bookmarkDataIsStale: &isStale) else { return nil }
        guard rootURL.startAccessingSecurityScopedResource() else { return nil }
        defer { rootURL.stopAccessingSecurityScopedResource() }
        let cleaned = relativePath.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        return rootURL.appendingPathComponent(cleaned)
    }
}

struct ResultSummaryView: View {
    let result: ClassificationResult

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Destination: \(result.destinationRelativePath)")
            Text("Filename: \(result.proposedFilename)")
            Text("Confidence: \(Int(result.confidence * 100))%")
            Text("Reason: \(result.rationale)")
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemBackground)))
    }
}
