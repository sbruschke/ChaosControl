import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = DashboardViewModel()
    @State private var showingSettings = false

    var body: some View {
        ZStack {
            ChaosTheme.background.ignoresSafeArea()
            ConstructionLines(verticalOffset: 0.5, horizontalOffset: 0.35)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    header
                        .padding(.bottom, 6)

                    dateLine
                        .padding(.bottom, 16)

                    // Central gauge
                    gaugeSection
                        .padding(.bottom, 12)

                    // Status
                    statusSection
                        .padding(.bottom, 12)

                    RedDivider()
                        .padding(.bottom, 12)

                    // Quick actions
                    quickActions
                        .padding(.bottom, 12)

                    ChaosDivider()
                        .padding(.bottom, 14)

                    // Stat cards
                    statsGrid
                        .padding(.bottom, 14)

                    // Recent readings sparkline
                    recentReadings
                }
                .padding(.horizontal, ChaosTheme.screenPadding)
                .padding(.bottom, 20)
            }

            // Corner annotations
            VStack {
                HStack {
                    Spacer()
                    AnnotationText(text: "SYS.v0.1")
                }
                Spacer()
                HStack {
                    AnnotationText(text: "REF//042")
                    Spacer()
                    AnnotationText(text: "CC-DB-01")
                }
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 8)
            .allowsHitTesting(false)
        }
        .onAppear {
            viewModel.loadData(modelContext: modelContext)
            Task { await viewModel.tryAutoConnect() }
            viewModel.startAutoRefresh(modelContext: modelContext)
        }
        .onDisappear {
            viewModel.stopAutoRefresh()
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Text("CHAOS CONTROL")
                .font(ChaosTheme.titleFont)
                .foregroundColor(ChaosTheme.ink)
                .tracking(4)

            Spacer()

            Button { showingSettings = true } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 14, weight: .light))
                    .foregroundColor(ChaosTheme.ink.opacity(0.5))
            }
        }
    }

    private var dateLine: some View {
        HStack {
            Text(Date.now.formatted(.dateTime.day().month(.abbreviated).year()))
                .font(ChaosTheme.font(9))
                .foregroundColor(ChaosTheme.faded)
                .tracking(2)
                .textCase(.uppercase)

            Text("//")
                .font(ChaosTheme.font(9))
                .foregroundColor(ChaosTheme.red)

            Text(Date.now.formatted(.dateTime.hour().minute()))
                .font(ChaosTheme.font(9))
                .foregroundColor(ChaosTheme.faded)
                .tracking(2)

            Spacer()
        }
    }

    // MARK: - Gauge

    private var gaugeSection: some View {
        GlucoseGaugeView(
            value: viewModel.currentReading?.value ?? 0,
            trend: viewModel.currentReading?.trend ?? .none,
            timeInRange: viewModel.timeInRange
        )
    }

    // MARK: - Status

    private var statusSection: some View {
        VStack(spacing: 4) {
            Text("STATUS")
                .font(ChaosTheme.font(9))
                .foregroundColor(ChaosTheme.faded)
                .tracking(3)

            if let reading = viewModel.currentReading {
                Text(viewModel.statusText)
                    .font(ChaosTheme.font(11))
                    .foregroundColor(ChaosTheme.glucoseColor(for: reading.value))
                    .tracking(2)
            } else {
                Text("AWAITING DATA")
                    .font(ChaosTheme.font(11))
                    .foregroundColor(ChaosTheme.faded)
                    .tracking(2)
            }
        }
    }

    // MARK: - Quick Actions

    private var quickActions: some View {
        HStack(spacing: 8) {
            QuickActionButton(title: "+ GLUCOSE") { }
            QuickActionButton(title: "+ MEAL") { }
            QuickActionButton(title: "CALC DOSE") { }
        }
    }

    // MARK: - Stats Grid

    private var statsGrid: some View {
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
                valueColor: ChaosTheme.inRange
            )
        }
    }

    // MARK: - Recent Readings

    private var recentReadings: some View {
        VStack(spacing: 10) {
            SectionHeader(title: "RECENT READINGS")

            if !viewModel.recentReadings.isEmpty {
                SparklineView(readings: viewModel.recentReadings)

                HStack {
                    ForEach(viewModel.recentReadings.suffix(5)) { reading in
                        VStack(spacing: 2) {
                            Text("\(reading.mgDL)")
                                .font(ChaosTheme.bodyFont)
                                .foregroundColor(ChaosTheme.ink)
                            Text(reading.timestamp.formatted(.dateTime.hour().minute()))
                                .font(ChaosTheme.captionFont)
                                .foregroundColor(ChaosTheme.faded)
                                .tracking(1)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            } else {
                Text("NO READINGS YET")
                    .font(ChaosTheme.captionFont)
                    .foregroundColor(ChaosTheme.faded)
                    .tracking(2)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            }
        }
    }
}
