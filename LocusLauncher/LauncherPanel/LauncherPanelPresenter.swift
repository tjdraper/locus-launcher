import AppKit

final class LauncherPanelPresenter {
    private lazy var panel = LauncherPanel(rootView: LauncherPanelView())

    func show() {
        panel.center()
        NSApp.activate()
        panel.makeKeyAndOrderFront(nil)
    }
}
