import AppKit

/// Draws the actions menu's items like a macOS menu, and picks one from the pointer.
final class AppActionsMenuView: NSView {
    private enum Metrics {
        static let padding: CGFloat = 5
        static let rowHeight: CGFloat = 24
        static let separatorHeight: CGFloat = 11
        static let textInset: CGFloat = 12
        static let shortcutGap: CGFloat = 32
        static let highlightRadius: CGFloat = 6
    }

    private enum Entry {
        case item(AppAction)
        case separator
    }

    private static let entries: [Entry] = AppAction.allCases.flatMap { action -> [Entry] in
        action == .hide ? [.separator, .item(action)] : [.item(action)]
    }

    private static let font = NSFont.menuFont(ofSize: 0)

    var highlighted: AppAction? {
        didSet {
            if highlighted != oldValue {
                needsDisplay = true
            }
        }
    }

    var onChoose: ((AppAction) -> Void)?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        // The launcher panel never activates the app, so tracking has to work while it's inactive.
        addTrackingArea(NSTrackingArea(
            rect: .zero,
            options: [.mouseMoved, .mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self
        ))
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override var isFlipped: Bool {
        true
    }

    override var intrinsicContentSize: NSSize {
        let widest = AppAction.allCases.map { action in
            Self.textWidth(action.title) + Metrics.shortcutGap + Self.textWidth(action.shortcutSymbols)
        }.max() ?? 0
        let height = Self.entries.reduce(Metrics.padding * 2) { total, entry in
            total + Self.height(of: entry)
        }
        return NSSize(width: ceil(widest + (Metrics.padding + Metrics.textInset) * 2), height: height)
    }

    override func acceptsFirstMouse(for _: NSEvent?) -> Bool {
        true
    }

    func moveHighlightDown() {
        let actions = AppAction.allCases
        guard let current = highlighted, let index = actions.firstIndex(of: current) else {
            highlighted = actions.first
            return
        }
        highlighted = actions[min(index + 1, actions.count - 1)]
    }

    func moveHighlightUp() {
        let actions = AppAction.allCases
        guard let current = highlighted, let index = actions.firstIndex(of: current) else {
            highlighted = actions.last
            return
        }
        highlighted = actions[max(index - 1, 0)]
    }

    override func mouseMoved(with event: NSEvent) {
        highlighted = action(at: convert(event.locationInWindow, from: nil))
    }

    override func mouseExited(with _: NSEvent) {
        highlighted = nil
    }

    override func mouseUp(with event: NSEvent) {
        if let action = action(at: convert(event.locationInWindow, from: nil)) {
            onChoose?(action)
        }
    }

    override func draw(_: NSRect) {
        for (entry, rect) in layout() {
            switch entry {
            case .separator:
                NSColor.separatorColor.setFill()
                NSRect(x: rect.minX + Metrics.textInset, y: rect.midY, width: rect.width - Metrics.textInset * 2, height: 1).fill()
            case let .item(action):
                drawItem(action, in: rect)
            }
        }
    }

    private func drawItem(_ action: AppAction, in rect: NSRect) {
        let isHighlighted = action == highlighted
        if isHighlighted {
            NSColor.selectedContentBackgroundColor.setFill()
            NSBezierPath(roundedRect: rect, xRadius: Metrics.highlightRadius, yRadius: Metrics.highlightRadius).fill()
        }
        let titleColor: NSColor = isHighlighted ? .alternateSelectedControlTextColor : .labelColor
        let shortcutColor: NSColor = isHighlighted ? .alternateSelectedControlTextColor : .secondaryLabelColor
        let title = NSAttributedString(string: action.title, attributes: [.font: Self.font, .foregroundColor: titleColor])
        let shortcut = NSAttributedString(string: action.shortcutSymbols, attributes: [.font: Self.font, .foregroundColor: shortcutColor])
        let textY = rect.midY - title.size().height / 2
        title.draw(at: NSPoint(x: rect.minX + Metrics.textInset, y: textY))
        shortcut.draw(at: NSPoint(x: rect.maxX - Metrics.textInset - shortcut.size().width, y: textY))
    }

    private func action(at point: NSPoint) -> AppAction? {
        for (entry, rect) in layout() {
            if case let .item(action) = entry, rect.contains(point) {
                return action
            }
        }
        return nil
    }

    private func layout() -> [(Entry, NSRect)] {
        var y = Metrics.padding
        return Self.entries.map { entry in
            let height = Self.height(of: entry)
            let rect = NSRect(x: Metrics.padding, y: y, width: bounds.width - Metrics.padding * 2, height: height)
            y += height
            return (entry, rect)
        }
    }

    private static func height(of entry: Entry) -> CGFloat {
        switch entry {
        case .item: Metrics.rowHeight
        case .separator: Metrics.separatorHeight
        }
    }

    private static func textWidth(_ string: String) -> CGFloat {
        NSAttributedString(string: string, attributes: [.font: font]).size().width
    }
}
