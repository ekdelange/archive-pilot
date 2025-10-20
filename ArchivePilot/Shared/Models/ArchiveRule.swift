import Foundation

/// Represents a learned classification rule saved by the user.
public struct ArchiveRule: Codable, Identifiable, Hashable {
    public struct RulePredicate: Codable, Hashable {
        public var containsTokens: [String]
        public var metadata: [String: String]
        public var minimumConfidence: Double?

        public init(containsTokens: [String] = [], metadata: [String: String] = [:], minimumConfidence: Double? = nil) {
            self.containsTokens = containsTokens
            self.metadata = metadata
            self.minimumConfidence = minimumConfidence
        }
    }

    public struct RuleAction: Codable, Hashable {
        public var destinationRelativePath: String
        public var filenameTemplate: String?

        public init(destinationRelativePath: String, filenameTemplate: String? = nil) {
            self.destinationRelativePath = destinationRelativePath
            self.filenameTemplate = filenameTemplate
        }
    }

    public var id: UUID
    public var name: String
    public var when: RulePredicate
    public var then: RuleAction
    public var priority: Int
    public var enabled: Bool

    public init(id: UUID = UUID(),
                name: String,
                when: RulePredicate,
                then: RuleAction,
                priority: Int = 0,
                enabled: Bool = true) {
        self.id = id
        self.name = name
        self.when = when
        self.then = then
        self.priority = priority
        self.enabled = enabled
    }
}
