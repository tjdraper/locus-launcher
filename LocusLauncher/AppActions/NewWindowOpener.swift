import AppKit
import Carbon.HIToolbox

/// Opens a new window in an app by bringing it forward and pressing Cmd+N for the user. Without
/// Accessibility access, or when the app wasn't running, it only opens the app, since an app
/// that's just starting shows a window of its own.
struct NewWindowOpener {
    private static let activationTimeout: Duration = .seconds(2)

    let access: AccessibilityAccessStore

    func open(_ app: IndexedApp) {
        let bundleURL = app.url.resolvingSymlinksInPath()
        let wasRunning = NSWorkspace.shared.runningApplications.contains {
            $0.bundleURL?.resolvingSymlinksInPath() == bundleURL
        }
        access.refresh()
        let canPressKeys = access.isGranted
        NSWorkspace.shared.openApplication(at: app.url, configuration: NSWorkspace.OpenConfiguration()) { running, _ in
            let processIdentifier = running?.processIdentifier
            Task { @MainActor in
                guard wasRunning, canPressKeys, let processIdentifier else { return }
                await Self.pressCommandN(in: processIdentifier)
            }
        }
        if !canPressKeys {
            access.requestAccessIfNeverAsked()
        }
    }

    /// Waits for the app to come forward first, so the window opens in front.
    private static func pressCommandN(in processIdentifier: pid_t) async {
        let clock = ContinuousClock()
        let deadline = clock.now + activationTimeout
        while NSWorkspace.shared.frontmostApplication?.processIdentifier != processIdentifier, clock.now < deadline {
            try? await Task.sleep(for: .milliseconds(20))
        }

        let source = CGEventSource(stateID: .combinedSessionState)
        for isKeyDown in [true, false] {
            let event = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(kVK_ANSI_N), keyDown: isKeyDown)
            event?.flags = .maskCommand
            // Apps match menu shortcuts by character, and on layouts like Dvorak the N key code
            // types another letter.
            event?.keyboardSetUnicodeString(stringLength: 1, unicodeString: [UniChar(("n" as Unicode.Scalar).value)])
            event?.postToPid(processIdentifier)
        }
    }
}
