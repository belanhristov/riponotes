import Foundation
import RipoDomain

public enum TaggingServiceError: Error {
    case noteNotFound
    case attachmentNotFound
    case tripNotFound
    case emptyTag
}

public struct TaggingService: Sendable {
    private let noteRepository: NoteRepository
    private let attachmentRepository: AttachmentRepository
    private let tripRepository: TripRepository

    public init(
        noteRepository: NoteRepository,
        attachmentRepository: AttachmentRepository,
        tripRepository: TripRepository
    ) {
        self.noteRepository = noteRepository
        self.attachmentRepository = attachmentRepository
        self.tripRepository = tripRepository
    }

    public func addTagToNote(noteId: UUID, rawTag: String, now: Date = .now) async throws -> Note {
        let normalized = try normalizedTag(rawTag)
        guard var note = try await noteRepository.note(by: noteId) else {
            throw TaggingServiceError.noteNotFound
        }
        note.tags.insert(normalized)
        note.updatedAt = now
        note.syncState = .pending
        note.version += 1
        try await noteRepository.update(note)
        return note
    }

    public func removeTagFromNote(noteId: UUID, rawTag: String, now: Date = .now) async throws -> Note {
        let normalized = try normalizedTag(rawTag)
        guard var note = try await noteRepository.note(by: noteId) else {
            throw TaggingServiceError.noteNotFound
        }
        note.tags.remove(normalized)
        note.updatedAt = now
        note.syncState = .pending
        note.version += 1
        try await noteRepository.update(note)
        return note
    }

    public func addTagToAttachment(attachmentId: UUID, rawTag: String, now: Date = .now) async throws -> Attachment {
        let normalized = try normalizedTag(rawTag)
        guard var attachment = try await attachmentRepository.attachment(by: attachmentId) else {
            throw TaggingServiceError.attachmentNotFound
        }
        attachment.tags.insert(normalized)
        attachment.updatedAt = now
        try await attachmentRepository.upsert(attachment)
        return attachment
    }

    public func removeTagFromAttachment(attachmentId: UUID, rawTag: String, now: Date = .now) async throws -> Attachment {
        let normalized = try normalizedTag(rawTag)
        guard var attachment = try await attachmentRepository.attachment(by: attachmentId) else {
            throw TaggingServiceError.attachmentNotFound
        }
        attachment.tags.remove(normalized)
        attachment.updatedAt = now
        try await attachmentRepository.upsert(attachment)
        return attachment
    }

    public func addTagToTrip(tripId: UUID, rawTag: String, now: Date = .now) async throws -> Trip {
        let normalized = try normalizedTag(rawTag)
        guard var trip = try await tripRepository.trip(by: tripId) else {
            throw TaggingServiceError.tripNotFound
        }
        trip.tags.insert(normalized)
        trip.updatedAt = now
        try await tripRepository.upsertTrip(trip)
        return trip
    }

    public func removeTagFromTrip(tripId: UUID, rawTag: String, now: Date = .now) async throws -> Trip {
        let normalized = try normalizedTag(rawTag)
        guard var trip = try await tripRepository.trip(by: tripId) else {
            throw TaggingServiceError.tripNotFound
        }
        trip.tags.remove(normalized)
        trip.updatedAt = now
        try await tripRepository.upsertTrip(trip)
        return trip
    }

    public func tagCloud(ownerUserId: UUID) async throws -> [TagCloudItem] {
        var counts: [String: Int] = [:]

        let notes = try await noteRepository.activeNotes(ownerUserId: ownerUserId)
        for note in notes {
            for tag in note.tags {
                counts[tag, default: 0] += 1
            }
        }

        let noteIds = Set(notes.map(\.id))
        let trips = try await tripRepository.trips(ownerUserId: ownerUserId)
        let tripIds = Set(trips.map(\.id))
        for trip in trips {
            for tag in trip.tags {
                counts[tag, default: 0] += 1
            }
        }

        let attachments = try await attachmentRepository.allAttachments()
        for attachment in attachments {
            let isOwned: Bool
            switch attachment.ownerType {
            case .note:
                isOwned = noteIds.contains(attachment.ownerId)
            case .trip:
                isOwned = tripIds.contains(attachment.ownerId)
            case .template:
                isOwned = false
            }

            if isOwned {
                for tag in attachment.tags {
                    counts[tag, default: 0] += 1
                }
            }
        }

        return counts
            .map { TagCloudItem(tag: $0.key, count: $0.value) }
            .sorted {
                if $0.count == $1.count {
                    return $0.tag < $1.tag
                }
                return $0.count > $1.count
            }
    }

    public func normalizeMany(_ raw: String) -> [String] {
        raw
            .split { $0 == "," || $0 == "#" || $0 == " " || $0 == "\n" || $0 == "\t" }
            .map { String($0) }
            .compactMap { try? normalizedTag($0) }
            .reduce(into: [String]()) { partial, tag in
                if !partial.contains(tag) {
                    partial.append(tag)
                }
            }
    }

    private func normalizedTag(_ value: String) throws -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty else {
            throw TaggingServiceError.emptyTag
        }
        return trimmed
    }
}
