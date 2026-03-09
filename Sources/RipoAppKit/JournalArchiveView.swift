import SwiftUI

public struct JournalArchiveView: View {
    @ObservedObject private var viewModel: JournalArchiveViewModel

    public init(viewModel: JournalArchiveViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                DatePicker("Month", selection: $viewModel.monthAnchor, displayedComponents: .date)
                    .labelsHidden()
                TextField("Mood filter (sad, calm...)", text: $viewModel.moodFilter)
                    .textFieldStyle(.roundedBorder)
                Button("Refresh") {
                    Task { await viewModel.loadSelectedMonth() }
                }
                .buttonStyle(.bordered)
            }

            List(viewModel.filteredCards) { card in
                VStack(alignment: .leading, spacing: 4) {
                    Text(card.title).font(.headline)
                    Text(card.excerpt)
                        .font(.footnote)
                        .foregroundStyle(card.isEncrypted ? .orange : .secondary)
                    HStack(spacing: 8) {
                        if let mood = card.moodTag {
                            Text("#\(mood)")
                        }
                        if let dayPart = card.dayPartTag {
                            Text("#\(dayPart)")
                        }
                        Text(card.createdAt.formatted(date: .abbreviated, time: .omitted))
                    }
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                }
            }

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }
        }
        .padding()
        .navigationTitle("Journal Archive")
        .task {
            await viewModel.loadSelectedMonth()
        }
    }
}
