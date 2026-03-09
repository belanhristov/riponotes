import Foundation
import RipoDomain
import RipoUseCases

@MainActor
public final class TravelWorkspaceViewModel: ObservableObject {
    @Published public private(set) var trips: [Trip] = []
    @Published public var selectedTripId: UUID?

    @Published public var draftTitle: String = ""
    @Published public var draftOrigin: String = ""
    @Published public var draftDestination: String = ""
    @Published public var draftStartDate: Date = .now
    @Published public var draftEndDate: Date = .now.addingTimeInterval(60.0 * 60.0 * 24.0 * 3.0)
    @Published public var draftBaseCurrency: String = "USD"
    @Published public var draftTargetCurrency: String = "EUR"

    @Published public private(set) var segments: [TripSegment] = []
    @Published public private(set) var checklistItems: [TripChecklistItem] = []
    @Published public private(set) var packingItems: [PackingItem] = []
    @Published public private(set) var budgetEstimate: TripBudgetEstimate?
    @Published public private(set) var weatherSummary: WeatherSnapshot?
    @Published public private(set) var fxQuote: TripFxQuote?
    @Published public var expenseBreakfast: String = "10"
    @Published public var expenseLunch: String = "20"
    @Published public var expenseDinner: String = "30"
    @Published public var expenseDrinks: String = "10"
    @Published public var expenseTransport: String = "10"
    @Published public var expenseMisc: String = "10"

    @Published public var errorMessage: String?

    private let ownerUserId: UUID
    private let tripRepository: TripRepository
    private let planner: TravelPlannerService
    private let smartPackingService: SmartPackingService?

    public init(
        ownerUserId: UUID,
        tripRepository: TripRepository,
        planner: TravelPlannerService,
        smartPackingService: SmartPackingService? = nil
    ) {
        self.ownerUserId = ownerUserId
        self.tripRepository = tripRepository
        self.planner = planner
        self.smartPackingService = smartPackingService
    }

    public func loadTrips() async {
        do {
            trips = try await tripRepository.trips(ownerUserId: ownerUserId)
            if selectedTripId == nil {
                selectedTripId = trips.first?.id
            }
            await loadSelectedTripDetails()
            errorMessage = nil
        } catch {
            errorMessage = String(describing: error)
        }
    }

    public func createTripFromDraft() async {
        do {
            let trip = try await planner.createTrip(
                ownerUserId: ownerUserId,
                title: draftTitle.isEmpty ? "Untitled Trip" : draftTitle,
                origin: draftOrigin,
                destination: draftDestination,
                startDate: draftStartDate,
                endDate: draftEndDate,
                baseCurrency: draftBaseCurrency,
                targetCurrency: draftTargetCurrency
            )
            await loadTrips()
            selectedTripId = trip.id
            await loadSelectedTripDetails()
            errorMessage = nil
        } catch {
            errorMessage = String(describing: error)
        }
    }

    public func selectTrip(_ id: UUID?) async {
        selectedTripId = id
        await loadSelectedTripDetails()
    }

    public func addFlight(providerName: String, confirmationCode: String, departureAt: Date, arrivalAt: Date) async {
        guard let selectedTripId else { return }
        do {
            _ = try await planner.addFlightSegment(
                tripId: selectedTripId,
                providerName: providerName,
                confirmationCode: confirmationCode,
                departureAt: departureAt,
                arrivalAt: arrivalAt
            )
            await loadSelectedTripDetails()
            errorMessage = nil
        } catch {
            errorMessage = String(describing: error)
        }
    }

    public func addHotel(hotelName: String, confirmationCode: String, checkIn: Date, checkOut: Date) async {
        guard let selectedTripId else { return }
        do {
            _ = try await planner.addHotelSegment(
                tripId: selectedTripId,
                hotelName: hotelName,
                confirmationCode: confirmationCode,
                checkIn: checkIn,
                checkOut: checkOut
            )
            await loadSelectedTripDetails()
            errorMessage = nil
        } catch {
            errorMessage = String(describing: error)
        }
    }

