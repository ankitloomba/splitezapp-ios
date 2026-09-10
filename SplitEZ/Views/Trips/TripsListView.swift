import SwiftUI

struct TripsListView: View {
    @State private var trips: [Trip] = []
    @State private var isLoading = true
    @State private var showCreate = false
    private let api = APIClient.shared

    var body: some View {
        NavigationStack {
            List {
                ForEach(trips) { trip in
                    NavigationLink(destination: TripDetailView(trip: trip)) {
                        HStack {
                            Image(systemName: "airplane")
                                .foregroundColor(SplitEZTheme.accent)
                                .frame(width: 40, height: 40)
                                .background(SplitEZTheme.accent.opacity(0.1))
                                .clipShape(Circle())
                            VStack(alignment: .leading) {
                                Text(trip.name).font(.headline)
                                if let dest = trip.destination {
                                    Text(dest).font(.caption).foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .overlay {
                if trips.isEmpty && !isLoading {
                    ContentUnavailableView("No Trips",
                        systemImage: "airplane",
                        description: Text("Plan a trip and track expenses"))
                }
            }
            .navigationTitle("Trips")
            .toolbar {
                Button { showCreate = true } label: { Image(systemName: "plus") }
            }
            .sheet(isPresented: $showCreate) {
                CreateTripView { await loadTrips() }
            }
            .refreshable { await loadTrips() }
            .task { await loadTrips() }
        }
    }

    private func loadTrips() async {
        isLoading = true
        trips = (try? await api.get("/trips")) ?? []
        isLoading = false
    }
}

struct TripDetailView: View {
    let trip: Trip
    @State private var expenses: [Expense] = []
    @State private var showAddExpense = false
    private let api = APIClient.shared

    var body: some View {
        List {
            Section("Details") {
                if let dest = trip.destination { Label(dest, systemImage: "mappin") }
                if let start = trip.startDate {
                    Label(String(start.prefix(10)), systemImage: "calendar")
                }
                if let end = trip.endDate {
                    Label("Until \(String(end.prefix(10)))", systemImage: "calendar.badge.clock")
                }
                Label("\(trip.members?.count ?? 0) members", systemImage: "person.2")
            }
            Section("Members") {
                ForEach(trip.members ?? [], id: \.id) { member in
                    HStack {
                        AvatarView(user: member, size: 32)
                        Text(member.displayName)
                    }
                }
            }
            Section("Expenses (\(expenses.count))") {
                if expenses.isEmpty {
                    Text("No expenses yet")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
                ForEach(expenses) { expense in
                    ExpenseRow(expense: expense)
                }
            }
        }
        .navigationTitle(trip.name)
        .toolbar {
            Button { showAddExpense = true } label: {
                Image(systemName: "plus")
            }
        }
        .sheet(isPresented: $showAddExpense) {
            CreateExpenseView(
                groupId: nil,
                tripId: trip.id,
                members: trip.members ?? [],
                onCreated: { await loadExpenses() }
            )
        }
        .task { await loadExpenses() }
    }

    private func loadExpenses() async {
        expenses = (try? await api.get("/expenses", query: ["tripId": trip.id])) ?? []
    }
}

struct CreateTripView: View {
    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    @State private var destination = ""
    @State private var startDate = Date()
    @State private var endDate = Date().addingTimeInterval(86400 * 3)
    @State private var showDates = false
    @State private var isLoading = false
    let onCreated: () async -> Void
    private let api = APIClient.shared
    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    var body: some View {
        NavigationStack {
            Form {
                Section("Trip Info") {
                    TextField("Trip Name", text: $name)
                    TextField("Destination (optional)", text: $destination)
                }
                Section("Dates") {
                    Toggle("Set dates", isOn: $showDates)
                    if showDates {
                        DatePicker("Start", selection: $startDate, displayedComponents: .date)
                        DatePicker("End", selection: $endDate, in: startDate..., displayedComponents: .date)
                    }
                }
            }
            .navigationTitle("New Trip")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        Task {
                            isLoading = true
                            let _: Trip? = try? await api.post("/trips", body: CreateTripRequest(
                                name: name,
                                destination: destination.isEmpty ? nil : destination,
                                startDate: showDates ? dateFormatter.string(from: startDate) : nil,
                                endDate: showDates ? dateFormatter.string(from: endDate) : nil
                            ))
                            await onCreated()
                            isLoading = false
                            dismiss()
                        }
                    }
                    .disabled(name.isEmpty || isLoading)
                }
            }
        }
    }
}
