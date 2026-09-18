import AppKit

/// The selected row's caret. It points right, and turns to point down while the actions menu is
/// open.
///
/// The chevron is a sublayer because AppKit resets the anchor point of a view's own layer, which
/// would turn it around a corner instead of its center.
final class ActionsCaretView: NSView {
    private static let symbol = NSImage(systemSymbolName: "chevron.right", accessibilityDescription: "Actions")?
        .withSymbolConfiguration(.init(pointSize: 13, weight: .semibold))

    private let chevron = CALayer()

    init() {
        super.init(frame: .zero)
        wantsLayer = true
        chevron.contentsGravity = .center
        layer?.addSublayer(chevron)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override var intrinsicContentSize: NSSize {
        Self.symbol?.size ?? .zero
    }

    override func layout() {
        super.layout()
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        chevron.bounds = bounds
        chevron.position = CGPoint(x: bounds.midX, y: bounds.midY)
        CATransaction.commit()
    }

    override func viewDidChangeBackingProperties() {
        super.viewDidChangeBackingProperties()
        drawChevron()
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        drawChevron()
    }

    func pointDown(_ pointsDown: Bool, animated: Bool) {
        let transform = pointsDown ? CGAffineTransform(rotationAngle: -.pi / 2) : .identity
        guard chevron.affineTransform() != transform else { return }
        CATransaction.begin()
        CATransaction.setDisableActions(!animated)
        CATransaction.setAnimationDuration(0.15)
        chevron.setAffineTransform(transform)
        CATransaction.commit()
        if animated {
            // The actions menu runs its own event loop right after this, which would hold the
            // turn back until the menu closes.
            CATransaction.flush()
        }
    }

    /// Only shown on the selection, which is drawn in the accent color.
    private func drawChevron() {
        guard let symbol = Self.symbol else { return }
        let scale = window?.backingScaleFactor ?? 2
        effectiveAppearance.performAsCurrentDrawingAppearance {
            let tinted = symbol.withSymbolConfiguration(.init(paletteColors: [.alternateSelectedControlTextColor])) ?? symbol
            chevron.contentsScale = tinted.recommendedLayerContentsScale(scale)
            chevron.contents = tinted.layerContents(forContentsScale: chevron.contentsScale)
        }
    }
}
