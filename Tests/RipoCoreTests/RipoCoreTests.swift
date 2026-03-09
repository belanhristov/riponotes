import Foundation
import Testing
@testable import RipoAppKit
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

    @MainActor
    @Test
    func inboxViewModelCreatesQuickNoteAndSelectsIt() async throws {
        let repo = InMemoryNoteRepository()
        let sync = InMemorySyncEngine()
        let userId = UUID()

        let quickNote = QuickNoteEngine(noteRepository: repo, syncEngine: sync)
        let vm = InboxViewModel(ownerUserId: userId, noteRepository: repo, quickNoteEngine: quickNote)

        let created = try await vm.addQuickNote(text: "Plan weekend walk", source: .manual)

        #expect(vm.notes.count == 1)
        #expect(vm.selectedNoteId == created.id)
        #expect(vm.notes.first?.title == "Plan weekend walk")
    }

    @MainActor
    @Test
    func noteEditorViewModelCreatesDraftAndSavesBody() async throws {
        let repo = InMemoryNoteRepository()
        let sync = InMemorySyncEngine()
        let userId = UUID()

        let service = NoteEditorService(noteRepository: repo, syncEngine: sync)
        let vm = NoteEditorViewModel(ownerUserId: userId, noteRepository: repo, editorService: service)

        try await vm.open(noteId: nil)
        vm.title = ""
        vm.body = "Daily reflection\nToday I learned..."
        let saved = try await vm.save()

        #expect(saved.title == "Daily reflection")
        #expect(saved.plainTextBody.contains("Today I learned"))

        let jobs = try await sync.pendingJobs()
        #expect(jobs.count == 2) // create draft + update on save

        vm.body = "line1\nline2"
        vm.applyToolbar(.indent, lineRange: 2...2)
        #expect(vm.body == "line1\n    line2")
    }

    #if canImport(SwiftData)
    @Test
    func swiftDataRepositorySupportsCrudAndSearch() async throws {
        let repo = try SwiftDataNoteRepository(inMemory: true)
        let userId = UUID()

        let note = Note(
            ownerUserId: userId,
            title: "Walk",
            plainTextBody: "Sunny weather at the beach",
            source: .manual,
            tags: ["health", "outdoor"]
        )

        try await repo.create(note)

        let inbox = try await repo.inboxNotes(ownerUserId: userId)
        #expect(inbox.count == 1)

        let matched = try await repo.search(ownerUserId: userId, query: "beach")
        #expect(matched.count == 1)
        #expect(matched.first?.id == note.id)

        try await repo.softDelete(noteId: note.id, deletedAt: .now)
        let afterDelete = try await repo.inboxNotes(ownerUserId: userId)
        #expect(afterDelete.isEmpty)
    }
    #endif

    @Test
    func quickCaptureFacadeCreatesWidgetAndMeetingNotes() async throws {
        let repo = InMemoryNoteRepository()
        let sync = InMemorySyncEngine()
        let engine = QuickNoteEngine(noteRepository: repo, syncEngine: sync)
        let facade = QuickCaptureFacade(quickNoteEngine: engine)
        let ownerUserId = UUID()

        let widgetNote = try await facade.createWidgetQuickNote(
            ownerUserId: ownerUserId,
            text: "Buy coffee beans"
        )
        #expect(widgetNote.source == .widget)

        let meetingNote = try await facade.createMeetingNoteFromIntent(
            ownerUserId: ownerUserId,
            title: "Sprint Planning",
            participantNames: ["Ahmet", "Ayse"]
        )
        #expect(meetingNote.source == .siri)
        #expect(meetingNote.plainTextBody.contains("Participants:"))
        #expect(meetingNote.plainTextBody.contains("- Ahmet"))
        #expect(meetingNote.plainTextBody.contains("- Ayse"))
    }

    @Test
    func reminderCalendarServiceBindsReminderAndCalendarLink() async throws {
        let reminderRepo = InMemoryReminderRepository()
        let scheduler = InMemoryReminderScheduler()
        let linkRepo = InMemoryCalendarLinkRepository()
        let eventService = InMemoryCalendarEventService()
        let service = ReminderCalendarService(
            reminderRepository: reminderRepo,
            reminderScheduler: scheduler,
            calendarLinkRepository: linkRepo,
            calendarEventService: eventService
        )

        let note = Note(
            ownerUserId: UUID(),
            title: "Doctor Appointment",
            plainTextBody: "Annual check-up",
            source: .manual
        )
        let start = Date(timeIntervalSince1970: 2_100_000_000)
        let end = start.addingTimeInterval(60 * 45)

        let result = try await service.bindNote(
            note: note,
            startAt: start,
            endAt: end,
            provider: .apple,
            addReminder: true,
            addCalendarEvent: true
        )

        #expect(result.reminder != nil)
        #expect(result.calendarLink != nil)

        let reminders = try await reminderRepo.reminders(for: note.id)
        #expect(reminders.count == 1)
        #expect(reminders.first?.triggerAt == start)

        let links = try await linkRepo.links(for: note.id)
        #expect(links.count == 1)
        #expect(links.first?.provider == .apple)
        #expect(links.first?.startAt == start)

        if let link = result.calendarLink {
            let event = await eventService.event(id: link.externalEventId)
            #expect(event != nil)
            #expect(event?.title == "Doctor Appointment")
        }
    }

    @Test
    func templateEngineCreatesAndClonesTemplateAndBuildsNote() async throws {
        let templates = InMemoryTemplateRepository()
        let notes = InMemoryNoteRepository()
        let sync = InMemorySyncEngine()
        let service = TemplateEngineService(
            templateRepository: templates,
            noteRepository: notes,
            syncEngine: sync
        )

        let userId = UUID()
        let created = try await service.createTemplate(
            ownerUserId: userId,
            name: "Beach Journal",
            scope: .journal,
            type: .daily,
            titleTemplate: "Journal - {{date}}",
            bodyTemplate: "Mood: {{mood}}\\nPlace: {{place}}\\nNotes:\\n"
        )

        let cloned = try await service.cloneTemplate(templateId: created.id, newName: "Beach Journal Copy")
        #expect(cloned.id != created.id)
        #expect(cloned.name == "Beach Journal Copy")

        let note = try await service.createNoteFromTemplate(
            templateId: created.id,
            ownerUserId: userId,
            variables: ["date": "2026-03-09", "mood": "Enerjik", "place": "Sahil"],
            source: .manual
        )

        #expect(note.title == "Journal - 2026-03-09")
        #expect(note.plainTextBody.contains("Mood: Enerjik"))
        #expect(note.plainTextBody.contains("Place: Sahil"))
    }

    @Test
    func attachmentServiceAddsAndUpdatesImageAttachments() async throws {
        let repo = InMemoryAttachmentRepository()
        let service = AttachmentService(attachmentRepository: repo)
        let noteId = UUID()
        let templateId = UUID()

        let noteImage = try await service.addImageToNote(
            noteId: noteId,
            localPath: "/tmp/note-image.jpg",
            metadataJSON: "{\"width\":1200,\"height\":800}"
        )
        let templateImage = try await service.addImageToTemplate(
            templateId: templateId,
            localPath: "/tmp/template-image.jpg"
        )

        let updated = try await service.updateMetadata(
            attachmentId: noteImage.id,
            metadataJSON: "{\"width\":1024,\"height\":768,\"edited\":true}"
        )
        #expect(updated.metadataJSON.contains("\"edited\":true"))

        let noteAttachments = try await repo.attachments(ownerType: .note, ownerId: noteId)
        let templateAttachments = try await repo.attachments(ownerType: .template, ownerId: templateId)
        #expect(noteAttachments.count == 1)
        #expect(templateAttachments.count == 1)
        #expect(templateImage.ownerType == .template)

        try await service.removeAttachment(templateImage.id)
        let afterDelete = try await repo.attachments(ownerType: .template, ownerId: templateId)
        #expect(afterDelete.isEmpty)
    }

    @Test
    func editorToolbarServiceAppliesCoreFormattingCommands() throws {
        let toolbar = EditorToolbarService()
        let input = "Title\nTask one\nTask two"

        let indented = try toolbar.apply(.indent, to: input, lineRange: 2...3)
        #expect(indented.contains("\n    Task one\n    Task two"))

        let checklist = try toolbar.apply(.toggleChecklist, to: input, lineRange: 2...3)
        #expect(checklist.contains("\n- [ ] Task one\n- [ ] Task two"))

        let heading = try toolbar.apply(.increaseHeading, to: "Hello")
        #expect(heading == "# Hello")

        let divider = try toolbar.apply(.insertDivider(afterLine: 1), to: "A\nB")
        #expect(divider == "A\n---\nB")
    }
}
