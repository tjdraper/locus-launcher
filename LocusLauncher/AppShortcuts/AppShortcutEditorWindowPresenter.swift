import AppKit
import SwiftUI

/// Shows the Manage Hot Keys window, one app at a time. It opens over whatever opened it and
/// doesn't remember where it was, since it belongs to that window or panel.
final class AppShortcutEditorWindowPresenter: NSObject, NSWindowDelegate {
    private let store: AppShortcutStore
    private let appIndex: AppIndexStore
    private let appIcons: AppIconCache
    private let accessibilityAccess: AccessibilityAccessStore
    private let dockIcon: DockIconPresence
    private var shownAppID: String?
    private lazy var window = makeWindow()

    init(
        store: AppShortcutStore,
        appIndex: AppIndexStore,
        appIcons: AppIconCache,
        accessibilityAccess: AccessibilityAccessStore,
        dockIcon: DockIconPresence
    ) {
        self.store = store
        self.appIndex = appIndex
        self.appIcons = appIcons
        self.accessibilityAccess = accessibilityAccess
        self.dockIcon = dockIcon
    }

    /// Starts an app with no hot keys off with an empty one, ready to record.
    func show(_ app: IndexedApp, over anchor: NSRect) {
        if store.list.entries(forAppID: app.persistentID).isEmpty {
            store.add(for: app)
        }
        show(appID: app.persistentID, appName: app.name, over: anchor)
    }

    /// The anchor is in screen coordinates.
    func show(appID: String, appName: String, over anchor: NSRect) {
        if let shownAppID, shownAppID != appID {
            store.removeUnrecorded(forAppID: shownAppID)
        }
        shownAppID = appID
        window.contentViewController = NSHostingController(rootView: AppShortcutEditorView(
            appID: appID,
            appName: appName,
            store: store,
            appIndex: appIndex,
            appIcons: appIcons,
            accessibilityAccess: accessibilityAccess
        ))
        window.title = "\(appName) Hot Keys"
        if !window.isVisible {
            place(over: anchor)
        }
        dockIcon.windowWillShow(window)
        AppActivation.bringToFront()
        window.makeKeyAndOrderFront(nil)
    }

    func windowWillClose(_: Notification) {
        if let shownAppID {
            store.removeUnrecorded(forAppID: shownAppID)
        }
        shownAppID = nil
        dockIcon.windowWillClose(window)
    }

    private func place(over anchor: NSRect) {
        guard let screen = NSScreen.screens.first(where: { $0.frame.intersects(anchor) }) ?? NSScreen.main else { return }
        window.layoutIfNeeded()
        let placement = AppShortcutEditorPlacement(anchor: anchor, visibleScreenFrame: screen.visibleFrame)
        window.setFrameOrigin(placement.origin(for: window.frame.size))
    }

    private func makeWindow() -> NSWindow {
        let window = NSWindow(contentRect: .zero, styleMask: [.titled, .closable], backing: .buffered, defer: true)
        window.isReleasedWhenClosed = false
        window.delegate = self
        return window
    }
}
