import AppKit

/// Application delegate for launch-time toggles (SwiftUI `App` has no `NSApplicationDelegate` by default).
final class VectifyAppDelegate: NSObject, NSApplicationDelegate {
    /// Set to `1` in source to enable the vd-tool XML preview column in **Release** builds.
    /// Debug builds always enable the preview column regardless of this value.
    static var showPreviewFlag: Int = 0

    func applicationWillFinishLaunching(_ notification: Notification) {
        if ProcessInfo.processInfo.environment["VECTIFY_VD_PREVIEW"] == "1" {
            Self.showPreviewFlag = 1
        }
    }
}

enum VdToolPreviewGate {
    static var isEnabled: Bool {
        #if DEBUG
        true
        #else
        VectifyAppDelegate.showPreviewFlag != 0
        #endif
    }
}
