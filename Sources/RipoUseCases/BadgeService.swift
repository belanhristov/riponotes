import Foundation
import RipoDomain

public struct BadgeService: Sendable {
    private let tripRepository: TripRepository
    private let socialRepository: SocialRepository
    private let badgeRepository: UserBadgeRepository

    public init(
        tripRepository: TripRepository,
        socialRepository: SocialRepository,
        badgeRepository: UserBadgeRepository
    ) {
        self.tripRepository = tripRepository
        self.socialRepository = socialRepository
        self.badgeRepository = badgeRepository
    }

    @discardableResult
    public func awardEligibleBadges(userId: UUID, now: Date = .now) async throws -> [UserBadge] {
        let existing = try await badgeRepository.badges(userId: userId)
        let existingTypes = Set(existing.map(\.type))

        var awarded: [UserBadge] = []
        for definition in try await eligibleBadgeDefinitions(userId: userId) where !existingTypes.contains(definition.type) {
            let badge = UserBadge(
                userId: userId,
                type: definition.type,
                title: definition.title,
                description: definition.description,
                awardedAt: now
            )
            try await badgeRepository.upsert(badge)
            awarded.append(badge)
        }
        return awarded
    }

    private func eligibleBadgeDefinitions(userId: UUID) async throws -> [(type: UserBadgeType, title: String, description: String)] {
        var out: [(UserBadgeType, String, String)] = []

        let trips = try await tripRepository.trips(ownerUserId: userId)
        let distinctCountries = Set(trips.map { $0.destination.lowercased() })
        if !trips.isEmpty {
            out.append((.rookieTraveler, "Gezgin Başlangıç", "İlk seyahat planını oluşturdun."))
        }
        if distinctCountries.count >= 3 {
            out.append((.countryCollector, "Ülke Koleksiyoncusu", "3 farklı destinasyon planladın."))
        }

        let posts = try await socialRepository.posts(authorUserId: userId)
        if posts.count >= 5 {
            out.append((.storyteller, "Hikaye Anlatıcısı", "5+ paylaşım yaptın."))
        }

        var receivedComments = 0
        for post in posts {
            receivedComments += try await socialRepository.comments(postId: post.id).count
        }
        if receivedComments >= 10 {
            out.append((.crowdFavorite, "Topluluk Favorisi", "Paylaşımlarına 10+ yorum geldi."))
        }

        return out
    }
}
