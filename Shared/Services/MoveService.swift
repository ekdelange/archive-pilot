import Foundation

public protocol MovingService {
    func moveItem(at sourceURL: URL, to destinationFolder: URL, proposedFilename: String) throws -> URL
}

public final class MoveService: MovingService {
    private let fileCoordinator: NSFileCoordinator
    private let fileManager: FileManager

    public init(fileCoordinator: NSFileCoordinator = NSFileCoordinator(), fileManager: FileManager = .default) {
        self.fileCoordinator = fileCoordinator
        self.fileManager = fileManager
    }

    public func moveItem(at sourceURL: URL, to destinationFolder: URL, proposedFilename: String) throws -> URL {
        var targetURL = destinationFolder.appendingPathComponent(proposedFilename)
        let ext = targetURL.pathExtension
        var attempt = 1
        while fileManager.fileExists(atPath: targetURL.path) {
            attempt += 1
            let basename = targetURL.deletingPathExtension().lastPathComponent
            let newName = "\(basename)_\(attempt).\(ext)"
            targetURL = destinationFolder.appendingPathComponent(newName)
        }
        var error: NSError?
        fileCoordinator.coordinate(movingItemAt: sourceURL, to: targetURL, error: &error, byAccessor: { source, destination in
            do {
                if fileManager.fileExists(atPath: destination.path) {
                    try fileManager.removeItem(at: destination)
                }
                try fileManager.moveItem(at: source, to: destination)
            } catch {
                throw error
            }
        })
        if let error { throw error }
        return targetURL
    }
}
