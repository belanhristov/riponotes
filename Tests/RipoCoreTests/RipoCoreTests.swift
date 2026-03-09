import Foundation
import Testing
@testable import RipoData
@testable import RipoDomain
@testable import RipoUseCases

struct RipoCoreTests {
    @Test
    func quickNoteDefaultsToInboxAndQueuesSyncJob() async throws {
        let repo = InMemoryNoteRepository()
        let sync = InMemorySyncEngine()
        let engine = QuickNoteEngine(noteRepository: repo, syncEngine: sync)

        let userId = UUID()
        let note = try await engine.createNote(
            QuickNoteInput(ownerUserId: userId, text: "Buy milk\n2L", source: .widget)
        )

        #expect(note.folderId == nil)
        #expect(note.title == "Buy milk")

        let inbox = try await repo.inboxNotes(ownerUserId: userId)
        #expect(inbox.count == 1)

        let jobs = try await sync.pendingJobs()
        #expect(jobs.count == 1)
        #expect(jobs.first?.entityId == note.id)
        #expect(jobs.first?.operation == .create)
    }

    @Test
    func convertNoteCreatesAndSchedulesReminder() async throws {
        let reminderRepo = InMemoryReminderRepository()
        let scheduler = InMemoryReminderScheduler()
        let convert = ConvertNoteService(reminderRepository: reminderRepo, reminderScheduler: scheduler)

        let noteId = UUID()
        let trigger = Date(timeIntervalSince1970: 2_000_000_000)
        let reminder = try await convert.convertToReminder(
            noteId: noteId,
            triggerAt: trigger,
            type: .alarm,
            priority: .critical,
            repeatRule: "FREQ=WEEKLY;BYDAY=MO"
        )

        let list = try await reminderRepo.reminders(for: noteId)
        #expect(list.count == 1)
        #expect(list.first?.type == .alarm)
        #expect(list.first?.priority == .critical)

        let scheduled = await scheduler.scheduledReminder(reminderId: reminder.id)
        #expect(scheduled != nil)
        #expect(scheduled?.triggerAt == trigger)
    }

    @Test
    func featureFlagsBootstrapMatchesProductDecision() {
        let flags = FeatureFlags.bootstrap

        #expect(flags[.googleSignIn] == false)
        #expect(flags[.outlookIntegration] == false)
        #expect(flags[.teamWorkspaces] == false)
        #expect(flags[.aiSummary] == false)
        #expect(flags[.mailCaptureAdvanced] == false)
        #expect(flags[.androidSyncCompat] == true)
    }
}
