import SwiftUI
import RipoDomain
import RipoUseCases

public struct JournalWorkspaceView: View {
    @ObservedObject private var viewModel: JournalWorkspaceViewModel
    @State private var passcodeInput: String = ""

    public init(viewModel: JournalWorkspaceViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ScrollView {
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

                Button("Context Mode") {
                    Task { await viewModel.startFromContextSuggestion() }
                }
                .buttonStyle(.bordered)

                Button("Save Entry") {
                    Task { await viewModel.saveCurrentEntry() }
                }
                .buttonStyle(.bordered)

                if viewModel.isCurrentEntryEncrypted {
                    Button("Secure Preview") {
                        Task { await viewModel.decryptCurrentEntryToPreview() }
                    }
                    .buttonStyle(.bordered)

                    Button("Decrypt Entry") {
                        Task { await viewModel.decryptCurrentEntryIfNeeded() }
                    }
                    .buttonStyle(.bordered)
                }
            }

                HStack(spacing: 8) {
                Picker("Mood", selection: $viewModel.selectedMood) {
                    ForEach(JourneyMood.allCases, id: \.self) { mood in
                        Text(mood.title).tag(mood)
                    }
                }
                Picker("Time", selection: $viewModel.selectedDayPart) {
                    ForEach(JourneyDayPart.allCases, id: \.self) { dayPart in
                        Text(dayPart.title).tag(dayPart)
                    }
                }
                Toggle("Auto Template", isOn: $viewModel.useAutoTemplate)
                Toggle("Encrypt On Save", isOn: $viewModel.encryptOnSave)
            }

                if let suggestion = viewModel.contextSuggestion {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Suggested Mode: \(suggestion.title)")
                        .font(.headline)
                    Text(suggestion.body)
                        .font(.footnote)
                    Text("Hints: \(suggestion.templateHints.joined(separator: ", "))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.secondary.opacity(0.08))
                )
            }

                if let preview = viewModel.decryptedPreviewText {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Secure Preview (Read Only)")
                        .font(.headline)
                    ScrollView {
                        Text(preview)
                            .font(.footnote)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(minHeight: 100, maxHeight: 180)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.green.opacity(0.08))
                )
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
                .frame(minHeight: 180)

                TextEditor(text: $viewModel.templateVariablesText)
                .frame(minHeight: 80)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                )

                if viewModel.isLockEnabled && !viewModel.isUnlocked {
                VStack(spacing: 8) {
                    Text("Journal Locked")
                        .font(.headline)
                    Text("Unlock to continue writing or viewing your journal.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, minHeight: 180)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.secondary.opacity(0.08))
                )
                } else {
                    NoteEditorView(viewModel: viewModel.noteEditorViewModel)
                }

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
            }
            .padding()
        }
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
