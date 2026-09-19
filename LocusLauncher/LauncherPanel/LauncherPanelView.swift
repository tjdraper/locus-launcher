import SwiftUI

struct LauncherPanelView: View {
    let appIndex: AppIndexStore
    let hiddenApps: HiddenAppsStore
    let appShortcuts: AppShortcutStore
    @Bindable var search: AppSearchSession
    let browse: AppBrowseTableController
    let updates: UpdateController
    let onShowUpdate: () -> Void

    @FocusState private var isSearchFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                TextField("Search Apps", text: $search.query)
                    .textFieldStyle(.plain)
                    .font(.title)
                    .focused($isSearchFocused)
                if let version = updates.waitingUpdateVersion {
                    Button("Update", systemImage: "arrow.down.circle", action: onShowUpdate)
                        .buttonStyle(.glass)
                        .help("Locus Launcher \(version) is ready to install")
                }
            }
            .padding(20)

            Divider()

            AppBrowseView(list: list, shortcutLabels: shortcutLabels, controller: browse)
                .overlay {
                    if list.rows.isEmpty, !search.query.isEmpty {
                        Text("No Matching Apps")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .glassEffect(.regular, in: .rect(cornerRadius: LauncherPanel.cornerRadius))
        .onAppear {
            // SwiftUI ignores a focus change made in the same pass the view appears in.
            DispatchQueue.main.async {
                isSearchFocused = true
            }
        }
    }

    private var shortcutLabels: [String: String] {
        AppShortcutRowLabels.make(from: appShortcuts.list, installedAppIDs: Set(appIndex.apps.map(\.persistentID)))
    }

    private var list: BrowseList {
        let apps = hiddenApps.list.visibleApps(in: appIndex.apps)
        return search.results(in: apps).map(BrowseList.init(searchResults:)) ?? BrowseList(apps: apps)
    }
}

#Preview {
    LauncherPanelView(
        appIndex: AppIndexStore(),
        hiddenApps: HiddenAppsStore(),
        appShortcuts: AppShortcutStore(),
        search: AppSearchSession(history: LaunchHistory()),
        browse: AppBrowseTableController(icons: AppIconCache()) { _, _ in
            // Previews don't launch apps.
        },
        updates: UpdateController()
    ) {
        // Previews don't install updates.
    }
        .frame(width: LauncherPanel.size.width, height: LauncherPanel.size.height)
}
