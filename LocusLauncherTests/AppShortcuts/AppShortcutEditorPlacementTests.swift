import CoreGraphics
import Testing

struct AppShortcutEditorPlacementTests {
    private let screen = CGRect(x: 0, y: 0, width: 1440, height: 875)
    private let editorSize = CGSize(width: 400, height: 300)

    @Test
    func dropsFromTheTopOfTheAnchorCenteredAcrossIt() {
        // Arrange
        let placement = AppShortcutEditorPlacement(
            anchor: CGRect(x: 400, y: 200, width: 600, height: 500),
            visibleScreenFrame: screen
        )

        // Act
        let origin = placement.origin(for: editorSize)

        // Assert
        #expect(origin == CGPoint(x: 500, y: 400))
    }

    @Test
    func stepsAsideWhenAnEditorIsAlreadyOpenWhereItWouldGo() {
        // Arrange
        let placement = AppShortcutEditorPlacement(
            anchor: CGRect(x: 400, y: 200, width: 600, height: 500),
            visibleScreenFrame: screen
        )

        // Act
        let origin = placement.origin(for: editorSize, avoiding: [
            CGRect(origin: CGPoint(x: 500, y: 400), size: editorSize),
            // A shorter editor whose top-left corner is where the first step would land.
            CGRect(x: 524, y: 476, width: 560, height: 200),
        ])

        // Assert
        #expect(origin == CGPoint(x: 548, y: 352))
    }

    @Test
    func staysOnScreenWhenTheAnchorIsNearAnEdge() {
        // Arrange
        let placement = AppShortcutEditorPlacement(
            anchor: CGRect(x: -100, y: 0, width: 200, height: 100),
            visibleScreenFrame: screen
        )

        // Act
        let origin = placement.origin(for: editorSize)

        // Assert
        #expect(origin == CGPoint(x: 0, y: 0))
    }

    @Test
    func keepsTheTitleBarAndLeadingEdgeVisibleWhenTallerAndWiderThanTheScreen() {
        // Arrange
        let placement = AppShortcutEditorPlacement(
            anchor: CGRect(x: 100, y: 100, width: 200, height: 200),
            visibleScreenFrame: CGRect(x: 0, y: 0, width: 300, height: 250)
        )

        // Act
        let origin = placement.origin(for: editorSize)

        // Assert
        #expect(origin == CGPoint(x: 0, y: -50))
    }
}
