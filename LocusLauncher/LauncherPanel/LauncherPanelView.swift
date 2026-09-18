import SwiftUI

struct LauncherPanelView: View {
    let appIndex: AppIndexStore
    @Bindable var search: AppSearchSession
    let browse: AppBrowseTableController

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
            }
            .padding(20)

            Divider()

            AppBrowseView(list: list, controller: browse)
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

    private var list: BrowseList {
        search.results(in: appIndex.apps).map(BrowseList.init(searchResults:)) ?? BrowseList(apps: appIndex.apps)
    }
}

#Preview {
    LauncherPanelView(
        appIndex: AppIndexStore(),
        search: AppSearchSession(history: LaunchHistory()),
        browse: AppBrowseTableController(icons: AppIconCache()) { _ in
            // Previews don't launch apps.
        }
    )
        .frame(width: LauncherPanel.size.width, height: LauncherPanel.size.height)
}
