import Foundation

/// Stores and resolves security-scoped bookmarks shared between the app and extension.
public protocol BookmarkStoring {
    func saveBookmark(_ data: Data, for key: String) throws
    func bookmark(for key: String) -> Data?
    func removeBookmark(for key: String)
    func allKeys() -> [String]
}

public final class BookmarkStore: BookmarkStoring {
    private let defaults: UserDefaults
    private let queue = DispatchQueue(label: "BookmarkStoreQueue")

    public init(suiteName: String) {
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            fatalError("Unable to open user defaults for app group")
        }
        self.defaults = defaults
    }

    public func saveBookmark(_ data: Data, for key: String) throws {
        queue.sync {
            defaults.set(data, forKey: key)
        }
    }

    public func bookmark(for key: String) -> Data? {
        queue.sync {
            defaults.data(forKey: key)
        }
    }

    public func removeBookmark(for key: String) {
        queue.sync {
            defaults.removeObject(forKey: key)
        }
    }

    public func allKeys() -> [String] {
        queue.sync {
            defaults.dictionaryRepresentation().keys.filter { defaults.data(forKey: $0) != nil }
        }
    }
}
