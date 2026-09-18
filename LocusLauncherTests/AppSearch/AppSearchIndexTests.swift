import Foundation
import Testing

struct AppSearchIndexTests {
    private let now = Date(timeIntervalSinceReferenceDate: 0)

    @Test
    func leavesOutAppsThatDontMatch() {
        // Arrange
        let index = AppSearchIndex(apps: [app("Safari"), app("Mail")])

        // Act
        let results = index.results(for: "saf", history: LaunchHistory(), at: now)

        // Assert
        #expect(results.map(\.name) == ["Safari"])
    }

    @Test
    func putsShorterNamesFirstWhenMatchesAreEqual() {
        // Arrange
        let index = AppSearchIndex(apps: [app("Mailplane"), app("Mail")])

        // Act
        let results = index.results(for: "mail", history: LaunchHistory(), at: now)

        // Assert
        #expect(results.map(\.name) == ["Mail", "Mailplane"])
    }

    @Test
    func putsAppsLaunchedForTheTermFirst() {
        // Arrange
        let terminal = app("Terminal")
        let index = AppSearchIndex(apps: [app("TextEdit"), terminal])
        var history = LaunchHistory()
        history.record(term: "te", appURL: terminal.url, at: now)

        // Act
        let results = index.results(for: "Te", history: history, at: now)

        // Assert
        #expect(results.map(\.name) == ["Terminal", "TextEdit"])
    }

    @Test
    func blankQueryHasNoResults() {
        // Arrange
        let index = AppSearchIndex(apps: [app("Safari")])

        // Act
        let results = index.results(for: "  ", history: LaunchHistory(), at: now)

        // Assert
        #expect(results.isEmpty)
    }

    private func app(_ name: String) -> IndexedApp {
        IndexedApp(url: URL(fileURLWithPath: "/Applications/\(name).app"), name: name, bundleIdentifier: nil)
    }
}
