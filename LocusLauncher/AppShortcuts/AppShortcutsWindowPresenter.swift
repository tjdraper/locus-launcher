import AppKit
import SwiftUI

final class AppShortcutsWindowPresenter: NSObject, NSWindowDelegate {
    private let store: AppShortcutStore
    private let appIndex: AppIndexStore
    private let appIcons: AppIconCache
    private let shortcutEditor: AppShortcutEditorWindowPresenter
    private let dockIcon: DockIconPresence
    private lazy var window = makeWindow()

    init(
        store: AppShortcutStore,
        appIndex: AppIndexStore,
        appIcons: AppIconCache,
        shortcutEditor: AppShortcutEditorWindowPresenter,
        dockIcon: DockIconPresence
    ) {
        self.store = store
        self.appIndex = appIndex
        self.appIcons = appIcons
        self.shortcutEditor = shortcutEditor
        self.dockIcon = dockIcon
    }

    func show() {
        dockIcon.windowWillShow(window)
        AppActivation.bringToFront()
        window.makeKeyAndOrderFront(nil)
    }

    func windowWillClose(_: Notification) {
        dockIcon.windowWillClose(window)
    }

    private func makeWindow() -> NSWindow {
        let window = NSWindow(contentViewController: NSHostingController(
            rootView: AppShortcutsView(store: store, appIndex: appIndex, appIcons: appIcons) { [weak self] appID, appName in
                guard let self else { return }
                shortcutEditor.show(appID: appID, appName: appName, over: window.convertToScreen(window.contentLayoutRect))
            }
        ))
        window.title = "Locus Launcher App Hot Keys"
        window.styleMask = [.titled, .closable, .resizable]
        window.isReleasedWhenClosed = false
        window.delegate = self
        RememberedWindowPlacement(autosaveName: "AppHotKeys").apply(to: window)
        return window
    }
}
