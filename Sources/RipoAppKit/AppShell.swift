import Foundation

public enum AppSection: String, CaseIterable, Identifiable, Sendable {
    case inbox
    case today
    case notes
    case lists
    case people
    case calendar
    case search
    case settings

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .inbox: return "Inbox"
        case .today: return "Today"
        case .notes: return "Notes"
        case .lists: return "Lists"
        case .people: return "People"
        case .calendar: return "Calendar"
        case .search: return "Search"
        case .settings: return "Settings"
        }
    }
}

@MainActor
public final class AppShellViewModel: ObservableObject {
    @Published public var selectedSection: AppSection = .inbox

    public init() {}

    public func open(_ section: AppSection) {
        selectedSection = section
    }
}
