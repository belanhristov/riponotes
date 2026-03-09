import Foundation
import Testing
@testable import RipoAppKit
@testable import RipoData
@testable import RipoDomain
@testable import RipoUseCases

struct RipoCoreTests {
    private struct FailingCurrencyRateProvider: CurrencyRateProvider {
        func rate(from _: String, to _: String) async throws -> Double {
            struct RateError: Error {}
            throw RateError()
        }
    }

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
    func inboxViewModelBrainDumpValidatesAndCreatesNote() async throws {
        let repo = InMemoryNoteRepository()
        let sync = InMemorySyncEngine()
        let userId = UUID()

        let quickNote = QuickNoteEngine(noteRepository: repo, syncEngine: sync)
        let vm = InboxViewModel(ownerUserId: userId, noteRepository: repo, quickNoteEngine: quickNote)

        vm.brainDumpText = "   "
        let emptyResult = try await vm.submitBrainDump()
        #expect(emptyResult == nil)
        #expect(vm.brainDumpError == "Brain dump is empty.")

        vm.brainDumpText = "Call dentist tomorrow"
        let created = try await vm.submitBrainDump()
        #expect(created != nil)
        #expect(vm.brainDumpText.isEmpty)
        #expect(vm.brainDumpError == nil)
        #expect(vm.notes.count == 1)
    }

    @MainActor
    @Test
    func noteEditorViewModelCreatesDraftAndSavesBody() async throws {
        let repo = InMemoryNoteRepository()
        let sync = InMemorySyncEngine()
        let attachmentRepo = InMemoryAttachmentRepository()
        let attachmentService = AttachmentService(attachmentRepository: attachmentRepo)
        let tripRepo = InMemoryTripRepository()
        let tagging = TaggingService(
            noteRepository: repo,
            attachmentRepository: attachmentRepo,
            tripRepository: tripRepo
        )
        let userId = UUID()

        let service = NoteEditorService(noteRepository: repo, syncEngine: sync)
        let vm = NoteEditorViewModel(
            ownerUserId: userId,
            noteRepository: repo,
            editorService: service,
            attachmentRepository: attachmentRepo,
            attachmentService: attachmentService,
            taggingService: tagging
        )

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

        vm.newAttachmentPath = "/tmp/note-editor-image.jpg"
        await vm.addImageAttachment()
        #expect(vm.noteAttachments.count == 1)
        #expect(vm.noteAttachments.first?.localPath == "/tmp/note-editor-image.jpg")
        vm.newNoteTagText = "journal"
        await vm.addNoteTag()
        #expect(vm.noteTags.contains("journal"))

        if let image = vm.noteAttachments.first {
            vm.attachmentTagInputs[image.id] = "travel"
            await vm.addAttachmentTag(attachmentId: image.id)
            #expect(vm.noteAttachments.first?.tags.contains("travel") == true)
        }

        if let image = vm.noteAttachments.first {
            await vm.removeAttachment(image.id)
        }
        #expect(vm.noteAttachments.isEmpty)
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
        let tripId = UUID()

        let noteImage = try await service.addImageToNote(
            noteId: noteId,
            localPath: "/tmp/note-image.jpg",
            metadataJSON: "{\"width\":1200,\"height\":800}"
        )
        let templateImage = try await service.addImageToTemplate(
            templateId: templateId,
            localPath: "/tmp/template-image.jpg"
        )
        let tripImage = try await service.addImageToTrip(
            tripId: tripId,
            localPath: "/tmp/trip-image.jpg"
        )

        let updated = try await service.updateMetadata(
            attachmentId: noteImage.id,
            metadataJSON: "{\"width\":1024,\"height\":768,\"edited\":true}"
        )
        #expect(updated.metadataJSON.contains("\"edited\":true"))

        let noteAttachments = try await repo.attachments(ownerType: .note, ownerId: noteId)
        let templateAttachments = try await repo.attachments(ownerType: .template, ownerId: templateId)
        let tripAttachments = try await repo.attachments(ownerType: .trip, ownerId: tripId)
        #expect(noteAttachments.count == 1)
        #expect(templateAttachments.count == 1)
        #expect(tripAttachments.count == 1)
        #expect(templateImage.ownerType == .template)
        #expect(tripImage.ownerType == .trip)

        try await service.removeAttachment(templateImage.id)
        let afterDelete = try await repo.attachments(ownerType: .template, ownerId: templateId)
        #expect(afterDelete.isEmpty)
    }

