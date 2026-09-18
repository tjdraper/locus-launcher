import AppKit

final class LauncherPanelPresenter {
    private let settings: SettingsWindowPresenter
    private lazy var panel = LauncherPanel(
        onDismiss: { [weak self] in
            self?.dismiss()
        },
        onOpenSettings: { [weak self] in
            self?.dismiss()
            self?.settings.show()
        }
    )

    init(settings: SettingsWindowPresenter) {
        self.settings = settings
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

        panel.setRootView(LauncherPanelView())
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
