import Foundation

public struct DirectoryNode: Codable, Identifiable, Hashable {
    public var id: UUID
    public var displayName: String
    public var relativePath: String
    public var bookmarkData: Data
    public var children: [DirectoryNode]
    public var embedding: [Double]

    public init(id: UUID = UUID(),
                displayName: String,
                relativePath: String,
                bookmarkData: Data,
                children: [DirectoryNode] = [],
                embedding: [Double] = []) {
        self.id = id
        self.displayName = displayName
        self.relativePath = relativePath
        self.bookmarkData = bookmarkData
        self.children = children
        self.embedding = embedding
    }
}
