import AppKit
import SwiftUI

/// An AppKit table rather than a SwiftUI list, because it reuses row views and scrolls smoothly
/// through hundreds of apps.
struct AppBrowseTable: NSViewRepresentable {
    let list: BrowseList
    let controller: AppBrowseTableController

    func makeNSView(context _: Context) -> NSScrollView {
        controller.makeScrollView()
    }

    func updateNSView(_: NSScrollView, context _: Context) {
        controller.show(list)
    }
}

/// Reports the row under the pointer whenever the pointer moves or the rows scroll beneath it.
final class AppBrowseTableView: NSTableView {
    var onHoverRow: ((Int) -> Void)?
    var showsSections = true

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        // The panel never activates the app, so tracking has to work while the app is inactive.
        addTrackingArea(NSTrackingArea(
            rect: .zero,
            options: [.mouseMoved, .activeAlways, .inVisibleRect],
            owner: self
        ))
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func acceptsFirstMouse(for _: NSEvent?) -> Bool {
        true
    }

    override func mouseMoved(with event: NSEvent) {
        super.mouseMoved(with: event)
        reportHover(at: event.locationInWindow)
    }

    override func scrollWheel(with event: NSEvent) {
        super.scrollWheel(with: event)
        if let window {
            reportHover(at: window.mouseLocationOutsideOfEventStream)
        }
    }

    /// The row at a point in the window, or nil when the point is on the section header pinned
    /// to the top or on the letter index, which `row(at:)` would see through.
    func visibleRow(atWindowLocation locationInWindow: NSPoint) -> Int? {
        let point = convert(locationInWindow, from: nil)
        let pinnedHeaderHeight = showsSections ? AppBrowseRowMetrics.headerHeight : 0
        let letterIndexWidth = showsSections ? AppBrowseRowMetrics.letterIndexWidth : 0
        guard visibleRect.contains(point),
              point.y >= visibleRect.minY + pinnedHeaderHeight,
              point.x < visibleRect.maxX - letterIndexWidth else {
            return nil
        }
        let row = row(at: point)
        return row >= 0 ? row : nil
    }

    private func reportHover(at locationInWindow: NSPoint) {
        if let row = visibleRow(atWindowLocation: locationInWindow) {
            onHoverRow?(row)
        }
    }
}
