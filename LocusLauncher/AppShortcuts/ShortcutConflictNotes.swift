import KeyboardShortcuts
import SwiftUI

/// Keys the user recorded that something in this app already uses. The recorder keeps showing
/// them, outlined in red, so the user sees what they pressed.
struct RejectedShortcut {
    let shortcut: KeyboardShortcuts.Shortcut
    let conflict: AppShortcutConflictCheck.Conflict
}

/// Says what already uses the keys, in place of an alert, and offers to move them when that's
/// safe.
struct ShortcutConflictNote: View {
    let reason: String
    let onUseHere: (() -> Void)?

    var body: some View {
        HStack {
            Text(reason)
                .font(.callout)
                .foregroundStyle(Color(nsColor: .systemRed))
            if let onUseHere {
                Button("Use Here Instead", action: onUseHere)
                    .controlSize(.small)
            }
        }
    }
}

/// Stands in for the recorder's "Use Anyway" alert.
struct SystemShortcutNote: View {
    var body: some View {
        Label("macOS also uses this shortcut, so it may not work.", systemImage: "exclamationmark.triangle.fill")
            .font(.callout)
            .symbolRenderingMode(.multicolor)
            .foregroundStyle(.secondary)
    }
}

extension View {
    func rejectedShortcutOutline(_ isShown: Bool) -> some View {
        overlay {
            if isShown {
                Capsule()
                    .strokeBorder(Color(nsColor: .systemRed), lineWidth: 2)
            }
        }
    }
}
