import Foundation
import RipoDomain
import RipoUseCases

@MainActor
public final class TagCloudViewModel: ObservableObject {
    @Published public private(set) var items: [TagCloudItem] = []
    @Published public var query: String = ""
    @Published public private(set) var errorMessage: String?

    private let ownerUserId: UUID
    private let taggingService: TaggingService

    public init(ownerUserId: UUID, taggingService: TaggingService) {
        self.ownerUserId = ownerUserId
        self.taggingService = taggingService
    }

    public var filteredItems: [TagCloudItem] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return items }
        return items.filter { $0.tag.contains(q) }
    }

    public func load() async {
        do {
            items = try await taggingService.tagCloud(ownerUserId: ownerUserId)
            errorMessage = nil
        } catch {
            errorMessage = String(describing: error)
        }
    }
}
