import AppKit

/// Warns at launch when Spotlight holds the launcher's shortcut, since the launcher silently never
/// opens in that case.
struct SpotlightConflictLaunchCheck {
    private let store = SpotlightShortcutStore()

    func run() async {
        store.refresh()
        guard !store.conflictingShortcuts.isEmpty else { return }

        let names = SpotlightShortcutStore.displayNames(of: store.conflictingShortcuts)
        AppActivation.bringToFront()
        guard askToTurnOff(names) else { return }

        await store.turnOffConflictingShortcuts()
        if store.changeFailed {
            reportFailure()
        }
    }

    private func askToTurnOff(_ names: String) -> Bool {
        let alert = NSAlert()
        alert.messageText = "Spotlight is using \(names)"
        alert.informativeText = """
        The launcher can't open with \(names) while Spotlight uses it. Turn off Spotlight's \
        shortcut so the launcher gets it?
        """
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Turn Off Spotlight’s Shortcut")
        alert.addButton(withTitle: "Cancel")
        return alert.runModal() == .alertFirstButtonReturn
    }

    private func reportFailure() {
        let alert = NSAlert()
        alert.messageText = "Locus Launcher couldn't turn off Spotlight's shortcut."
        alert.informativeText = "Turn it off in Keyboard Settings under Keyboard Shortcuts › Spotlight."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Open Keyboard Settings")
        alert.addButton(withTitle: "Cancel")
        if alert.runModal() == .alertFirstButtonReturn {
            store.openKeyboardSettings()
        }
    }
}
