import SwiftUI
import SwiftData

struct DoseCalculatorView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = DoseCalculatorViewModel()
    @State private var showSavedConfirmation = false

    var body: some View {
        ZStack {
            ChaosTheme.background.ignoresSafeArea()
            ConstructionLines(verticalOffset: 0.3, horizontalOffset: 0.55)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    header
                        .padding(.bottom, 18)

                    // Input fields
                    inputSection
                        .padding(.bottom, 14)

                    ChaosDivider()
                        .padding(.bottom, 10)

                    // Current settings
                    settingsSection
                        .padding(.bottom, 4)

                    formulaNote
                        .padding(.bottom, 10)

                    RedDivider()
                        .padding(.bottom, 14)

                    // Calculation result
                    resultSection
                }
                .padding(.horizontal, ChaosTheme.screenPadding)
                .padding(.bottom, 20)
            }

            // Annotations
            VStack {
                HStack {
                    Spacer()
                    AnnotationText(text: "CC-DC-02")
                }
                Spacer()
                HStack {
                    Spacer()
                    AnnotationText(text: "\u{16A0}\u{16B1} DOSE.REF")
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .allowsHitTesting(false)
        }
        .onAppear {
            viewModel.loadSettings(modelContext: modelContext)
        }
        .onChange(of: viewModel.currentGlucose) { _, _ in viewModel.calculate() }
        .onChange(of: viewModel.carbIntake) { _, _ in viewModel.calculate() }
        .overlay {
            if showSavedConfirmation {
                savedOverlay
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("DOSE CODEX")
                .font(ChaosTheme.titleFont)
                .foregroundColor(ChaosTheme.ink)
                .tracking(4)

            Text("INSULIN CALCULATION // ACTIVE")
                .font(ChaosTheme.captionFont)
                .foregroundColor(ChaosTheme.faded)
                .tracking(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Inputs

    private var inputSection: some View {
        VStack(spacing: 14) {
            ChaosNumericField(
                label: "CURRENT GLUCOSE",
                value: $viewModel.currentGlucose,
                unit: "MG/DL"
            )

            ChaosNumericField(
                label: "TARGET GLUCOSE",
                value: $viewModel.targetGlucose,
                unit: "MG/DL"
            )

            ChaosNumericField(
                label: "CARB INTAKE",
                value: $viewModel.carbIntake,
                unit: "GRAMS",
                highlighted: true
            )
        }
    }

    // MARK: - Settings

    private var settingsSection: some View {
        VStack(spacing: 0) {
            SettingsRow(label: "INSULIN:CARB RATIO (ICR)", value: "1:\(Int(viewModel.carbRatio))")
            SettingsRow(label: "INSULIN SENSITIVITY (ISF)", value: "1:\(Int(viewModel.sensitivityFactor))")
            SettingsRow(
                label: "ACTIVE INSULIN ON BOARD",
                value: String(format: "%.1f u", viewModel.insulinOnBoard)
            )
        }
    }

    private var formulaNote: some View {
        Text("DOSE = (CARBS / ICR) + ((BG - TARGET) / ISF) - IOB")
            .font(ChaosTheme.microFont)
            .foregroundColor(ChaosTheme.ink.opacity(0.2))
            .tracking(1)
            .frame(maxWidth: .infinity, alignment: .trailing)
    }

    // MARK: - Result

    private var resultSection: some View {
        VStack(spacing: 14) {
            RedSectionHeader(title: "DOSE CALCULATION")

            if let calc = viewModel.calculation {
                // Breakdown
                HStack(spacing: 0) {
                    doseComponent(label: "MEAL DOSE", value: calc.mealDose, unit: "u")
                    doseOperator("+")
                    doseComponent(label: "CORRECTION", value: calc.correctionDose, unit: "u")
                    doseOperator("\u{2212}")
                    doseComponent(label: "IOB", value: calc.iob, unit: "u")
                }

                // Total
                totalDoseDisplay(calc.totalDose)

                ChaosButton(title: "CONFIRM & LOG DOSE") {
                    if let _ = viewModel.saveDose(modelContext: modelContext) {
                        showSavedConfirmation = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            showSavedConfirmation = false
                            viewModel.reset()
                            viewModel.loadSettings(modelContext: modelContext)
                        }
                    }
                }
            } else {
                Text("ENTER VALUES TO CALCULATE")
                    .font(ChaosTheme.captionFont)
                    .foregroundColor(ChaosTheme.faded)
                    .tracking(2)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 30)
            }
        }
    }

    private func doseComponent(label: String, value: Double, unit: String) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(ChaosTheme.microFont)
                .foregroundColor(ChaosTheme.faded)
                .tracking(1.5)

            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(String(format: "%.1f", value))
                    .font(ChaosTheme.font(16))
                    .foregroundColor(ChaosTheme.ink)
                    .tracking(1)
                Text(unit)
                    .font(ChaosTheme.microFont)
                    .foregroundColor(ChaosTheme.faded)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func doseOperator(_ op: String) -> some View {
        Text(op)
            .font(ChaosTheme.font(14))
            .foregroundColor(ChaosTheme.red.opacity(0.4))
    }

    private func totalDoseDisplay(_ total: Double) -> some View {
        VStack(spacing: 8) {
            Text("RECOMMENDED DOSE")
                .font(ChaosTheme.captionFont)
                .foregroundColor(ChaosTheme.faded)
                .tracking(3)

            Text(String(format: "%.1f", total))
                .font(ChaosTheme.font(48))
                .foregroundColor(ChaosTheme.ink)
                .tracking(2)

            Text("UNITS")
                .font(ChaosTheme.font(12))
                .foregroundColor(ChaosTheme.faded)
                .tracking(3)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(ChaosTheme.background.opacity(0.3))
        .overlay(
            Rectangle().stroke(ChaosTheme.border, lineWidth: 0.5)
        )
        .overlay(
            Rectangle()
                .stroke(ChaosTheme.red.opacity(0.1), lineWidth: 0.5)
                .padding(4)
        )
    }

    private var savedOverlay: some View {
        VStack {
            Text("\u{25C6} DOSE LOGGED")
                .font(ChaosTheme.font(14))
                .foregroundColor(ChaosTheme.inRange)
                .tracking(4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ChaosTheme.background.opacity(0.9))
        .transition(.opacity)
    }
}
