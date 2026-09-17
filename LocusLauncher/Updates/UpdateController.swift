import Sparkle
import SwiftUI

/// Owns the Sparkle updater and mirrors its readiness so the menu item can disable itself
/// while a check is already running.
@Observable
final class UpdateController {
    private let menuBarFocus: MenuBarUpdateFocus
    private let updaterController: SPUStandardUpdaterController
    private var readinessObservation: NSKeyValueObservation?

    private(set) var canCheckForUpdates = false

    init() {
        let focus = MenuBarUpdateFocus()
        menuBarFocus = focus
        updaterController = SPUStandardUpdaterController(
            startingUpdater: false,
            updaterDelegate: nil,
            userDriverDelegate: focus
        )
        readinessObservation = updaterController.updater.observe(
            \.canCheckForUpdates,
            options: [.initial, .new]
        ) { [weak self] updater, _ in
            // Sparkle mutates this on the main thread, so the observer fires there too.
            MainActor.assumeIsolated {
                self?.canCheckForUpdates = updater.canCheckForUpdates
            }
        }
    }

    func start() {
        updaterController.startUpdater()
    }

    func checkForUpdates() {
        updaterController.checkForUpdates(nil)
    }
}

/// Without a Dock icon there is nothing to bring the app forward, so Sparkle's windows would
/// open behind whatever the user is working in.
private final class MenuBarUpdateFocus: NSObject, SPUStandardUserDriverDelegate {
    nonisolated func standardUserDriverWillShowModalAlert() {
        activate()
    }

    nonisolated func standardUserDriverWillHandleShowingUpdate(
        _: Bool,
        forUpdate _: SUAppcastItem,
        state _: SPUUserUpdateState
    ) {
        activate()
    }

    // Sparkle calls its user driver delegate on the main thread.
    private nonisolated func activate() {
        MainActor.assumeIsolated {
            NSApp.activate()
        }
    }
}
