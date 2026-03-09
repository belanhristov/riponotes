import SwiftUI
import RipoDomain

public struct JournalWorkspaceView: View {
    @ObservedObject private var viewModel: JournalWorkspaceViewModel
    @State private var passcodeInput: String = ""

    public init(viewModel: JournalWorkspaceViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                TextField("Passcode", text: $passcodeInput)
                    .textFieldStyle(.roundedBorder)
                Button("Enable Lock") {
                    Task { await viewModel.enableLock(passcode: passcodeInput) }
                }
                .buttonStyle(.bordered)
                Button("Unlock") {
                    Task { await viewModel.unlockWithPasscode(passcodeInput) }
                }
                .buttonStyle(.bordered)
                Button("Biometric") {
                    Task { await viewModel.unlockWithBiometrics() }
                }
                .buttonStyle(.bordered)
                Button("Lock") {
                    Task { await viewModel.lockJournal() }
                }
                .buttonStyle(.bordered)
            }

            Text("Lock: \(viewModel.isLockEnabled ? "Enabled" : "Disabled") • Session: \(viewModel.isUnlocked ? "Unlocked" : "Locked")")
                .font(.footnote)
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                Button("New Journal Entry") {
                    Task { await viewModel.startBlankEntry() }
                }
                .buttonStyle(.borderedProminent)

                Button("Use Selected Template") {
                    Task { await viewModel.startFromSelectedTemplate() }
                }
                .buttonStyle(.bordered)
            }

            List(viewModel.journalTemplates, selection: selectedBinding) { template in
                VStack(alignment: .leading, spacing: 4) {
                    Text(template.name)
                        .font(.headline)
                    Text(template.type.rawValue.capitalized)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    viewModel.selectTemplate(template.id)
                }
            }

            TextEditor(text: $viewModel.templateVariablesText)
                .frame(minHeight: 80)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                )

            NoteEditorView(viewModel: viewModel.noteEditorViewModel)

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }
        }
        .padding()
        .navigationTitle("Journal")
        .task {
            await viewModel.load()
        }
    }

    private var selectedBinding: Binding<UUID?> {
        Binding(
            get: { viewModel.selectedTemplateId },
            set: { viewModel.selectTemplate($0) }
        )
    }
}
