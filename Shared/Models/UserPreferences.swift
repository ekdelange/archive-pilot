import Foundation

public struct UserPreferences: Codable, Equatable {
    public var systemMessage: String
    public var namingTemplate: String
    public var useAppleIntelligence: Bool
    public var useOpenAI: Bool
    public var openAIModel: String
    public var openAIKeyRef: String?
    public var confidenceThreshold: Double

    public init(systemMessage: String = "",
                namingTemplate: String = "yyyy-MM-dd__Vendor__DocType__Amount",
                useAppleIntelligence: Bool = true,
                useOpenAI: Bool = false,
                openAIModel: String = "gpt-4o-mini",
                openAIKeyRef: String? = nil,
                confidenceThreshold: Double = 0.65) {
        self.systemMessage = systemMessage
        self.namingTemplate = namingTemplate
        self.useAppleIntelligence = useAppleIntelligence
        self.useOpenAI = useOpenAI
        self.openAIModel = openAIModel
        self.openAIKeyRef = openAIKeyRef
        self.confidenceThreshold = confidenceThreshold
    }
}
