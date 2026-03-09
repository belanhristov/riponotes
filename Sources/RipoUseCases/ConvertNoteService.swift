import Foundation
import RipoDomain

public struct ConvertNoteService: Sendable {
    private let reminderRepository: ReminderRepository
    private let reminderScheduler: ReminderScheduler

    public init(reminderRepository: ReminderRepository, reminderScheduler: ReminderScheduler) {
        self.reminderRepository = reminderRepository
        self.reminderScheduler = reminderScheduler
    }

    public func convertToReminder(
        noteId: UUID,
        triggerAt: Date,
        type: ReminderType = .reminder,
        priority: ReminderPriority = .followUp,
        repeatRule: String? = nil
    ) async throws -> Reminder {
        var reminder = Reminder(
            noteId: noteId,
            type: type,
            triggerAt: triggerAt,
            repeatRule: repeatRule,
            priority: priority,
            isEnabled: true
        )
        reminder.updatedAt = .now

        try await reminderRepository.upsert(reminder)
        try await reminderScheduler.schedule(reminder)
        return reminder
    }
}
