import SwiftUI
import RipoUseCases

public struct NoteEditorView: View {
    @ObservedObject private var viewModel: NoteEditorViewModel
    @State private var selectedFontName: String = "Sans Serif"
    @State private var selectedFontSize: Int = 15

    private let fontNames: [String] = ["Sans Serif", "Serif", "Mono"]
    private let fontSizes: [Int] = [12, 14, 15, 16, 18, 20, 24]

    public init(viewModel: NoteEditorViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        Menu {
                            Button("Yeni bağlantılı not") { insertSnippet("Linked note: ") }
                            Button("Görev") { viewModel.applyToolbar(.toggleChecklist) }
                            Button("Takvim Etkinliği") { insertSnippet("Calendar event: ") }
                            Button("Bağlantı") { insertSnippet("https://") }
                            Button("Not bağlantısı") { insertSnippet("Note link: ") }
                            Button("Tablo") { insertSnippet("| Col 1 | Col 2 |\n|---|---|\n|  |  |") }
                            Button("Bölücü") { viewModel.applyToolbar(.insertDivider(afterLine: nil)) }
                            Button("Ek") { insertSnippet("Attachment: ") }
                            Button("Resim") { insertSnippet("![image](path)") }
                            Button("Alıntı") { viewModel.applyToolbar(.toggleQuote) }
                            Button("Onay Kutusu") { viewModel.applyToolbar(.toggleChecklist) }
                            Button("İçindekiler") { insertSnippet("## İçindekiler\n- ") }
                            Button("Ses Kaydı") { insertSnippet("Voice note: ") }
                            Button("Kod Bloku") { viewModel.applyToolbar(.toggleCodeFence) }
                            Button("Formül") { insertSnippet("Formula: ") }
                            Button("Çizim") { insertSnippet("Drawing note: ") }
                            Button("Şu anki tarih") { insertSnippet(Date.now.formatted(date: .abbreviated, time: .omitted)) }
                            Button("Şu anki zaman") { insertSnippet(Date.now.formatted(date: .omitted, time: .shortened)) }
                            Button("Google Drive") { insertSnippet("Google Drive: ") }
                        } label: {
                            Label("Ekle", systemImage: "plus.circle.fill")
                        }
                        .buttonStyle(.borderless)

                        Picker("Font", selection: $selectedFontName) {
                            ForEach(fontNames, id: \.self) { name in
                                Text(name).tag(name)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(width: 140)

                        Picker("Size", selection: $selectedFontSize) {
                            ForEach(fontSizes, id: \.self) { size in
                                Text("\(size)").tag(size)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(width: 72)

                        Button("B") { viewModel.applyToolbar(.toggleBold) }
                            .fontWeight(.bold)
                        Button("I") { viewModel.applyToolbar(.toggleItalic) }
                            .italic()
                        Button("U") { viewModel.applyToolbar(.toggleUnderline) }
                            .underline()

                        Menu("Daha fazla") {
                            Button("Bullets") { viewModel.applyToolbar(.toggleBulletedList) }
                            Button("Numbers") { viewModel.applyToolbar(.toggleNumberedList) }
                            Button("Quote") { viewModel.applyToolbar(.toggleQuote) }
                            Button("Code") { viewModel.applyToolbar(.toggleCodeFence) }
                            Button("Time") { viewModel.applyToolbar(.insertTimestamp) }
                            Button("Indent") { viewModel.applyToolbar(.indent) }
                            Button("Outdent") { viewModel.applyToolbar(.outdent) }
                            Button("Heading +") { viewModel.applyToolbar(.increaseHeading) }
                            Button("Heading -") { viewModel.applyToolbar(.decreaseHeading) }
                        }
                    }
                    .padding(8)
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            toolbarButton("Indent") { viewModel.applyToolbar(.indent) }
                            toolbarButton("Outdent") { viewModel.applyToolbar(.outdent) }
                            toolbarButton("H+") { viewModel.applyToolbar(.increaseHeading) }
                            toolbarButton("H-") { viewModel.applyToolbar(.decreaseHeading) }
                            toolbarButton("Checklist") { viewModel.applyToolbar(.toggleChecklist) }
                            toolbarButton("Bullets") { viewModel.applyToolbar(.toggleBulletedList) }
                            toolbarButton("Numbers") { viewModel.applyToolbar(.toggleNumberedList) }
                            toolbarButton("Quote") { viewModel.applyToolbar(.toggleQuote) }
                            toolbarButton("Code") { viewModel.applyToolbar(.toggleCodeFence) }
                            toolbarButton("Time") { viewModel.applyToolbar(.insertTimestamp) }
                            toolbarButton("Divider") { viewModel.applyToolbar(.insertDivider(afterLine: nil)) }
                        }
                    }
                }

                TextField("Title", text: $viewModel.title)
                    .textFieldStyle(.roundedBorder)

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

                VStack(alignment: .leading, spacing: 8) {
                    Text("Convert")
                        .font(.headline)

                HStack(spacing: 8) {
                    DatePicker("Reminder", selection: $viewModel.convertReminderAt, displayedComponents: [.date, .hourAndMinute])
                    Button("To Reminder") {
                        Task { await viewModel.convertToReminder() }
                    }
                    .buttonStyle(.bordered)
                }

                HStack(spacing: 8) {
                    TextField("List title", text: $viewModel.convertListTitle)
                        .textFieldStyle(.roundedBorder)
                    Button("To List") {
                        Task { await viewModel.convertToList() }
                    }
                    .buttonStyle(.bordered)
                }
                TextEditor(text: $viewModel.convertListItemsText)
                    .frame(minHeight: 60)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                    )

                HStack(spacing: 8) {
                    TextField("Contact id", text: $viewModel.convertContactIdentifier)
                    TextField("Contact name", text: $viewModel.convertContactDisplayName)
                    Button("To Contact") {
                        Task { await viewModel.convertToContactLink() }
                    }
                    .buttonStyle(.bordered)
                }
                .textFieldStyle(.roundedBorder)

                HStack(spacing: 8) {
                    TextField("Location label", text: $viewModel.convertLocationLabel)
                    TextField("Lat", text: $viewModel.convertLatitude)
                    TextField("Lon", text: $viewModel.convertLongitude)
                    TextField("Radius", text: $viewModel.convertRadiusMeters)
                    Button("To Location") {
                        Task { await viewModel.convertToLocationLink() }
                    }
                    .buttonStyle(.bordered)
                }
                .textFieldStyle(.roundedBorder)
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

            if let convertMessage = viewModel.convertMessage {
                Text(convertMessage)
                    .font(.footnote)
                    .foregroundStyle(.green)
            }

            if let convertError = viewModel.convertError {
                Text(convertError)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }
            }
            .padding()
        }
        .navigationTitle("Edit Note")
    }

    private func toolbarButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(title, action: action)
            .buttonStyle(.bordered)
    }

    private func insertSnippet(_ text: String) {
        if viewModel.body.isEmpty {
            viewModel.body = text
        } else {
            viewModel.body += "\n" + text
        }
    }
}