    public func addChecklist(text: String, category: TripChecklistCategory = .misc, isCritical: Bool = false) async {
        guard let selectedTripId else { return }
        do {
            _ = try await planner.addChecklistItem(
                tripId: selectedTripId,
                category: category,
                text: text,
                isCritical: isCritical
            )
            await loadSelectedTripDetails()
            errorMessage = nil
        } catch {
            errorMessage = String(describing: error)
        }
    }

    public func toggleChecklist(_ item: TripChecklistItem) async {
        do {
            _ = try await planner.toggleChecklistItem(item)
            await loadSelectedTripDetails()
            errorMessage = nil
        } catch {
            errorMessage = String(describing: error)
        }
    }

    public func addPacking(text: String, category: PackingCategory = .custom, quantity: Int = 1, isCritical: Bool = false) async {
        guard let selectedTripId else { return }
        do {
            _ = try await planner.addPackingItem(
                tripId: selectedTripId,
                category: category,
                text: text,
                quantity: quantity,
                isCritical: isCritical
            )
            await loadSelectedTripDetails()
            errorMessage = nil
        } catch {
            errorMessage = String(describing: error)
        }
    }

    public func togglePacking(_ item: PackingItem) async {
        do {
            _ = try await planner.togglePackingItem(item)
            await loadSelectedTripDetails()
            errorMessage = nil
        } catch {
            errorMessage = String(describing: error)
        }
    }

    public func estimateBudget(dailySpendInBaseCurrency: Double) async {
        guard let selectedTripId else { return }
        do {
            budgetEstimate = try await planner.estimateBudget(
                tripId: selectedTripId,
                dailySpendInBaseCurrency: dailySpendInBaseCurrency
            )
            errorMessage = nil
        } catch {
            errorMessage = String(describing: error)
        }
    }

    public func estimateBudgetFromProfile() async {
        guard let selectedTripId else { return }
        do {
            let profile = TripExpenseProfile(
                breakfastCost: Double(expenseBreakfast) ?? 0,
                lunchCost: Double(expenseLunch) ?? 0,
                dinnerCost: Double(expenseDinner) ?? 0,
                drinksCost: Double(expenseDrinks) ?? 0,
                transportCost: Double(expenseTransport) ?? 0,
                miscCost: Double(expenseMisc) ?? 0
            )
            budgetEstimate = try await planner.estimateBudgetFromExpenseProfile(
                tripId: selectedTripId,
                profile: profile
            )
            errorMessage = nil
        } catch {
            errorMessage = String(describing: error)
        }
    }

    public func refreshWeather(latitude: Double, longitude: Double) async {
        guard let selectedTripId else { return }
        do {
            weatherSummary = try await planner.weatherSummaryForTripDestination(
                tripId: selectedTripId,
                latitude: latitude,
                longitude: longitude
            )
            errorMessage = nil
        } catch {
            errorMessage = String(describing: error)
        }
    }

    public func refreshFxQuote() async {
        guard let selectedTripId else { return }
        do {
            fxQuote = try await planner.currentFxQuote(tripId: selectedTripId)
            errorMessage = nil
        } catch {
            errorMessage = String(describing: error)
        }
    }

    public func generateSmartPacking(
        weather: WeatherCondition,
        activities: [TravelActivity],
        travelers: Int = 1,
        laundryAccess: Bool = false
    ) async {
        guard let selectedTripId,
              let smartPackingService else { return }
        do {
            _ = try await smartPackingService.generateAndSave(
                tripId: selectedTripId,
                config: SmartPackingConfig(
                    weather: weather,
                    activities: activities,
                    travelers: travelers,
                    laundryAccess: laundryAccess
                )
            )
            await loadSelectedTripDetails()
            errorMessage = nil
        } catch {
            errorMessage = String(describing: error)
        }
    }

    private func loadSelectedTripDetails() async {
        guard let selectedTripId else {
            segments = []
            checklistItems = []
            packingItems = []
            budgetEstimate = nil
            weatherSummary = nil
            fxQuote = nil
            return
        }

        do {
            segments = try await tripRepository.segments(tripId: selectedTripId)
            checklistItems = try await tripRepository.checklistItems(tripId: selectedTripId)
            packingItems = try await tripRepository.packingItems(tripId: selectedTripId)
            budgetEstimate = try await tripRepository.budgetEstimate(tripId: selectedTripId)
        } catch {
            errorMessage = String(describing: error)
        }
    }
}
