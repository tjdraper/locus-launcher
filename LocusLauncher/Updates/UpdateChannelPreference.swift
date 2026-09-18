import Foundation

/// Whether this Mac also receives beta releases.
nonisolated struct UpdateChannelPreference {
    static let betaChannel = "beta"

    private static let defaultsKey = "ReceiveBetaUpdates"

    var receivesBetaUpdates: Bool {
        get { UserDefaults.standard.bool(forKey: Self.defaultsKey) }
        nonmutating set { UserDefaults.standard.set(newValue, forKey: Self.defaultsKey) }
    }

    /// Sparkle always includes the default channel, so this only ever names the extras.
    var allowedChannels: Set<String> {
        receivesBetaUpdates ? [Self.betaChannel] : []
    }
}
