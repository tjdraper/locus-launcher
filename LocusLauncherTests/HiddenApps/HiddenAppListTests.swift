import Foundation
import Testing

struct HiddenAppListTests {
    private let safari = IndexedApp(
        url: URL(fileURLWithPath: "/Applications/Safari.app"),
        name: "Safari",
        bundleIdentifier: "com.apple.Safari"
    )
    private let tool = IndexedApp(url: URL(fileURLWithPath: "/Users/test/Tool.app"), name: "Tool", bundleIdentifier: nil)

    @Test
    func dropsHiddenAppsAndKeepsTheOrder() {
        // Arrange
        let mail = IndexedApp(
            url: URL(fileURLWithPath: "/System/Applications/Mail.app"),
            name: "Mail",
            bundleIdentifier: "com.apple.mail"
        )
        var list = HiddenAppList()
        list.hide(safari)

        // Act
        let visible = list.visibleApps(in: [tool, safari, mail])

        // Assert
        #expect(visible == [tool, mail])
    }

    @Test
    func matchesAHiddenAppThatMoved() {
        // Arrange
        var list = HiddenAppList()
        list.hide(safari)
        let moved = IndexedApp(
            url: URL(fileURLWithPath: "/Users/test/Applications/Safari.app"),
            name: "Safari",
            bundleIdentifier: "com.apple.safari"
        )

        // Act
        let visible = list.visibleApps(in: [moved])

        // Assert
        #expect(visible.isEmpty)
    }

    @Test
    func syncsAppsWithABundleIdentifierByDefault() {
        // Arrange
        var list = HiddenAppList()

        // Act
        list.hide(safari)
        list.hide(tool)

        // Assert
        #expect(list.entries.map(\.syncsToOtherMacs) == [true, false])
        #expect(list.entries.map(\.canSync) == [true, false])
    }

    @Test
    func keepsAppsWithoutABundleIdentifierLocal() {
        // Arrange
        var list = HiddenAppList()
        list.hide(tool)

        // Act
        list.setSyncsToOtherMacs(true, for: HiddenAppList.id(of: tool))

        // Assert
        #expect(list.entries.first?.syncsToOtherMacs == false)
    }

    @Test
    func unhidesAnApp() {
        // Arrange
        var list = HiddenAppList()
        list.hide(safari)

        // Act
        list.unhide(HiddenAppList.id(of: safari))

        // Assert
        #expect(list.visibleApps(in: [safari]) == [safari])
    }

    @Test
    func hidesAnAppOnlyOnce() {
        // Arrange
        var list = HiddenAppList()
        list.hide(safari)
        list.setSyncsToOtherMacs(false, for: HiddenAppList.id(of: safari))

        // Act
        list.hide(safari)

        // Assert
        #expect(list.entries.count == 1)
        #expect(list.entries.first?.syncsToOtherMacs == false)
    }
}
