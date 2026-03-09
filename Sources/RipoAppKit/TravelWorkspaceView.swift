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

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
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
