import SwiftUI
import RipoDomain

public struct InboxView: View {
    @ObservedObject private var viewModel: InboxViewModel

    public init(viewModel: InboxViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        List(viewModel.notes) { note in
            VStack(alignment: .leading, spacing: 4) {
                Text(note.title)
                    .font(.headline)
                Text(note.plainTextBody)
                    .font(.subheadline)
                    .lineLimit(2)
                    .foregroundStyle(.secondary)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                viewModel.select(noteId: note.id)
            }
        }
        .navigationTitle("Inbox")
    }
}
