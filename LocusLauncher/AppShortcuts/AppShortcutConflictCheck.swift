import KeyboardShortcuts

/// Keeps a key combination from doing two things in this app: opening the launcher and an app, or
/// two apps.
struct AppShortcutConflictCheck {
    enum Recording {
        case launcher
        case appShortcut(AppShortcutList.Entry.ID)
    }

    enum Conflict {
        case launcher
        case appShortcut(AppShortcutList.Entry)

        var reason: String {
            switch self {
            case .launcher:
                "This shortcut already opens the launcher."
            case let .appShortcut(entry):
                switch entry.action {
                case .open: "This shortcut already opens \(entry.appName)."
                case .newWindow: "This shortcut already opens a new \(entry.appName) window."
                }
            }
        }
    }

    let store: AppShortcutStore

    func conflict(for shortcut: KeyboardShortcuts.Shortcut, recording: Recording) -> Conflict? {
        switch recording {
        case .launcher:
            return store.list.entry(using: AppShortcutList.Keys(shortcut)).map(Conflict.appShortcut)
        case let .appShortcut(id):
            if KeyboardShortcuts.getShortcut(for: .toggleLauncher) == shortcut {
                return .launcher
            }
            return store.list.entry(using: AppShortcutList.Keys(shortcut), except: id).map(Conflict.appShortcut)
        }
    }
}
