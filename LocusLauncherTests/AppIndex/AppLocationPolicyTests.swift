import Testing

struct AppLocationPolicyTests {
    private let policy = AppLocationPolicy(homeDirectory: "/Users/test")

    @Test(arguments: [
        "/Applications/Safari.app",
        "/Applications/Utilities/Some Tool.app",
        "/System/Applications/Mail.app",
        "/System/Applications/Utilities/Terminal.app",
        "/Users/test/Applications/Edge Apps.localized/Outlook.app",
        "/System/Library/CoreServices/Applications/Archive Utility.app",
        "/System/Library/CoreServices/Finder.app",
        "/System/Volumes/Data/Applications/Safari.app",
    ])
    func includesStandardLocationsEvenOnDiskImages(path: String) {
        // Arrange
        var askedAboutDiskImage = false

        // Act
        let isIncluded = policy.isIncluded(path: path) {
            askedAboutDiskImage = true
            return true
        }

        // Assert
        #expect(isIncluded)
        #expect(!askedAboutDiskImage)
    }

    @Test(arguments: [
        "/Users/test/bin/JDownloader 2.0/JDownloader2.app",
        "/Volumes/External/Apps/Tool.app",
        "/Users/test/Applications (Parallels)/Notepad.app",
    ])
    func includesAppsElsewhereWhenNotOnDiskImage(path: String) {
        // Act
        let isIncluded = policy.isIncluded(path: path) { false }

        // Assert
        #expect(isIncluded)
    }

    @Test(arguments: [
        "/Applications/Xcode.app/Contents/Developer/Applications/Simulator.app",
        "/Users/test/Library/Developer/Xcode/Archives/App.xcarchive/Products/Applications/App.app",
        "/Volumes/Work/Sparkle.framework/Versions/B/Updater.app",
        "/Users/test/.Trash/Old.app",
        "/Volumes/External/.Trashes/501/Old.app",
        "/Users/test/Downloads/Installer.app",
        "/Users/test/Library/Application Support/Updater/Updater.app",
        "/Library/Application Support/Vendor/Helper.app",
        "/System/Library/CoreServices/Dock.app",
        "/private/var/folders/xy/AppTranslocation/ABC/d/Tool.app",
        "/Users/Shared/Previously Relocated Items 23/Incompatible/Old.app",
        "/Volumes/Backup/Backups.backupdb/Mac/Latest/Applications/Safari.app",
        "/Users/test/Documents/notes.js",
    ])
    func excludesAppsPeopleDoNotLaunchDirectly(path: String) {
        // Act
        let isIncluded = policy.isIncluded(path: path) { false }

        // Assert
        #expect(!isIncluded)
    }

    @Test
    func excludesAppsOnDiskImages() {
        // Act
        let isIncluded = policy.isIncluded(path: "/Volumes/Installer/Tool.app") { true }

        // Assert
        #expect(!isIncluded)
    }

    @Test
    func allowsFoldersWithDotsThatAreNotBundles() {
        // Act
        let isIncluded = policy.isIncluded(path: "/Users/test/bin/Tool 2.0/Tool.app") { false }

        // Assert
        #expect(isIncluded)
    }

    @Test
    func ranksStandardFoldersAheadOfEverywhereElse() {
        // Act
        let ranks = [
            "/Applications/A.app",
            "/System/Applications/A.app",
            "/Users/test/Applications/A.app",
            "/System/Library/CoreServices/Applications/A.app",
            "/System/Library/CoreServices/Finder.app",
            "/Volumes/External/A.app",
        ].map { policy.preferenceRank(path: $0) }

        // Assert
        #expect(ranks == ranks.sorted())
        #expect(Set(ranks).count == ranks.count)
    }
}
