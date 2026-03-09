import SwiftUI
import RipoDomain

public struct TemplateStudioView: View {
    @ObservedObject private var viewModel: TemplateStudioViewModel
    @State private var name: String = ""

    public init(viewModel: TemplateStudioViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                TextField("Template Name", text: $name)
                    .textFieldStyle(.roundedBorder)

                Button("Create") {
                    Task {
                        await viewModel.createTemplate(
                            name: name.isEmpty ? "Untitled Template" : name,
                            scope: .note,
                            type: .custom,
                            titleTemplate: "{{title}}",
                            bodyTemplate: "{{body}}"
                        )
                        name = ""
                    }
                }
                .buttonStyle(.borderedProminent)

                Button("Clone Selected") {
                    Task { await viewModel.cloneSelectedTemplate(newName: "Template Copy") }
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
}
