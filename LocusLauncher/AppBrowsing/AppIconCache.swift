import AppKit
import Observation
import UniformTypeIdentifiers

/// App icons pre-rendered at the size the list draws them, so scrolling never asks the system for
/// an icon or scales a full-size one. An update to an app changes its key, so its icon is drawn
/// again.
final class AppIconCache {
    nonisolated static let pointSize: CGFloat = 32

    private struct Key: Hashable {
        let url: URL
        let lastModified: Date?

        init(_ app: IndexedApp) {
            url = app.url
            lastModified = app.lastModified
        }
    }

    private var icons: [Key: NSImage] = [:]
    private var loads: [Key: Task<NSImage, Never>] = [:]
    private var prewarm: Task<Void, Never>?

    lazy var placeholder: NSImage = Self.render(NSWorkspace.shared.icon(for: .applicationBundle)).map(Self.image)
        ?? NSImage(size: NSSize(width: Self.pointSize, height: Self.pointSize))

    /// Renders icons for every indexed app in the background, so the list rarely waits on one.
    func start(observing appIndex: AppIndexStore) {
        Task { [weak self] in
            for await apps in Observations({ appIndex.apps }) {
                self?.refresh(for: apps)
            }
        }
    }

    func cachedIcon(for app: IndexedApp) -> NSImage? {
        icons[Key(app)]
    }

    func icon(for app: IndexedApp) async -> NSImage {
        let key = Key(app)
        if let icon = icons[key] {
            return icon
        }
        if let load = loads[key] {
            return await load.value
        }

        let load = Task {
            let icon = await Self.renderIcon(at: app.url).map(Self.image) ?? placeholder
            icons[key] = icon
            loads[key] = nil
            return icon
        }
        loads[key] = load
        return await load.value
    }

    private func refresh(for apps: [IndexedApp]) {
        let current = Set(apps.map(Key.init))
        icons = icons.filter { current.contains($0.key) }

        prewarm?.cancel()
        prewarm = Task { [weak self] in
            // One icon at a time in list order, so the rows at the top are ready first and a large
            // index doesn't occupy every core.
            for app in apps {
                guard !Task.isCancelled, let self else { return }
                _ = await icon(for: app)
            }
        }
    }

    @concurrent
    private nonisolated static func renderIcon(at url: URL) async -> CGImage? {
        render(NSWorkspace.shared.icon(forFile: url.path))
    }

    // Always 2x: Retina is the common case, and a 1x screen scales it down by exactly half.
    private nonisolated static func render(_ icon: NSImage) -> CGImage? {
        let pixels = Int(pointSize * 2)
        guard let context = CGContext(
            data: nil,
            width: pixels,
            height: pixels,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return nil
        }

        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: false)
        icon.draw(in: NSRect(x: 0, y: 0, width: pixels, height: pixels))
        NSGraphicsContext.restoreGraphicsState()
        return context.makeImage()
    }

    private nonisolated static func image(from cgImage: CGImage) -> NSImage {
        NSImage(cgImage: cgImage, size: NSSize(width: pointSize, height: pointSize))
    }
}
