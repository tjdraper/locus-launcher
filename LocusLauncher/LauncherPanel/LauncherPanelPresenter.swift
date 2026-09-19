import AppKit

final class LauncherPanelPresenter {
    /// How long a closed panel keeps the search text, cursor and selection before starting over.
    private static let sessionGracePeriod: Duration = .seconds(10)

    private let settings: SettingsWindowPresenter
    private let hiddenAppsWindow: HiddenAppsWindowPresenter
    private let appShortcutsWindow: AppShortcutsWindowPresenter
    private let shortcutEditor: AppShortcutEditorWindowPresenter
    private let updates: UpdateController
    private let appIndex: AppIndexStore
    private let appIcons: AppIconCache
    private let hiddenApps: HiddenAppsStore
    private let appShortcuts: AppShortcutStore
    private let newWindowOpener: NewWindowOpener
    private let launchHistory = LaunchHistoryStore()
    private lazy var panel = LauncherPanel(
        onDismiss: { [weak self] in
            self?.dismiss()
        },
        onOpenSettings: { [weak self] in
            self?.dismiss()
            self?.settings.show()
        },
        onOpenHiddenApps: { [weak self] in
            self?.dismiss()
            self?.hiddenAppsWindow.show()
        },
        onOpenAppShortcuts: { [weak self] in
            self?.dismiss()
            self?.appShortcutsWindow.show()
        },
        onKeyCommand: { [weak self] command in
            self?.perform(command)
        }
    )
    private var browse: AppBrowseTableController?
    private var search: AppSearchSession?
    private var sessionEnd: Task<Void, Never>?

    init(
        settings: SettingsWindowPresenter,
        hiddenAppsWindow: HiddenAppsWindowPresenter,
        appShortcutsWindow: AppShortcutsWindowPresenter,
        shortcutEditor: AppShortcutEditorWindowPresenter,
        updates: UpdateController,
        appIndex: AppIndexStore,
        appIcons: AppIconCache,
        hiddenApps: HiddenAppsStore,
        appShortcuts: AppShortcutStore,
        newWindowOpener: NewWindowOpener
    ) {
        self.settings = settings
        self.hiddenAppsWindow = hiddenAppsWindow
        self.appShortcutsWindow = appShortcutsWindow
        self.shortcutEditor = shortcutEditor
        self.updates = updates
        self.appIndex = appIndex
        self.appIcons = appIcons
        self.hiddenApps = hiddenApps
        self.appShortcuts = appShortcuts
        self.newWindowOpener = newWindowOpener
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

        browse?.closeActionsMenu()
        panel.orderOut(nil)
        sessionEnd = Task { [weak self] in
            try? await Task.sleep(for: Self.sessionGracePeriod)
            guard !Task.isCancelled else { return }
            self?.endSession()
        }
    }

    private func startSession() {
        let browse = AppBrowseTableController(icons: appIcons) { [weak self] action, app in
            self?.perform(action, on: app)
        }
        let search = AppSearchSession(history: launchHistory.history)
        self.browse = browse
        self.search = search
        panel.interceptEvent = { [weak browse] event in
            browse?.handleEventWhileActionsMenuIsOpen(event) ?? false
        }
        panel.setRootView(
            LauncherPanelView(
                appIndex: appIndex,
                hiddenApps: hiddenApps,
                appShortcuts: appShortcuts,
                search: search,
                browse: browse,
                updates: updates
            ) { [weak self] in
                self?.dismiss()
                self?.updates.checkForUpdates()
            }
        )
    }

    private func endSession() {
        sessionEnd?.cancel()
        browse = nil
        search = nil
        panel.contentView = nil
    }

    private func perform(_ command: LauncherPanel.KeyCommand) {
        switch command {
        case .moveUp: browse?.moveSelectionUp()
        case .moveDown: browse?.moveSelectionDown()
        case .showActions: browse?.showActionsForSelection()
        case let .perform(action):
            if let app = browse?.selectedApp {
                perform(action, on: app)
            }
        }
    }

    private func perform(_ action: AppAction, on app: IndexedApp) {
        switch action {
        case .open:
            launchHistory.record(app, searchedFor: search?.query ?? "")
            NSWorkspace.shared.openApplication(at: app.url, configuration: NSWorkspace.OpenConfiguration())
            dismissAndEndSession()
        case .newWindow:
            launchHistory.record(app, searchedFor: search?.query ?? "")
            newWindowOpener.open(app)
            dismissAndEndSession()
        case .revealInFinder:
            NSWorkspace.shared.activateFileViewerSelecting([app.url])
            dismissAndEndSession()
        case .manageShortcuts:
            dismiss()
            shortcutEditor.show(app, over: panel.frame)
        case .hide:
            hiddenApps.hide(app)
        }
    }

    private func dismissAndEndSession() {
        dismiss()
        // A click launches from inside the table's own mouse handling, which must finish before
        // the table is torn down.
        Task { [weak self] in
            self?.endSession()
        }
    }
}
