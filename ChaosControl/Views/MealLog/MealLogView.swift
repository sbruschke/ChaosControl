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

                    // Meal name input
                    mealNameInput
                        .padding(.bottom, 14)

                    // Meal type tabs
                    mealTabs
                        .padding(.bottom, 16)

                    // Current meal summary (carbs only)
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

                    // Category filter
                    categoryFilter
                        .padding(.bottom, 12)

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
            .chaosKeyboardDismiss()

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
            viewModel.loadCategories(modelContext: modelContext)
            autoSelectMealType()
        }
        .sheet(isPresented: $viewModel.showingAddItem) {
            addItemSheet
        }
        .sheet(isPresented: $viewModel.showingCategoryManagement) {
            CategoryManagementView()
        }
        .overlay {
            if showSavedConfirmation {
                savedOverlay
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
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

            Spacer()

            Button {
                viewModel.showingCategoryManagement = true
            } label: {
                Image(systemName: "square.grid.2x2")
                    .font(.system(size: 15, weight: .light))
                    .foregroundColor(ChaosTheme.ink.opacity(0.5))
            }
        }
    }

    // MARK: - Meal Name

    private var mealNameInput: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Circle()
                    .fill(ChaosTheme.red.opacity(0.4))
                    .frame(width: 4, height: 4)
                Text("MEAL NAME (OPTIONAL)")
                    .font(ChaosTheme.microFont)
                    .foregroundColor(ChaosTheme.faded)
                    .tracking(2.5)
            }

            TextField("E.G. LUNCH AT HOME", text: $viewModel.mealName)
                .font(ChaosTheme.bodyFont)
                .foregroundColor(ChaosTheme.ink)
                .textInputAutocapitalization(.characters)
                .tracking(1)
                .padding(10)
                .background(ChaosTheme.paperDark.opacity(0.5))
                .overlay(alignment: .bottom) {
                    LinearGradient(
                        colors: [ChaosTheme.red.opacity(0.4), ChaosTheme.red.opacity(0.1)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(height: 1.5)
                }
                .overlay(
                    Rectangle().stroke(ChaosTheme.border, lineWidth: 0.5)
                )
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

    // MARK: - Meal Summary (carbs only)

    private var mealSummary: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("\(viewModel.selectedMealType.rawValue) INTAKE // ACTIVE")
                    .font(ChaosTheme.font(12))
                    .foregroundColor(ChaosTheme.ink)
                    .tracking(2)
                Spacer()
                Text(Date.now.formatted(.dateTime.hour().minute()))
                    .font(ChaosTheme.microFont)
                    .foregroundColor(ChaosTheme.faded)
                    .tracking(1)
            }

            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text("\(Int(viewModel.totalCarbs))")
                    .font(ChaosTheme.font(42))
                    .foregroundColor(ChaosTheme.ink)
                    .tracking(1)
                Text("g CARBS")
                    .font(ChaosTheme.captionFont)
                    .foregroundColor(ChaosTheme.faded)
                    .tracking(2)
            }
        }
        .chaosCard()
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
                        if !item.servingSize.isEmpty {
                            Text(item.servingSize)
                                .font(ChaosTheme.microFont)
                                .foregroundColor(ChaosTheme.faded)
                                .tracking(1)
                        }
                    }

                    Spacer()

                    VStack(alignment: .trailing) {
                        Text("\(Int(item.carbs))")
                            .font(ChaosTheme.font(17))
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
                .font(ChaosTheme.font(12))
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

    // MARK: - Category Filter

    private var categoryFilter: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(title: "FILTER BY CATEGORY")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    // "All" pill
                    categoryPill(name: "ALL", isSelected: viewModel.selectedCategory == nil) {
                        viewModel.selectedCategory = nil
                        recentFoods = viewModel.loadRecentFoods(modelContext: modelContext)
                    }

                    ForEach(viewModel.allCategories, id: \.self) { category in
                        categoryPill(name: category, isSelected: viewModel.selectedCategory == category) {
                            viewModel.selectedCategory = category
                            recentFoods = viewModel.loadFoodsByCategory(modelContext: modelContext, category: category)
                        }
                    }
                }
            }
        }
    }

    private func categoryPill(name: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(name)
                .font(ChaosTheme.microFont)
                .foregroundColor(isSelected ? ChaosTheme.red : ChaosTheme.faded)
                .tracking(1.5)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? ChaosTheme.red.opacity(0.06) : .clear)
                .overlay(
                    Rectangle()
                        .stroke(isSelected ? ChaosTheme.red.opacity(0.4) : ChaosTheme.border, lineWidth: 0.5)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Recent Foods

    private var recentSection: some View {
        VStack(spacing: 0) {
            SectionHeader(title: viewModel.selectedCategory != nil ? "\(viewModel.selectedCategory!) FOODS" : "RECENT // FAVORITES")
                .padding(.bottom, 8)

            if recentFoods.isEmpty {
                Text("NO FOODS FOUND")
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
                                .font(ChaosTheme.font(15))
                                .foregroundColor(ChaosTheme.faded)
                                .frame(width: 22, height: 22)
                                .overlay(
                                    Rectangle().stroke(ChaosTheme.ink.opacity(0.15), lineWidth: 0.5)
                                )

                            VStack(alignment: .leading, spacing: 2) {
                                Text(food.name)
                                    .font(ChaosTheme.font(12))
                                    .foregroundColor(ChaosTheme.ink)
                                    .tracking(1)
                                Text("\(Int(food.carbsPerServing))g CARB // \(food.category ?? "UNCATEGORIZED")")
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

    // MARK: - Add Item Sheet (simplified)

    private var addItemSheet: some View {
        NavigationStack {
            ZStack {
                ChaosTheme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 14) {
                        // Food name
                        VStack(alignment: .leading, spacing: 6) {
                            Text("FOOD NAME")
                                .font(ChaosTheme.microFont)
                                .foregroundColor(ChaosTheme.faded)
                                .tracking(2.5)

                            TextField("", text: $viewModel.newItemName)
                                .font(ChaosTheme.font(17))
                                .foregroundColor(ChaosTheme.ink)
                                .textInputAutocapitalization(.characters)
                                .padding(12)
                                .background(ChaosTheme.paperDark.opacity(0.5))
                                .overlay(alignment: .bottom) {
                                    LinearGradient(
                                        colors: [ChaosTheme.red.opacity(0.4), ChaosTheme.red.opacity(0.1)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                    .frame(height: 1.5)
                                }
                                .overlay(Rectangle().stroke(ChaosTheme.border, lineWidth: 0.5))
                        }

                        // Serving size
                        VStack(alignment: .leading, spacing: 6) {
                            Text("QUANTITY / SERVING")
                                .font(ChaosTheme.microFont)
                                .foregroundColor(ChaosTheme.faded)
                                .tracking(2.5)

                            TextField("E.G. 1 CUP", text: $viewModel.newItemServing)
                                .font(ChaosTheme.font(17))
                                .foregroundColor(ChaosTheme.ink)
                                .textInputAutocapitalization(.characters)
                                .padding(12)
                                .background(ChaosTheme.paperDark.opacity(0.5))
                                .overlay(alignment: .bottom) {
                                    LinearGradient(
                                        colors: [ChaosTheme.red.opacity(0.4), ChaosTheme.red.opacity(0.1)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                    .frame(height: 1.5)
                                }
                                .overlay(Rectangle().stroke(ChaosTheme.border, lineWidth: 0.5))
                        }

                        // Carbs
                        ChaosNumericField(label: "CARBS", value: $viewModel.newItemCarbs, unit: "g")

                        // Category picker
                        VStack(alignment: .leading, spacing: 8) {
                            Text("CATEGORY")
                                .font(ChaosTheme.microFont)
                                .foregroundColor(ChaosTheme.faded)
                                .tracking(2.5)

                            categoryPickerGrid
                        }

                        ChaosButton(title: "ADD ITEM") {
                            viewModel.addItem()
                        }
                    }
                    .padding(ChaosTheme.screenPadding)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(ChaosTheme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
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
        .chaosKeyboardDismiss()
    }

    private var categoryPickerGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 6),
            GridItem(.flexible(), spacing: 6),
            GridItem(.flexible(), spacing: 6)
        ], spacing: 6) {
            ForEach(viewModel.allCategories, id: \.self) { category in
                Button {
                    viewModel.newItemCategory = category
                } label: {
                    Text(category)
                        .font(ChaosTheme.microFont)
                        .foregroundColor(viewModel.newItemCategory == category ? ChaosTheme.red : ChaosTheme.faded)
                        .tracking(1)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(viewModel.newItemCategory == category ? ChaosTheme.red.opacity(0.06) : .clear)
                        .overlay(
                            Rectangle()
                                .stroke(
                                    viewModel.newItemCategory == category ? ChaosTheme.red.opacity(0.4) : ChaosTheme.border,
                                    lineWidth: 0.5
                                )
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var savedOverlay: some View {
        VStack {
            Text("\u{25C6} MEAL LOGGED")
                .font(ChaosTheme.font(17))
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
