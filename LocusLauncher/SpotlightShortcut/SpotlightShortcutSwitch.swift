import Foundation

/// Turns Spotlight's shortcuts on and off by editing the system's keyboard shortcut settings, the
/// same place System Settings › Keyboard › Keyboard Shortcuts writes to.
struct SpotlightShortcutSwitch {
    enum Failure: Error {
        case settingsNotApplied
    }

    private static let domain = "com.apple.symbolichotkeys"
    private static let key = "AppleSymbolicHotKeys"

    /// Without this, a changed keyboard shortcut only takes effect after logging out. It's a
    /// private system tool, so it may move or change in a future macOS release.
    private static let activateSettingsURL = URL(
        fileURLWithPath: "/System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings"
    )

    private var defaults: UserDefaults? {
        UserDefaults(suiteName: Self.domain)
    }

    func read() -> SpotlightHotKeys {
        SpotlightHotKeys(symbolicHotKeys: defaults?.dictionary(forKey: Self.key) ?? [:])
    }

    func setEnabled(_ isEnabled: Bool, for ids: Set<String>) async throws {
        let changed = read().settingEnabled(isEnabled, for: ids)
        defaults?.set(changed.symbolicHotKeys, forKey: Self.key)
        try await applyWithoutLogout()

        let applied = read().entries.filter { ids.contains($0.id) }.allSatisfy { $0.isEnabled == isEnabled }
        guard applied else { throw Failure.settingsNotApplied }
    }

    private func applyWithoutLogout() async throws {
        let process = Process()
        process.executableURL = Self.activateSettingsURL
        process.arguments = ["-u"]
        let status: Int32 = try await withCheckedThrowingContinuation { continuation in
            process.terminationHandler = { continuation.resume(returning: $0.terminationStatus) }
            do {
                try process.run()
            } catch {
                continuation.resume(throwing: error)
            }
        }
        guard status == 0 else { throw Failure.settingsNotApplied }
    }
}
