import SwiftUI

struct LauncherPanelView: View {
    var body: some View {
        Text("Hello, world!")
            .font(.largeTitle)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .glassEffect(.regular, in: .rect(cornerRadius: LauncherPanel.cornerRadius))
    }
}

#Preview {
    LauncherPanelView()
        .frame(width: 640, height: 400)
}
