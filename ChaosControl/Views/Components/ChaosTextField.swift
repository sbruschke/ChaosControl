import SwiftUI

// MARK: - Chaos Input Field

struct ChaosInputField: View {
    let label: String
    @Binding var value: String
    var unit: String = ""
    var highlighted: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Label
            HStack(spacing: 6) {
                Circle()
                    .fill(ChaosTheme.red.opacity(0.4))
                    .frame(width: 4, height: 4)
                Text(label)
                    .font(ChaosTheme.microFont)
                    .foregroundColor(ChaosTheme.faded)
                    .tracking(2.5)
            }

            // Field
            HStack {
                TextField("", text: $value)
                    .font(ChaosTheme.font(22))
                    .foregroundColor(ChaosTheme.ink)
                    .tracking(1)
                    .keyboardType(.decimalPad)

                if !unit.isEmpty {
                    Text(unit)
                        .font(ChaosTheme.font(9))
                        .foregroundColor(ChaosTheme.faded)
                        .tracking(2)
                }
            }
            .padding(14)
            .background(ChaosTheme.background.opacity(0.3))
            .overlay(
                Rectangle()
                    .stroke(
                        highlighted ? ChaosTheme.red.opacity(0.25) : ChaosTheme.border,
                        lineWidth: 0.5
                    )
            )
            .overlay(alignment: .topLeading) {
                CornerBracket()
                    .stroke(ChaosTheme.red, lineWidth: 0.5)
                    .frame(width: 6, height: 6)
                    .offset(x: -0.5, y: -0.5)
            }
            .overlay(alignment: .bottomTrailing) {
                CornerBracket()
                    .rotation(Angle(degrees: 180))
                    .stroke(ChaosTheme.red, lineWidth: 0.5)
                    .frame(width: 6, height: 6)
                    .offset(x: 0.5, y: 0.5)
            }
        }
    }
}

// MARK: - Numeric Input Field (Double binding)

struct ChaosNumericField: View {
    let label: String
    @Binding var value: Double
    var unit: String = ""
    var highlighted: Bool = false

    @State private var textValue: String = ""

    var body: some View {
        ChaosInputField(
            label: label,
            value: $textValue,
            unit: unit,
            highlighted: highlighted
        )
        .onAppear {
            textValue = value == 0 ? "" : formatNumber(value)
        }
        .onChange(of: textValue) { _, newValue in
            if let parsed = Double(newValue) {
                value = parsed
            }
        }
        .onChange(of: value) { _, newValue in
            let formatted = formatNumber(newValue)
            if textValue != formatted {
                textValue = formatted
            }
        }
    }

    private func formatNumber(_ v: Double) -> String {
        if v == v.rounded() {
            return String(Int(v))
        }
        return String(format: "%.1f", v)
    }
}
