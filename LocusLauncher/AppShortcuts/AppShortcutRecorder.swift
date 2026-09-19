import KeyboardShortcuts
import SwiftUI

/// The package's recorder, wrapped here rather than through its SwiftUI `Recorder`, which gives no
/// way to start recording without a click.
struct AppShortcutRecorder: NSViewRepresentable {
    let shortcut: KeyboardShortcuts.Shortcut?
    /// Starts recording as soon as the recorder is in its window.
    let recordsOnAppear: Bool
    let onChange: (KeyboardShortcuts.Shortcut?) -> Void

    final class Coordinator {
        var onChange: (KeyboardShortcuts.Shortcut?) -> Void

        init(onChange: @escaping (KeyboardShortcuts.Shortcut?) -> Void) {
            self.onChange = onChange
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onChange: onChange)
    }

    func makeNSView(context: Context) -> KeyboardShortcuts.RecorderCocoa {
        let coordinator = context.coordinator
        let recorder = KeyboardShortcuts.RecorderCocoa(shortcut: shortcut) { shortcut in
            coordinator.onChange(shortcut)
        }
        // The only menu is this app's own, which exists while this window is open. AppKit fills it
        // with items like Emoji & Symbols, and a global hotkey fires before any menu sees the keys,
        // so those are never real conflicts. System shortcuts are flagged under the row instead of
        // in an alert.
        recorder.conflictPolicy = .init(menuItem: .allow, systemShortcut: .allow)
        if recordsOnAppear {
            // SwiftUI puts the view in its window after this returns.
            DispatchQueue.main.async { [weak recorder] in
                recorder?.window?.makeFirstResponder(recorder)
            }
        }
        return recorder
    }

    func updateNSView(_ recorder: KeyboardShortcuts.RecorderCocoa, context: Context) {
        context.coordinator.onChange = onChange
        recorder.shortcut = shortcut
    }
}
