import SwiftUI
import UniformTypeIdentifiers

@main
struct ArchivePilotApp: App {
    @StateObject private var settingsViewModel = SettingsViewModel(
        preferencesStore: PreferencesStore(appGroup: "group.com.example.archivepilot"),
        rulesStore: RulesStore(appGroup: "group.com.example.archivepilot"),
        bookmarkStore: BookmarkStore(suiteName: "group.com.example.archivepilot")
    )

    var body: some Scene {
        WindowGroup {
            HomeView(settingsViewModel: settingsViewModel)
        }
    }
}
