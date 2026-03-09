import Foundation
import RipoDomain

public struct SocialPostDetails: Sendable, Equatable {
    public var post: SocialPost
    public var comments: [SocialComment]
    public var reactions: [SocialReaction]

    public init(post: SocialPost, comments: [SocialComment], reactions: [SocialReaction]) {
        self.post = post
        self.comments = comments
        self.reactions = reactions
    }

    public var likeCount: Int {
        reactions.filter { $0.type == .like }.count
    }

    public var dislikeCount: Int {
        reactions.filter { $0.type == .dislike }.count
    }
}

public struct SocialFeedService: Sendable {
    private let repository: SocialRepository

    public init(repository: SocialRepository) {
        self.repository = repository
    }

    @discardableResult
    public func publishPost(
        authorUserId: UUID,
        tripId: UUID? = nil,
        placeReviewId: UUID? = nil,
        text: String,
        tags: Set<String> = [],
        now: Date = .now
    ) async throws -> SocialPost {
        let post = SocialPost(
            authorUserId: authorUserId,
            tripId: tripId,
            placeReviewId: placeReviewId,
            text: text,
            tags: tags,
            createdAt: now,
            updatedAt: now
        )
        try await repository.upsertPost(post)
        return post
    }

    @discardableResult
    public func addComment(
        postId: UUID,
        authorUserId: UUID,
        text: String,
        now: Date = .now
    ) async throws -> SocialComment {
        let comment = SocialComment(postId: postId, authorUserId: authorUserId, text: text, createdAt: now)
        try await repository.upsertComment(comment)
        return comment
    }

    @discardableResult
    public func react(
        postId: UUID,
        userId: UUID,
        type: SocialReactionType,
        now: Date = .now
    ) async throws -> SocialReaction {
        let reaction = SocialReaction(postId: postId, userId: userId, type: type, createdAt: now)
        try await repository.upsertReaction(reaction)
        return reaction
    }

    public func followUser(followerUserId: UUID, followedUserId: UUID, now: Date = .now) async throws -> UserFollow {
        let follow = UserFollow(followerUserId: followerUserId, followedUserId: followedUserId, createdAt: now)
        try await repository.upsertUserFollow(follow)
        return follow
    }

    public func followTag(followerUserId: UUID, tag: String, now: Date = .now) async throws -> TagFollow {
        let follow = TagFollow(followerUserId: followerUserId, tag: tag.lowercased(), createdAt: now)
        try await repository.upsertTagFollow(follow)
        return follow
    }

    public func feedForUser(userId: UUID) async throws -> [SocialPostDetails] {
        let follows = try await repository.follows(followerUserId: userId)
        let tagFollows = try await repository.tagFollows(followerUserId: userId)

        let followedUsers = Set(follows.map(\.followedUserId))
        let followedTags = Set(tagFollows.map { $0.tag.lowercased() })

        let allPosts = try await repository.posts(authorUserId: nil)
        let visible = allPosts.filter { post in
            if followedUsers.contains(post.authorUserId) {
                return true
            }
            return post.tags.contains(where: { followedTags.contains($0.lowercased()) })
        }

        var result: [SocialPostDetails] = []
        for post in visible {
            let comments = try await repository.comments(postId: post.id)
            let reactions = try await repository.reactions(postId: post.id)
            result.append(SocialPostDetails(post: post, comments: comments, reactions: reactions))
        }
        return result.sorted(by: { $0.post.createdAt > $1.post.createdAt })
    }
}
