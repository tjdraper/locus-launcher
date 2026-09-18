import Sparkle
import SwiftUI

/// Keeps an update found by a scheduled check out of the user's way. Instead of Sparkle's window
/// jumping to the front, the update waits behind a quiet sign in the menu and the launcher panel
/// until the user asks to see it. https://sparkle-project.org/documentation/gentle-reminders
///
/// Without a Dock icon there is nothing to bring the app forward, so Sparkle's windows would
/// otherwise open behind whatever the user is working in.
@Observable
final class UpdateReminder: NSObject, SPUStandardUserDriverDelegate {
    private(set) var waitingVersion: String?

    nonisolated var supportsGentleScheduledUpdateReminders: Bool {
        true
    }

    /// Sparkle proposes showing the update right away shortly after launch, but for an app that
    /// opens at login that's an arbitrary moment too, so the sign handles every scheduled update.
    nonisolated func standardUserDriverShouldHandleShowingScheduledUpdate(
        _: SUAppcastItem,
        andInImmediateFocus _: Bool
    ) -> Bool {
        false
    }

    nonisolated func standardUserDriverWillHandleShowingUpdate(
        _ handleShowingUpdate: Bool,
        forUpdate update: SUAppcastItem,
        state _: SPUUserUpdateState
    ) {
        let version = update.displayVersionString
        onMain {
            if handleShowingUpdate {
                AppActivation.bringToFront()
            } else {
                waitingVersion = version
            }
        }
    }

    nonisolated func standardUserDriverDidReceiveUserAttention(forUpdate _: SUAppcastItem) {
        onMain {
            waitingVersion = nil
        }
    }

    nonisolated func standardUserDriverWillFinishUpdateSession() {
        onMain {
            waitingVersion = nil
        }
    }

    nonisolated func standardUserDriverWillShowModalAlert() {
        onMain {
            AppActivation.bringToFront()
        }
    }

    // Sparkle calls its user driver delegate on the main thread.
    private nonisolated func onMain(_ body: @MainActor () -> Void) {
        MainActor.assumeIsolated(body)
    }
}
