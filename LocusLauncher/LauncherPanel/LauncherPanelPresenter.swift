import AppKit

final class LauncherPanelPresenter {
    private let settings: SettingsWindowPresenter
    private let appIndex: AppIndexStore
    private lazy var panel = LauncherPanel(
        onDismiss: { [weak self] in
            self?.dismiss()
        },
        onOpenSettings: { [weak self] in
            self?.dismiss()
            self?.settings.show()
        }
    )

    init(settings: SettingsWindowPresenter, appIndex: AppIndexStore) {
        self.settings = settings
        self.appIndex = appIndex
    }

    func toggle() {
        if panel.isVisible {
            dismiss()
        } else {
            show()
        }
    }

    func show() {
        guard !panel.isVisible else { return }

        panel.setRootView(LauncherPanelView(appIndex: appIndex))
        if let frame = LauncherPanelPlacement(size: LauncherPanel.size).frame() {
            panel.setFrame(frame, display: false)
        } else {
            panel.center()
        }
        panel.makeKeyAndOrderFront(nil)
    }

    func dismiss() {
        guard panel.isVisible else { return }

        panel.orderOut(nil)
    }
}
