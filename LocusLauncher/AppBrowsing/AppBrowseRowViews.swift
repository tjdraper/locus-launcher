import AppKit

enum AppBrowseRowMetrics {
    static let appHeight: CGFloat = 44
    static let headerHeight: CGFloat = 28
    /// Empty space at the top of each section's first app row, so its selection sits apart from
    /// the header, or from the search field above search results. It belongs to the app row so
    /// nothing shows through below a pinned header.
    static let sectionTopGap: CGFloat = 6
    static let leadingInset: CGFloat = 20
    static let selectionInset: CGFloat = 8
    static let bottomPadding: CGFloat = 8
    /// The letter index sits over the right edge of the app rows, below the pinned header.
    static let letterIndexWidth: CGFloat = 24
    /// The part of the selection, at its trailing edge, that opens the actions menu.
    static let caretAreaWidth: CGFloat = 40

    static func trailingInset(reservesLetterIndex: Bool) -> CGFloat {
        selectionInset + (reservesLetterIndex ? letterIndexWidth : 0)
    }

    /// Takes an app row's bounds in flipped coordinates.
    static func selectionRect(inRow bounds: NSRect, reservesLetterIndex: Bool) -> NSRect {
        // The vertical inset keeps the selection off the section header above it.
        NSRect(
            x: bounds.minX + selectionInset,
            y: bounds.maxY - appHeight + 3,
            width: bounds.width - selectionInset - trailingInset(reservesLetterIndex: reservesLetterIndex),
            height: appHeight - 6
        )
    }

    static func caretArea(inRow bounds: NSRect, reservesLetterIndex: Bool) -> NSRect {
        let selection = selectionRect(inRow: bounds, reservesLetterIndex: reservesLetterIndex)
        return NSRect(x: selection.maxX - caretAreaWidth, y: selection.minY, width: caretAreaWidth, height: selection.height)
    }
}

final class AppBrowseCellView: NSTableCellView {
    static let identifier = NSUserInterfaceItemIdentifier("AppBrowseCell")

    private(set) var appURL: URL?
    private let caret = ActionsCaretView()
    private let shortcuts = NSTextField(labelWithString: "")
    private var caretTrailing: NSLayoutConstraint?

    init() {
        super.init(frame: .zero)
        identifier = Self.identifier

        let icon = NSImageView()
        icon.imageScaling = .scaleProportionallyUpOrDown
        let name = NSTextField(labelWithString: "")
        name.font = .preferredFont(forTextStyle: .title3)
        name.lineBreakMode = .byTruncatingTail
        name.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        caret.isHidden = true
        shortcuts.font = .preferredFont(forTextStyle: .body)
        shortcuts.textColor = .secondaryLabelColor
        shortcuts.setContentCompressionResistancePriority(.required, for: .horizontal)
        shortcuts.setContentHuggingPriority(.required, for: .horizontal)

        for view in [icon, name, shortcuts, caret] {
            view.translatesAutoresizingMaskIntoConstraints = false
            addSubview(view)
        }
        imageView = icon
        textField = name
        let caretTrailing = caret.centerXAnchor.constraint(equalTo: trailingAnchor)
        self.caretTrailing = caretTrailing

        NSLayoutConstraint.activate([
            icon.leadingAnchor.constraint(equalTo: leadingAnchor, constant: AppBrowseRowMetrics.leadingInset),
            icon.centerYAnchor.constraint(equalTo: bottomAnchor, constant: -AppBrowseRowMetrics.appHeight / 2),
            icon.widthAnchor.constraint(equalToConstant: AppIconCache.pointSize),
            icon.heightAnchor.constraint(equalToConstant: AppIconCache.pointSize),
            name.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 12),
            name.trailingAnchor.constraint(lessThanOrEqualTo: shortcuts.leadingAnchor, constant: -12),
            name.centerYAnchor.constraint(equalTo: icon.centerYAnchor),
            shortcuts.trailingAnchor.constraint(
                equalTo: caret.centerXAnchor,
                constant: -AppBrowseRowMetrics.caretAreaWidth / 2
            ),
            shortcuts.firstBaselineAnchor.constraint(equalTo: name.firstBaselineAnchor),
            caretTrailing,
            caret.centerYAnchor.constraint(equalTo: icon.centerYAnchor),
        ])
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override var backgroundStyle: NSView.BackgroundStyle {
        didSet {
            caret.isHidden = backgroundStyle != .emphasized
            shortcuts.textColor = backgroundStyle == .emphasized ? .alternateSelectedControlTextColor : .secondaryLabelColor
        }
    }

