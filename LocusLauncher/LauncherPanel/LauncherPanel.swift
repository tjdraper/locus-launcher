import AppKit
import SwiftUI

/// A borderless panel that takes keyboard input without activating the app, so the app the user
/// was in stays frontmost and gets focus back as soon as the panel goes away.
final class LauncherPanel: NSPanel {
    static let cornerRadius: CGFloat = 24
    static let size = NSSize(width: 640, height: 400)

    private let onDismiss: () -> Void
    private let onOpenSettings: () -> Void

    init(onDismiss: @escaping () -> Void, onOpenSettings: @escaping () -> Void) {
        self.onDismiss = onDismiss
        self.onOpenSettings = onOpenSettings
        super.init(
            contentRect: NSRect(origin: .zero, size: Self.size),
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
    }

    /// Each presentation gets a fresh view, so the search starts empty and the field takes focus
    /// again. SwiftUI keeps a view's state and skips `onAppear` when its window is only hidden.
    func setRootView(_ rootView: some View) {
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

    override func resignKey() {
        super.resignKey()
        onDismiss()
    }

    // Esc is caught here because the focused search field would otherwise consume it before it
    // reached the window's `cancelOperation`.
    override func sendEvent(_ event: NSEvent) {
        if event.type == .keyDown, event.keyCode == Self.escapeKeyCode {
            onDismiss()
            return
        }
        super.sendEvent(event)
    }

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        if modifiers == .command, event.charactersIgnoringModifiers == "," {
            onOpenSettings()
            return true
        }
        return super.performKeyEquivalent(with: event)
    }

    private static let escapeKeyCode: UInt16 = 53
}
