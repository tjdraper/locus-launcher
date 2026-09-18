import AppKit

final class LauncherPanelPresenter {
    /// How long a closed panel keeps the search text, cursor and selection before starting over.
    private static let sessionGracePeriod: Duration = .seconds(10)

    private let settings: SettingsWindowPresenter
    private let appIndex: AppIndexStore
    private let appIcons: AppIconCache
    private lazy var panel = LauncherPanel(
        onDismiss: { [weak self] in
            self?.dismiss()
        },
        onOpenSettings: { [weak self] in
            self?.dismiss()
            self?.settings.show()
        },
        onKeyCommand: { [weak self] command in
            self?.perform(command)
        }
    )
    private var browse: AppBrowseTableController?
    private var sessionEnd: Task<Void, Never>?

    init(settings: SettingsWindowPresenter, appIndex: AppIndexStore, appIcons: AppIconCache) {
        self.settings = settings
        self.appIndex = appIndex
        self.appIcons = appIcons
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

        sessionEnd?.cancel()
        if browse == nil {
            startSession()
        }
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
        sessionEnd = Task { [weak self] in
            try? await Task.sleep(for: Self.sessionGracePeriod)
            guard !Task.isCancelled else { return }
            self?.endSession()
        }
    }

    private func startSession() {
        let browse = AppBrowseTableController(icons: appIcons) { [weak self] app in
            self?.launch(app)
        }
        self.browse = browse
        panel.setRootView(LauncherPanelView(appIndex: appIndex, browse: browse))
    }

    private func endSession() {
        sessionEnd?.cancel()
        browse = nil
        panel.contentView = nil
    }

    private func perform(_ command: LauncherPanel.KeyCommand) {
        switch command {
        case .moveUp: browse?.moveSelectionUp()
        case .moveDown: browse?.moveSelectionDown()
        case .launch: browse?.launchSelection()
        }
    }

    private func launch(_ app: IndexedApp) {
        NSWorkspace.shared.openApplication(at: app.url, configuration: NSWorkspace.OpenConfiguration())
        dismiss()
        // A click launches from inside the table's own mouse handling, which must finish before
        // the table is torn down.
        Task { [weak self] in
            self?.endSession()
        }
    }
}
