import AppKit
import SwiftUI

struct LauncherAppList: View {
    let apps: [IndexedApp]

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(apps) { app in
                    LauncherAppRow(app: app)
                }
            }
            .padding(.vertical, 8)
        }
    }
}

private struct LauncherAppRow: View {
    let app: IndexedApp

    var body: some View {
        HStack(spacing: 12) {
            // Built in the row so icons only load for rows that are on screen.
            Image(nsImage: NSWorkspace.shared.icon(forFile: app.url.path))
                .resizable()
                .frame(width: 32, height: 32)
            Text(app.name)
                .font(.title3)
                .lineLimit(1)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
