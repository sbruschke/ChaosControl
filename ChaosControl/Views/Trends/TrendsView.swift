import SwiftUI
import SwiftData
import Charts

struct TrendsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = TrendsViewModel()
    @Binding var selectedTab: Int

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Time range selector
                    Picker("Time Range", selection: $viewModel.selectedRange) {
                        ForEach(TimeRange.allCases, id: \.self) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                    .pickerStyle(.segmented)

                    // Main chart
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Glucose Pattern - \(viewModel.selectedRange.rawValue)")
                            .font(.headline)

                        if viewModel.readings.isEmpty {
                            Text("No data for this period")
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 40)
                        } else {
                            Chart {
                                RectangleMark(
                                    xStart: .value("Start", viewModel.cutoffDate),
                                    xEnd: .value("End", Date.now),
                                    yStart: .value("Low", 70),
                                    yEnd: .value("High", 180)
                                )
                                .foregroundStyle(.green.opacity(0.08))

                                ForEach(viewModel.readings) { reading in
                                    LineMark(
                                        x: .value("Time", reading.timestamp),
                                        y: .value("Glucose", reading.value)
                                    )
                                    .foregroundStyle(.primary)
                                    .lineStyle(StrokeStyle(lineWidth: 1.2))

                                    PointMark(
                                        x: .value("Time", reading.timestamp),
                                        y: .value("Glucose", reading.value)
                                    )
                                    .foregroundStyle(ChaosTheme.glucoseColor(for: reading.value))
                                    .symbolSize(reading.value > 180 || reading.value < 70 ? 20 : 12)
                                }

                                RuleMark(y: .value("High", 180))
                                    .foregroundStyle(.green.opacity(0.3))
                                    .lineStyle(StrokeStyle(lineWidth: 0.5, dash: [4, 4]))

                                RuleMark(y: .value("Low", 70))
                                    .foregroundStyle(.green.opacity(0.3))
                                    .lineStyle(StrokeStyle(lineWidth: 0.5, dash: [4, 4]))
                            }
                            .chartXScale(domain: viewModel.cutoffDate...Date.now)
                            .frame(height: 180)
                        }
                    }

                    // Stats row
                    HStack(spacing: 8) {
                        miniStat("Average", value: "\(Int(viewModel.averageGlucose))")
                        miniStat("High", value: "\(Int(viewModel.highGlucose))", color: .orange)
                        miniStat("Low", value: "\(Int(viewModel.lowGlucose))")
                        miniStat("Std Dev", value: "\(Int(viewModel.standardDeviation))")
                    }

                    Divider()

                    // Time in range
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Time in Range")
                            .font(.headline)

                        VStack(spacing: 4) {
                            tirRow(color: .red, label: "Very High >250", value: viewModel.rangeBreakdown.veryHigh)
                            tirRow(color: .orange, label: "High 181-250", value: viewModel.rangeBreakdown.high)
                            tirRow(color: .green, label: "In Range 70-180", value: viewModel.rangeBreakdown.inRange, highlight: true)
                            tirRow(color: .purple, label: "Low <70", value: viewModel.rangeBreakdown.low)
                            tirRow(color: .red.opacity(0.6), label: "Very Low <54", value: viewModel.rangeBreakdown.veryLow)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)

                    // A1C estimate
                    VStack(spacing: 8) {
                        Text("Estimated A1C")
                            .font(.headline)

                        HStack(alignment: .lastTextBaseline, spacing: 2) {
                            Text(String(format: "%.1f", viewModel.estimatedA1C))
                                .font(.system(size: 36, weight: .bold))
                            Text("%")
                                .foregroundStyle(.secondary)
                        }

                        Text("Based on \(viewModel.selectedRange.rawValue) avg - \(a1cAssessment)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)

                    Divider()

                    // Daily averages
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Daily Averages")
                            .font(.headline)

                        ForEach(viewModel.dailyAverages.prefix(7)) { day in
                            HStack(spacing: 10) {
                                Text(day.date.formatted(.dateTime.month(.abbreviated).day()).uppercased())
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .frame(width: 50, alignment: .leading)

                                GeometryReader { geo in
                                    let rangeStart = max(0, (day.low - 40) / 260) * geo.size.width
                                    let rangeWidth = max(0, (day.high - day.low) / 260) * geo.size.width

                                    ZStack(alignment: .leading) {
                                        Rectangle()
                                            .fill(Color(.systemGray5))
                                            .frame(height: 12)
                                            .cornerRadius(2)

                                        Rectangle()
                                            .fill(.green.opacity(0.5))
                                            .frame(width: min(rangeWidth, geo.size.width - rangeStart), height: 12)
                                            .cornerRadius(2)
                                            .offset(x: rangeStart)
                                    }
                                }
                                .frame(height: 12)

                                Text("\(Int(day.average))")
                                    .font(.caption.bold())
                                    .frame(width: 36, alignment: .trailing)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Trends")
        }
        .onAppear { viewModel.loadData(modelContext: modelContext) }
        .onChange(of: viewModel.selectedRange) { _, _ in
            viewModel.loadData(modelContext: modelContext)
        }
        .onChange(of: selectedTab) { _, newTab in
            if newTab == 4 {
                viewModel.loadData(modelContext: modelContext)
            }
        }
    }

    private func miniStat(_ label: String, value: String, color: Color = .primary) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3.bold())
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding(10)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }

    private func tirRow(color: Color, label: String, value: Double, highlight: Bool = false) -> some View {
        HStack {
            Rectangle()
                .fill(color)
                .frame(width: 12, height: 4)
                .cornerRadius(2)

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()

            Text("\(Int(value))%")
                .font(.body)
                .foregroundColor(highlight ? .green : .primary)
        }
        .padding(.vertical, 2)
    }

    private var a1cAssessment: String {
        switch viewModel.estimatedA1C {
        case ..<5.7: return "Normal"
        case ..<6.5: return "Well Managed"
        case ..<7.0: return "Good Control"
        case ..<8.0: return "Moderate"
        default: return "Needs Attention"
        }
    }
}
