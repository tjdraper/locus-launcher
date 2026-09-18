import AppKit
import SwiftUI

/// A borderless panel that takes keyboard input without activating the app, so the app the user
/// was in stays frontmost and gets focus back as soon as the panel goes away.
final class LauncherPanel: NSPanel {
    enum KeyCommand {
        case moveUp
        case moveDown
        case showActions
        case perform(AppAction)
    }

    static let cornerRadius: CGFloat = 24
    static let size = NSSize(width: 640, height: 400)

    private let onDismiss: () -> Void
    private let onOpenSettings: () -> Void
    private let onOpenHiddenApps: () -> Void
    private let onKeyCommand: (KeyCommand) -> Void

    /// Sees each event first, and returns whether it used it up. The actions menu takes the
    /// panel's events this way while it's open.
    var interceptEvent: ((NSEvent) -> Bool)?

    init(
        onDismiss: @escaping () -> Void,
        onOpenSettings: @escaping () -> Void,
        onOpenHiddenApps: @escaping () -> Void,
        onKeyCommand: @escaping (KeyCommand) -> Void
    ) {
        self.onDismiss = onDismiss
        self.onOpenSettings = onOpenSettings
        self.onOpenHiddenApps = onOpenHiddenApps
        self.onKeyCommand = onKeyCommand
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

    /// A fresh view starts with an empty search and the field focused. SwiftUI keeps a view's state
    /// and skips `onAppear` when its window is only hidden, so reusing one resumes where it left off.
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

    // Esc, the list keys and the action shortcuts are caught here because the focused search field
    // would otherwise consume them.
    override func sendEvent(_ event: NSEvent) {
        if interceptEvent?(event) == true {
            return
        }
        if event.type == .keyDown, event.keyCode == Self.escapeKeyCode {
            onDismiss()
            return
        }
        if event.type == .keyDown, !isComposingText, let command = keyCommand(for: event) {
            onKeyCommand(command)
            return
        }
        super.sendEvent(event)
    }

    /// While an input method is composing text, the arrows pick candidates and Return commits.
    private var isComposingText: Bool {
        (firstResponder as? NSTextView)?.hasMarkedText() == true
    }

    private func keyCommand(for event: NSEvent) -> KeyCommand? {
        if let action = AppAction(keyCode: event.keyCode, modifierFlags: event.modifierFlags) {
            return .perform(action)
        }
        guard event.modifierFlags.isDisjoint(with: [.command, .option, .control, .shift]) else {
            return nil
        }
        switch event.keyCode {
        case Self.upArrowKeyCode: return .moveUp
        case Self.downArrowKeyCode: return .moveDown
        case Self.tabKeyCode: return .showActions
        default: return nil
        }
    }

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        if modifiers == .command, event.charactersIgnoringModifiers == "," {
            onOpenSettings()
            return true
        }
        // Cmd+Option+H is left alone, since it's the system's Hide Others.
        if modifiers == [.command, .option, .control], event.charactersIgnoringModifiers?.lowercased() == "h" {
            onOpenHiddenApps()
            return true
        }
        return super.performKeyEquivalent(with: event)
    }

    private static let escapeKeyCode: UInt16 = 53
    private static let tabKeyCode: UInt16 = 48
    private static let upArrowKeyCode: UInt16 = 126
    private static let downArrowKeyCode: UInt16 = 125
}
