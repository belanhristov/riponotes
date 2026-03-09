import SwiftUI
import RipoAppKit
import RipoData
import RipoDomain
import RipoUseCases

@main
struct RipoDemoApp: App {
    @StateObject private var container = DemoContainer()

    var body: some Scene {
        WindowGroup {
            DemoRootView(container: container)
                .task {
                    await container.bootstrapIfNeeded()
                }
        }
    }
}

@MainActor
final class DemoContainer: ObservableObject {
    let ownerUserId = UUID()

    private let noteRepository = InMemoryNoteRepository()
    private let templateRepository = InMemoryTemplateRepository()
    private let reminderRepository = InMemoryReminderRepository()
    private let reminderScheduler = InMemoryReminderScheduler()
    private let attachmentRepository = InMemoryAttachmentRepository()
    private let listRepository = InMemoryListRepository()
    private let contactLinkRepository = InMemoryContactLinkRepository()
    private let locationLinkRepository = InMemoryLocationLinkRepository()
    private let tripRepository = InMemoryTripRepository()
    private let syncEngine = InMemorySyncEngine()

    private let templateEngine: TemplateEngineService
    private let quickNoteEngine: QuickNoteEngine
    private let noteEditorService: NoteEditorService
    private let attachmentService: AttachmentService
    private let taggingService: TaggingService
    private let convertService: ConvertNoteService
    private let archiveService: JournalArchiveService
    private let userProfileRepository = InMemoryUserProfileRepository()
    private let userProfileService: UserProfileService

    let inboxViewModel: InboxViewModel
    let noteEditorViewModel: NoteEditorViewModel
    let templateStudioViewModel: TemplateStudioViewModel
    let journalWorkspaceViewModel: JournalWorkspaceViewModel
    let tagCloudViewModel: TagCloudViewModel
    let journalArchiveViewModel: JournalArchiveViewModel
    let profileViewModel: DemoProfileViewModel

    private var seeded = false

    init() {
        templateEngine = TemplateEngineService(
            templateRepository: templateRepository,
            noteRepository: noteRepository,
            syncEngine: syncEngine
        )
        quickNoteEngine = QuickNoteEngine(noteRepository: noteRepository, syncEngine: syncEngine)
        noteEditorService = NoteEditorService(noteRepository: noteRepository, syncEngine: syncEngine)
        attachmentService = AttachmentService(attachmentRepository: attachmentRepository)
        taggingService = TaggingService(
            noteRepository: noteRepository,
            attachmentRepository: attachmentRepository,
            tripRepository: tripRepository
        )
        convertService = ConvertNoteService(
            reminderRepository: reminderRepository,
            reminderScheduler: reminderScheduler,
            listRepository: listRepository,
            contactLinkRepository: contactLinkRepository,
            locationLinkRepository: locationLinkRepository
        )
        archiveService = JournalArchiveService(noteRepository: noteRepository)
        userProfileService = UserProfileService(profileRepository: userProfileRepository)

        inboxViewModel = InboxViewModel(
            ownerUserId: ownerUserId,
            noteRepository: noteRepository,
            quickNoteEngine: quickNoteEngine
        )
        noteEditorViewModel = NoteEditorViewModel(
            ownerUserId: ownerUserId,
            noteRepository: noteRepository,
            editorService: noteEditorService,
            attachmentRepository: attachmentRepository,
            attachmentService: attachmentService,
            taggingService: taggingService,
            convertService: convertService
        )
        templateStudioViewModel = TemplateStudioViewModel(
            ownerUserId: ownerUserId,
            templateRepository: templateRepository,
            templateEngine: templateEngine,
            attachmentRepository: attachmentRepository,
            attachmentService: attachmentService
        )

        let contextSuggestionService = ContextSuggestionService(
            weatherProvider: InMemoryWeatherProvider(
                snapshot: WeatherSnapshot(condition: .sunny, temperatureCelsius: 26, feelsLikeCelsius: 27)
            ),
            placeProvider: InMemoryPlaceContextProvider(
                context: PlaceContext(latitude: 36.89, longitude: 30.71, label: "Konyaalti", distanceToBeachMeters: 500)
            )
        )

        journalWorkspaceViewModel = JournalWorkspaceViewModel(
            ownerUserId: ownerUserId,
            templateRepository: templateRepository,
            templateEngine: templateEngine,
            noteEditorViewModel: noteEditorViewModel,
            securityService: AppComposition.makeJournalSecurityService(useProductionAdapters: false),
            contextSuggestionService: contextSuggestionService
        )
        tagCloudViewModel = TagCloudViewModel(ownerUserId: ownerUserId, taggingService: taggingService)
        journalArchiveViewModel = JournalArchiveViewModel(ownerUserId: ownerUserId, archiveService: archiveService)
        profileViewModel = DemoProfileViewModel(ownerUserId: ownerUserId, service: userProfileService)
    }

