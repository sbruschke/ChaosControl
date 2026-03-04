import SwiftUI

struct ChaosInputField: View {
    let label: String
    @Binding var value: String
    var unit: String = ""
    var highlighted: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack {
                TextField(label, text: $value)
                    .keyboardType(.decimalPad)

                if !unit.isEmpty {
                    Text(unit)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(10)
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
    }
}

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
