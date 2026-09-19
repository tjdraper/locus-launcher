import Foundation
import Observation

/// Keeps the hot keys and hidden apps marked "Sync to other Macs" the same on every Mac signed in
/// to the same iCloud account.
final class ICloudSyncCoordinator {
    private let appShortcuts: AppShortcutStore
    private let hiddenApps: HiddenAppsStore
    private static let accountDefaultsKey = "ICloudSyncAccount"
    private let cloudStore = NSUbiquitousKeyValueStore.default
    private let shortcutEntries = ICloudEntryStore<AppShortcutList.Entry>(
        keyPrefix: "AppShortcut.",
        baseDefaultsKey: "AppShortcutsSyncBase"
    )
    private let hiddenAppEntries = ICloudEntryStore<HiddenAppList.Entry>(
        keyPrefix: "HiddenApp.",
        baseDefaultsKey: "HiddenAppsSyncBase"
    )

    init(appShortcuts: AppShortcutStore, hiddenApps: HiddenAppsStore) {
        self.appShortcuts = appShortcuts
        self.hiddenApps = hiddenApps
    }

    func start() {
        let reasons = NotificationCenter.default
            .notifications(named: NSUbiquitousKeyValueStore.didChangeExternallyNotification)
            .map { $0.userInfo?[NSUbiquitousKeyValueStoreChangeReasonKey] as? Int }
        forgetBasesIfAccountChanged()
        cloudStore.synchronize()
        Task { [appShortcuts] in
            for await _ in Observations({ appShortcuts.list }) {
                syncAppShortcuts()
            }
        }
        Task { [hiddenApps] in
            for await _ in Observations({ hiddenApps.list }) {
                syncHiddenApps()
            }
        }
        Task {
            for await reason in reasons {
                cloudStoreDidChange(reason: reason)
            }
        }
    }

    private func cloudStoreDidChange(reason: Int?) {
        switch reason {
        case NSUbiquitousKeyValueStoreInitialSyncChange:
            // Writes made before the first download were thrown away, so what this Mac last
            // agreed on no longer holds.
            forgetBases()
        case NSUbiquitousKeyValueStoreAccountChange:
            forgetBasesIfAccountChanged()
        default:
            break
        }
        syncAppShortcuts()
        syncHiddenApps()
    }

    /// The account can change while the app isn't running, and then no notification says so. The
    /// store would hold another account's entries, and comparing them with what this Mac agreed
    /// with the old account would delete every synced entry here. Signing out counts as a change
    /// too.
    private func forgetBasesIfAccountChanged() {
        let token = FileManager.default.ubiquityIdentityToken
            .flatMap { try? NSKeyedArchiver.archivedData(withRootObject: $0, requiringSecureCoding: true) }
        guard token != UserDefaults.standard.data(forKey: Self.accountDefaultsKey) else { return }
        forgetBases()
        UserDefaults.standard.set(token, forKey: Self.accountDefaultsKey)
    }

    private func forgetBases() {
        shortcutEntries.forgetBase()
        hiddenAppEntries.forgetBase()
    }

    private func syncAppShortcuts() {
        let entries = shortcutEntries.sync(appShortcuts.list.entries, with: cloudStore)
        if entries != appShortcuts.list.entries {
            appShortcuts.replaceEntries(entries)
        }
    }

    private func syncHiddenApps() {
        let entries = hiddenAppEntries.sync(hiddenApps.list.entries, with: cloudStore)
        if entries != hiddenApps.list.entries {
            hiddenApps.replaceEntries(entries)
        }
    }
}
