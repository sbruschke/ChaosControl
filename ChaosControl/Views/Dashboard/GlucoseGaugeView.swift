import SwiftUI

// MARK: - Central Glucose Gauge
// Archaic compass-style circular gauge with construction lines

struct GlucoseGaugeView: View {
    let value: Double
    let trend: TrendDirection
    let timeInRange: Double

    private let gaugeSize: CGFloat = 240

    var body: some View {
        ZStack {
            // Outer dashed construction circle
            Circle()
                .stroke(ChaosTheme.ink.opacity(0.06), style: StrokeStyle(lineWidth: 0.5, dash: [4, 6]))
                .frame(width: gaugeSize + 10, height: gaugeSize + 10)

            // Time in range arc (background)
            Circle()
                .stroke(ChaosTheme.ink.opacity(0.05), lineWidth: 2)
                .frame(width: gaugeSize - 20, height: gaugeSize - 20)

            // Time in range arc (filled)
            Circle()
                .trim(from: 0, to: timeInRange / 100)
                .stroke(ChaosTheme.inRange.opacity(0.6), lineWidth: 2)
                .frame(width: gaugeSize - 20, height: gaugeSize - 20)
                .rotationEffect(.degrees(-90))

            // Main gauge circle
            Circle()
                .stroke(ChaosTheme.ink.opacity(0.15), lineWidth: 0.5)
                .frame(width: gaugeSize - 35, height: gaugeSize - 35)

            // Inner decorative circles
            Circle()
                .stroke(ChaosTheme.ink.opacity(0.04), style: StrokeStyle(lineWidth: 0.3, dash: [2, 4]))
                .frame(width: gaugeSize - 55, height: gaugeSize - 55)

            Circle()
                .stroke(ChaosTheme.ink.opacity(0.04), lineWidth: 0.3)
                .frame(width: gaugeSize - 75, height: gaugeSize - 75)

            // Crosshair lines through center
            crosshairs

            // Tick marks
            tickMarks

            // Red marker dots
            markerDots

            // Runic glyphs at cardinal points
            runicGlyphs

            // Central reading
            VStack(spacing: 4) {
                Text("\(Int(value))")
                    .font(ChaosTheme.displayFont)
                    .foregroundColor(ChaosTheme.ink)
                    .tracking(2)

                Text("MG/DL")
                    .font(ChaosTheme.font(12))
                    .foregroundColor(ChaosTheme.faded)
                    .tracking(3)

                // Trend arrow
                HStack(spacing: 4) {
                    Text(trend.arrow)
                        .font(ChaosTheme.font(17))
                        .foregroundColor(ChaosTheme.glucoseColor(for: value))
                }
                .padding(.top, 4)

                Text("\u{25C6} \(trend.description)")
                    .font(ChaosTheme.annotationFont)
                    .foregroundColor(ChaosTheme.red.opacity(0.35))
                    .tracking(1)
            }
        }
        .frame(width: gaugeSize + 20, height: gaugeSize + 20)
    }

    // MARK: - Subviews

    private var crosshairs: some View {
        ZStack {
            // Horizontal
            Rectangle()
                .fill(ChaosTheme.red.opacity(0.12))
                .frame(width: gaugeSize + 10, height: 0.3)

            // Vertical
            Rectangle()
                .fill(ChaosTheme.red.opacity(0.12))
                .frame(width: 0.3, height: gaugeSize + 10)

            // Diagonals (faint)
            Path { path in
                path.move(to: CGPoint(x: 25, y: 25))
                path.addLine(to: CGPoint(x: gaugeSize - 15, y: gaugeSize - 15))
            }
            .stroke(ChaosTheme.red.opacity(0.06), lineWidth: 0.3)
            .frame(width: gaugeSize + 10, height: gaugeSize + 10)

            Path { path in
                path.move(to: CGPoint(x: gaugeSize - 15, y: 25))
                path.addLine(to: CGPoint(x: 25, y: gaugeSize - 15))
            }
            .stroke(ChaosTheme.red.opacity(0.06), lineWidth: 0.3)
            .frame(width: gaugeSize + 10, height: gaugeSize + 10)
        }
    }

    private var tickMarks: some View {
        ZStack {
            ForEach(0..<12) { i in
                let angle = Double(i) * 30
                Rectangle()
                    .fill(ChaosTheme.ink.opacity(i % 3 == 0 ? 0.2 : 0.08))
                    .frame(width: 0.5, height: i % 3 == 0 ? 10 : 6)
                    .offset(y: -(gaugeSize / 2 - 18))
                    .rotationEffect(.degrees(angle))
            }
        }
    }

