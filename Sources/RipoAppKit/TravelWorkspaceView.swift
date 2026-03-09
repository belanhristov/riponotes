import SwiftUI
import RipoDomain

public struct TravelWorkspaceView: View {
    @ObservedObject private var viewModel: TravelWorkspaceViewModel

    @State private var flightProvider: String = "THY"
    @State private var flightCode: String = ""
    @State private var hotelName: String = ""
    @State private var hotelCode: String = ""
    @State private var checklistText: String = ""
    @State private var packingText: String = ""
    @State private var budgetDaily: String = "100"
    @State private var weatherLat: String = ""
    @State private var weatherLon: String = ""

    public init(viewModel: TravelWorkspaceViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                TextField("Trip title", text: $viewModel.draftTitle)
                TextField("Origin", text: $viewModel.draftOrigin)
                TextField("Destination", text: $viewModel.draftDestination)
            }
            .textFieldStyle(.roundedBorder)

            HStack(spacing: 8) {
                DatePicker("Start", selection: $viewModel.draftStartDate, displayedComponents: [.date])
                DatePicker("End", selection: $viewModel.draftEndDate, displayedComponents: [.date])
                TextField("Base", text: $viewModel.draftBaseCurrency)
                TextField("Target", text: $viewModel.draftTargetCurrency)
                Button("Create Trip") { Task { await viewModel.createTripFromDraft() } }
                    .buttonStyle(.borderedProminent)
            }

