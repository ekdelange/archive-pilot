import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        Form {
            Section("Apple Intelligence") {
                Toggle("Use Apple Intelligence", isOn: $viewModel.preferences.useAppleIntelligence)
                    .disabled(!viewModel.appleIntelligenceAvailable)
                Text(viewModel.appleIntelligenceAvailable ? "Available on this device" : "Not supported")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("Naming Template") {
                TextField("Template", text: $viewModel.preferences.namingTemplate)
                Text("Preview: \(FilenameSuggester.makeFilename(template: viewModel.preferences.namingTemplate, fields: ExtractedFields(vendor: "Vendor", docType: "Invoice", date: Date(), amount: 129.99, currency: "USD", reference: nil), originalExtension: "pdf"))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("System Message") {
                TextEditor(text: $viewModel.preferences.systemMessage)
                    .frame(height: 120)
            }

            Section("Rules") {
                if viewModel.rules.isEmpty {
                    Text("No rules yet")
                } else {
                    ForEach(viewModel.rules) { rule in
                        VStack(alignment: .leading) {
                            Text(rule.name)
                            Text(rule.then.destinationRelativePath)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .onDelete { indexSet in
                        viewModel.deleteRule(at: indexSet)
                    }
                }
            }

            Section("OpenAI Fallback") {
                Toggle("Enable OpenAI", isOn: $viewModel.preferences.useOpenAI)
                TextField("API Key", text: Binding(get: { viewModel.preferences.openAIKeyRef ?? "" }, set: { viewModel.preferences.openAIKeyRef = $0 }))
                    .textInputAutocapitalization(.never)
            }
        }
        .navigationTitle("Settings")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    viewModel.savePreferences()
                }
            }
        }
    }
}
