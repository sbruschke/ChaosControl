import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @State private var viewModel = DashboardViewModel()
    @State private var showingSettings = false
    @Binding var selectedTab: Int

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Central gauge
                    GlucoseGaugeView(
                        value: viewModel.currentReading?.value ?? 0,
                        trend: viewModel.currentReading?.trend ?? .none,
                        timeInRange: viewModel.timeInRange
                    )

                    // Status
                    if let reading = viewModel.currentReading {
                        Text(viewModel.statusText)
                            .foregroundColor(ChaosTheme.glucoseColor(for: reading.value))
                    } else {
                        Text("Awaiting Data")
                            .foregroundStyle(.secondary)
                    }

                    Divider()

                    // Quick actions
                    HStack(spacing: 8) {
                        QuickActionButton(title: "+ Glucose") { }
                        QuickActionButton(title: "+ Meal") { }
                        QuickActionButton(title: "Calc Dose") { }
                    }

                    // Stat cards
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 10),
                        GridItem(.flexible(), spacing: 10)
                    ], spacing: 10) {
                        StatCard(
                            label: "ACTIVE INSULIN",
                            value: String(format: "%.1f", viewModel.activeInsulin),
                            unit: "u"
                        )
                        StatCard(
                            label: "LAST MEAL",
                            value: viewModel.lastMealTimeString
                        )
                        StatCard(
                            label: "CARBS TODAY",
                            value: "\(Int(viewModel.carbsToday))",
                            unit: "g"
                        )
                        StatCard(
                            label: "TIME IN RANGE",
                            value: "\(Int(viewModel.timeInRange))",
                            unit: "%",
                            valueColor: .green
                        )
                    }

                    // Recent readings
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Recent Readings")
                            .font(.headline)

                        if !viewModel.recentReadings.isEmpty {
                            SparklineView(readings: Array(viewModel.recentReadings.prefix(5).reversed()))

                            HStack {
                                ForEach(viewModel.recentReadings.prefix(5)) { reading in
                                    VStack(spacing: 2) {
                                        Text("\(reading.mgDL)")
                                            .font(.body)
                                        Text(reading.timestamp.formatted(.dateTime.hour().minute()))
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                            }
                        } else {
                            Text("No readings yet")
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 20)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Chaos Control")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingSettings = true } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
        }
        .onAppear {
            viewModel.loadData(modelContext: modelContext)
            Task { await viewModel.tryAutoConnect() }
            viewModel.startAutoRefresh(modelContext: modelContext)
        }
        .onDisappear {
            viewModel.stopAutoRefresh()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                viewModel.loadData(modelContext: modelContext)
                Task { await viewModel.refreshDexcomData(modelContext: modelContext) }
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView(dashboardViewModel: viewModel)
        }
    }
}
