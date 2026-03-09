import SwiftUI
import RipoDomain

public struct TemplateStudioView: View {
    @ObservedObject private var viewModel: TemplateStudioViewModel

    public init(viewModel: TemplateStudioViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                HStack(spacing: 8) {
                TextField("Template Name", text: $viewModel.draftName)
                    .textFieldStyle(.roundedBorder)

                Button("Create") {
                    Task { await viewModel.createTemplateFromDraft() }
                }
                .buttonStyle(.borderedProminent)

                Button("Clone Selected") {
                    Task { await viewModel.cloneSelectedTemplate(newName: "Template Copy") }
                }
                .buttonStyle(.bordered)

                Button("Save Edits") {
                    Task { await viewModel.saveSelectedTemplateEdits() }
                }
                .buttonStyle(.bordered)
            }

                List(viewModel.templates, selection: selectedBinding) { template in
                VStack(alignment: .leading, spacing: 4) {
                    Text(template.name).font(.headline)
                    Text("\(template.scope.rawValue) • \(template.type.rawValue)")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    viewModel.selectTemplate(template.id)
                }
                }
                .frame(minHeight: 180)

                HStack(spacing: 8) {
                Picker("Scope", selection: $viewModel.draftScope) {
                    ForEach(TemplateScope.allCases, id: \.self) { scope in
                        Text(scope.rawValue.capitalized).tag(scope)
                    }
                }
                Picker("Type", selection: $viewModel.draftType) {
                    ForEach(TemplateType.allCases, id: \.self) { type in
                        Text(type.rawValue.capitalized).tag(type)
                    }
                }
            }

                TextField("Title Template", text: $viewModel.draftTitleTemplate)
                    .textFieldStyle(.roundedBorder)

                ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    toolbarButton("Indent") { viewModel.applyToolbarToDraftBody(.indent) }
                    toolbarButton("Outdent") { viewModel.applyToolbarToDraftBody(.outdent) }
                    toolbarButton("H+") { viewModel.applyToolbarToDraftBody(.increaseHeading) }
                    toolbarButton("Checklist") { viewModel.applyToolbarToDraftBody(.toggleChecklist) }
                    toolbarButton("Divider") { viewModel.applyToolbarToDraftBody(.insertDivider(afterLine: nil)) }
                }
            }

                TextEditor(text: $viewModel.draftBodyTemplate)
                .frame(minHeight: 120)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                )
                .onChange(of: viewModel.draftBodyTemplate) {
                    viewModel.refreshPreview()
                }

                TextEditor(text: $viewModel.previewVariablesText)
                .frame(minHeight: 80)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                )
                .onChange(of: viewModel.previewVariablesText) {
                    viewModel.refreshPreview()
                }

                VStack(alignment: .leading, spacing: 4) {
                Text("Preview Title: \(viewModel.previewTitle)")
                    .font(.headline)
                Text(viewModel.previewBody)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

                VStack(alignment: .leading, spacing: 8) {
                Text("Template Images")
                    .font(.headline)

                HStack(spacing: 8) {
                    TextField("Image path (/tmp/example.jpg)", text: $viewModel.newAttachmentPath)
                        .textFieldStyle(.roundedBorder)
                    Button("Add Image") {
                        Task { await viewModel.addImageToSelectedTemplate() }
                    }
                    .buttonStyle(.bordered)
                }

                ForEach(viewModel.templateAttachments) { attachment in
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

                Button("Create Note From Selected") {
                Task {
                    _ = await viewModel.createNoteFromSelectedTemplate(
                        variables: ["title": "Quick Start", "body": "Start writing..."]
                    )
                }
                }
                .buttonStyle(.bordered)

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
            }
            .padding()
        }
        .navigationTitle("Template Studio")
        .task {
            await viewModel.load(scope: nil)
        }
    }

    private var selectedBinding: Binding<UUID?> {
        Binding(
            get: { viewModel.selectedTemplateId },
            set: { viewModel.selectTemplate($0) }
        )
    }

    private func toolbarButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(title, action: action)
            .buttonStyle(.bordered)
    }
}