    @Test
    func taggingServiceSupportsNoteAttachmentTripAndTagCloud() async throws {
        let userId = UUID()
        let noteRepo = InMemoryNoteRepository()
        let attachmentRepo = InMemoryAttachmentRepository()
        let tripRepo = InMemoryTripRepository()
        let sync = InMemorySyncEngine()
        let noteEngine = QuickNoteEngine(noteRepository: noteRepo, syncEngine: sync)
        let attachmentService = AttachmentService(attachmentRepository: attachmentRepo)
        let tagging = TaggingService(
            noteRepository: noteRepo,
            attachmentRepository: attachmentRepo,
            tripRepository: tripRepo
        )

        let note = try await noteEngine.createNote(
            QuickNoteInput(ownerUserId: userId, text: "Günlük entry", source: .manual)
        )
        _ = try await tagging.addTagToNote(noteId: note.id, rawTag: "Journal")
        _ = try await tagging.addTagToNote(noteId: note.id, rawTag: "Mood")

        let trip = Trip(
            ownerUserId: userId,
            title: "Rome",
            origin: "IST",
            destination: "ROM",
            startDate: Date(timeIntervalSince1970: 2_000_000_000),
            endDate: Date(timeIntervalSince1970: 2_000_000_000 + 86_400),
            baseCurrency: "USD",
            targetCurrency: "EUR"
        )
        try await tripRepo.upsertTrip(trip)
        _ = try await tagging.addTagToTrip(tripId: trip.id, rawTag: "Travel")
        _ = try await tagging.addTagToTrip(tripId: trip.id, rawTag: "Mood")

        let image = try await attachmentService.addImageToTrip(
            tripId: trip.id,
            localPath: "/tmp/rome.jpg"
        )
        _ = try await tagging.addTagToAttachment(attachmentId: image.id, rawTag: "Sunset")
        _ = try await tagging.addTagToAttachment(attachmentId: image.id, rawTag: "Travel")

        let cloud = try await tagging.tagCloud(ownerUserId: userId)
        #expect(cloud.first(where: { $0.tag == "mood" })?.count == 2)
        #expect(cloud.first(where: { $0.tag == "travel" })?.count == 2)
        #expect(cloud.first(where: { $0.tag == "journal" })?.count == 1)
        #expect(cloud.first(where: { $0.tag == "sunset" })?.count == 1)
    }

    @Test
    func socialShareServiceBuildsXAndInstagramPayloadWithHashtags() {
        let service = SocialShareService()
        let trip = Trip(
            ownerUserId: UUID(),
            title: "Lisbon Weekend",
            origin: "IST",
            destination: "LIS",
            startDate: Date(timeIntervalSince1970: 2_000_000_000),
            endDate: Date(timeIntervalSince1970: 2_000_000_000 + 86_400),
            baseCurrency: "USD",
            targetCurrency: "EUR",
            tags: ["travel"]
        )

        let xPayload = service.buildTravelImageShare(
            platform: .x,
            trip: trip,
            imagePath: "/tmp/lisbon.jpg",
            tags: ["food", "sunset"]
        )
        #expect(xPayload.platform == .x)
        #expect(xPayload.shareURL?.contains("twitter.com/intent/tweet") == true)
        #expect(xPayload.message.contains("#food"))

        let igPayload = service.buildTravelImageShare(
            platform: .instagram,
            trip: trip,
            imagePath: "/tmp/lisbon.jpg",
            tags: ["travel"]
        )
        #expect(igPayload.platform == .instagram)
        #expect(igPayload.shareURL == "instagram://camera")
    }