    private var markerDots: some View {
        ZStack {
            // Top
            Circle()
                .fill(ChaosTheme.red.opacity(0.5))
                .frame(width: 4, height: 4)
                .offset(y: -(gaugeSize / 2 + 1))

            // Right
            Circle()
                .fill(ChaosTheme.red.opacity(0.3))
                .frame(width: 3, height: 3)
                .offset(x: gaugeSize / 2 + 1)

            // Left
            Circle()
                .fill(ChaosTheme.red.opacity(0.3))
                .frame(width: 3, height: 3)
                .offset(x: -(gaugeSize / 2 + 1))
        }
    }

    private var runicGlyphs: some View {
        ZStack {
            Text("\u{16A0}")
                .font(.system(size: 8, design: .serif))
                .foregroundColor(ChaosTheme.ink.opacity(0.2))
                .offset(y: -(gaugeSize / 2 + 8))

            Text("\u{16B1}")
                .font(.system(size: 8, design: .serif))
                .foregroundColor(ChaosTheme.ink.opacity(0.15))
                .offset(x: gaugeSize / 2 + 8)

            Text("\u{16D6}")
                .font(.system(size: 8, design: .serif))
                .foregroundColor(ChaosTheme.ink.opacity(0.15))
                .offset(x: -(gaugeSize / 2 + 8))

            Text("\u{16C7}")
                .font(.system(size: 8, design: .serif))
                .foregroundColor(ChaosTheme.ink.opacity(0.15))
                .offset(y: gaugeSize / 2 + 8)
        }
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let label: String
    let value: String
    var unit: String = ""
    var valueColor: Color = ChaosTheme.ink

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(ChaosTheme.microFont)
                .foregroundColor(ChaosTheme.faded)
                .tracking(2)

            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(ChaosTheme.font(22))
                    .foregroundColor(valueColor)
                    .tracking(1)

                if !unit.isEmpty {
                    Text(unit)
                        .font(ChaosTheme.captionFont)
                        .foregroundColor(ChaosTheme.faded)
                        .tracking(1)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .chaosCard()
    }
}

// MARK: - Sparkline View

struct SparklineView: View {
    let readings: [GlucoseReading]
    var height: CGFloat = 50

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let values = readings.map(\.value)
            let minVal = (values.min() ?? 60) - 10
            let maxVal = (values.max() ?? 200) + 10
            let range = maxVal - minVal

            ZStack {
                // Target range band
                let lowY = yPosition(70, min: minVal, range: range, height: height)
                let highY = yPosition(180, min: minVal, range: range, height: height)
                Rectangle()
                    .fill(ChaosTheme.inRange.opacity(0.05))
                    .frame(height: max(0, lowY - highY))
                    .offset(y: highY - height / 2 + (lowY - highY) / 2)

                // Range lines
                Path { path in
                    path.move(to: CGPoint(x: 0, y: highY))
                    path.addLine(to: CGPoint(x: width, y: highY))
                }
                .stroke(ChaosTheme.inRange.opacity(0.15), style: StrokeStyle(lineWidth: 0.5, dash: [3, 3]))

                Path { path in
                    path.move(to: CGPoint(x: 0, y: lowY))
                    path.addLine(to: CGPoint(x: width, y: lowY))
                }
                .stroke(ChaosTheme.inRange.opacity(0.15), style: StrokeStyle(lineWidth: 0.5, dash: [3, 3]))

                // Sparkline
                if readings.count >= 2 {
                    Path { path in
                        for (index, reading) in readings.enumerated() {
                            let x = width * CGFloat(index) / CGFloat(readings.count - 1)
                            let y = yPosition(reading.value, min: minVal, range: range, height: height)
                            if index == 0 {
                                path.move(to: CGPoint(x: x, y: y))
                            } else {
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                        }
                    }
                    .stroke(ChaosTheme.ink, lineWidth: 1)

                    // Data points
                    ForEach(readings.indices, id: \.self) { index in
                        let reading = readings[index]
                        let x = width * CGFloat(index) / CGFloat(readings.count - 1)
                        let y = yPosition(reading.value, min: minVal, range: range, height: height)

                        Circle()
                            .fill(index == readings.count - 1 ? ChaosTheme.red.opacity(0.6) : ChaosTheme.ink)
                            .frame(width: index == readings.count - 1 ? 5 : 4)
                            .position(x: x, y: y)
                    }
                }
            }
        }
        .frame(height: height)
    }

    private func yPosition(_ value: Double, min: Double, range: Double, height: CGFloat) -> CGFloat {
        guard range > 0 else { return height / 2 }
        return height - CGFloat((value - min) / range) * height
    }
}
