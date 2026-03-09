import Foundation
import RipoDomain

public enum UserProfileServiceError: Error, Equatable {
    case emptyUsername
    case usernameTooShort
    case usernameTaken
}

public struct UserProfileService: Sendable {
    private let profileRepository: UserProfileRepository

    public init(profileRepository: UserProfileRepository) {
        self.profileRepository = profileRepository
    }

    @discardableResult
    public func upsertProfile(
        userId: UUID,
        username: String,
        avatarPath: String?,
        bio: String? = nil,
        now: Date = .now
    ) async throws -> UserProfile {
        let normalized = try normalizedUsername(username)
        if let existing = try await profileRepository.profile(username: normalized),
           existing.userId != userId
        {
            throw UserProfileServiceError.usernameTaken
        }

        var profile = try await profileRepository.profile(userId: userId)
            ?? UserProfile(userId: userId, username: normalized, avatarPath: avatarPath, bio: bio, createdAt: now, updatedAt: now)
        profile.username = normalized
        profile.avatarPath = avatarPath
        profile.bio = bio
        profile.updatedAt = now

        try await profileRepository.upsert(profile)
        return profile
    }

    private func normalizedUsername(_ value: String) throws -> String {
        let cleaned = value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !cleaned.isEmpty else { throw UserProfileServiceError.emptyUsername }
        guard cleaned.count >= 3 else { throw UserProfileServiceError.usernameTooShort }
        return cleaned
    }
}
