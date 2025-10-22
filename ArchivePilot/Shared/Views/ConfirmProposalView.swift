import SwiftUI

struct ConfirmProposalView: View {
    (\.dismiss) private var dismiss
    let result: ClassificationResult
    @ObservedObject var settingsViewModel: SettingsViewModel
    @State private var showFolderPicker = false
    @State private var editedFilename: String
    @State private var selectedPath: String
    @State private var saveAsRule = false

    init(result: ClassificationResult, settingsViewModel: SettingsViewModel) {
        self.result = result
        self.settingsViewModel = settingsViewModel
        _editedFilename = State(initialValue: result.proposedFilename)
        _selectedPath = State(initialValue: result.destinationRelativePath)
    }

    var body: some View {
        Form {
            Section("Destination") {
                HStack {
                    Text(selectedPath)
                        .lineLimit(2)
                    Spacer()
                    Button("Change") { showFolderPicker.toggle() }
                }
            }

            Section("Filename") {
                TextField("Filename", text: $editedFilename)
            }

            Section("Rationale") {
                Text(result.rationale)
            }

            Section {
                Toggle("Save as rule", isOn: $saveAsRule)
            }
        }
        .navigationTitle("Confirm")
        .sheet(isPresented: $showFolderPicker) {
            FolderPickerView { path in
                selectedPath = path
            }
        }
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    if saveAsRule {
                        let rule = ArchiveRule(name: "Manual \(Date().formatted())",
                                               when: .init(containsTokens: result.fields.vendor.map { [$0] } ?? [], metadata: [:], minimumConfidence: 0.99),
                                               then: .init(destinationRelativePath: selectedPath, filenameTemplate: editedFilename))
                        settingsViewModel.addRule(rule)
                    }
                    settingsViewModel.preferences.namingTemplate = editedFilename
                    settingsViewModel.savePreferences()
                    dismiss()
                }
            }
        }
    }
}
