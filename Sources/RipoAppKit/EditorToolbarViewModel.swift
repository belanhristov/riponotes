import Foundation
import RipoUseCases

@MainActor
public final class EditorToolbarViewModel: ObservableObject {
    private let toolbarService: EditorToolbarService

    public init(toolbarService: EditorToolbarService = EditorToolbarService()) {
        self.toolbarService = toolbarService
    }

    public func apply(
        _ command: EditorCommand,
        text: String,
        lineRange: ClosedRange<Int>? = nil
    ) throws -> String {
        try toolbarService.apply(command, to: text, lineRange: lineRange)
    }
}
