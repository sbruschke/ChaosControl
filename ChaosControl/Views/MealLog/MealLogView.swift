import SwiftUI
import SwiftData

struct MealLogView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = MealLogViewModel()
    @State private var recentFoods: [FoodItem] = []
    @State private var showSavedConfirmation = false
    @Binding var selectedTab: Int

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Meal name input
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Meal Name (Optional)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        TextField("e.g. Lunch at home", text: $viewModel.mealName)
                            .textFieldStyle(.roundedBorder)
                            .textInputAutocapitalization(.words)
                    }

                    // Meal type tabs
                    Picker("Meal Type", selection: $viewModel.selectedMealType) {
                        ForEach(MealType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)

                    // Current meal summary
                    if !viewModel.currentItems.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("\(viewModel.selectedMealType.rawValue) Intake")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            HStack(alignment: .lastTextBaseline, spacing: 4) {
                                Text("\(Int(viewModel.totalCarbs))")
                                    .font(.system(size: 36, weight: .bold))
                                Text("g carbs")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }

                    // Logged items
                    if !viewModel.currentItems.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Logged Items")
                                .font(.headline)

                            ForEach(viewModel.currentItems.indices, id: \.self) { index in
                                let item = viewModel.currentItems[index]
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(item.name)
                                        if !item.servingSize.isEmpty {
                                            Text(item.servingSize)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }

                                    Spacer()

                                    Text("\(Int(item.carbs))g")
                                        .font(.body.bold())
                                }
                                .padding(.vertical, 4)
                                if index < viewModel.currentItems.count - 1 {
                                    Divider()
                                }
                            }
                        }
                    }

                    // Add food button
                    Button { viewModel.showingAddItem = true } label: {
                        Label("Add Food Item", systemImage: "plus")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)

                    Divider()

                    // Category filter
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Filter by Category")
                            .font(.headline)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                categoryPill(name: "All", isSelected: viewModel.selectedCategory == nil) {
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

                    // Recent foods
                    VStack(alignment: .leading, spacing: 8) {
                        Text(viewModel.selectedCategory != nil ? "\(viewModel.selectedCategory!) Foods" : "Recent / Favorites")
                            .font(.headline)

                        if recentFoods.isEmpty {
                            Text("No foods found")
                                .foregroundStyle(.secondary)
                                .padding(.vertical, 8)
                        } else {
                            ForEach(recentFoods) { food in
                                Button {
                                    viewModel.addFromFavorite(food, modelContext: modelContext)
                                } label: {
                                    HStack {
                                        Image(systemName: "plus.circle")
                                            .foregroundStyle(.secondary)

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(food.name)
                                            Text("\(Int(food.carbsPerServing))g carb / \(food.category ?? "Uncategorized")")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                    }
                                    .padding(.vertical, 4)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    // Log meal button
                    if !viewModel.currentItems.isEmpty {
                        ChaosButton(title: "Log Meal & Calculate Dose") {
                            appLog("Attempting to save meal: \(viewModel.currentItems.count) items, \(viewModel.totalCarbs)g carbs", category: "DATA")
                            if let meal = viewModel.saveMeal(modelContext: modelContext) {
                                appLog("Meal saved: \(meal.totalCarbs)g carbs, \(meal.items.count) items", category: "DATA")
                                showSavedConfirmation = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    showSavedConfirmation = false
                                    viewModel.reset()
                                    recentFoods = viewModel.loadRecentFoods(modelContext: modelContext)
                                }
                            } else {
                                appLog("Meal save returned nil — empty items?", category: "WARN")
                            }
                        }
                    }
                }
                .padding()
            }
            .chaosKeyboardDismiss()
            .navigationTitle("Meal Log")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.showingCategoryManagement = true
                    } label: {
                        Image(systemName: "square.grid.2x2")
                    }
                }
            }
        }
        .onAppear {
            recentFoods = viewModel.loadRecentFoods(modelContext: modelContext)
            viewModel.loadCategories(modelContext: modelContext)
            autoSelectMealType()
        }
        .onChange(of: selectedTab) { _, newTab in
            if newTab == 3 {
                recentFoods = viewModel.loadRecentFoods(modelContext: modelContext)
                viewModel.loadCategories(modelContext: modelContext)
            }
        }
        .sheet(isPresented: $viewModel.showingAddItem) {
            addItemSheet
        }
        .sheet(isPresented: $viewModel.showingCategoryManagement) {
            CategoryManagementView()
        }
        .overlay {
            if showSavedConfirmation {
                VStack {
                    Text("Meal Logged!")
                        .font(.title2.bold())
                        .foregroundColor(.green)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.ultraThinMaterial)
                .transition(.opacity)
            }
        }
    }

    private func categoryPill(name: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(name)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.accentColor.opacity(0.15) : Color(.systemGray6))
                .cornerRadius(6)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Add Item Sheet

    private var addItemSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Food Name")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        TextField("Food name", text: $viewModel.newItemName)
                            .textFieldStyle(.roundedBorder)
                            .textInputAutocapitalization(.words)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Quantity / Serving")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        TextField("e.g. 1 cup", text: $viewModel.newItemServing)
                            .textFieldStyle(.roundedBorder)
                            .textInputAutocapitalization(.words)
                    }

                    ChaosNumericField(label: "CARBS", value: $viewModel.newItemCarbs, unit: "g")

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Category")
                            .font(.caption)
                            .foregroundStyle(.secondary)

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
                                        .font(.caption)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 8)
                                        .background(viewModel.newItemCategory == category ? Color.accentColor.opacity(0.15) : Color(.systemGray6))
                                        .cornerRadius(6)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    ChaosButton(title: "Add Item") {
                        viewModel.addItem()
                    }
                }
                .padding()
            }
            .navigationTitle("Add Food")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { viewModel.showingAddItem = false }
                }
            }
        }
        .chaosKeyboardDismiss()
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
