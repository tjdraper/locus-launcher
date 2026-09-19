import KeyboardShortcuts
import Observation

/// Registers every hot key that works on this Mac with the system, and runs its entry when it's
/// pressed.
final class AppShortcutListener {
    private let store: AppShortcutStore
    private let appIndex: AppIndexStore
    private let runner: AppShortcutRunner
    private var listeners: [AppShortcutList.Keys: Task<Void, Never>] = [:]

    init(store: AppShortcutStore, appIndex: AppIndexStore, runner: AppShortcutRunner) {
        self.store = store
        self.appIndex = appIndex
        self.runner = runner
    }

    func start() {
        Task { [store, appIndex] in
            let workingKeys = Observations {
                Set(store.list.workingEntries(installedAppIDs: Set(appIndex.apps.map(\.persistentID))).keys)
            }
            for await keys in workingKeys {
                listen(to: keys)
            }
        }
    }

    private func listen(to keys: Set<AppShortcutList.Keys>) {
        for (registered, listener) in listeners where !keys.contains(registered) {
            // Ending the event stream unregisters the hot key.
            listener.cancel()
            listeners[registered] = nil
        }
        for newKeys in keys where listeners[newKeys] == nil {
            listeners[newKeys] = Task { [weak self] in
                for await _ in KeyboardShortcuts.events(.keyDown, for: newKeys.shortcut) {
                    self?.press(newKeys)
                }
            }
        }
    }

    /// A hot key synced from another Mac can use this Mac's launcher keys. The package runs every
    /// handler for a combination, so the launcher opens and the hot key has to stand aside.
    private func press(_ keys: AppShortcutList.Keys) {
        guard KeyboardShortcuts.getShortcut(for: .toggleLauncher) != keys.shortcut else { return }
        let installedAppIDs = Set(appIndex.apps.map(\.persistentID))
        guard let entry = store.list.workingEntries(installedAppIDs: installedAppIDs)[keys] else { return }
        runner.run(entry)
    }
}
