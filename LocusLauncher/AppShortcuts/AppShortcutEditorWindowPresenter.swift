import AppKit
import SwiftUI

/// Shows the Manage Hot Keys window, one per app, so several apps can be edited side by side. Each
/// one opens over whatever opened it and doesn't remember where it was, since it belongs to that
/// window or panel.
final class AppShortcutEditorWindowPresenter: NSObject, NSWindowDelegate {
    private let store: AppShortcutStore
    private let appIndex: AppIndexStore
    private let appIcons: AppIconCache
    private let accessibilityAccess: AccessibilityAccessStore
    private let dockIcon: DockIconPresence
    private var windowsByAppID: [String: NSWindow] = [:]

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
        let window = windowsByAppID[appID] ?? makeWindow(appID: appID, appName: appName, over: anchor)
        windowsByAppID[appID] = window
        dockIcon.windowWillShow(window)
        AppActivation.bringToFront()
        window.makeKeyAndOrderFront(nil)
    }

    func windowWillClose(_ notification: Notification) {
        guard let window = notification.object as? NSWindow,
              let appID = windowsByAppID.first(where: { $0.value === window })?.key else { return }
        store.removeUnrecorded(forAppID: appID)
        windowsByAppID[appID] = nil
        dockIcon.windowWillClose(window)
    }

    private func makeWindow(appID: String, appName: String, over anchor: NSRect) -> NSWindow {
        let window = NSWindow(contentRect: .zero, styleMask: [.titled, .closable], backing: .buffered, defer: true)
        window.contentViewController = NSHostingController(rootView: AppShortcutEditorView(
            appID: appID,
            appName: appName,
            store: store,
            appIndex: appIndex,
            appIcons: appIcons,
            accessibilityAccess: accessibilityAccess
        ))
        window.title = "\(appName) Hot Keys"
        window.isReleasedWhenClosed = false
        window.delegate = self
        place(window, over: anchor)
        return window
    }

    private func place(_ window: NSWindow, over anchor: NSRect) {
        guard let screen = NSScreen.screens.first(where: { $0.frame.intersects(anchor) }) ?? NSScreen.main else { return }
        window.layoutIfNeeded()
        let placement = AppShortcutEditorPlacement(anchor: anchor, visibleScreenFrame: screen.visibleFrame)
        let taken = windowsByAppID.values.filter(\.isVisible).map(\.frame)
        window.setFrameOrigin(placement.origin(for: window.frame.size, avoiding: taken))
    }
}
