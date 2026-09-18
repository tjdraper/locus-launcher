import SwiftUI

struct AccessibilityAccessRow: View {
    let store: AccessibilityAccessStore

    var body: some View {
        LabeledContent {
            if store.isGranted {
                Label("Allowed", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.secondary)
            } else {
                Button("Allow…") {
                    store.requestAccess()
                }
            }
        } label: {
            Text("Accessibility access")
            Text(store.isGranted
                ? "New Window opens a new window in the app."
                : "Without it, New Window only brings the app forward.")
        }
    }
}
