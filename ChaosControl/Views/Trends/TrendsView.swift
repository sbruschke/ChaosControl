import SwiftUI
import SwiftData
import Charts

struct TrendsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = TrendsViewModel()

    var body: some View {
        ZStack {
            ChaosTheme.background.ignoresSafeArea()
            ConstructionLines(showVertical: false, horizontalOffset: 0.2)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    header
                        .padding(.bottom, 16)

                    // Time range selector
                    timeRangeSelector
                        .padding(.bottom, 18)

                    // Main chart
                    chartSection
                        .padding(.bottom, 18)

                    // Stats row
                    statsRow
                        .padding(.bottom, 18)

                    // Time in range
                    timeInRangeSection
                        .padding(.bottom, 18)

                    // A1C estimate
                    a1cSection
                        .padding(.bottom, 14)

                    ChaosDivider()
                        .padding(.bottom, 14)

                    // Daily averages
                    dailyAveragesSection
                }
                .padding(.horizontal, ChaosTheme.screenPadding)
                .padding(.bottom, 20)
            }

            // Annotations
            VStack {
                HStack {
                    Spacer()
                    AnnotationText(text: "CC-TA-05")
                }
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .allowsHitTesting(false)
        }
        .onAppear { viewModel.loadData(modelContext: modelContext) }
        .onChange(of: viewModel.selectedRange) { _, _ in
            viewModel.loadData(modelContext: modelContext)
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("TEMPORAL ANALYSIS")
                .font(ChaosTheme.titleFont)
                .foregroundColor(ChaosTheme.ink)
                .tracking(4)

            HStack(spacing: 0) {
                Text("BLOOD SUGAR PATTERNS ")
                    .font(ChaosTheme.captionFont)
                    .foregroundColor(ChaosTheme.faded)
                    .tracking(2)
                Text("//")
                    .font(ChaosTheme.captionFont)
                    .foregroundColor(ChaosTheme.red)
                Text(" TRENDS")
                    .font(ChaosTheme.captionFont)
                    .foregroundColor(ChaosTheme.faded)
                    .tracking(2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Time Range

    private var timeRangeSelector: some View {
        HStack(spacing: 0) {
            ForEach(TimeRange.allCases, id: \.self) { range in
                Button {
                    viewModel.selectedRange = range
                } label: {
                    Text(range.rawValue)
                        .font(ChaosTheme.captionFont)
                        .foregroundColor(viewModel.selectedRange == range ? ChaosTheme.red : ChaosTheme.faded)
                        .tracking(1.5)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 7)
                        .background(viewModel.selectedRange == range ? ChaosTheme.red.opacity(0.03) : .clear)
                        .overlay(
                            Rectangle()
                                .stroke(
                                    viewModel.selectedRange == range ? ChaosTheme.red.opacity(0.3) : ChaosTheme.ink.opacity(0.06),
                                    lineWidth: 0.5
                                )
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Chart

    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "GLUCOSE PATTERN // \(viewModel.selectedRange.rawValue)")

            if viewModel.readings.isEmpty {
                Text("NO DATA FOR THIS PERIOD")
                    .font(ChaosTheme.captionFont)
                    .foregroundColor(ChaosTheme.faded)
                    .tracking(2)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
            } else {
                Chart {
                    // Target range band
                    RectangleMark(
                        xStart: .value("Start", viewModel.readings.first?.timestamp ?? .now),
                        xEnd: .value("End", viewModel.readings.last?.timestamp ?? .now),
                        yStart: .value("Low", 70),
                        yEnd: .value("High", 180)
                    )
                    .foregroundStyle(ChaosTheme.inRange.opacity(0.06))

                    // Glucose line
                    ForEach(viewModel.readings) { reading in
                        LineMark(
                            x: .value("Time", reading.timestamp),
                            y: .value("Glucose", reading.value)
                        )
                        .foregroundStyle(ChaosTheme.ink)
                        .lineStyle(StrokeStyle(lineWidth: 1.2))

                        PointMark(
                            x: .value("Time", reading.timestamp),
                            y: .value("Glucose", reading.value)
                        )
                        .foregroundStyle(ChaosTheme.glucoseColor(for: reading.value))
                        .symbolSize(reading.value > 180 || reading.value < 70 ? 20 : 12)
                    }

                    // Target range lines
                    RuleMark(y: .value("High", 180))
                        .foregroundStyle(ChaosTheme.inRange.opacity(0.2))
                        .lineStyle(StrokeStyle(lineWidth: 0.5, dash: [4, 4]))

                    RuleMark(y: .value("Low", 70))
                        .foregroundStyle(ChaosTheme.inRange.opacity(0.2))
                        .lineStyle(StrokeStyle(lineWidth: 0.5, dash: [4, 4]))
                }
                .chartYAxis {
                    AxisMarks(values: [60, 120, 180, 240, 300]) { value in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.3))
                            .foregroundStyle(ChaosTheme.ink.opacity(0.05))
                        AxisValueLabel {
                            if let intValue = value.as(Int.self) {
                                Text("\(intValue)")
                                    .font(ChaosTheme.annotationFont)
                                    .foregroundColor(ChaosTheme.faded)
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks { value in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.3, dash: [2, 4]))
                            .foregroundStyle(ChaosTheme.ink.opacity(0.04))
                        AxisValueLabel {
                            if let date = value.as(Date.self) {
                                Text(date.formatted(.dateTime.day()))
                                    .font(ChaosTheme.annotationFont)
                                    .foregroundColor(ChaosTheme.faded)
                            }
                        }
                    }
                }
                .frame(height: 160)
            }
        }
    }

    // MARK: - Stats

    private var statsRow: some View {
        HStack(spacing: 8) {
            miniStat("AVERAGE", value: "\(Int(viewModel.averageGlucose))")
            miniStat("HIGH", value: "\(Int(viewModel.highGlucose))", color: ChaosTheme.warning)
            miniStat("LOW", value: "\(Int(viewModel.lowGlucose))")
            miniStat("STD DEV", value: "\(Int(viewModel.standardDeviation))")
        }
    }

    private func miniStat(_ label: String, value: String, color: Color = ChaosTheme.ink) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(ChaosTheme.annotationFont)
                .foregroundColor(ChaosTheme.faded)
                .tracking(2)
            Text(value)
                .font(ChaosTheme.font(18))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .chaosCard()
    }

    // MARK: - Time in Range

    private var timeInRangeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "TIME IN RANGE")

            HStack(spacing: 20) {
                // Donut chart
                ZStack {
                    Circle()
                        .stroke(ChaosTheme.ink.opacity(0.04), lineWidth: 8)
                        .frame(width: 76, height: 76)

                    tirArc(start: 0, percent: viewModel.rangeBreakdown.veryHigh, color: ChaosTheme.danger)
                    tirArc(start: viewModel.rangeBreakdown.veryHigh, percent: viewModel.rangeBreakdown.high, color: ChaosTheme.warning)
                    tirArc(start: viewModel.rangeBreakdown.veryHigh + viewModel.rangeBreakdown.high, percent: viewModel.rangeBreakdown.inRange, color: ChaosTheme.inRange)
                    tirArc(start: viewModel.rangeBreakdown.veryHigh + viewModel.rangeBreakdown.high + viewModel.rangeBreakdown.inRange, percent: viewModel.rangeBreakdown.low, color: ChaosTheme.low)

                    VStack(spacing: 2) {
                        Text("\(Int(viewModel.timeInRangePercent))")
                            .font(ChaosTheme.font(18))
                            .foregroundColor(ChaosTheme.ink)
                        Text("% IN RANGE")
                            .font(ChaosTheme.annotationFont)
                            .foregroundColor(ChaosTheme.faded)
                            .tracking(1.5)
                    }
                }

                // Breakdown list
                VStack(spacing: 4) {
                    tirRow(color: ChaosTheme.danger, label: "VERY HIGH >250", value: viewModel.rangeBreakdown.veryHigh)
                    tirRow(color: ChaosTheme.warning, label: "HIGH 181-250", value: viewModel.rangeBreakdown.high)
                    tirRow(color: ChaosTheme.inRange, label: "IN RANGE 70-180", value: viewModel.rangeBreakdown.inRange, highlight: true)
                    tirRow(color: ChaosTheme.low, label: "LOW <70", value: viewModel.rangeBreakdown.low)
                    tirRow(color: ChaosTheme.danger.opacity(0.6), label: "VERY LOW <54", value: viewModel.rangeBreakdown.veryLow)
                }
            }
            .padding(14)
            .overlay(Rectangle().stroke(ChaosTheme.ink.opacity(0.08), lineWidth: 0.5))
            .overlay(alignment: .bottomTrailing) {
                CornerBracket()
                    .rotation(Angle(degrees: 180))
                    .stroke(ChaosTheme.red, lineWidth: 0.5)
                    .frame(width: 6, height: 6)
                    .offset(x: 0.5, y: 0.5)
            }
        }
    }

    private func tirArc(start: Double, percent: Double, color: Color) -> some View {
        Circle()
            .trim(from: start / 100, to: (start + percent) / 100)
            .stroke(color.opacity(0.6), lineWidth: 8)
            .frame(width: 76, height: 76)
            .rotationEffect(.degrees(-90))
    }

    private func tirRow(color: Color, label: String, value: Double, highlight: Bool = false) -> some View {
        HStack {
            Rectangle()
                .fill(color.opacity(0.6))
                .frame(width: 8, height: 3)

            Text(label)
                .font(ChaosTheme.microFont)
                .foregroundColor(ChaosTheme.faded)
                .tracking(1.5)

            Spacer()

            Text("\(Int(value))%")
                .font(ChaosTheme.font(9))
                .foregroundColor(highlight ? ChaosTheme.inRange : ChaosTheme.ink)
                .tracking(1)
        }
        .padding(.vertical, 2)
    }

    // MARK: - A1C

    private var a1cSection: some View {
        VStack(spacing: 10) {
            SectionHeader(title: "ESTIMATED A1C")

            VStack(spacing: 6) {
                Text("GLYCATED HEMOGLOBIN ESTIMATE")
                    .font(ChaosTheme.captionFont)
                    .foregroundColor(ChaosTheme.faded)
                    .tracking(3)

                HStack(alignment: .lastTextBaseline, spacing: 2) {
                    Text(String(format: "%.1f", viewModel.estimatedA1C))
                        .font(ChaosTheme.font(36))
                        .foregroundColor(ChaosTheme.ink)
                        .tracking(2)
                    Text("%")
                        .font(ChaosTheme.bodyFont)
                        .foregroundColor(ChaosTheme.faded)
                        .tracking(2)
                }

                HStack(spacing: 0) {
                    Text("BASED ON \(viewModel.selectedRange.rawValue) AVG // ")
                        .font(ChaosTheme.microFont)
                        .foregroundColor(ChaosTheme.faded)
                        .tracking(1)
                    Text(a1cAssessment)
                        .font(ChaosTheme.microFont)
                        .foregroundColor(ChaosTheme.inRange)
                        .tracking(1)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(16)
            .overlay(Rectangle().stroke(ChaosTheme.ink.opacity(0.1), lineWidth: 0.5))
            .overlay(
                Rectangle()
                    .stroke(ChaosTheme.red.opacity(0.06), lineWidth: 0.5)
                    .padding(4)
            )
        }
    }

    private var a1cAssessment: String {
        switch viewModel.estimatedA1C {
        case ..<5.7: return "NORMAL"
        case ..<6.5: return "WELL MANAGED"
        case ..<7.0: return "GOOD CONTROL"
        case ..<8.0: return "MODERATE"
        default: return "NEEDS ATTENTION"
        }
    }

    // MARK: - Daily Averages

    private var dailyAveragesSection: some View {
        VStack(spacing: 0) {
            SectionHeader(title: "DAILY AVERAGES")
                .padding(.bottom, 8)

            ForEach(viewModel.dailyAverages.prefix(7)) { day in
                HStack(spacing: 10) {
                    Text(day.date.formatted(.dateTime.month(.abbreviated).day()).uppercased())
                        .font(ChaosTheme.captionFont)
                        .foregroundColor(ChaosTheme.faded)
                        .tracking(1)
                        .frame(width: 50, alignment: .leading)

                    GeometryReader { geo in
                        let rangeStart = max(0, (day.low - 40) / 260) * geo.size.width
                        let rangeWidth = max(0, (day.high - day.low) / 260) * geo.size.width

                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(ChaosTheme.ink.opacity(0.02))
                                .frame(height: 12)

                            Rectangle()
                                .fill(ChaosTheme.inRange.opacity(0.5))
                                .frame(width: min(rangeWidth, geo.size.width - rangeStart), height: 12)
                                .offset(x: rangeStart)
                        }
                    }
                    .frame(height: 12)

                    Text("\(Int(day.average))")
                        .font(ChaosTheme.font(9))
                        .foregroundColor(ChaosTheme.ink)
                        .tracking(1)
                        .frame(width: 36, alignment: .trailing)
                }
                .padding(.vertical, 8)
                .overlay(alignment: .bottom) {
                    Rectangle().fill(ChaosTheme.ink.opacity(0.04)).frame(height: 0.5)
                }
            }
        }
    }
}
