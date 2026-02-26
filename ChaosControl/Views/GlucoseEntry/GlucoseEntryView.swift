import SwiftUI
import SwiftData

struct GlucoseEntryView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = GlucoseEntryViewModel()
    @State private var showSavedConfirmation = false

    var body: some View {
        ZStack {
            ChaosTheme.background.ignoresSafeArea()
            ConstructionLines(showVertical: false, horizontalOffset: 0.25)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    header
                        .padding(.bottom, 24)

                    // Central reading input
                    readingInput
                        .padding(.bottom, 8)

                    // Range indicator
                    rangeBar
                        .padding(.horizontal, 20)
                        .padding(.bottom, 24)

                    // Context tags
                    contextSection
                        .padding(.bottom, 20)

                    // Timestamp
                    timestampRow
                        .padding(.bottom, 20)

                    // Notes
                    notesSection
                        .padding(.bottom, 20)

                    // Buttons
                    buttonSection
                }
                .padding(.horizontal, ChaosTheme.screenPadding)
                .padding(.bottom, 20)
            }

            // Annotations
            VStack {
                HStack {
                    Spacer()
                    AnnotationText(text: "CC-GL-04")
                }
                Spacer()
                HStack {
                    AnnotationText(text: "\u{16A0}\u{16D6} ENTRY.LOG")
                    Spacer()
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .allowsHitTesting(false)
        }
        .overlay {
            if showSavedConfirmation {
                savedOverlay
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("GLUCOSE ENTRY")
                .font(ChaosTheme.titleFont)
                .foregroundColor(ChaosTheme.ink)
                .tracking(4)

            Text("BLOOD SUGAR READING // MANUAL")
                .font(ChaosTheme.captionFont)
                .foregroundColor(ChaosTheme.faded)
                .tracking(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Reading Input

    private var readingInput: some View {
        ZStack {
            // Decorative circles
            Circle()
                .stroke(ChaosTheme.ink.opacity(0.03), style: StrokeStyle(lineWidth: 0.5, dash: [4, 8]))
                .frame(width: 200, height: 200)

            Circle()
                .stroke(ChaosTheme.ink.opacity(0.03), lineWidth: 0.3)
                .frame(width: 150, height: 150)

            // Crosshair
            Rectangle()
                .fill(ChaosTheme.red.opacity(0.08))
                .frame(width: 250, height: 0.3)

            Rectangle()
                .fill(ChaosTheme.red.opacity(0.08))
                .frame(width: 0.3, height: 180)

            // Center dot
            Circle()
                .fill(ChaosTheme.red.opacity(0.15))
                .frame(width: 3, height: 3)

            VStack(spacing: 6) {
                HStack(spacing: 2) {
                    TextField("", text: $viewModel.glucoseValue)
                        .font(ChaosTheme.font(72))
                        .foregroundColor(ChaosTheme.ink)
                        .tracking(4)
                        .multilineTextAlignment(.center)
                        .keyboardType(.numberPad)
                        .frame(maxWidth: 200)

                    Rectangle()
                        .fill(ChaosTheme.red.opacity(0.6))
                        .frame(width: 2, height: 56)
                        .opacity(viewModel.glucoseValue.isEmpty ? 1 : 0)
                        .animation(.easeInOut(duration: 0.6).repeatForever(), value: viewModel.glucoseValue.isEmpty)
                }

                Text("MG / DL")
                    .font(ChaosTheme.font(11))
                    .foregroundColor(ChaosTheme.faded)
                    .tracking(4)
            }
        }
        .frame(height: 200)
    }

    // MARK: - Range Bar

    private var rangeBar: some View {
        VStack(spacing: 6) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Range gradient track
                    LinearGradient(
                        colors: [
                            ChaosTheme.danger.opacity(0.4),
                            ChaosTheme.warning.opacity(0.4),
                            ChaosTheme.inRange.opacity(0.4),
                            ChaosTheme.warning.opacity(0.4),
                            ChaosTheme.danger.opacity(0.4)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(height: 3)
                    .clipShape(Capsule())

                    // Marker
                    if viewModel.glucoseDouble != nil {
                        Rectangle()
                            .fill(ChaosTheme.ink)
                            .frame(width: 2, height: 11)
                            .offset(x: geometry.size.width * viewModel.rangePosition, y: -4)
                    }
                }
            }
            .frame(height: 11)

            // Labels
            HStack {
                Text("LOW")
                    .font(ChaosTheme.annotationFont)
                    .foregroundColor(ChaosTheme.faded)
                Text("70")
                    .font(ChaosTheme.annotationFont)
                    .foregroundColor(ChaosTheme.faded)
                Spacer()
                if let value = viewModel.glucoseDouble {
                    Text("\(Int(value)) \(viewModel.rangeStatus)")
                        .font(ChaosTheme.microFont)
                        .foregroundColor(ChaosTheme.glucoseColor(for: value))
                }
                Spacer()
                Text("180")
                    .font(ChaosTheme.annotationFont)
                    .foregroundColor(ChaosTheme.faded)
                Text("HIGH")
                    .font(ChaosTheme.annotationFont)
                    .foregroundColor(ChaosTheme.faded)
            }
        }
    }

    // MARK: - Context Tags

    private var contextSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "READING CONTEXT")

            FlowLayout(spacing: 8) {
                ForEach(ReadingContext.allCases, id: \.self) { context in
                    contextTag(context)
                }
            }
        }
    }

    private func contextTag(_ context: ReadingContext) -> some View {
        Button {
            if viewModel.selectedContext == context {
                viewModel.selectedContext = nil
            } else {
                viewModel.selectedContext = context
            }
        } label: {
            Text(context.rawValue)
                .font(ChaosTheme.captionFont)
                .foregroundColor(viewModel.selectedContext == context ? ChaosTheme.red : ChaosTheme.faded)
                .tracking(2)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(viewModel.selectedContext == context ? ChaosTheme.red.opacity(0.03) : .clear)
                .overlay(
                    Rectangle()
                        .stroke(
                            viewModel.selectedContext == context ? ChaosTheme.red.opacity(0.4) : ChaosTheme.border,
                            lineWidth: 0.5
                        )
                )
                .overlay(alignment: .topLeading) {
                    if viewModel.selectedContext == context {
                        CornerBracket()
                            .stroke(ChaosTheme.red, lineWidth: 0.5)
                            .frame(width: 4, height: 4)
                            .offset(x: -0.5, y: -0.5)
                    }
                }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Timestamp

    private var timestampRow: some View {
        HStack {
            Text("TIMESTAMP")
                .font(ChaosTheme.captionFont)
                .foregroundColor(ChaosTheme.faded)
                .tracking(2)

            Spacer()

            DatePicker("", selection: $viewModel.timestamp)
                .labelsHidden()
                .tint(ChaosTheme.red)
        }
        .padding(.vertical, 10)
        .overlay(alignment: .top) {
            Rectangle().fill(ChaosTheme.ink.opacity(0.06)).frame(height: 0.5)
        }
        .overlay(alignment: .bottom) {
            Rectangle().fill(ChaosTheme.ink.opacity(0.06)).frame(height: 0.5)
        }
    }

    // MARK: - Notes

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            SectionHeader(title: "NOTES")

            TextField("ADD NOTES...", text: $viewModel.notes, axis: .vertical)
                .font(ChaosTheme.font(9))
                .foregroundColor(ChaosTheme.ink)
                .tracking(1)
                .lineLimit(3...6)
                .padding(12)
                .background(ChaosTheme.background.opacity(0.3))
                .overlay(
                    Rectangle()
                        .stroke(ChaosTheme.ink.opacity(0.08), lineWidth: 0.5)
                )
        }
    }

    // MARK: - Buttons

    private var buttonSection: some View {
        VStack(spacing: 10) {
            ChaosButton(title: "LOG READING") {
                if let _ = viewModel.save(modelContext: modelContext) {
                    showSavedConfirmation = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        showSavedConfirmation = false
                        viewModel.reset()
                    }
                }
            }

            ChaosSecondaryButton(title: "LOG & CALCULATE DOSE") {
                // Save and navigate to dose calculator
                if let _ = viewModel.save(modelContext: modelContext) {
                    viewModel.reset()
                }
            }
        }
    }

    // MARK: - Saved Confirmation

    private var savedOverlay: some View {
        VStack {
            Text("\u{25C6} LOGGED")
                .font(ChaosTheme.font(14))
                .foregroundColor(ChaosTheme.inRange)
                .tracking(4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ChaosTheme.background.opacity(0.9))
        .transition(.opacity)
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
