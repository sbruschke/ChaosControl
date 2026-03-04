import SwiftUI

struct GlucoseGaugeView: View {
    let value: Double
    let trend: TrendDirection
    let timeInRange: Double

    var body: some View {
        VStack(spacing: 8) {
            Text("\(Int(value))")
                .font(.system(size: 64, weight: .bold, design: .monospaced))

            Text("mg/dL")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: 4) {
                Text(trend.arrow)
                    .font(.title2)
                    .foregroundColor(ChaosTheme.glucoseColor(for: value))

                Text(trend.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text("\(Int(timeInRange))% in range")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 20)
    }
}

struct StatCard: View {
    let label: String
    let value: String
    var unit: String = ""
    var valueColor: Color = .primary

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)

            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.title3.bold())
                    .foregroundColor(valueColor)

                if !unit.isEmpty {
                    Text(unit)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

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
                    .stroke(Color.primary, lineWidth: 1)

                    ForEach(readings.indices, id: \.self) { index in
                        let reading = readings[index]
                        let x = width * CGFloat(index) / CGFloat(readings.count - 1)
                        let y = yPosition(reading.value, min: minVal, range: range, height: height)

                        Circle()
                            .fill(ChaosTheme.glucoseColor(for: reading.value))
                            .frame(width: 5)
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
