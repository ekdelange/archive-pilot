import SwiftUI
import UniformTypeIdentifiers

struct HomeView: View {
    @ObservedObject var settingsViewModel: SettingsViewModel
    @StateObject private var inboxViewModel: InboxFlowViewModel

    init(settingsViewModel: SettingsViewModel) {
        self.settingsViewModel = settingsViewModel
        let embeddingGenerator = NLEmbeddingGenerator()
        let heuristic = HeuristicClassifier(embeddingGenerator: embeddingGenerator)
        let pipeline = ClassificationPipeline(
            textExtractor: TextExtractorService(),
            nlpService: NLPService(),
            heuristic: heuristic,
            preferencesStore: settingsViewModel.preferencesStore,
            rulesStore: settingsViewModel.rulesStore,
            directoryIndexer: DirectoryIndexer(embeddingGenerator: embeddingGenerator),
            foundationFactory: {
                if #available(iOS 18.4, *) {
                    return try FoundationLLMService()
                } else {
                    throw NSError(domain: "FoundationUnavailable", code: -1)
                }
            },
            openAIClient: OpenAIClient(keyProvider: { settingsViewModel.preferences.openAIKeyRef })
        )
        _inboxViewModel = StateObject(wrappedValue: InboxFlowViewModel(pipeline: pipeline, bookmarkStore: settingsViewModel.bookmarkStore))
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Inbox") {
                    Button("Pick from Inbox") {
                        if let first = inboxViewModel.inboxItems.first {
                            inboxViewModel.selectedURL = first
                            Task { await inboxViewModel.classifySelected() }
                        }
                    }
                    if let classification = inboxViewModel.classification {
                        NavigationLink("Last classified") {
                            ConfirmProposalView(result: classification, settingsViewModel: settingsViewModel)
                        }
                    }
                }

                Section("Settings") {
                    NavigationLink("Settings") {
                        SettingsView(viewModel: settingsViewModel)
                    }
                }
            }
            .navigationTitle("ArchivePilot")
            .alert("Error", isPresented: Binding(get: { inboxViewModel.errorMessage != nil }, set: { _ in inboxViewModel.errorMessage = nil })) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(inboxViewModel.errorMessage ?? "Unknown")
            }
        }
    }
}
