import Foundation
import RipoDomain

public enum SocialPlatform: String, Codable, Sendable, Equatable {
    case x
    case instagram
}

public struct SocialSharePayload: Sendable, Equatable {
    public var platform: SocialPlatform
    public var message: String
    public var hashtags: [String]
    public var shareURL: String?

    public init(platform: SocialPlatform, message: String, hashtags: [String], shareURL: String?) {
        self.platform = platform
        self.message = message
        self.hashtags = hashtags
        self.shareURL = shareURL
    }
}

public struct SocialShareService: Sendable {
    public init() {}

    public func buildTravelImageShare(
        platform: SocialPlatform,
        trip: Trip,
        imagePath: String,
        tags: Set<String>
    ) -> SocialSharePayload {
        let cleaned = tags
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
            .filter { !$0.isEmpty }
            .sorted()
        let hashtags = cleaned.map { "#\($0.replacingOccurrences(of: " ", with: ""))" }

        let baseMessage = "Trip: \(trip.title) • \(trip.origin) -> \(trip.destination)\nImage: \(imagePath)"
        let fullMessage = hashtags.isEmpty ? baseMessage : "\(baseMessage)\n\(hashtags.joined(separator: " "))"

        switch platform {
        case .x:
            let encoded = fullMessage.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
            let url = encoded.map { "https://twitter.com/intent/tweet?text=\($0)" }
            return SocialSharePayload(
                platform: .x,
                message: fullMessage,
                hashtags: hashtags,
                shareURL: url
            )
        case .instagram:
            return SocialSharePayload(
                platform: .instagram,
                message: fullMessage,
                hashtags: hashtags,
                shareURL: "instagram://camera"
            )
        }
    }
}