    @Test
    func tripAlertServiceSchedulesPreTripAndJourneyPromptsAndRefreshesOnOpen() async throws {
        let tripRepo = InMemoryTripRepository()
        let reminderRepo = InMemoryReminderRepository()
        let scheduler = InMemoryReminderScheduler()
        let fx = InMemoryCurrencyRateProvider(rates: ["USD_EUR": 0.9])
        let weather = InMemoryWeatherProvider(
            snapshot: WeatherSnapshot(condition: .sunny, temperatureCelsius: 24, feelsLikeCelsius: 25)
        )
        let planner = TravelPlannerService(
            tripRepository: tripRepo,
            currencyRateProvider: fx,
            weatherProvider: weather
        )

        let now = Date(timeIntervalSince1970: 2_000_000_000)
        let start = now.addingTimeInterval(5 * 24 * 60 * 60)
        let end = start.addingTimeInterval(2 * 24 * 60 * 60)
        let trip = Trip(
            ownerUserId: UUID(),
            title: "April Rome",
            origin: "IST",
            destination: "Rome",
            destinationLatitude: 41.9028,
            destinationLongitude: 12.4964,
            startDate: start,
            endDate: end,
            baseCurrency: "USD",
            targetCurrency: "EUR"
        )
        try await tripRepo.upsertTrip(trip)

        let service = TripAlertService(
            tripRepository: tripRepo,
            reminderRepository: reminderRepo,
            reminderScheduler: scheduler,
            planner: planner
        )

        let preTrip = try await service.schedulePreTripChecks(tripId: trip.id, now: now)
        #expect(preTrip.count == 2)
        let journey = try await service.scheduleJourneyPrompts(tripId: trip.id, localHour: 9, now: now)
        #expect(journey.count == 3)

        let reminders = try await reminderRepo.reminders(for: trip.id)
        #expect(reminders.count == 5)

        let snapshot = try await service.refreshOnTripOpen(tripId: trip.id)
        #expect(snapshot.fxQuote.rate == 0.9)
        #expect(snapshot.weather?.condition == .sunny)
    }

    @Test
    func journeyServiceCreatesEntryAndPlaceReviewWithLocationAndStars() async throws {
        let tripRepo = InMemoryTripRepository()
        let journeyRepo = InMemoryJourneyRepository()
        let service = JourneyService(tripRepository: tripRepo, journeyRepository: journeyRepo)

        let trip = Trip(
            ownerUserId: UUID(),
            title: "Rome",
            origin: "IST",
            destination: "Rome",
            startDate: Date(timeIntervalSince1970: 2_000_000_000),
            endDate: Date(timeIntervalSince1970: 2_000_100_000),
            baseCurrency: "USD",
            targetCurrency: "EUR"
        )
        try await tripRepo.upsertTrip(trip)

        let entry = try await service.addJourneyEntry(
            tripId: trip.id,
            title: "Day 1",
            body: "Trevi was crowded but beautiful.",
            moodTag: "excited",
            tags: ["rome", "trevi"]
        )
        let review = try await service.addPlaceReview(
            tripId: trip.id,
            journeyEntryId: entry.id,
            placeName: "Trevi Fountain",
            latitude: 41.9009,
            longitude: 12.4833,
            locationTag: "trevi-fountain",
            rating: 5,
            comment: "Night lights were amazing.",
            tags: ["baroque", "mustsee"]
        )
        #expect(review.rating == 5)

        let byTag = try await service.placeReviewsByLocationTag("trevi-fountain")
        #expect(byTag.count == 1)
        #expect(byTag.first?.placeName == "Trevi Fountain")
        #expect(byTag.first?.journeyEntryId == entry.id)
    }

    @Test
    func socialFeedServiceSupportsFollowTagCommentAndReactions() async throws {
        let repo = InMemorySocialRepository()
        let service = SocialFeedService(repository: repo)
        let author = UUID()
        let viewer = UUID()

        let post = try await service.publishPost(
            authorUserId: author,
            text: "Trevi review posted",
            tags: ["rome", "trevi"]
        )
        _ = try await service.addComment(postId: post.id, authorUserId: viewer, text: "Super useful")
        _ = try await service.react(postId: post.id, userId: viewer, type: .like)
        _ = try await service.followUser(followerUserId: viewer, followedUserId: author)
        _ = try await service.followTag(followerUserId: viewer, tag: "rome")

        let feed = try await service.feedForUser(userId: viewer)
        #expect(feed.count == 1)
        #expect(feed.first?.post.id == post.id)
        #expect(feed.first?.comments.count == 1)
        #expect(feed.first?.likeCount == 1)
    }

