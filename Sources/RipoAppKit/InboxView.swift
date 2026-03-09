import SwiftUI
import RipoDomain

public struct InboxView: View {
    @ObservedObject private var viewModel: InboxViewModel

    public init(viewModel: InboxViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                TextField("Brain dump...", text: $viewModel.brainDumpText)
                    .textFieldStyle(.roundedBorder)
                Button("Save") {
                    Task { _ = try? await viewModel.submitBrainDump() }
                }
                .buttonStyle(.borderedProminent)
            }

            if let brainDumpError = viewModel.brainDumpError {
                Text(brainDumpError)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }

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
        }
        .navigationTitle("Inbox")
    }
}
