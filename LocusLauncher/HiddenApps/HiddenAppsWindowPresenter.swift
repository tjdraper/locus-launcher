import AppKit
import SwiftUI

final class HiddenAppsWindowPresenter: NSObject, NSWindowDelegate {
    private let hiddenApps: HiddenAppsStore
    private let appIndex: AppIndexStore
    private let appIcons: AppIconCache
    private let dockIcon: DockIconPresence
    private lazy var window = makeWindow()

    init(hiddenApps: HiddenAppsStore, appIndex: AppIndexStore, appIcons: AppIconCache, dockIcon: DockIconPresence) {
        self.hiddenApps = hiddenApps
        self.appIndex = appIndex
        self.appIcons = appIcons
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
            rootView: HiddenAppsView(store: hiddenApps, appIndex: appIndex, appIcons: appIcons)
        ))
        window.title = "Locus Launcher Hidden Apps"
        window.styleMask = [.titled, .closable, .resizable]
        window.isReleasedWhenClosed = false
        window.delegate = self
        window.center()
        window.setFrameAutosaveName("HiddenApps")
        return window
    }
}
