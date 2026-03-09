import Foundation
import RipoDomain

public enum AttachmentServiceError: Error {
    case invalidPath
    case attachmentNotFound
}

public struct AttachmentService: Sendable {
    private let attachmentRepository: AttachmentRepository

    public init(attachmentRepository: AttachmentRepository) {
        self.attachmentRepository = attachmentRepository
    }

    @discardableResult
    public func addImageToNote(
        noteId: UUID,
        localPath: String,
        metadataJSON: String = "{}",
        now: Date = .now
    ) async throws -> Attachment {
        try validatePath(localPath)
        let attachment = Attachment(
            ownerType: .note,
            ownerId: noteId,
            type: .image,
            localPath: localPath,
            metadataJSON: metadataJSON,
            createdAt: now,
            updatedAt: now
        )
        try await attachmentRepository.upsert(attachment)
        return attachment
    }

    @discardableResult
    public func addImageToTemplate(
        templateId: UUID,
        localPath: String,
        metadataJSON: String = "{}",
        now: Date = .now
    ) async throws -> Attachment {
        try validatePath(localPath)
        let attachment = Attachment(
            ownerType: .template,
            ownerId: templateId,
            type: .image,
            localPath: localPath,
            metadataJSON: metadataJSON,
            createdAt: now,
            updatedAt: now
        )
        try await attachmentRepository.upsert(attachment)
        return attachment
    }

    @discardableResult
    public func updateMetadata(
        attachmentId: UUID,
        metadataJSON: String,
        now: Date = .now
    ) async throws -> Attachment {
        guard var attachment = try await attachmentRepository.attachment(by: attachmentId) else {
            throw AttachmentServiceError.attachmentNotFound
        }

        attachment.metadataJSON = metadataJSON
        attachment.updatedAt = now
        try await attachmentRepository.upsert(attachment)
        return attachment
    }

    public func removeAttachment(_ attachmentId: UUID) async throws {
        try await attachmentRepository.delete(attachmentId: attachmentId)
    }

    private func validatePath(_ path: String) throws {
        if path.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw AttachmentServiceError.invalidPath
        }
    }
}
