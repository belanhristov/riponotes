import SwiftUI

public struct TagCloudView: View {
    @ObservedObject private var viewModel: TagCloudViewModel

    public init(viewModel: TagCloudViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(spacing: 12) {
            TextField("Search tag...", text: $viewModel.query)
                .textFieldStyle(.roundedBorder)

            List(viewModel.filteredItems) { item in
                HStack {
                    Text("#\(item.tag)")
                    Spacer()
                    Text("\(item.count)")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.secondary.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }
        }
        .padding()
        .navigationTitle("Tags")
        .task {
            await viewModel.load()
        }
    }
}
