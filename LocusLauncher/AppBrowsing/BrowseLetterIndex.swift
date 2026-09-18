import SwiftUI

/// The A–Z strip on the right. Clicking a letter or dragging along the strip jumps to that section.
struct BrowseLetterIndex: View {
    let sectionTitles: Set<String>
    let onSelect: (String) -> Void

    @State private var draggedTitle: String?

    var body: some View {
        GeometryReader { geometry in
            // Each letter gets an equal share of the height, so all of them fit however tall the
            // panel is.
            let letterHeight = geometry.size.height / CGFloat(BrowseList.indexTitles.count)
            VStack(spacing: 0) {
                ForEach(BrowseList.indexTitles, id: \.self) { title in
                    Text(title)
                        .font(.system(size: min(10, letterHeight * 0.85), weight: .semibold))
                        .foregroundStyle(sectionTitles.contains(title) ? .secondary : .quaternary)
                        .frame(maxWidth: .infinity)
                        .frame(height: letterHeight)
                }
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let title = title(at: value.location.y, height: geometry.size.height)
                        guard title != draggedTitle else { return }
                        draggedTitle = title
                        onSelect(title)
                    }
                    .onEnded { _ in
                        draggedTitle = nil
                    }
            )
        }
        .padding(.top, 8)
        // Clears the panel's rounded bottom corner.
        .padding(.bottom, 20)
        .frame(width: AppBrowseRowMetrics.letterIndexWidth)
    }

    private func title(at y: CGFloat, height: CGFloat) -> String {
        let titles = BrowseList.indexTitles
        let position = Int(y / height * CGFloat(titles.count))
        return titles[min(max(position, 0), titles.count - 1)]
    }
}
