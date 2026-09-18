import Foundation
import Testing

struct LaunchHistoryTests {
    private let safari = URL(fileURLWithPath: "/Applications/Safari.app")
    private let slack = URL(fileURLWithPath: "/Applications/Slack.app")
    private let start = Date(timeIntervalSinceReferenceDate: 0)

    @Test
    func boostsAppsLaunchedForTheSameTerm() {
        // Arrange
        var history = LaunchHistory()
        history.record(term: "saf", appURL: safari, at: start)

        // Act
        let boosts = history.boosts(for: "saf", at: start)

        // Assert
        #expect(boosts == [safari: 1])
    }

    @Test
    func boostsAppsLaunchedForLongerTermsLess() throws {
        // Arrange
        var history = LaunchHistory()
        history.record(term: "saf", appURL: safari, at: start)
        history.record(term: "s", appURL: slack, at: start)

        // Act
        let boosts = history.boosts(for: "s", at: start)

        // Assert
        #expect(try #require(boosts[slack]) > #require(boosts[safari]))
    }

    @Test
    func ignoresTermsThatDontStartWithTheQuery() {
        // Arrange
        var history = LaunchHistory()
        history.record(term: "saf", appURL: safari, at: start)

        // Act
        let boosts = history.boosts(for: "sl", at: start)

        // Assert
        #expect(boosts.isEmpty)
    }

    @Test
    func recentLaunchesOutweighOlderOnes() throws {
        // Arrange
        var history = LaunchHistory()
        history.record(term: "s", appURL: safari, at: start)
        history.record(term: "s", appURL: safari, at: start)
        let later = start.addingTimeInterval(LaunchHistory.halfLife * 2)
        history.record(term: "s", appURL: slack, at: later)

        // Act
        let boosts = history.boosts(for: "s", at: later)

        // Assert
        #expect(try #require(boosts[slack]) > #require(boosts[safari]))
    }

    @Test
    func forgetsLaunchesThatHaveFadedAway() {
        // Arrange
        var history = LaunchHistory()
        history.record(term: "saf", appURL: safari, at: start)
        let later = start.addingTimeInterval(LaunchHistory.halfLife * 5)

        // Act
        history.record(term: "sl", appURL: slack, at: later)

        // Assert
        #expect(history.entries.map(\.appURL) == [slack])
    }
}
