import SwiftUI

struct LauncherPanelView: View {
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

            Spacer()
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
    LauncherPanelView()
        .frame(width: LauncherPanel.size.width, height: LauncherPanel.size.height)
}