    func bootstrapIfNeeded() async {
        guard !seeded else { return }
        seeded = true

        _ = try? await quickNoteEngine.createNote(
            QuickNoteInput(ownerUserId: ownerUserId, text: "Welcome to Ripo Notes", source: .manual)
        )
        _ = try? await quickNoteEngine.createNote(
            QuickNoteInput(ownerUserId: ownerUserId, text: "Try Journal > Auto Template + Encrypt", source: .manual)
        )

        _ = try? await templateEngine.createTemplate(
            ownerUserId: ownerUserId,
            name: "Daily Journal",
            scope: .journal,
            type: .daily,
            titleTemplate: "Journal {{date}}",
            bodyTemplate: "Mood: {{mood}}\\nWhat happened today?\\n"
        )

        try? await inboxViewModel.loadInbox()
        try? await noteEditorViewModel.open(noteId: nil)
        await templateStudioViewModel.load(scope: nil)
        await journalWorkspaceViewModel.load()
        await tagCloudViewModel.load()
        await journalArchiveViewModel.loadSelectedMonth()
        await profileViewModel.load()
    }
}

struct DemoRootView: View {
    @ObservedObject var container: DemoContainer
    @State private var selectedModule: LaunchModule?

    var body: some View {
        Group {
            if let selectedModule {
                switch selectedModule {
                case .notes:
                    NotesWorkspaceView(container: container) {
                        self.selectedModule = nil
                    }
                case .journey:
                    NavigationStack {
                        JournalWorkspaceView(viewModel: container.journalWorkspaceViewModel)
                            .toolbar {
                                ToolbarItem(placement: .navigation) {
                                    Button("Home") { self.selectedModule = nil }
                                }
                            }
                    }
                case .travel:
                    NavigationStack {
                        TravelWorkspaceView(viewModel: travelViewModel(container: container))
                            .toolbar {
                                ToolbarItem(placement: .navigation) {
                                    Button("Home") { self.selectedModule = nil }
                                }
                            }
                    }
                }
            } else {
                LaunchScreenView { module in
                    self.selectedModule = module
                }
            }
        }
        .frame(minWidth: 980, minHeight: 700)
    }

    private func travelViewModel(container: DemoContainer) -> TravelWorkspaceViewModel {
        let tripRepository = InMemoryTripRepository()
        let attachmentRepository = InMemoryAttachmentRepository()
        return TravelWorkspaceViewModel(
            ownerUserId: container.ownerUserId,
            tripRepository: tripRepository,
            planner: TravelPlannerService(
                tripRepository: tripRepository,
                currencyRateProvider: AppComposition.makeCurrencyRateProvider(useProductionAdapters: false),
                weatherProvider: InMemoryWeatherProvider(
                    snapshot: WeatherSnapshot(condition: .cloudy, temperatureCelsius: 21, feelsLikeCelsius: 21)
                )
            ),
            smartPackingService: SmartPackingService(tripRepository: tripRepository),
            attachmentRepository: attachmentRepository,
            attachmentService: AttachmentService(attachmentRepository: attachmentRepository),
            taggingService: TaggingService(
                noteRepository: InMemoryNoteRepository(),
                attachmentRepository: attachmentRepository,
                tripRepository: tripRepository
            )
        )
    }
}

