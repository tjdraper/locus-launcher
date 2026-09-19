import Foundation
import Testing

struct UpdateChannelPreferenceTests {
    private let suiteName = "UpdateChannelPreferenceTests-\(UUID().uuidString)"

    private func makeDefaults() throws -> UserDefaults {
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }

    @Test
    func aBetaGetsBetasEvenWhenTurnedOff() throws {
        // Arrange
        let preference = try UpdateChannelPreference(defaults: makeDefaults(), version: "2026.0.13")

        // Act
        preference.receivesBetaUpdates = false

        // Assert
        #expect(preference.receivesBetaUpdates)
        #expect(preference.allowedChannels == ["beta"])
    }

    @Test
    func aFullReleaseGetsBetasOnlyWhenTurnedOn() throws {
        // Arrange
        let preference = try UpdateChannelPreference(defaults: makeDefaults(), version: "2026.1")

        // Act
        let before = preference.allowedChannels
        preference.receivesBetaUpdates = true

        // Assert
        #expect(before.isEmpty)
        #expect(preference.allowedChannels == ["beta"])
    }

    @Test
    func aFullReleaseAfterABetaOwesATrackChoiceUntilAnswered() throws {
        // Arrange
        let defaults = try makeDefaults()
        UpdateChannelPreference(defaults: defaults, version: "2026.0.13").settleAtLaunch()
        let release = UpdateChannelPreference(defaults: defaults, version: "2026.1")
        release.settleAtLaunch()

        // Act
        let owedBeforeAnswering = release.owesTrackChoice
        release.chooseTrack(staysOnBetas: false)

        // Assert
        #expect(owedBeforeAnswering)
        #expect(!release.owesTrackChoice)
        #expect(!release.receivesBetaUpdates)
    }

    @Test
    func aFreshFullReleaseOwesNoTrackChoice() throws {
        // Arrange
        let preference = try UpdateChannelPreference(defaults: makeDefaults(), version: "2026.1")

        // Act
        preference.settleAtLaunch()

        // Assert
        #expect(!preference.owesTrackChoice)
    }
}
