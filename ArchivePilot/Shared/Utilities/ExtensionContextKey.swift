import SwiftUI
import UIKit

private struct ExtensionContextKey: EnvironmentKey {
    static let defaultValue: NSExtensionContext? = nil
}

public extension EnvironmentValues {
    var extensionContext: NSExtensionContext? {
        get { self[ExtensionContextKey.self] }
        set { self[ExtensionContextKey.self] = newValue }
    }
}
