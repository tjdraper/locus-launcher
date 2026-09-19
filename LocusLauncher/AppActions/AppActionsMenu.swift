import AppKit

/// The menu Tab or the selected row's caret opens. It's drawn by the app instead of `NSMenu`,
/// because while an `NSMenu` is open, Return runs the item whose shortcut is Return even when the
/// arrow keys have highlighted another, and nothing outside the menu sees the keys first.
///
/// The launcher panel keeps keyboard focus and hands its keys to the menu while it's open.
final class AppActionsMenu {
    enum KeyResult {
        case handled
        case close
        case notHandled
    }

    private static let gap: CGFloat = 4

    private let window: NSPanel
    private let menuView = AppActionsMenuView()
    private let onChoose: (AppAction) -> Void

    init(highlightingFirstItem: Bool, onChoose: @escaping (AppAction) -> Void) {
        self.onChoose = onChoose
        menuView.onChoose = onChoose
        if highlightingFirstItem {
            menuView.highlighted = AppAction.allCases.first
        }

        let glass = NSGlassEffectView()
        glass.cornerRadius = 12
        let size = menuView.intrinsicContentSize
        menuView.frame = NSRect(origin: .zero, size: size)
        glass.frame = menuView.frame
        glass.contentView = menuView
        window = AppActionsMenuWindow(contentRect: NSRect(origin: .zero, size: size))
        window.contentView = glass
    }

    /// Opens below `anchor`, or above `rowTop` when there's no room below.
    func show(below anchor: NSPoint, orAbove rowTop: CGFloat, attachedTo parent: NSWindow) {
        let size = menuView.intrinsicContentSize
        let visible = parent.screen?.visibleFrame ?? .infinite
        var origin = NSPoint(x: anchor.x, y: anchor.y - Self.gap - size.height)
        if origin.y < visible.minY {
            origin.y = rowTop + Self.gap
        }
        origin.x = min(origin.x, visible.maxX - size.width)
        window.setFrame(NSRect(origin: origin, size: size), display: true)
        parent.addChildWindow(window, ordered: .above)
    }

    func close() {
        window.parent?.removeChildWindow(window)
        window.orderOut(nil)
    }

    func handleKeyDown(_ event: NSEvent) -> KeyResult {
        let modifiers = event.modifierFlags.intersection([.command, .option, .control, .shift])
        switch event.keyCode {
        case Self.upArrowKeyCode where modifiers.isEmpty:
            menuView.moveHighlightUp()
            return .handled
        case Self.downArrowKeyCode where modifiers.isEmpty:
            menuView.moveHighlightDown()
            return .handled
        case Self.escapeKeyCode, Self.tabKeyCode:
            return .close
        default:
            break
        }
        if AppAction.key(forKeyCode: event.keyCode, characters: nil) == .returnKey, modifiers.isEmpty {
            if let action = menuView.highlighted {
                onChoose(action)
            }
            return .handled
        }
        if let action = AppAction(
            keyCode: event.keyCode,
            characters: event.charactersIgnoringModifiers,
            modifierFlags: event.modifierFlags
        ) {
            onChoose(action)
            return .handled
        }
        return .notHandled
    }

    private static let tabKeyCode: UInt16 = 48
    private static let escapeKeyCode: UInt16 = 53
    private static let upArrowKeyCode: UInt16 = 126
    private static let downArrowKeyCode: UInt16 = 125
}

/// Never takes keyboard focus, so the launcher panel stays key and doesn't close.
private final class AppActionsMenuWindow: NSPanel {
    init(contentRect: NSRect) {
        super.init(contentRect: contentRect, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: true)
        isReleasedWhenClosed = false
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
    }

    override var canBecomeKey: Bool {
        false
    }

    override var canBecomeMain: Bool {
        false
    }
}
