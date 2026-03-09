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
        let attachmentRepo = InMemoryAttachmentRepository()
        let attachmentService = AttachmentService(attachmentRepository: attachmentRepo)
        let userId = UUID()

        let service = NoteEditorService(noteRepository: repo, syncEngine: sync)
        let vm = NoteEditorViewModel(
            ownerUserId: userId,
            noteRepository: repo,
            editorService: service,
            attachmentRepository: attachmentRepo,
            attachmentService: attachmentService
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
        let vm = TravelWorkspaceViewModel(
            ownerUserId: userId,
            tripRepository: tripRepo,
            planner: planner,
            smartPackingService: smartPacking
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
}