    @MainActor
    @Test
    func tagCloudViewModelFiltersByQuery() async throws {
        let userId = UUID()
        let noteRepo = InMemoryNoteRepository()
        let attachmentRepo = InMemoryAttachmentRepository()
        let tripRepo = InMemoryTripRepository()
        let sync = InMemorySyncEngine()
        let note = try await QuickNoteEngine(noteRepository: noteRepo, syncEngine: sync).createNote(
            QuickNoteInput(ownerUserId: userId, text: "test", source: .manual)
        )
        try await noteRepo.update(
            Note(
                id: note.id,
                ownerUserId: note.ownerUserId,
                title: note.title,
                plainTextBody: note.plainTextBody,
                folderId: note.folderId,
                isPinned: note.isPinned,
                status: note.status,
                source: note.source,
                tags: ["journal", "travel"],
                syncState: note.syncState,
                version: note.version,
                lastSyncedAt: note.lastSyncedAt,
                createdAt: note.createdAt,
                updatedAt: note.updatedAt,
                deletedAt: note.deletedAt
            )
        )

        let tagging = TaggingService(
            noteRepository: noteRepo,
            attachmentRepository: attachmentRepo,
            tripRepository: tripRepo
        )
        let vm = TagCloudViewModel(ownerUserId: userId, taggingService: tagging)
        await vm.load()

        #expect(vm.items.contains(where: { $0.tag == "journal" }))
        vm.query = "jou"
        #expect(vm.filteredItems.count == 1)
        #expect(vm.filteredItems.first?.tag == "journal")
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

    @MainActor
    @Test
    func templateStudioViewModelCreatesClonesAndBuildsNote() async throws {
        let userId = UUID()
        let templateRepo = InMemoryTemplateRepository()
        let noteRepo = InMemoryNoteRepository()
        let sync = InMemorySyncEngine()
        let attachmentRepo = InMemoryAttachmentRepository()
        let attachmentService = AttachmentService(attachmentRepository: attachmentRepo)
        let engine = TemplateEngineService(
            templateRepository: templateRepo,
            noteRepository: noteRepo,
            syncEngine: sync
        )
        let vm = TemplateStudioViewModel(
            ownerUserId: userId,
            templateRepository: templateRepo,
            templateEngine: engine,
            attachmentRepository: attachmentRepo,
            attachmentService: attachmentService
        )

        vm.draftName = "Daily Journal"
        vm.draftScope = .journal
        vm.draftType = .daily
        vm.draftTitleTemplate = "Journal {{date}}"
        vm.draftBodyTemplate = "Mood: {{mood}}"
        await vm.createTemplateFromDraft()
        #expect(vm.templates.count == 1)
        vm.previewVariablesText = "date=2026-03-09\nmood=Calm"
        vm.refreshPreview()
        #expect(vm.previewTitle == "Journal 2026-03-09")

        vm.draftBodyTemplate = "Mood: {{mood}}\nPlace: {{place}}"
        vm.previewVariablesText = "date=2026-03-09\nmood=Calm\nplace=Sahil"
        vm.refreshPreview()
        #expect(vm.previewBody.contains("Place: Sahil"))
        await vm.saveSelectedTemplateEdits()

        vm.newAttachmentPath = "/tmp/template-cover.jpg"
        await vm.addImageToSelectedTemplate()
        #expect(vm.templateAttachments.count == 1)
        #expect(vm.templateAttachments.first?.localPath == "/tmp/template-cover.jpg")

        if let image = vm.templateAttachments.first {
            await vm.removeAttachment(image.id)
        }
        #expect(vm.templateAttachments.isEmpty)

        await vm.cloneSelectedTemplate(newName: "Daily Journal Copy")
        #expect(vm.templates.count == 2)

        let createdNote = await vm.createNoteFromSelectedTemplate(
            variables: ["date": "2026-03-09", "mood": "Calm"]
        )
        #expect(createdNote != nil)
        #expect(createdNote?.plainTextBody.contains("Mood: Calm") == true)
    }

    @MainActor
    @Test
    func journalWorkspaceStartsEntryFromJournalTemplate() async throws {
        let userId = UUID()
        let templateRepo = InMemoryTemplateRepository()
        let noteRepo = InMemoryNoteRepository()
        let sync = InMemorySyncEngine()
        let attachmentRepo = InMemoryAttachmentRepository()
        let attachmentService = AttachmentService(attachmentRepository: attachmentRepo)

        let templateEngine = TemplateEngineService(
            templateRepository: templateRepo,
            noteRepository: noteRepo,
            syncEngine: sync
        )

        _ = try await templateEngine.createTemplate(
            ownerUserId: userId,
            name: "Night Journal",
            scope: .journal,
            type: .daily,
            titleTemplate: "Journal {{date}}",
            bodyTemplate: "Mood: {{mood}}\\nPlace: {{place}}"
        )

        let editorService = NoteEditorService(noteRepository: noteRepo, syncEngine: sync)
        let noteEditorVM = NoteEditorViewModel(
            ownerUserId: userId,
            noteRepository: noteRepo,
            editorService: editorService,
            attachmentRepository: attachmentRepo,
            attachmentService: attachmentService
        )

        let journalVM = JournalWorkspaceViewModel(
            ownerUserId: userId,
            templateRepository: templateRepo,
            templateEngine: templateEngine,
            noteEditorViewModel: noteEditorVM
        )

        await journalVM.load()
        #expect(journalVM.journalTemplates.count == 1)

        journalVM.templateVariablesText = """
        date=2026-03-09
        mood=Relaxed
        place=Balcony
        """
        await journalVM.startFromSelectedTemplate()

        #expect(journalVM.noteEditorViewModel.noteId != nil)
        #expect(journalVM.noteEditorViewModel.title == "Journal 2026-03-09")
        #expect(journalVM.noteEditorViewModel.body.contains("Mood: Relaxed"))
        #expect(journalVM.noteEditorViewModel.body.contains("Place: Balcony"))
    }

    @Test
    func journalSecurityServiceSupportsPasscodeAndEncryptionRoundtrip() async throws {
        let store = InMemorySecureStore()
        let auth = InMemoryAppAuthenticator(nextResult: true)
        let security = JournalSecurityService(secureStore: store, authenticator: auth)

        try await security.enableLock(passcode: "1234")
        var status = try await security.status()
        #expect(status.isLockEnabled == true)
        #expect(status.isUnlocked == true)

        let cipher = try await security.encrypt("private journal entry")
        #expect(cipher != "private journal entry")
        let plain = try await security.decrypt(cipher)
        #expect(plain == "private journal entry")

        try await security.lock()
        status = try await security.status()
        #expect(status.isUnlocked == false)

        try await security.unlockWithPasscode("1234")
        status = try await security.status()
        #expect(status.isUnlocked == true)
    }

    @MainActor
    @Test
    func journalWorkspaceBlocksEntryWhenLocked() async throws {
        let userId = UUID()
        let templateRepo = InMemoryTemplateRepository()
        let noteRepo = InMemoryNoteRepository()
        let sync = InMemorySyncEngine()
        let attachmentRepo = InMemoryAttachmentRepository()
        let attachmentService = AttachmentService(attachmentRepository: attachmentRepo)
        let security = JournalSecurityService(
            secureStore: InMemorySecureStore(),
            authenticator: InMemoryAppAuthenticator(nextResult: true)
        )

        let templateEngine = TemplateEngineService(
            templateRepository: templateRepo,
            noteRepository: noteRepo,
            syncEngine: sync
        )

        _ = try await templateEngine.createTemplate(
            ownerUserId: userId,
            name: "Locked Journal",
            scope: .journal,
            type: .daily,
            titleTemplate: "Journal {{date}}",
            bodyTemplate: "Mood: {{mood}}"
        )

        let editorService = NoteEditorService(noteRepository: noteRepo, syncEngine: sync)
        let noteEditorVM = NoteEditorViewModel(
            ownerUserId: userId,
            noteRepository: noteRepo,
            editorService: editorService,
            attachmentRepository: attachmentRepo,
            attachmentService: attachmentService
        )

        let journalVM = JournalWorkspaceViewModel(
            ownerUserId: userId,
            templateRepository: templateRepo,
            templateEngine: templateEngine,
            noteEditorViewModel: noteEditorVM,
            securityService: security
        )

        await journalVM.load()
        await journalVM.enableLock(passcode: "9999")
        await journalVM.lockJournal()
        #expect(journalVM.isLockEnabled == true)
        #expect(journalVM.isUnlocked == false)

        await journalVM.startFromSelectedTemplate()
        #expect(journalVM.noteEditorViewModel.noteId == nil)

        await journalVM.unlockWithPasscode("9999")
        await journalVM.startFromSelectedTemplate()
        #expect(journalVM.noteEditorViewModel.noteId != nil)

        await journalVM.lockJournal()
        #expect(journalVM.noteEditorViewModel.noteId == nil)
        #expect(journalVM.noteEditorViewModel.title.isEmpty)
        #expect(journalVM.noteEditorViewModel.body.isEmpty)
    }

    @Test
    func contextSuggestionServiceProducesBeachSuggestionWhenSunnyAndNearby() async throws {
        let weather = InMemoryWeatherProvider(
            snapshot: WeatherSnapshot(
                condition: .sunny,
                temperatureCelsius: 27,
                feelsLikeCelsius: 29
            )
        )
        let place = InMemoryPlaceContextProvider(
            context: PlaceContext(
                latitude: 36.89,
                longitude: 30.71,
                label: "Konyaalti",
                distanceToBeachMeters: 300
            )
        )
        let service = ContextSuggestionService(weatherProvider: weather, placeProvider: place)

        let suggestion = try await service.suggest()
        #expect(suggestion.title == "Sahil Molası")
        #expect(suggestion.body.contains("5 dakika"))
        #expect(suggestion.templateHints.contains("journal_walk"))
    }

    @Test
    func travelPlannerCreatesTripSegmentsChecklistsAndBudgetEstimate() async throws {
        let tripRepo = InMemoryTripRepository()
        let fx = InMemoryCurrencyRateProvider(rates: ["USD_EUR": 0.9])
        let weather = InMemoryWeatherProvider(
            snapshot: WeatherSnapshot(condition: .sunny, temperatureCelsius: 26, feelsLikeCelsius: 28)
        )
        let planner = TravelPlannerService(
            tripRepository: tripRepo,
            currencyRateProvider: fx,
            weatherProvider: weather
        )

        let userId = UUID()
        let start = Date(timeIntervalSince1970: 2_200_000_000)
        let end = start.addingTimeInterval(60 * 60 * 24 * 5)

        let trip = try await planner.createTrip(
            ownerUserId: userId,
            title: "Rome Trip",
            origin: "Istanbul",
            destination: "Rome",
            startDate: start,
            endDate: end,
            baseCurrency: "USD",
            targetCurrency: "EUR"
        )

        _ = try await planner.addFlightSegment(
            tripId: trip.id,
            providerName: "THY",
            confirmationCode: "TK123",
            departureAt: start,
            arrivalAt: start.addingTimeInterval(60 * 60 * 2)
        )
        _ = try await planner.addHotelSegment(
            tripId: trip.id,
            hotelName: "Roma Hotel",
            confirmationCode: "HOTEL987",
            checkIn: start,
            checkOut: end
        )

        let checklist = try await planner.addChecklistItem(
            tripId: trip.id,
            category: .documents,
            text: "Passport",
            isCritical: true
        )
        let checklistDone = try await planner.toggleChecklistItem(checklist)
        #expect(checklistDone.isDone == true)

        let packing = try await planner.addPackingItem(
            tripId: trip.id,
            category: .clothes,
            text: "T-Shirts",
            quantity: 3
        )
        let packingDone = try await planner.togglePackingItem(packing)
        #expect(packingDone.isDone == true)

        let estimate = try await planner.estimateBudget(
            tripId: trip.id,
            dailySpendInBaseCurrency: 120
        )
        #expect(estimate.currency == "EUR")
        #expect(estimate.fxRateUsed == 0.9)
        #expect(estimate.estimatedTotal > 0)

        let weatherSummary = try await planner.weatherSummaryForTripDestination(
            tripId: trip.id,
            latitude: 41.9,
            longitude: 12.5
        )
        #expect(weatherSummary.condition == .sunny)

        let segments = try await tripRepo.segments(tripId: trip.id)
        #expect(segments.count == 2)

        let profileEstimate = try await planner.estimateBudgetFromExpenseProfile(
            tripId: trip.id,
            profile: TripExpenseProfile(
                breakfastCost: 10,
                lunchCost: 20,
                dinnerCost: 30,
                drinksCost: 15,
                transportCost: 10,
                miscCost: 15
            )
        )
        #expect(profileEstimate.dailyEstimate == 90)
    }

    @MainActor
    @Test
    func travelWorkspaceViewModelRunsTripFlow() async throws {
        let userId = UUID()
        let tripRepo = InMemoryTripRepository()
        let attachmentRepo = InMemoryAttachmentRepository()
        let fx = InMemoryCurrencyRateProvider(rates: ["USD_EUR": 0.9])
        let weather = InMemoryWeatherProvider(
            snapshot: WeatherSnapshot(condition: .cloudy, temperatureCelsius: 21, feelsLikeCelsius: 21)
        )
        let planner = TravelPlannerService(
            tripRepository: tripRepo,
            currencyRateProvider: fx,
            weatherProvider: weather
        )
        let smartPacking = SmartPackingService(tripRepository: tripRepo)
        let tagging = TaggingService(
            noteRepository: InMemoryNoteRepository(),
            attachmentRepository: attachmentRepo,
            tripRepository: tripRepo
        )
        let attachmentService = AttachmentService(attachmentRepository: attachmentRepo)
        let vm = TravelWorkspaceViewModel(
            ownerUserId: userId,
            tripRepository: tripRepo,
            planner: planner,
            smartPackingService: smartPacking,
            attachmentRepository: attachmentRepo,
            attachmentService: attachmentService,
            taggingService: tagging
        )

        vm.draftTitle = "Paris Trip"
        vm.draftOrigin = "Istanbul"
        vm.draftDestination = "Paris"
        vm.draftBaseCurrency = "USD"
        vm.draftTargetCurrency = "EUR"
        vm.draftStartDate = Date(timeIntervalSince1970: 2_300_000_000)
        vm.draftEndDate = vm.draftStartDate.addingTimeInterval(60 * 60 * 24 * 4)

        await vm.createTripFromDraft()
        #expect(vm.trips.count == 1)
        #expect(vm.selectedTripId != nil)

        await vm.addFlight(
            providerName: "AF",
            confirmationCode: "AF123",
            departureAt: vm.draftStartDate,
            arrivalAt: vm.draftStartDate.addingTimeInterval(60 * 60 * 3)
        )
        await vm.addHotel(
            hotelName: "Paris Inn",
            confirmationCode: "HOTELX",
            checkIn: vm.draftStartDate,
            checkOut: vm.draftEndDate
        )
        await vm.addChecklist(text: "Passport", category: .documents, isCritical: true)
        await vm.addPacking(text: "Jacket", category: .clothes, quantity: 1, isCritical: false)
        await vm.estimateBudget(dailySpendInBaseCurrency: 150)
        await vm.refreshWeather(latitude: 48.85, longitude: 2.35)

        #expect(vm.segments.count == 2)
        #expect(vm.checklistItems.count == 1)
        #expect(vm.packingItems.count == 1)
        #expect(vm.budgetEstimate != nil)
        #expect(vm.weatherSummary?.condition == .cloudy)

        vm.expenseBreakfast = "12"
        vm.expenseLunch = "20"
        vm.expenseDinner = "35"
        vm.expenseDrinks = "8"
        vm.expenseTransport = "10"
        vm.expenseMisc = "5"
        await vm.estimateBudgetFromProfile()
        #expect(vm.budgetEstimate != nil)
        if let estimate = vm.budgetEstimate {
            #expect(estimate.dailyEstimate == 90 * estimate.fxRateUsed)
            #expect(estimate.currency == "EUR")
        }

        await vm.generateSmartPacking(
            weather: .sunny,
            activities: [.beach, .cityWalk],
            travelers: 1,
            laundryAccess: false
        )
        #expect(vm.packingItems.count > 1)
        #expect(vm.packingItems.contains(where: { $0.text == "Swimsuit" }))

        await vm.refreshFxQuote()
        #expect(vm.fxQuote != nil)
        #expect(vm.fxQuote?.baseCurrency == "USD")
        #expect(vm.fxQuote?.targetCurrency == "EUR")
        #expect(vm.fxQuote?.rate == 0.9)

        vm.newTripTagText = "citybreak"
        await vm.addTripTag()
        #expect(vm.selectedTripTags.contains("citybreak"))

        vm.newTripImagePath = "/tmp/flight-window.jpg"
        await vm.addTripImage()
        #expect(vm.tripAttachments.count == 1)
        if let image = vm.tripAttachments.first {
            vm.tripAttachmentTagInputs[image.id] = "skyline"
            await vm.addTagToTripImage(attachmentId: image.id)
            #expect(vm.tripAttachments.first?.tags.contains("skyline") == true)

            await vm.previewShare(attachmentId: image.id, platform: .x)
            #expect(vm.socialSharePreview?.platform == .x)
            #expect(vm.socialSharePreview?.message.contains("#citybreak") == true)
        }
    }

    @Test
    func smartPackingServiceGeneratesPackPointLikeEssentials() async throws {
        let tripRepo = InMemoryTripRepository()
        let userId = UUID()
        let trip = Trip(
            ownerUserId: userId,
            title: "Antalya",
            origin: "Istanbul",
            destination: "Antalya",
            startDate: Date(timeIntervalSince1970: 2_300_000_000),
            endDate: Date(timeIntervalSince1970: 2_300_000_000 + 60 * 60 * 24 * 3),
            baseCurrency: "USD",
            targetCurrency: "TRY"
        )
        try await tripRepo.upsertTrip(trip)

        let service = SmartPackingService(tripRepository: tripRepo)
        let saved = try await service.generateAndSave(
            tripId: trip.id,
            config: SmartPackingConfig(
                weather: .rainy,
                activities: [.beach, .hiking],
                travelers: 1,
                laundryAccess: false
            )
        )

        #expect(saved.contains(where: { $0.text == "Passport" && $0.isCritical }))
        #expect(saved.contains(where: { $0.text == "Umbrella" }))
        #expect(saved.contains(where: { $0.text == "Swimsuit" }))
        #expect(saved.contains(where: { $0.text == "Hiking Shoes" }))
    }

    @Test
    func frankfurterProviderParsesLatestRatePayload() throws {
        let json = """
        {
          "amount": 1.0,
          "base": "USD",
          "date": "2026-03-09",
          "rates": {
            "EUR": 0.92
          }
        }
        """
        let data = Data(json.utf8)
        let rate = try FrankfurterCurrencyRateProvider.parseRate(data: data, targetCurrency: "EUR")
        #expect(rate == 0.92)
    }

    @Test
    func travelPlannerFallsBackToCachedFxQuoteWhenProviderFails() async throws {
        let tripRepo = InMemoryTripRepository()
        let cache = InMemoryFxQuoteCache()
        let weather = InMemoryWeatherProvider(
            snapshot: WeatherSnapshot(condition: .sunny, temperatureCelsius: 25, feelsLikeCelsius: 25)
        )
        let userId = UUID()
        let trip = Trip(
            ownerUserId: userId,
            title: "Berlin",
            origin: "IST",
            destination: "BER",
            startDate: Date(timeIntervalSince1970: 2_350_000_000),
            endDate: Date(timeIntervalSince1970: 2_350_000_000 + 60 * 60 * 24),
            baseCurrency: "USD",
            targetCurrency: "EUR"
        )
        try await tripRepo.upsertTrip(trip)

        let liveProvider = InMemoryCurrencyRateProvider(rates: ["USD_EUR": 0.91])
        let livePlanner = TravelPlannerService(
            tripRepository: tripRepo,
            currencyRateProvider: liveProvider,
            weatherProvider: weather,
            fxQuoteCache: cache
        )
        let liveQuote = try await livePlanner.currentFxQuote(tripId: trip.id)
        #expect(liveQuote.source == .live)

        let failingPlanner = TravelPlannerService(
            tripRepository: tripRepo,
            currencyRateProvider: FailingCurrencyRateProvider(),
            weatherProvider: weather,
            fxQuoteCache: cache
        )
        let cachedQuote = try await failingPlanner.currentFxQuote(tripId: trip.id)
        #expect(cachedQuote.source == .cached)
        #expect(cachedQuote.rate == 0.91)
    }

    @Test
    func travelWorkspaceFxAgeAndStaleCalculations() {
        let now = Date(timeIntervalSince1970: 2_000_000_000)
        let tenMinutesAgo = now.addingTimeInterval(-600)
        let ninetyMinutesAgo = now.addingTimeInterval(-(90 * 60))

        #expect(TravelWorkspaceViewModel.fxAgeMinutes(quotedAt: tenMinutesAgo, now: now) == 10)
        #expect(TravelWorkspaceViewModel.fxIsStale(quotedAt: tenMinutesAgo, now: now) == false)
        #expect(TravelWorkspaceViewModel.fxIsStale(quotedAt: ninetyMinutesAgo, now: now) == true)
    }
}
