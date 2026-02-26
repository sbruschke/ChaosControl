import SwiftUI
import SwiftData

struct MealLogView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = MealLogViewModel()
    @State private var recentFoods: [FoodItem] = []
    @State private var showSavedConfirmation = false

    var body: some View {
        ZStack {
            ChaosTheme.background.ignoresSafeArea()
            ConstructionLines(showVertical: false, horizontalOffset: 0.3)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    header
                        .padding(.bottom, 16)

                    // Search bar
                    searchBar
                        .padding(.bottom, 14)

                    // Meal type tabs
                    mealTabs
                        .padding(.bottom, 16)

                    // Current meal summary
                    if !viewModel.currentItems.isEmpty {
                        mealSummary
                            .padding(.bottom, 16)
                    }

                    // Logged items
                    if !viewModel.currentItems.isEmpty {
                        loggedItems
                            .padding(.bottom, 14)
                    }

                    // Add food button
                    addFoodButton
                        .padding(.bottom, 14)

                    ChaosDivider()
                        .padding(.bottom, 14)

                    // Recent / favorites
                    recentSection
                        .padding(.bottom, 16)

                    // Log meal button
                    if !viewModel.currentItems.isEmpty {
                        ChaosButton(title: "LOG MEAL & CALCULATE DOSE") {
                            if let _ = viewModel.saveMeal(modelContext: modelContext) {
                                showSavedConfirmation = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    showSavedConfirmation = false
                                    viewModel.reset()
                                    recentFoods = viewModel.loadRecentFoods(modelContext: modelContext)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, ChaosTheme.screenPadding)
                .padding(.bottom, 20)
            }

            // Annotations
            VStack {
                HStack {
                    Spacer()
                    AnnotationText(text: "CC-ML-03")
                }
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .allowsHitTesting(false)
        }
        .onAppear {
            recentFoods = viewModel.loadRecentFoods(modelContext: modelContext)
            autoSelectMealType()
        }
        .sheet(isPresented: $viewModel.showingAddItem) {
            addItemSheet
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
            Text("SUSTENANCE LOG")
                .font(ChaosTheme.titleFont)
                .foregroundColor(ChaosTheme.ink)
                .tracking(4)

            HStack(spacing: 0) {
                Text("MEAL TRACKING ")
                    .font(ChaosTheme.captionFont)
                    .foregroundColor(ChaosTheme.faded)
                    .tracking(2)
                Text("//")
                    .font(ChaosTheme.captionFont)
                    .foregroundColor(ChaosTheme.red)
                Text(" \(Date.now.formatted(.dateTime.day().month(.abbreviated).year()).uppercased())")
                    .font(ChaosTheme.captionFont)
                    .foregroundColor(ChaosTheme.faded)
                    .tracking(2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Search

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 12))
                .foregroundColor(ChaosTheme.ink.opacity(0.3))

            Text("SEARCH FOODS...")
                .font(ChaosTheme.bodyFont)
                .foregroundColor(ChaosTheme.faded)
                .tracking(2)

            Spacer()
        }
        .padding(10)
        .background(ChaosTheme.background.opacity(0.3))
        .overlay(
            Rectangle().stroke(ChaosTheme.border, lineWidth: 0.5)
        )
        .overlay(alignment: .topLeading) {
            CornerBracket()
                .stroke(ChaosTheme.red, lineWidth: 0.5)
                .frame(width: 5, height: 5)
                .offset(x: -0.5, y: -0.5)
        }
    }

    // MARK: - Meal Type Tabs

    private var mealTabs: some View {
        HStack(spacing: 0) {
            ForEach(MealType.allCases, id: \.self) { type in
                Button {
                    viewModel.selectedMealType = type
                } label: {
                    Text(type.rawValue)
                        .font(ChaosTheme.microFont)
                        .foregroundColor(viewModel.selectedMealType == type ? ChaosTheme.red : ChaosTheme.faded)
                        .tracking(2)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .overlay(alignment: .bottom) {
                            Rectangle()
                                .fill(viewModel.selectedMealType == type ? ChaosTheme.red : ChaosTheme.ink.opacity(0.08))
                                .frame(height: viewModel.selectedMealType == type ? 1 : 0.5)
                        }
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Meal Summary

    private var mealSummary: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("\(viewModel.selectedMealType.rawValue) INTAKE // ACTIVE")
                    .font(ChaosTheme.font(9))
                    .foregroundColor(ChaosTheme.ink)
                    .tracking(2)
                Spacer()
                Text(Date.now.formatted(.dateTime.hour().minute()))
                    .font(ChaosTheme.microFont)
                    .foregroundColor(ChaosTheme.faded)
                    .tracking(1)
            }

            HStack(spacing: 16) {
                macroItem("CARBS", value: viewModel.totalCarbs, unit: "g", fill: ChaosTheme.red.opacity(0.5))
                macroItem("PROTEIN", value: viewModel.totalProtein, unit: "g", fill: ChaosTheme.inRange.opacity(0.5))
                macroItem("FAT", value: viewModel.totalFat, unit: "g", fill: ChaosTheme.warning.opacity(0.5))
                macroItem("FIBER", value: viewModel.totalFiber, unit: "g", fill: ChaosTheme.ink.opacity(0.15))
                macroItem("KCAL", value: viewModel.totalCalories, unit: "", fill: ChaosTheme.ink.opacity(0.1))
            }
        }
        .chaosCard()
    }

    private func macroItem(_ label: String, value: Double, unit: String, fill: Color) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(ChaosTheme.annotationFont)
                .foregroundColor(ChaosTheme.faded)
                .tracking(2)

            HStack(alignment: .lastTextBaseline, spacing: 1) {
                Text("\(Int(value))")
                    .font(ChaosTheme.font(16))
                    .foregroundColor(ChaosTheme.ink)
                if !unit.isEmpty {
                    Text(unit)
                        .font(ChaosTheme.microFont)
                        .foregroundColor(ChaosTheme.faded)
                }
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(ChaosTheme.ink.opacity(0.06))
                        .frame(height: 2)
                    Rectangle()
                        .fill(fill)
                        .frame(width: min(geo.size.width, geo.size.width * min(1, value / 100)), height: 2)
                }
            }
            .frame(height: 2)
        }
    }

    // MARK: - Logged Items

    private var loggedItems: some View {
        VStack(spacing: 0) {
            SectionHeader(title: "LOGGED ITEMS")
                .padding(.bottom, 8)

            ForEach(viewModel.currentItems.indices, id: \.self) { index in
                let item = viewModel.currentItems[index]
                HStack {
                    Rectangle()
                        .fill(ChaosTheme.red.opacity(0.4))
                        .frame(width: 3, height: 3)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.name)
                            .font(ChaosTheme.bodyFont)
                            .foregroundColor(ChaosTheme.ink)
                            .tracking(1)
                        Text("\(item.servingSize) // \(Int(item.calories)) KCAL // \(Int(item.carbs))g CARB")
                            .font(ChaosTheme.microFont)
                            .foregroundColor(ChaosTheme.faded)
                            .tracking(1)
                    }

                    Spacer()

                    VStack(alignment: .trailing) {
                        Text("\(Int(item.carbs))")
                            .font(ChaosTheme.font(14))
                            .foregroundColor(ChaosTheme.ink)
                            .tracking(1)
                        Text("g")
                            .font(ChaosTheme.microFont)
                            .foregroundColor(ChaosTheme.faded)
                    }
                }
                .padding(.vertical, 10)
                .overlay(alignment: .bottom) {
                    if index < viewModel.currentItems.count - 1 {
                        Rectangle().fill(ChaosTheme.ink.opacity(0.05)).frame(height: 0.5)
                    }
                }
            }
        }
    }

    // MARK: - Add Food

    private var addFoodButton: some View {
        Button { viewModel.showingAddItem = true } label: {
            Text("+ ADD FOOD ITEM")
                .font(ChaosTheme.font(9))
                .foregroundColor(ChaosTheme.faded)
                .tracking(3)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .overlay(
                    Rectangle()
                        .stroke(ChaosTheme.ink.opacity(0.15), style: StrokeStyle(lineWidth: 0.5, dash: [4, 4]))
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Recent Foods

    private var recentSection: some View {
        VStack(spacing: 0) {
            SectionHeader(title: "RECENT // FAVORITES")
                .padding(.bottom, 8)

            if recentFoods.isEmpty {
                Text("NO RECENT FOODS")
                    .font(ChaosTheme.captionFont)
                    .foregroundColor(ChaosTheme.faded)
                    .tracking(2)
                    .padding(.vertical, 12)
            } else {
                ForEach(recentFoods) { food in
                    Button {
                        viewModel.addFromFavorite(food, modelContext: modelContext)
                    } label: {
                        HStack {
                            Text("+")
                                .font(ChaosTheme.font(12))
                                .foregroundColor(ChaosTheme.faded)
                                .frame(width: 20, height: 20)
                                .overlay(
                                    Rectangle().stroke(ChaosTheme.ink.opacity(0.15), lineWidth: 0.5)
                                )

                            VStack(alignment: .leading, spacing: 2) {
                                Text(food.name)
                                    .font(ChaosTheme.font(9))
                                    .foregroundColor(ChaosTheme.ink)
                                    .tracking(1)
                                Text("\(Int(food.carbsPerServing))g CARB // \(Int(food.caloriesPerServing)) KCAL")
                                    .font(ChaosTheme.microFont)
                                    .foregroundColor(ChaosTheme.faded)
                                    .tracking(1)
                            }

                            Spacer()
                        }
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Add Item Sheet

    private var addItemSheet: some View {
        NavigationStack {
            ZStack {
                ChaosTheme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 14) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("FOOD NAME")
                                .font(ChaosTheme.microFont)
                                .foregroundColor(ChaosTheme.faded)
                                .tracking(2.5)

                            TextField("", text: $viewModel.newItemName)
                                .font(ChaosTheme.font(14))
                                .foregroundColor(ChaosTheme.ink)
                                .textInputAutocapitalization(.characters)
                                .padding(12)
                                .overlay(Rectangle().stroke(ChaosTheme.border, lineWidth: 0.5))
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("SERVING SIZE")
                                .font(ChaosTheme.microFont)
                                .foregroundColor(ChaosTheme.faded)
                                .tracking(2.5)

                            TextField("e.g. 1 CUP", text: $viewModel.newItemServing)
                                .font(ChaosTheme.font(14))
                                .foregroundColor(ChaosTheme.ink)
                                .textInputAutocapitalization(.characters)
                                .padding(12)
                                .overlay(Rectangle().stroke(ChaosTheme.border, lineWidth: 0.5))
                        }

                        ChaosNumericField(label: "CARBS", value: $viewModel.newItemCarbs, unit: "g")
                        ChaosNumericField(label: "PROTEIN", value: $viewModel.newItemProtein, unit: "g")
                        ChaosNumericField(label: "FAT", value: $viewModel.newItemFat, unit: "g")
                        ChaosNumericField(label: "FIBER", value: $viewModel.newItemFiber, unit: "g")
                        ChaosNumericField(label: "CALORIES", value: $viewModel.newItemCalories, unit: "KCAL")

                        ChaosButton(title: "ADD ITEM") {
                            viewModel.addItem()
                        }
                    }
                    .padding(ChaosTheme.screenPadding)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("ADD FOOD")
                        .font(ChaosTheme.titleFont)
                        .foregroundColor(ChaosTheme.ink)
                        .tracking(4)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("CLOSE") { viewModel.showingAddItem = false }
                        .font(ChaosTheme.captionFont)
                        .foregroundColor(ChaosTheme.red)
                }
            }
        }
    }

    private var savedOverlay: some View {
        VStack {
            Text("\u{25C6} MEAL LOGGED")
                .font(ChaosTheme.font(14))
                .foregroundColor(ChaosTheme.inRange)
                .tracking(4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ChaosTheme.background.opacity(0.9))
        .transition(.opacity)
    }

    private func autoSelectMealType() {
        let hour = Calendar.current.component(.hour, from: .now)
        switch hour {
        case 0..<6: viewModel.selectedMealType = .snack
        case 6..<11: viewModel.selectedMealType = .morning
        case 11..<15: viewModel.selectedMealType = .midday
        case 15..<20: viewModel.selectedMealType = .evening
        default: viewModel.selectedMealType = .snack
        }
    }
}
