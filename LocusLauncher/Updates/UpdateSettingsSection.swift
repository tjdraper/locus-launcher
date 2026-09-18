import SwiftUI

struct UpdateSettingsSection: View {
    @Bindable var updates: UpdateController

    var body: some View {
        Section("Updates") {
            Toggle("Check for updates automatically", isOn: $updates.automaticallyChecksForUpdates)
            Toggle(isOn: $updates.receivesBetaUpdates) {
                Text("Get beta updates")
                Text("Betas arrive more often and may break things.")
            }
        }
    }
}
