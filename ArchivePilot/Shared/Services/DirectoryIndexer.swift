import Foundation

public protocol DirectoryIndexing {
    func refreshIndex(from bookmarks: [String: Data]) async throws -> [DirectoryNode]
    func flatten(nodes: [DirectoryNode]) -> [DirectoryNode]
}

public final class DirectoryIndexer: DirectoryIndexing {
    private let fileManager: FileManager
    private let maxDepth: Int
    private let embeddingGenerator: EmbeddingGenerating

    public init(fileManager: FileManager = .default,
                maxDepth: Int = 6,
                embeddingGenerator: EmbeddingGenerating) {
        self.fileManager = fileManager
        self.maxDepth = maxDepth
        self.embeddingGenerator = embeddingGenerator
    }

    public func refreshIndex(from bookmarks: [String: Data]) async throws -> [DirectoryNode] {
        try await withThrowingTaskGroup(of: DirectoryNode?.self) { group in
            for (key, bookmark) in bookmarks {
                group.addTask {
                    try self.resolveNode(for: key, bookmark: bookmark)
                }
            }

            var nodes: [DirectoryNode] = []
            for try await node in group {
                if let node {
                    nodes.append(node)
                }
            }
            return nodes
        }
    }

    public func flatten(nodes: [DirectoryNode]) -> [DirectoryNode] {
        var output: [DirectoryNode] = []
        func visit(_ node: DirectoryNode) {
            output.append(node)
            node.children.forEach(visit)
        }
        nodes.forEach(visit)
        return output
    }

    private func resolveNode(for key: String, bookmark: Data) throws -> DirectoryNode? {
        var isStale = false
        let url = try URL(resolvingBookmarkData: bookmark,
                          options: [.withoutUI, .withSecurityScope],
                          relativeTo: nil,
                          bookmarkDataIsStale: &isStale)
        guard url.startAccessingSecurityScopedResource() else {
            return nil
        }
        defer { url.stopAccessingSecurityScopedResource() }

        return try enumerate(url: url, relativePath: "/" + key, depth: 0)
    }

    private func enumerate(url: URL, relativePath: String, depth: Int) throws -> DirectoryNode {
        let displayName = url.lastPathComponent
        let bookmark = try url.bookmarkData(options: [.suitableForBookmarkFile], includingResourceValuesForKeys: nil, relativeTo: nil)
        let embedding = embeddingGenerator.embedding(for: displayName + " " + relativePath)
        guard depth < maxDepth else {
            return DirectoryNode(displayName: displayName, relativePath: relativePath, bookmarkData: bookmark, children: [], embedding: embedding)
        }

        let contents = try fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles])
        let directories = contents.filter { url in
            (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
        }

        let children = try directories.map { directoryURL -> DirectoryNode in
            let childRelative = relativePath.appendingPathComponent(directoryURL.lastPathComponent)
            return try enumerate(url: directoryURL, relativePath: childRelative, depth: depth + 1)
        }

        return DirectoryNode(displayName: displayName, relativePath: relativePath, bookmarkData: bookmark, children: children, embedding: embedding)
    }
}

private extension String {
    func appendingPathComponent(_ component: String) -> String {
        let base = self == "/" ? "" : self
        return base + "/" + component
    }
}
