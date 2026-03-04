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
                        QuickActionButton(title: "+ Glucose") { selectedTab = 1 }
                        QuickActionButton(title: "+ Meal") { selectedTab = 3 }
                        QuickActionButton(title: "Calc Dose") { selectedTab = 2 }
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
            appLog("Dashboard appeared", category: "NAV")
            viewModel.loadData(modelContext: modelContext)
            Task { await viewModel.tryAutoConnect(modelContext: modelContext) }
            viewModel.startAutoRefresh(modelContext: modelContext)
        }
        .onDisappear {
            viewModel.stopAutoRefresh()
        }
        .onChange(of: selectedTab) { _, newTab in
            if newTab == 0 {
                appLog("Dashboard tab selected — reloading data", category: "NAV")
                viewModel.loadData(modelContext: modelContext)
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                appLog("Scene became active — reloading dashboard", category: "NAV")
                viewModel.loadData(modelContext: modelContext)
                Task { await viewModel.refreshDexcomData(modelContext: modelContext) }
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView(dashboardViewModel: viewModel)
        }
    }
}
