import SwiftUI
import SwiftData

struct DoseCalculatorView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = DoseCalculatorViewModel()
    @State private var showSavedConfirmation = false
    @Binding var selectedTab: Int

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Input fields
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
                        unit: "GRAMS"
                    )

                    Divider()

                    // Food search
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Add Carbs from Food")
                            .font(.headline)

                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundStyle(.secondary)
                            TextField("Search foods...", text: $viewModel.foodSearchText)
                                .textInputAutocapitalization(.characters)
                        }
                        .padding(10)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)

                        if !viewModel.searchResults.isEmpty {
                            ForEach(viewModel.searchResults) { food in
                                Button {
                                    viewModel.addFoodCarbs(food)
                                } label: {
                                    HStack {
                                        Image(systemName: "plus.circle")
                                            .foregroundStyle(.secondary)

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(food.name)
                                            Text("\(Int(food.carbsPerServing))g carb / \(food.defaultServingSize)")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                    }
                                    .padding(.vertical, 4)
                                }
                                .buttonStyle(.plain)
                            }
                        } else if viewModel.foodSearchText.isEmpty && !viewModel.recentFoods.isEmpty {
                            Text("Recent Foods")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            ForEach(viewModel.recentFoods) { food in
                                Button {
                                    viewModel.addFoodCarbs(food)
                                } label: {
                                    HStack {
                                        Image(systemName: "plus.circle")
                                            .foregroundStyle(.secondary)
                                        Text(food.name)
                                        Spacer()
                                        Text("\(Int(food.carbsPerServing))g")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    .padding(.vertical, 4)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    Divider()

                    // Current settings
                    VStack(spacing: 0) {
                        SettingsRow(label: "Insulin:Carb Ratio (ICR)", value: "1:\(Int(viewModel.carbRatio))")
                        SettingsRow(label: "Insulin Sensitivity (ISF)", value: "1:\(Int(viewModel.sensitivityFactor))")
                        SettingsRow(
                            label: "Active Insulin on Board",
                            value: String(format: "%.1f u", viewModel.insulinOnBoard)
                        )
                    }

                    Text("Dose = (Carbs / ICR) + ((BG - Target) / ISF) - IOB")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .frame(maxWidth: .infinity, alignment: .trailing)

                    Divider()

                    // Result
                    VStack(spacing: 12) {
                        Text("Dose Calculation")
                            .font(.headline)

                        if let calc = viewModel.calculation {
                            HStack(spacing: 0) {
                                doseComponent(label: "Meal Dose", value: calc.mealDose, unit: "u")
                                Text("+").foregroundStyle(.secondary)
                                doseComponent(label: "Correction", value: calc.correctionDose, unit: "u")
                                Text("\u{2212}").foregroundStyle(.secondary)
                                doseComponent(label: "IOB", value: calc.iob, unit: "u")
                            }

                            VStack(spacing: 4) {
                                Text("Recommended Dose")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(String(format: "%.1f", calc.totalDose))
                                    .font(.system(size: 48, weight: .bold, design: .monospaced))
                                Text("units")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)

                            ChaosButton(title: "Confirm & Log Dose") {
                                if let dose = viewModel.saveDose(modelContext: modelContext) {
                                    appLog("Dose logged: \(dose.totalUnits)u (meal=\(dose.mealUnits), corr=\(dose.correctionUnits), iob=\(dose.iobDeducted))", category: "DATA")
                                    DatabaseExporter.shared.exportDose(
                                        glucose: viewModel.currentGlucose,
                                        correction: dose.correctionUnits,
                                        carbDose: dose.mealUnits,
                                        total: dose.totalUnits,
                                        iob: dose.iobDeducted
                                    )
                                    showSavedConfirmation = true
                                    Task {
                                        try? await Task.sleep(for: .seconds(1.5))
                                        showSavedConfirmation = false
                                        viewModel.reset()
                                        viewModel.loadSettings(modelContext: modelContext)
                                    }
                                }
                            }
                        } else {
                            Text("Enter values to calculate")
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 30)
                        }
                    }
                }
                .padding()
            }
            .chaosKeyboardDismiss()
            .navigationTitle("Dose Calculator")
        }
        .onAppear {
            appLog("Dose calculator appeared — loading settings", category: "NAV")
            viewModel.loadSettings(modelContext: modelContext)
            viewModel.calculate()
        }
        .onChange(of: selectedTab) { _, newTab in
            if newTab == 2 {
                appLog("Dose tab selected — reloading settings (ICR=\(viewModel.carbRatio), ISF=\(viewModel.sensitivityFactor))", category: "NAV")
                viewModel.loadSettings(modelContext: modelContext)
                viewModel.calculate()
            }
        }
        .onChange(of: viewModel.currentGlucose) { _, _ in viewModel.calculate() }
        .onChange(of: viewModel.carbIntake) { _, _ in viewModel.calculate() }
        .onChange(of: viewModel.foodSearchText) { _, _ in
            viewModel.searchFoods(modelContext: modelContext)
        }
        .overlay {
            if showSavedConfirmation {
                VStack {
                    Text("Dose Logged!")
                        .font(.title2.bold())
                        .foregroundColor(.green)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.ultraThinMaterial)
                .transition(.opacity)
            }
        }
    }

    private func doseComponent(label: String, value: Double, unit: String) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)

            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(String(format: "%.1f", value))
                    .font(.title3)
                Text(unit)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
    }
}