    func showActionsMenuOpen(_ isOpen: Bool) {
        caret.pointDown(isOpen, animated: true)
    }

    func show(_ app: IndexedApp, icon: NSImage, shortcuts shortcutLabel: String?, reservesLetterIndex: Bool) {
        appURL = app.url
        caret.pointDown(false, animated: false)
        textField?.stringValue = app.name
        shortcuts.stringValue = shortcutLabel ?? ""
        imageView?.image = icon
        caretTrailing?.constant = -(AppBrowseRowMetrics.trailingInset(reservesLetterIndex: reservesLetterIndex)
            + AppBrowseRowMetrics.caretAreaWidth / 2)
    }
}

final class AppBrowseHeaderView: NSTableCellView {
    static let identifier = NSUserInterfaceItemIdentifier("AppBrowseHeader")

    init() {
        super.init(frame: .zero)
        identifier = Self.identifier

        let title = NSTextField(labelWithString: "")
        title.font = .systemFont(ofSize: NSFont.smallSystemFontSize, weight: .semibold)
        title.textColor = .secondaryLabelColor
        title.translatesAutoresizingMaskIntoConstraints = false
        addSubview(title)
        textField = title

        NSLayoutConstraint.activate([
            title.leadingAnchor.constraint(equalTo: leadingAnchor, constant: AppBrowseRowMetrics.leadingInset),
            title.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) is not supported")
    }
}

/// Draws the selection as a rounded accent-colored bar, and keeps it that color even though the
/// search field, not the table, has keyboard focus.
final class AppBrowseRowView: NSTableRowView {
    static let identifier = NSUserInterfaceItemIdentifier("AppBrowseRow")

    var reservesLetterIndex = true {
        didSet {
            needsDisplay = true
        }
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        identifier = Self.identifier
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override var isEmphasized: Bool {
        get { true }
        set { super.isEmphasized = newValue }
    }

    override func drawSelection(in _: NSRect) {
        var rect = AppBrowseRowMetrics.selectionRect(inRow: bounds, reservesLetterIndex: reservesLetterIndex)
        if !isFlipped {
            rect.origin.y = bounds.maxY - rect.maxY
        }
        NSColor.selectedContentBackgroundColor.setFill()
        NSBezierPath(roundedRect: rect, xRadius: 8, yRadius: 8).fill()
    }
}

/// A section header, with glass behind it only while it's pinned to the top so the rows scrolling
/// underneath don't show through the letter.
final class AppBrowseHeaderRowView: NSTableRowView {
    static let identifier = NSUserInterfaceItemIdentifier("AppBrowseHeaderRow")

    private let glass = NSGlassEffectView()

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        identifier = Self.identifier
        glass.cornerRadius = 0
        // Plain glass lets the rows underneath read through too clearly behind the letter.
        glass.tintColor = NSColor.windowBackgroundColor.withAlphaComponent(0.4)
        glass.frame = bounds
        glass.autoresizingMask = [.width, .height]
        glass.isHidden = true
        addSubview(glass, positioned: .below, relativeTo: nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override var isFloating: Bool {
        didSet {
            glass.isHidden = !isFloating
        }
    }

    override func drawBackground(in _: NSRect) {
        // The group row style's own background would cover the panel's glass.
    }
}
