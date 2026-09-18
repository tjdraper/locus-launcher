import SwiftUI

struct HiddenAppsView: View {
    let store: HiddenAppsStore
    let appIndex: AppIndexStore
    let appIcons: AppIconCache

    var body: some View {
        Group {
            if store.list.entries.isEmpty {
                ContentUnavailableView {
                    Label("No Hidden Apps", systemImage: "eye.slash")
                } description: {
                    Text("To hide an app, select it in the launcher and press Tab, or press ⌘⌥⌫.")
                }
            } else {
                Form {
                    ForEach(entries) { entry in
                        HiddenAppRow(
                            entry: entry,
                            installedApp: installedApps[entry.id],
                            appIcons: appIcons,
                            store: store
                        )
                    }
                }
                .formStyle(.grouped)
            }
        }
        .frame(minWidth: 420, idealWidth: 480, maxWidth: .infinity, minHeight: 240, idealHeight: 360, maxHeight: .infinity)
    }

    private var entries: [HiddenAppList.Entry] {
        store.list.entries.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    private var installedApps: [String: IndexedApp] {
        Dictionary(appIndex.apps.map { (HiddenAppList.id(of: $0), $0) }) { first, _ in first }
    }
}

private struct HiddenAppRow: View {
    let entry: HiddenAppList.Entry
    let installedApp: IndexedApp?
    let appIcons: AppIconCache
    let store: HiddenAppsStore

    var body: some View {
        HStack(spacing: 12) {
            Image(nsImage: installedApp.flatMap(appIcons.cachedIcon(for:)) ?? appIcons.placeholder)
                .frame(width: AppIconCache.pointSize, height: AppIconCache.pointSize)
            VStack(alignment: .leading) {
                Text(installedApp?.name ?? entry.name)
                    .lineLimit(1)
                    .truncationMode(.tail)
                if installedApp == nil {
                    Text("Not on this Mac")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Toggle("Sync to other Macs", isOn: Binding(
                get: { entry.syncsToOtherMacs },
                set: { store.setSyncsToOtherMacs($0, for: entry.id) }
            ))
            .toggleStyle(.checkbox)
            .fixedSize()
            .disabled(!entry.canSync)
            .help(entry.canSync ? "" : "This app has no bundle identifier, so other Macs can’t recognize it.")
            Button("Unhide") {
                store.unhide(entry.id)
            }
        }
    }
}
