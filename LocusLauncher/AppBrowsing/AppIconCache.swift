import AppKit
import Observation
import UniformTypeIdentifiers

/// App icons pre-rendered at the size the list draws them, so scrolling never asks the system for
/// an icon or scales a full-size one.
final class AppIconCache {
    nonisolated static let pointSize: CGFloat = 32

    private var icons: [URL: NSImage] = [:]
    private var loads: [URL: Task<NSImage, Never>] = [:]
    private var prewarm: Task<Void, Never>?

    lazy var placeholder: NSImage = Self.render(NSWorkspace.shared.icon(for: .applicationBundle)).map(Self.image)
        ?? NSImage(size: NSSize(width: Self.pointSize, height: Self.pointSize))

    /// Renders icons for every indexed app in the background, so the list rarely waits on one.
    func start(observing appIndex: AppIndexStore) {
        Task { [weak self] in
            for await apps in Observations({ appIndex.apps }) {
                self?.refresh(for: apps.map(\.url))
            }
        }
    }

    func cachedIcon(for url: URL) -> NSImage? {
        icons[url]
    }

    func icon(for url: URL) async -> NSImage {
        if let icon = icons[url] {
            return icon
        }
        if let load = loads[url] {
            return await load.value
        }

        let load = Task {
            let icon = await Self.renderIcon(at: url).map(Self.image) ?? placeholder
            icons[url] = icon
            loads[url] = nil
            return icon
        }
        loads[url] = load
        return await load.value
    }

    private func refresh(for urls: [URL]) {
        let current = Set(urls)
        icons = icons.filter { current.contains($0.key) }

        prewarm?.cancel()
        prewarm = Task { [weak self] in
            // One icon at a time in list order, so the rows at the top are ready first and a large
            // index doesn't occupy every core.
            for url in urls {
                guard !Task.isCancelled, let self else { return }
                _ = await icon(for: url)
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
