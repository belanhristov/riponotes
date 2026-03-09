import Foundation

public enum FeatureFlag: String, CaseIterable, Sendable {
    case googleSignIn
    case outlookIntegration
    case teamWorkspaces
    case aiSummary
    case mailCaptureAdvanced
    case androidSyncCompat
}

public struct FeatureFlags: Sendable {
    private let values: [FeatureFlag: Bool]

    public init(values: [FeatureFlag: Bool]) {
        self.values = values
    }

    public subscript(_ flag: FeatureFlag) -> Bool {
        values[flag] ?? false
    }

    public static let bootstrap = FeatureFlags(values: [
        .googleSignIn: false,
        .outlookIntegration: false,
        .teamWorkspaces: false,
        .aiSummary: false,
        .mailCaptureAdvanced: false,
        .androidSyncCompat: true,
    ])
}
