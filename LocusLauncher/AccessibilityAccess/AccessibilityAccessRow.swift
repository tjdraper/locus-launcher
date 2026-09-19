import SwiftUI

struct AccessibilityAccessRow: View {
    let store: AccessibilityAccessStore

    var body: some View {
        LabeledContent {
            if store.isGranted {
                Label {
                    Text("Allowed")
                        .foregroundStyle(.secondary)
                } icon: {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }
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
