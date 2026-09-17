import AppKit
import SwiftUI

final class LauncherPanel: NSPanel {
    static let cornerRadius: CGFloat = 24

    init(rootView: some View) {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 640, height: 400),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        isFloatingPanel = true
        level = .floating
        isReleasedWhenClosed = false
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        let hostingView = NSHostingView(rootView: rootView)
        hostingView.wantsLayer = true
        hostingView.layer?.cornerRadius = Self.cornerRadius
        hostingView.layer?.masksToBounds = true
        contentView = hostingView
    }

    // Borderless windows refuse key status by default, which would block keyboard input in the panel.
    override var canBecomeKey: Bool {
        true
    }

    override func cancelOperation(_: Any?) {
        close()
    }
}
