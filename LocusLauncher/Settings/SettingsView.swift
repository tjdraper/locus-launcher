import KeyboardShortcuts
import SwiftUI

struct SettingsView: View {
    var body: some View {
        Form {
            LabeledContent("Launcher shortcut") {
                Text(KeyboardShortcuts.Name.toggleLauncher.shortcut?.description ?? "None")
            }
        }
        .formStyle(.grouped)
        .frame(width: 420)
        .fixedSize()
    }
}

#Preview {
    SettingsView()
}