enum LaunchModule {
    case notes
    case journey
    case travel
}

struct LaunchScreenView: View {
    let onSelect: (LaunchModule) -> Void

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.blue.opacity(0.15), Color.white, Color.green.opacity(0.12)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 28) {
                RipoLogoView()

                Text("ripo.life")
                    .font(.system(size: 38, weight: .bold, design: .rounded))

                Text("Choose your workspace")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                HStack(spacing: 14) {
                    launchButton("Notes", subtitle: "Quick notes, editor, templates") {
                        onSelect(.notes)
                    }
                    launchButton("Journey", subtitle: "Mood-based journal flow") {
                        onSelect(.journey)
                    }
                    launchButton("Travel", subtitle: "Trip planning workspace") {
                        onSelect(.travel)
                    }
                }
            }
            .padding(28)
        }
    }

    private func launchButton(_ title: String, subtitle: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.title2.weight(.semibold))
                Text(subtitle)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, minHeight: 100, alignment: .leading)
            .padding(14)
            .background(.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }
}

struct RipoLogoView: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.blue, Color.indigo, Color.teal],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            Text("R")
                .font(.system(size: 44, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
        }
        .frame(width: 92, height: 92)
        .shadow(color: .blue.opacity(0.35), radius: 16, x: 0, y: 8)
    }
}

struct NotesWorkspaceView: View {
    @ObservedObject var container: DemoContainer
    let onHome: () -> Void

    var body: some View {
        TabView {
            NavigationStack {
                DemoProfileView(viewModel: container.profileViewModel)
            }
            .tabItem { Text("Profile") }

            NavigationStack {
                InboxView(viewModel: container.inboxViewModel)
            }
            .tabItem { Text("Inbox") }

            NavigationStack {
                NoteEditorView(viewModel: container.noteEditorViewModel)
            }
            .tabItem { Text("Editor") }

            NavigationStack {
                TemplateStudioView(viewModel: container.templateStudioViewModel)
            }
            .tabItem { Text("Templates") }

            NavigationStack {
                TagCloudView(viewModel: container.tagCloudViewModel)
            }
            .tabItem { Text("Tags") }

            NavigationStack {
                JournalArchiveView(viewModel: container.journalArchiveViewModel)
            }
            .tabItem { Text("Archive") }
        }
        .overlay(alignment: .topLeading) {
            Button("Home") { onHome() }
                .padding(10)
        }
    }
}

@MainActor
final class DemoProfileViewModel: ObservableObject {
    @Published var username: String = ""
    @Published var avatarPath: String = ""
    @Published var message: String?
    @Published var errorMessage: String?

    private let ownerUserId: UUID
    private let service: UserProfileService

    init(ownerUserId: UUID, service: UserProfileService) {
        self.ownerUserId = ownerUserId
        self.service = service
    }

    func load() async {
        message = "Set your unique username and avatar path."
    }

    func save() async {
        do {
            let profile = try await service.upsertProfile(
                userId: ownerUserId,
                username: username,
                avatarPath: avatarPath.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : avatarPath
            )
            message = "Saved profile: @\(profile.username)"
            errorMessage = nil
        } catch {
            errorMessage = String(describing: error)
        }
    }
}

struct DemoProfileView: View {
    @ObservedObject var viewModel: DemoProfileViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Profile")
                .font(.largeTitle)
                .bold()
            TextField("Unique username", text: $viewModel.username)
                .textFieldStyle(.roundedBorder)
            TextField("Avatar path (/tmp/me.jpg)", text: $viewModel.avatarPath)
                .textFieldStyle(.roundedBorder)
            Button("Save Profile") {
                Task { await viewModel.save() }
            }
            .buttonStyle(.borderedProminent)

            if let message = viewModel.message {
                Text(message)
                    .foregroundStyle(.green)
            }
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
            }
            Spacer()
        }
        .padding()
        .navigationTitle("Profile")
    }
}
