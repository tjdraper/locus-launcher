import AppKit
import SwiftUI

/// Every setup step on one page. Each row shows the setting's real state, so a change made in
/// System Settings shows up here too.
struct FirstRunView: View {
    @Bindable var updates: UpdateController
    let launchAtLogin: LaunchAtLoginStore
    let spotlight: SpotlightShortcutStore
    let accessibilityAccess: AccessibilityAccessStore
    let appShortcuts: AppShortcutStore
    let screenFit: ScreenFit
    let onDone: () -> Void

    var body: some View {
        Form {
            Section {
                welcome
            }

            if ApplicationsFolderMoveWorkflow.isAvailable {
                Section {
                    ApplicationsFolderRow()
                }
            }

            Section {
                LauncherShortcutRow(appShortcuts: appShortcuts, spotlight: spotlight)
                SpotlightShortcutRows(store: spotlight)
            } header: {
                Text("Launcher")
            } footer: {
                Text("Press the shortcut in any app to open the launcher.")
                    .foregroundStyle(.secondary)
            }

            Section {
                AccessibilityAccessRow(store: accessibilityAccess)
            } header: {
                Text("Permissions")
            } footer: {
                Text("""
                Optional. New Window and new-window hot keys press ⌘N in the app, which needs \
                Accessibility access. Skip it if you don’t need them, and allow it later in Settings.
                """)
                .foregroundStyle(.secondary)
            }

            Section {
                LaunchAtLoginToggle(store: launchAtLogin)
            }

            Section("Updates") {
                Toggle("Check for updates automatically", isOn: $updates.automaticallyChecksForUpdates)
            }
        }
        .formStyle(.grouped)
        .scrollBounceBehavior(.basedOnSize)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            HStack {
                Spacer()
                Button("Done", action: onDone)
                    .keyboardShortcut(.defaultAction)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .glassEffect(.regular, in: .rect)
        }
        .frame(width: 480)
        // Only as tall as the steps need, unless the screen is shorter, when the steps scroll.
        .frame(maxHeight: screenFit.maxContentHeight)
        .fixedSize()
        .task {
            refresh()
            for await _ in NotificationCenter.default.notifications(named: NSApplication.didBecomeActiveNotification) {
                refresh()
            }
        }
    }

    private var welcome: some View {
        HStack(spacing: 14) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 56, height: 56)
            VStack(alignment: .leading, spacing: 4) {
                Text("Welcome to Locus Launcher")
                    .font(.title2.bold())
                Text("Set up the launcher here. You can open this again from the menu bar or Settings.")
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 4)
    }

    private func refresh() {
        launchAtLogin.refresh()
        spotlight.refresh()
        accessibilityAccess.refresh()
    }
}

#Preview {
    FirstRunView(
        updates: UpdateController(),
        launchAtLogin: LaunchAtLoginStore(),
        spotlight: SpotlightShortcutStore(),
        accessibilityAccess: AccessibilityAccessStore(),
        appShortcuts: AppShortcutStore(),
        screenFit: ScreenFit(),
        onDone: { print("Done") }
    )
}
