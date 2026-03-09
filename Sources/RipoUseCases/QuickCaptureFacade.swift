import Foundation
import RipoDomain

public struct QuickCaptureFacade: Sendable {
    private let quickNoteEngine: QuickNoteEngine

    public init(quickNoteEngine: QuickNoteEngine) {
        self.quickNoteEngine = quickNoteEngine
    }

    public func createWidgetQuickNote(
        ownerUserId: UUID,
        text: String,
        lastFolderId: UUID? = nil
    ) async throws -> Note {
        try validate(text: text)
        return try await quickNoteEngine.createNote(
            QuickNoteInput(
                ownerUserId: ownerUserId,
                text: text,
                source: .widget,
                folderId: lastFolderId
            )
        )
    }

    public func createNoteFromIntent(
        ownerUserId: UUID,
        text: String,
        targetFolderId: UUID? = nil
    ) async throws -> Note {
        try validate(text: text)
        return try await quickNoteEngine.createNote(
            QuickNoteInput(
                ownerUserId: ownerUserId,
                text: text,
                source: .siri,
                folderId: targetFolderId
            )
        )
    }

    public func createMeetingNoteFromIntent(
        ownerUserId: UUID,
        title: String,
        participantNames: [String],
        targetFolderId: UUID? = nil
    ) async throws -> Note {
        let normalizedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedTitle.isEmpty else {
            throw QuickCaptureError.emptyText
        }

        let participants = participantNames
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .map { "- \($0)" }
            .joined(separator: "\n")

        let participantSection = participants.isEmpty ? "-" : participants
        let templateBody = """
        \(normalizedTitle)

        Participants:
        \(participantSection)

        Agenda:
        -

        Notes:
        """

        return try await quickNoteEngine.createNote(
            QuickNoteInput(
                ownerUserId: ownerUserId,
                text: templateBody,
                source: .siri,
                folderId: targetFolderId
            )
        )
    }

    private func validate(text: String) throws {
        if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw QuickCaptureError.emptyText
        }
    }
}

public enum QuickCaptureError: Error {
    case emptyText
}
