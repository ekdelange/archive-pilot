import Foundation
import UniformTypeIdentifiers

@MainActor
public final class SettingsViewModel: ObservableObject {
    @Published public var preferences: UserPreferences
    @Published public var rules: [ArchiveRule]
    @Published public var appleIntelligenceAvailable: Bool
    @Published public var bookmarkKeys: [String]
    @Published public var errorMessage: String?

    let preferencesStore: PreferencesStoring
    let rulesStore: RulesStoring
    let bookmarkStore: BookmarkStoring

    public init(preferencesStore: PreferencesStoring,
                rulesStore: RulesStoring,
                bookmarkStore: BookmarkStoring) {
        self.preferencesStore = preferencesStore
        self.rulesStore = rulesStore
        self.bookmarkStore = bookmarkStore
        self.preferences = preferencesStore.loadPreferences()
        self.rules = rulesStore.loadRules()
        self.bookmarkKeys = bookmarkStore.allKeys()
        if #available(iOS 18.4, *) {
            self.appleIntelligenceAvailable = true
        } else {
            self.appleIntelligenceAvailable = false
            self.preferences.useAppleIntelligence = false
        }
    }

    public func savePreferences() {
        preferencesStore.savePreferences(preferences)
    }

    public func addRule(_ rule: ArchiveRule) {
        rules.append(rule)
        rulesStore.save(rules: rules)
    }

    public func deleteRule(at offsets: IndexSet) {
        rules.remove(atOffsets: offsets)
        rulesStore.save(rules: rules)
    }

    public func updateRule(_ rule: ArchiveRule) {
        if let index = rules.firstIndex(where: { $0.id == rule.id }) {
            rules[index] = rule
            rulesStore.save(rules: rules)
        }
    }

    public func removeBookmark(_ key: String) {
        bookmarkStore.removeBookmark(for: key)
        bookmarkKeys = bookmarkStore.allKeys()
    }
}
