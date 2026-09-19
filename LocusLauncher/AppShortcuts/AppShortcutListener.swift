import KeyboardShortcuts
import Observation

/// Registers every recorded hot key with the system, and runs its entry when it's pressed.
final class AppShortcutListener {
    private let store: AppShortcutStore
    private let runner: AppShortcutRunner
    private var listeners: [AppShortcutList.Keys: Task<Void, Never>] = [:]

    init(store: AppShortcutStore, runner: AppShortcutRunner) {
        self.store = store
        self.runner = runner
    }

    func start() {
        Task { [store] in
            for await keys in Observations({ Set(store.list.entries.compactMap(\.keys)) }) {
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

    private func press(_ keys: AppShortcutList.Keys) {
        guard let entry = store.list.entry(using: keys) else { return }
        runner.run(entry)
    }
}
