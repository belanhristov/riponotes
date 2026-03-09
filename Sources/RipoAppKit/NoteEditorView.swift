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
                Text("Tags")
                    .font(.headline)
                HStack(spacing: 8) {
                    TextField("Add tag (#travel, idea...)", text: $viewModel.newNoteTagText)
                        .textFieldStyle(.roundedBorder)
                    Button("Add Tag") {
                        Task { await viewModel.addNoteTag() }
                    }
                    .buttonStyle(.bordered)
                }
                if viewModel.noteTags.isEmpty {
                    Text("No tags yet")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(viewModel.noteTags, id: \.self) { tag in
                                HStack(spacing: 4) {
                                    Text("#\(tag)")
                                    Button("x") {
                                        Task { await viewModel.removeNoteTag(tag) }
                                    }
                                    .buttonStyle(.borderless)
                                }
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                    }
                }
            }

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
                    VStack(alignment: .leading, spacing: 6) {
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

                        HStack(spacing: 8) {
                            TextField("Attachment tag", text: Binding(
                                get: { viewModel.attachmentTagInputs[attachment.id] ?? "" },
                                set: { viewModel.attachmentTagInputs[attachment.id] = $0 }
                            ))
                            .textFieldStyle(.roundedBorder)
                            Button("Add") {
                                Task { await viewModel.addAttachmentTag(attachmentId: attachment.id) }
                            }
                            .buttonStyle(.bordered)
                        }

                        if !attachment.tags.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 6) {
                                    ForEach(attachment.tags.sorted(), id: \.self) { tag in
                                        HStack(spacing: 4) {
                                            Text("#\(tag)")
                                            Button("x") {
                                                Task {
                                                    await viewModel.removeAttachmentTag(
                                                        attachmentId: attachment.id,
                                                        tag: tag
                                                    )
                                                }
                                            }
                                            .buttonStyle(.borderless)
                                        }
                                        .font(.caption2)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.orange.opacity(0.14))
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                    }
                                }
                            }
                        }
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

            if let tagError = viewModel.tagError {
                Text(tagError)
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