            List(viewModel.trips, selection: selectedBinding) { trip in
                VStack(alignment: .leading, spacing: 4) {
                    Text(trip.title).font(.headline)
                    Text("\(trip.origin) -> \(trip.destination)")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(minHeight: 110)

            VStack(alignment: .leading, spacing: 8) {
                Text("Trip Tags")
                    .font(.headline)
                HStack(spacing: 8) {
                    TextField("Add trip tag", text: $viewModel.newTripTagText)
                    Button("Add Tag") { Task { await viewModel.addTripTag() } }
                        .buttonStyle(.bordered)
                }
                .textFieldStyle(.roundedBorder)
                if !viewModel.selectedTripTags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(viewModel.selectedTripTags, id: \.self) { tag in
                                HStack(spacing: 4) {
                                    Text("#\(tag)")
                                    Button("x") { Task { await viewModel.removeTripTag(tag) } }
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
                Text("Trip Images")
                    .font(.headline)
                HStack(spacing: 8) {
                    TextField("Image path (/tmp/trip.jpg)", text: $viewModel.newTripImagePath)
                    Button("Add Image") { Task { await viewModel.addTripImage() } }
                        .buttonStyle(.bordered)
                }
                .textFieldStyle(.roundedBorder)

                ForEach(viewModel.tripAttachments) { attachment in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(attachment.localPath)
                            .font(.footnote)
                            .lineLimit(1)
                        HStack(spacing: 8) {
                            TextField("Image tag", text: Binding(
                                get: { viewModel.tripAttachmentTagInputs[attachment.id] ?? "" },
                                set: { viewModel.tripAttachmentTagInputs[attachment.id] = $0 }
                            ))
                            Button("Add") { Task { await viewModel.addTagToTripImage(attachmentId: attachment.id) } }
                                .buttonStyle(.bordered)
                        }
                        .textFieldStyle(.roundedBorder)

                        if !attachment.tags.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 6) {
                                    ForEach(attachment.tags.sorted(), id: \.self) { tag in
                                        HStack(spacing: 4) {
                                            Text("#\(tag)")
                                            Button("x") {
                                                Task { await viewModel.removeTagFromTripImage(attachmentId: attachment.id, tag: tag) }
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

                        HStack(spacing: 8) {
                            Button("Share X") {
                                Task { await viewModel.previewShare(attachmentId: attachment.id, platform: .x) }
                            }
                            .buttonStyle(.bordered)
                            Button("Share Instagram") {
                                Task { await viewModel.previewShare(attachmentId: attachment.id, platform: .instagram) }
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }
            }

            HStack(spacing: 8) {
                TextField("Flight Provider", text: $flightProvider)
                TextField("Code", text: $flightCode)
                Button("Add Flight") {
                    Task {
                        await viewModel.addFlight(
                            providerName: flightProvider,
                            confirmationCode: flightCode,
                            departureAt: viewModel.draftStartDate,
                            arrivalAt: viewModel.draftStartDate.addingTimeInterval(60 * 60 * 2)
                        )
                    }
                }
                .buttonStyle(.bordered)
            }
            .textFieldStyle(.roundedBorder)

            HStack(spacing: 8) {
                TextField("Hotel", text: $hotelName)
                TextField("Code", text: $hotelCode)
                Button("Add Hotel") {
                    Task {
                        await viewModel.addHotel(
                            hotelName: hotelName,
                            confirmationCode: hotelCode,
                            checkIn: viewModel.draftStartDate,
                            checkOut: viewModel.draftEndDate
                        )
                    }
                }
                .buttonStyle(.bordered)
            }
            .textFieldStyle(.roundedBorder)

            HStack(spacing: 8) {
                TextField("Checklist item", text: $checklistText)
                Button("Add Checklist") {
                    Task { await viewModel.addChecklist(text: checklistText, category: .documents, isCritical: true) }
                }
                .buttonStyle(.bordered)
            }
            .textFieldStyle(.roundedBorder)

            HStack(spacing: 8) {
                TextField("Packing item", text: $packingText)
                Button("Add Packing") {
                    Task { await viewModel.addPacking(text: packingText, category: .clothes, quantity: 1, isCritical: false) }
                }
                .buttonStyle(.bordered)
                Button("Smart Packing (PackPoint)") {
                    Task {
                        await viewModel.generateSmartPacking(
                            weather: .sunny,
                            activities: [.beach, .cityWalk],
                            travelers: 1,
                            laundryAccess: false
                        )
                    }
                }
                .buttonStyle(.bordered)
            }
            .textFieldStyle(.roundedBorder)

            HStack(spacing: 8) {
                TextField("Daily budget", text: $budgetDaily)
                Button("Estimate Budget") {
                    Task {
                        await viewModel.estimateBudget(dailySpendInBaseCurrency: Double(budgetDaily) ?? 0)
                    }
                }
                .buttonStyle(.bordered)

                TextField("Lat", text: $weatherLat)
                TextField("Lon", text: $weatherLon)
                Button("Weather") {
                    Task {
                        await viewModel.refreshWeather(
                            latitude: Double(weatherLat) ?? 0,
                            longitude: Double(weatherLon) ?? 0
                        )
                    }
                }
                .buttonStyle(.bordered)
                Button("FX") {
                    Task { await viewModel.refreshFxQuote() }
                }
                .buttonStyle(.bordered)
            }
            .textFieldStyle(.roundedBorder)

            HStack(spacing: 8) {
                TextField("Breakfast", text: $viewModel.expenseBreakfast)
                TextField("Lunch", text: $viewModel.expenseLunch)
                TextField("Dinner", text: $viewModel.expenseDinner)
                TextField("Drinks", text: $viewModel.expenseDrinks)
                TextField("Transport", text: $viewModel.expenseTransport)
                TextField("Misc", text: $viewModel.expenseMisc)
                Button("Estimate From Profile") {
                    Task { await viewModel.estimateBudgetFromProfile() }
                }
                .buttonStyle(.bordered)
            }
            .textFieldStyle(.roundedBorder)

            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Segments: \(viewModel.segments.count)")
                    Text("Checklist: \(viewModel.checklistItems.count)")
                    Text("Packing: \(viewModel.packingItems.count)")
                }

                if let budget = viewModel.budgetEstimate {
                    Text("Budget: \(String(format: "%.2f", budget.estimatedTotal)) \(budget.currency)")
                }
                if let weather = viewModel.weatherSummary {
                    Text("Weather: \(weather.condition.rawValue) \(String(format: "%.1f", weather.temperatureCelsius))C")
                }
            }
            .font(.footnote)

            if let fx = viewModel.fxQuote {
                let ageMinutes = TravelWorkspaceViewModel.fxAgeMinutes(quotedAt: fx.quotedAt)
                let isStale = TravelWorkspaceViewModel.fxIsStale(quotedAt: fx.quotedAt)
                HStack {
                    Text("FX")
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.blue.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    Text("1 \(fx.baseCurrency) = \(String(format: "%.4f", fx.rate)) \(fx.targetCurrency)")
                        .font(.footnote)
                    Text(fx.source == .cached ? "cached" : "live")
                        .font(.caption2)
                        .foregroundStyle(fx.source == .cached ? .orange : .green)
                    Text("updated \(ageMinutes)m ago")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    if isStale {
                        Text("stale")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                    }
                }
            }

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }

            if let preview = viewModel.socialSharePreview {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Share Preview (\(preview.platform.rawValue))")
                        .font(.headline)
                    Text(preview.message)
                        .font(.footnote)
                    if let shareURL = preview.shareURL {
                        Text(shareURL)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.secondary.opacity(0.08))
                )
            }
        }
        .padding()
        .navigationTitle("Travel")
        .task {
            await viewModel.loadTrips()
        }
    }

    private var selectedBinding: Binding<UUID?> {
        Binding(
            get: { viewModel.selectedTripId },
            set: { newValue in
                Task { await viewModel.selectTrip(newValue) }
            }
        )
    }
}
