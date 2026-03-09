import Foundation
import RipoUseCases

@MainActor
public final class JournalArchiveViewModel: ObservableObject {
    @Published public private(set) var cards: [JournalMemoryCard] = []
    @Published public var moodFilter: String = ""
    @Published public var monthAnchor: Date = .now
    @Published public private(set) var errorMessage: String?

    private let ownerUserId: UUID
    private let archiveService: JournalArchiveService

    public init(ownerUserId: UUID, archiveService: JournalArchiveService) {
        self.ownerUserId = ownerUserId
        self.archiveService = archiveService
    }

    public var filteredCards: [JournalMemoryCard] {
        let mood = moodFilter.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !mood.isEmpty else { return cards }
        return cards.filter { $0.moodTag?.lowercased() == mood }
    }

    public func loadSelectedMonth() async {
        do {
            cards = try await archiveService.timeline(ownerUserId: ownerUserId, monthAnchor: monthAnchor)
            errorMessage = nil
        } catch {
            errorMessage = String(describing: error)
        }
    }
}
