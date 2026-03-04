import SwiftUI
import SwiftData

struct GlucoseEntryView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = GlucoseEntryViewModel()
    @State private var showSavedConfirmation = false
    @Binding var selectedTab: Int

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Central reading input
                    VStack(spacing: 8) {
                        TextField("0", text: $viewModel.glucoseValue)
                            .font(.system(size: 64, weight: .bold, design: .monospaced))
                            .multilineTextAlignment(.center)
                            .keyboardType(.numberPad)
                            .frame(maxWidth: 200)

                        Text("mg/dL")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 16)

                    // Range status
                    if let value = viewModel.glucoseDouble {
                        HStack {
                            Text("LOW 70")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("\(Int(value)) \(viewModel.rangeStatus)")
                                .font(.caption)
                                .foregroundColor(ChaosTheme.glucoseColor(for: value))
                            Spacer()
                            Text("180 HIGH")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Divider()

                    // Context tags
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Reading Context")
                            .font(.headline)

                        FlowLayout(spacing: 8) {
                            ForEach(ReadingContext.allCases, id: \.self) { context in
                                Button {
                                    if viewModel.selectedContext == context {
                                        viewModel.selectedContext = nil
                                    } else {
                                        viewModel.selectedContext = context
                                    }
                                } label: {
                                    Text(context.rawValue)
                                        .font(.caption)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(viewModel.selectedContext == context ? Color.accentColor.opacity(0.15) : Color(.systemGray6))
                                        .cornerRadius(6)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    // Timestamp
                    HStack {
                        Text("Timestamp")
                            .foregroundStyle(.secondary)
                        Spacer()
                        DatePicker("", selection: $viewModel.timestamp)
                            .datePickerStyle(.compact)
                            .labelsHidden()
                    }

                    Divider()

                    // Notes
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Notes")
                            .font(.headline)

                        TextField("Add notes...", text: $viewModel.notes, axis: .vertical)
                            .lineLimit(3...6)
                            .textFieldStyle(.roundedBorder)
                    }

                    // Buttons
                    VStack(spacing: 10) {
                        ChaosButton(title: "Log Reading") {
                            if let reading = viewModel.save(modelContext: modelContext) {
                                appLog("Glucose reading saved: \(reading.mgDL) mg/dL", category: "DATA")
                                DatabaseExporter.shared.exportReading(
                                    value: reading.value,
                                    trend: reading.trend.description,
                                    context: reading.context?.rawValue,
                                    source: reading.source.rawValue
                                )
                                showSavedConfirmation = true
                                Task {
                                    try? await Task.sleep(for: .seconds(1.5))
                                    showSavedConfirmation = false
                                    viewModel.reset()
                                }
                            } else {
                                appLog("Glucose save failed — validation error", category: "WARN")
                            }
                        }

                        ChaosSecondaryButton(title: "Log & Calculate Dose") {
                            if let reading = viewModel.save(modelContext: modelContext) {
                                appLog("Glucose saved, navigating to dose: \(reading.mgDL) mg/dL", category: "DATA")
                                DatabaseExporter.shared.exportReading(
                                    value: reading.value,
                                    trend: reading.trend.description,
                                    context: reading.context?.rawValue,
                                    source: reading.source.rawValue
                                )
                                viewModel.reset()
                                selectedTab = 2
                            }
                        }
                    }
                }
                .padding()
            }
            .chaosKeyboardDismiss()
            .navigationTitle("Glucose Entry")
        }
        .overlay {
            if showSavedConfirmation {
                VStack {
                    Text("Logged!")
                        .font(.title2.bold())
                        .foregroundColor(.green)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.ultraThinMaterial)
                .transition(.opacity)
            }
        }
    }
}

// MARK: - Flow Layout for Tags

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = layout(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(proposal: ProposedViewSize(width: bounds.width, height: bounds.height), subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func layout(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }

        return (CGSize(width: maxWidth, height: y + rowHeight), positions)
    }
}
