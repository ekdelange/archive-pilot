import SwiftUI

struct PrivacyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Privacy")
                    .font(.title2)
                    .bold()
                Text("ArchivePilot keeps your documents on device. Apple Intelligence runs locally when available. If you enable OpenAI fallback, only condensed snippets and folder metadata are sent.")
                Text("You can disable network fallbacks at any time in Settings.")
            }
            .padding()
        }
        .navigationTitle("Privacy")
    }
}
