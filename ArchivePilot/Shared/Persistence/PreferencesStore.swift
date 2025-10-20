import Foundation

public protocol PreferencesStoring {
    func loadPreferences() -> UserPreferences
    func savePreferences(_ preferences: UserPreferences)
}

public final class PreferencesStore: PreferencesStoring {
    private let defaults: UserDefaults
    private let key = "preferences"

    public init(appGroup: String) {
        guard let defaults = UserDefaults(suiteName: appGroup) else {
            fatalError("Unable to create UserDefaults for group")
        }
        self.defaults = defaults
    }

    public func loadPreferences() -> UserPreferences {
        guard let data = defaults.data(forKey: key),
              let prefs = try? JSONDecoder().decode(UserPreferences.self, from: data) else {
            return UserPreferences()
        }
        return prefs
    }

    public func savePreferences(_ preferences: UserPreferences) {
        if let data = try? JSONEncoder().encode(preferences) {
            defaults.set(data, forKey: key)
        }
    }
}
