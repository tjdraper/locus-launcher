import Foundation
import Testing

struct BrowseListTests {
    @Test
    func groupsAppsUnderTheirFirstLetter() {
        // Arrange
        let apps = [app("Calendar"), app("Chess"), app("Mail")]

        // Act
        let list = BrowseList(apps: apps)

        // Assert
        #expect(list.rows == [.header("C"), .app(apps[0]), .app(apps[1]), .header("M"), .app(apps[2])])
    }

    @Test
    func putsDigitsSymbolsAndOtherScriptsInTheLastSection() {
        // Arrange
        let apps = [app("1Password"), app("Xcode"), app("[Old] Tool"), app("カレンダー")]

        // Act
        let list = BrowseList(apps: apps)

        // Assert
        #expect(list.rows == [.header("X"), .app(apps[1]), .header("#"), .app(apps[0]), .app(apps[2]), .app(apps[3])])
    }

    @Test
    func ignoresCaseAndAccents() {
        // Arrange
        let names = ["élan", "Épicerie", "iTerm"]

        // Act
        let titles = names.map(BrowseList.sectionTitle)

        // Assert
        #expect(titles == ["E", "E", "I"])
    }

    @Test
    func indexLetterWithoutAppsLandsOnTheNextSection() {
        // Arrange
        let list = BrowseList(apps: [app("Calendar"), app("Mail")])

        // Act
        let row = list.headerRow(forIndexTitle: "D")

        // Assert
        #expect(row == 2)
    }

    @Test
    func indexLetterPastTheLastSectionLandsOnTheLastSection() {
        // Arrange
        let list = BrowseList(apps: [app("Calendar"), app("Mail")])

        // Act
        let row = list.headerRow(forIndexTitle: "#")

        // Assert
        #expect(row == 2)
    }

    @Test
    func stepsBetweenAppsSkippingHeaders() {
        // Arrange
        let list = BrowseList(apps: [app("Calendar"), app("Mail")])

        // Act
        let next = list.appRow(after: 1)
        let previous = list.appRow(before: 3)

        // Assert
        #expect(next == 3)
        #expect(previous == 1)
        #expect(list.appRow(after: 3) == nil)
        #expect(list.firstAppRow == 1)
    }

    @Test
    func selectsTheAppThatTakesARemovedAppsPlace() {
        // Arrange
        let apps = [app("Calendar"), app("Chess"), app("Mail")]
        let previous = BrowseList(apps: apps)

        // Act
        let row = BrowseList(apps: [apps[0], apps[2]]).row(replacing: apps[1], removedFrom: previous)

        // Assert
        #expect(row == 3)
    }

    @Test
    func selectsTheNewLastAppWhenTheLastAppIsRemoved() {
        // Arrange
        let apps = [app("Calendar"), app("Mail")]
        let previous = BrowseList(searchResults: apps)

        // Act
        let row = BrowseList(searchResults: [apps[0]]).row(replacing: apps[1], removedFrom: previous)

        // Assert
        #expect(row == 0)
    }

    @Test
    func findsNoReplacementWhenOtherAppsChanged() {
        // Arrange
        let apps = [app("Calendar"), app("Chess"), app("Mail")]
        let previous = BrowseList(apps: apps)

        // Act
        let row = BrowseList(apps: [apps[2]]).row(replacing: apps[1], removedFrom: previous)

        // Assert
        #expect(row == nil)
    }

    private func app(_ name: String) -> IndexedApp {
        IndexedApp(url: URL(fileURLWithPath: "/Applications/\(name).app"), name: name, bundleIdentifier: nil)
    }
}
