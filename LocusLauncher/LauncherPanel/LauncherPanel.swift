import AppKit
import SwiftUI

/// A borderless panel that takes keyboard input without activating the app, so the app the user
/// was in stays frontmost and gets focus back as soon as the panel goes away.
final class LauncherPanel: NSPanel {
    enum KeyCommand {
        case moveUp
        case moveDown
        case launch
    }

    static let cornerRadius: CGFloat = 24
    static let size = NSSize(width: 640, height: 400)

    private let onDismiss: () -> Void
    private let onOpenSettings: () -> Void
    private let onKeyCommand: (KeyCommand) -> Void

    init(
        onDismiss: @escaping () -> Void,
        onOpenSettings: @escaping () -> Void,
        onKeyCommand: @escaping (KeyCommand) -> Void
    ) {
        self.onDismiss = onDismiss
        self.onOpenSettings = onOpenSettings
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

    // Esc and the list keys are caught here because the focused search field would otherwise
    // consume them.
    override func sendEvent(_ event: NSEvent) {
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
        guard event.modifierFlags.isDisjoint(with: [.command, .option, .control, .shift]) else {
            return nil
        }
        switch event.keyCode {
        case Self.upArrowKeyCode: return .moveUp
        case Self.downArrowKeyCode: return .moveDown
        case Self.returnKeyCode, Self.keypadEnterKeyCode: return .launch
        default: return nil
        }
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
    private static let returnKeyCode: UInt16 = 36
    private static let keypadEnterKeyCode: UInt16 = 76
    private static let upArrowKeyCode: UInt16 = 126
    private static let downArrowKeyCode: UInt16 = 125
}
