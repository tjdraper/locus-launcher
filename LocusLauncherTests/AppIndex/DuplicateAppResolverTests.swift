import Foundation
import Testing

struct DuplicateAppResolverTests {
    private let resolver = DuplicateAppResolver(policy: AppLocationPolicy(homeDirectory: "/Users/test"))

    @Test
    func keepsTheCopyInApplications() {
        // Arrange
        let stray = app("/Users/test/Desktop/Tool.app", bundleIdentifier: "com.example.tool")
        let installed = app("/Applications/Tool.app", bundleIdentifier: "com.example.tool")

        // Act
        let resolved = resolver.resolve([stray, installed])

        // Assert
        #expect(resolved == [installed])
    }

    @Test
    func matchesBundleIdentifiersIgnoringCase() {
        // Arrange
        let installed = app("/Applications/Tool.app", bundleIdentifier: "com.example.Tool")
        let stray = app("/Volumes/External/Tool.app", bundleIdentifier: "com.example.tool")

        // Act
        let resolved = resolver.resolve([installed, stray])

        // Assert
        #expect(resolved == [installed])
    }

    @Test
    func prefersTheShorterPathWithinTheSameFolder() {
        // Arrange
        let nested = app("/Applications/Tools/Old/Tool.app", bundleIdentifier: "com.example.tool")
        let topLevel = app("/Applications/Tool.app", bundleIdentifier: "com.example.tool")

        // Act
        let resolved = resolver.resolve([nested, topLevel])

        // Assert
        #expect(resolved == [topLevel])
    }

    @Test
    func keepsEveryAppWithoutABundleIdentifier() {
        // Arrange
        let first = app("/Applications/Script.app", bundleIdentifier: nil)
        let second = app("/Users/test/Scripts/Script.app", bundleIdentifier: nil)

        // Act
        let resolved = resolver.resolve([first, second])

        // Assert
        #expect(Set(resolved) == [first, second])
    }

    @Test
    func keepsDifferentAppsWithTheSameName() {
        // Arrange
        let mac = app("/System/Applications/Utilities/Terminal.app", bundleIdentifier: "com.apple.Terminal")
        let windows = app("/Users/test/Applications (Parallels)/Terminal.app", bundleIdentifier: "com.parallels.winapp.terminal")

        // Act
        let resolved = resolver.resolve([mac, windows])

        // Assert
        #expect(Set(resolved) == [mac, windows])
    }

    private func app(_ path: String, bundleIdentifier: String?) -> IndexedApp {
        IndexedApp(
            url: URL(fileURLWithPath: path),
            name: URL(fileURLWithPath: path).deletingPathExtension().lastPathComponent,
            bundleIdentifier: bundleIdentifier
        )
    }
}
