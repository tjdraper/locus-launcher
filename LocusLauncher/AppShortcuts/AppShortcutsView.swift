import SwiftUI

/// Every app with hot keys, including apps that are no longer on this Mac, so their hot keys can
/// be found and removed.
struct AppShortcutsView: View {
    let store: AppShortcutStore
    let appIndex: AppIndexStore
    let appIcons: AppIconCache
    let shortcutEditor: AppShortcutEditorWindowPresenter

    var body: some View {
        Group {
            if apps.isEmpty {
                ContentUnavailableView {
                    Label("No App Hot Keys", systemImage: "keyboard")
                } description: {
                    Text("To add a hot key, select an app in the launcher and press Tab, or press ⌘K.")
                }
            } else {
                Form {
                    ForEach(apps) { app in
                        AppShortcutsRow(
                            app: app,
                            installedApp: installedApps[app.id],
                            appIcons: appIcons,
                            onEdit: { shortcutEditor.show(appID: app.id, appName: app.name) },
                            onRemove: { store.removeAll(forAppID: app.id) }
                        )
                    }
                }
                .formStyle(.grouped)
            }
        }
        .frame(minWidth: 420, idealWidth: 480, maxWidth: .infinity, minHeight: 240, idealHeight: 360, maxHeight: .infinity)
    }

    private var apps: [AppWithShortcuts] {
        store.list.recordedEntriesByAppID
            .map { appID, entries in
                AppWithShortcuts(id: appID, name: installedApps[appID]?.name ?? entries[0].appName, entries: entries)
            }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    private var installedApps: [String: IndexedApp] {
        Dictionary(appIndex.apps.map { ($0.persistentID, $0) }) { first, _ in first }
    }
}

private struct AppWithShortcuts: Identifiable {
    let id: String
    let name: String
    let entries: [AppShortcutList.Entry]
}

private struct AppShortcutsRow: View {
    let app: AppWithShortcuts
    let installedApp: IndexedApp?
    let appIcons: AppIconCache
    let onEdit: () -> Void
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(nsImage: installedApp.flatMap(appIcons.cachedIcon(for:)) ?? appIcons.placeholder)
                .frame(width: AppIconCache.pointSize, height: AppIconCache.pointSize)
            VStack(alignment: .leading) {
                Text(app.name)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Text(installedApp == nil ? "Not on this Mac" : summary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            Spacer()
            Button("Edit…", action: onEdit)
            Button("Remove", action: onRemove)
        }
    }

    private var summary: String {
        app.entries.compactMap { entry in
            entry.keys.map { "\($0.symbols) \(entry.action.title)" }
        }
        .joined(separator: ", ")
    }
}
