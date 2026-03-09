import SwiftUI
import RipoUseCases

public struct NoteEditorView: View {
    @ObservedObject private var viewModel: NoteEditorViewModel

    public init(viewModel: NoteEditorViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(spacing: 12) {
            TextField("Title", text: $viewModel.title)
                .textFieldStyle(.roundedBorder)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    toolbarButton("Indent") { viewModel.applyToolbar(.indent) }
                    toolbarButton("Outdent") { viewModel.applyToolbar(.outdent) }
                    toolbarButton("H+") { viewModel.applyToolbar(.increaseHeading) }
                    toolbarButton("H-") { viewModel.applyToolbar(.decreaseHeading) }
                    toolbarButton("Checklist") { viewModel.applyToolbar(.toggleChecklist) }
                    toolbarButton("Divider") { viewModel.applyToolbar(.insertDivider(afterLine: nil)) }
                }
            }

            TextEditor(text: $viewModel.body)
                .frame(minHeight: 220)
                .padding(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                )

            VStack(alignment: .leading, spacing: 8) {
                Text("Images")
                    .font(.headline)

                HStack(spacing: 8) {
                    TextField("Image path (/tmp/note.jpg)", text: $viewModel.newAttachmentPath)
                        .textFieldStyle(.roundedBorder)
                    Button("Add") {
                        Task { await viewModel.addImageAttachment() }
                    }
                    .buttonStyle(.bordered)
                }

                ForEach(viewModel.noteAttachments) { attachment in
                    HStack {
                        Text(attachment.localPath)
                            .lineLimit(1)
                            .font(.footnote)
                        Spacer()
                        Button("Remove") {
                            Task { await viewModel.removeAttachment(attachment.id) }
                        }
                        .buttonStyle(.borderless)
                    }
                }
            }

            if let toolbarError = viewModel.toolbarError {
                Text(toolbarError)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }

            if let attachmentError = viewModel.attachmentError {
                Text(attachmentError)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }
        }
        .padding()
        .navigationTitle("Edit Note")
    }

    private func toolbarButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(title, action: action)
            .buttonStyle(.bordered)
    }
}
