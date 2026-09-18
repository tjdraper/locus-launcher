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
}

final class AppBrowseCellView: NSTableCellView {
    static let identifier = NSUserInterfaceItemIdentifier("AppBrowseCell")

    private(set) var appURL: URL?

    init() {
        super.init(frame: .zero)
        identifier = Self.identifier

        let icon = NSImageView()
        icon.imageScaling = .scaleProportionallyUpOrDown
        let name = NSTextField(labelWithString: "")
        name.font = .preferredFont(forTextStyle: .title3)
        name.lineBreakMode = .byTruncatingTail
        name.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        for view in [icon, name] {
            view.translatesAutoresizingMaskIntoConstraints = false
            addSubview(view)
        }
        imageView = icon
        textField = name

        NSLayoutConstraint.activate([
            icon.leadingAnchor.constraint(equalTo: leadingAnchor, constant: AppBrowseRowMetrics.leadingInset),
            icon.centerYAnchor.constraint(equalTo: bottomAnchor, constant: -AppBrowseRowMetrics.appHeight / 2),
            icon.widthAnchor.constraint(equalToConstant: AppIconCache.pointSize),
            icon.heightAnchor.constraint(equalToConstant: AppIconCache.pointSize),
            name.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 12),
            name.trailingAnchor.constraint(
                lessThanOrEqualTo: trailingAnchor,
                constant: -(AppBrowseRowMetrics.letterIndexWidth + AppBrowseRowMetrics.selectionInset)
            ),
            name.centerYAnchor.constraint(equalTo: icon.centerYAnchor),
        ])
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    func show(_ app: IndexedApp, icon: NSImage) {
        appURL = app.url
        textField?.stringValue = app.name
        imageView?.image = icon
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
        let appBounds = NSRect(
            x: bounds.minX,
            y: isFlipped ? bounds.maxY - AppBrowseRowMetrics.appHeight : bounds.minY,
            width: bounds.width,
            height: AppBrowseRowMetrics.appHeight
        )
        // The vertical inset keeps the selection off the section header above it.
        var rect = appBounds.insetBy(dx: AppBrowseRowMetrics.selectionInset, dy: 3)
        if reservesLetterIndex {
            rect.size.width -= AppBrowseRowMetrics.letterIndexWidth
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
