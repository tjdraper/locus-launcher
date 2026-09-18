import SwiftUI

struct LauncherPanelView: View {
    let appIndex: AppIndexStore
    let browse: AppBrowseTableController

    @State private var query = ""
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                TextField("Search Apps", text: $query)
                    .textFieldStyle(.plain)
                    .font(.title)
                    .focused($isSearchFocused)
            }
            .padding(20)

            Divider()

            AppBrowseView(appIndex: appIndex, controller: browse)
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
}

#Preview {
    LauncherPanelView(
        appIndex: AppIndexStore(),
        browse: AppBrowseTableController(icons: AppIconCache()) { _ in
            // Previews don't launch apps.
        }
    )
        .frame(width: LauncherPanel.size.width, height: LauncherPanel.size.height)
}
