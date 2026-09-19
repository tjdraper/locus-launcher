import AppKit

/// Opens the app a hot key belongs to, or a new window in it.
struct AppShortcutRunner {
    let appIndex: AppIndexStore
    let newWindowOpener: NewWindowOpener

    func run(_ entry: AppShortcutList.Entry) {
        guard let app = appIndex.apps.first(where: { $0.persistentID == entry.appID }) else {
            NSSound.beep()
            return
        }
        switch entry.action {
        case .open:
            // Leaving an app that's already in front alone is a choice; some launchers hide it.
            guard !isFrontmost(app) else { return }
            NSWorkspace.shared.openApplication(at: app.url, configuration: NSWorkspace.OpenConfiguration())
        case .newWindow:
            newWindowOpener.open(app)
        }
    }

    private func isFrontmost(_ app: IndexedApp) -> Bool {
        NSWorkspace.shared.frontmostApplication?.bundleURL?.resolvingSymlinksInPath() == app.url.resolvingSymlinksInPath()
    }
}
