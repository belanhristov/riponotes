import Foundation
import RipoDomain

public enum JourneyServiceError: Error {
    case tripNotFound
    case invalidPlaceReviewRating
}

public struct JourneyService: Sendable {
    private let tripRepository: TripRepository
    private let journeyRepository: JourneyRepository

    public init(tripRepository: TripRepository, journeyRepository: JourneyRepository) {
        self.tripRepository = tripRepository
        self.journeyRepository = journeyRepository
    }

    @discardableResult
    public func addJourneyEntry(
        tripId: UUID,
        noteId: UUID? = nil,
        title: String,
        body: String,
        moodTag: String? = nil,
        tags: Set<String> = [],
        now: Date = .now
    ) async throws -> JourneyEntry {
        guard try await tripRepository.trip(by: tripId) != nil else {
            throw JourneyServiceError.tripNotFound
        }

        let entry = JourneyEntry(
            tripId: tripId,
            noteId: noteId,
            title: title,
            body: body,
            moodTag: moodTag,
            tags: tags,
            createdAt: now,
            updatedAt: now
        )
        try await journeyRepository.upsertEntry(entry)
        return entry
    }

    @discardableResult
    public func addPlaceReview(
        tripId: UUID,
        journeyEntryId: UUID? = nil,
        placeName: String,
        latitude: Double,
        longitude: Double,
        locationTag: String,
        rating: Int,
        comment: String,
        tags: Set<String> = [],
        now: Date = .now
    ) async throws -> PlaceReview {
        guard try await tripRepository.trip(by: tripId) != nil else {
            throw JourneyServiceError.tripNotFound
        }
        guard (1...5).contains(rating) else {
            throw JourneyServiceError.invalidPlaceReviewRating
        }

        let review = PlaceReview(
            tripId: tripId,
            journeyEntryId: journeyEntryId,
            placeName: placeName,
            latitude: latitude,
            longitude: longitude,
            locationTag: locationTag.lowercased(),
            rating: rating,
            comment: comment,
            tags: tags,
            createdAt: now,
            updatedAt: now
        )
        try await journeyRepository.upsertPlaceReview(review)
        return review
    }

    public func placeReviewsByLocationTag(_ locationTag: String) async throws -> [PlaceReview] {
        try await journeyRepository.placeReviews(locationTag: locationTag)
    }
}
