import Foundation

public protocol RulesStoring {
    func loadRules() -> [ArchiveRule]
    func save(rules: [ArchiveRule])
}

public final class RulesStore: RulesStoring {
    private let url: URL
    private let queue = DispatchQueue(label: "RulesStoreQueue")

    public init(appGroup: String) {
        let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroup)!
        self.url = container.appendingPathComponent("rules.json")
    }

    public func loadRules() -> [ArchiveRule] {
        queue.sync {
            guard let data = try? Data(contentsOf: url) else { return [] }
            return (try? JSONDecoder().decode([ArchiveRule].self, from: data)) ?? []
        }
    }

    public func save(rules: [ArchiveRule]) {
        queue.async {
            if let data = try? JSONEncoder().encode(rules) {
                try? data.write(to: self.url, options: [.atomic])
            }
        }
    }
}
