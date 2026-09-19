import AppKit
import ApplicationServices
import Carbon.HIToolbox

/// Opens a new window in an app by bringing it forward and choosing its New Window menu item for
/// the user. Without Accessibility access, or when the app wasn't running, it only opens the app,
/// since an app that's just starting shows a window of its own.
struct NewWindowOpener {
    private static let activationTimeout: Duration = .seconds(2)
    /// A hung app would otherwise hold the launcher for the system's default of several seconds.
    private static let menuTimeout: Float = 1

    let access: AccessibilityAccessStore

    func open(_ app: IndexedApp) {
        let bundleURL = app.url.resolvingSymlinksInPath()
        let wasRunning = NSWorkspace.shared.runningApplications.contains {
            $0.bundleURL?.resolvingSymlinksInPath() == bundleURL
        }
        access.refresh()
        let canControlApps = access.isGranted
        NSWorkspace.shared.openApplication(at: app.url, configuration: NSWorkspace.OpenConfiguration()) { running, _ in
            let processIdentifier = running?.processIdentifier
            Task { @MainActor in
                guard wasRunning, canControlApps, let processIdentifier else { return }
                await Self.openWindow(in: processIdentifier)
            }
        }
        if !canControlApps {
            access.requestAccessIfNeverAsked()
        }
    }

    /// Waits for the app to come forward first, so the window opens in front.
    private static func openWindow(in processIdentifier: pid_t) async {
        let clock = ContinuousClock()
        let deadline = clock.now + activationTimeout
        while NSWorkspace.shared.frontmostApplication?.processIdentifier != processIdentifier, clock.now < deadline {
            try? await Task.sleep(for: .milliseconds(20))
        }

        if !pressNewWindowMenuItem(in: processIdentifier) {
            pressCommandN(in: processIdentifier)
        }
    }

    /// The menu item reaches apps whose New Window isn't Cmd+N, and apps such as iTerm that ignore
    /// keystrokes posted to them.
    private static func pressNewWindowMenuItem(in processIdentifier: pid_t) -> Bool {
        let app = AXUIElementCreateApplication(processIdentifier)
        AXUIElementSetMessagingTimeout(app, menuTimeout)
        guard let menuBar: AXUIElement = value(of: kAXMenuBarAttribute, in: app) else { return false }

        let menuItems = children(of: menuBar)
            .flatMap(children(of:))
            .flatMap(children(of:))
        let item = menuItemTitles(for: processIdentifier).lazy.compactMap { menuItemTitle in
            menuItems.first { element in
                let title: String? = value(of: kAXTitleAttribute, in: element)
                let isEnabled: Bool? = value(of: kAXEnabledAttribute, in: element)
                return title?.caseInsensitiveCompare(menuItemTitle) == .orderedSame && isEnabled == true
            }
        }.first
        guard let item else { return false }
        return AXUIElementPerformAction(item, kAXPressAction as CFString) == .success
    }

    /// Finder names its item New Finder Window, and ignores a Cmd+N posted to it. Matching only
    /// the app's own name keeps items such as New Private Window out.
    private static func menuItemTitles(for processIdentifier: pid_t) -> [String] {
        guard let appName = NSRunningApplication(processIdentifier: processIdentifier)?.localizedName else {
            return ["New Window"]
        }
        return ["New Window", "New \(appName) Window"]
    }

    /// For apps without a New Window menu item, including apps whose menus aren't in English.
    private static func pressCommandN(in processIdentifier: pid_t) {
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

    private static func children(of element: AXUIElement) -> [AXUIElement] {
        value(of: kAXChildrenAttribute, in: element) ?? []
    }

    private static func value<Value>(of attribute: String, in element: AXUIElement) -> Value? {
        var value: AnyObject?
        guard AXUIElementCopyAttributeValue(element, attribute as CFString, &value) == .success else { return nil }
        return value as? Value
    }
}
