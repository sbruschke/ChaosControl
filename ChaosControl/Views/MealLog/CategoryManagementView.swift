import SwiftUI
import SwiftData

struct CategoryManagementView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var allSettings: [UserSettings]

    @State private var newCategoryName: String = ""

    private var settings: UserSettings? { allSettings.first }

    private var customCategories: [String] {
        settings?.customCategories ?? []
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ChaosTheme.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Default categories (read-only)
                        VStack(alignment: .leading, spacing: 8) {
                            SectionHeader(title: "DEFAULT CATEGORIES")

                            ForEach(DefaultFoodCategory.defaultNames, id: \.self) { name in
                                HStack {
                                    Rectangle()
                                        .fill(ChaosTheme.red.opacity(0.4))
                                        .frame(width: 3, height: 3)
                                    Text(name)
                                        .font(ChaosTheme.bodyFont)
                                        .foregroundColor(ChaosTheme.ink)
                                        .tracking(1)
                                    Spacer()
                                }
                                .padding(.vertical, 6)
                                .overlay(alignment: .bottom) {
                                    Rectangle().fill(ChaosTheme.ink.opacity(0.04)).frame(height: 0.5)
                                }
                            }
                        }

                        RedDivider()

                        // Custom categories
                        VStack(alignment: .leading, spacing: 8) {
                            SectionHeader(title: "CUSTOM CATEGORIES")

                            if customCategories.isEmpty {
                                Text("NO CUSTOM CATEGORIES")
                                    .font(ChaosTheme.captionFont)
                                    .foregroundColor(ChaosTheme.faded)
                                    .tracking(2)
                                    .padding(.vertical, 8)
                            } else {
                                ForEach(customCategories, id: \.self) { name in
                                    HStack {
                                        Rectangle()
                                            .fill(ChaosTheme.warning.opacity(0.4))
                                            .frame(width: 3, height: 3)
                                        Text(name)
                                            .font(ChaosTheme.bodyFont)
                                            .foregroundColor(ChaosTheme.ink)
                                            .tracking(1)
                                        Spacer()

                                        Button {
                                            deleteCategory(name)
                                        } label: {
                                            Text("\u{00D7}")
                                                .font(ChaosTheme.font(17))
                                                .foregroundColor(ChaosTheme.red.opacity(0.6))
                                        }
                                        .buttonStyle(.plain)
                                    }
                                    .padding(.vertical, 6)
                                    .overlay(alignment: .bottom) {
                                        Rectangle().fill(ChaosTheme.ink.opacity(0.04)).frame(height: 0.5)
                                    }
                                }
                            }

                            // Add new category
                            HStack(spacing: 8) {
                                TextField("NEW CATEGORY", text: $newCategoryName)
                                    .font(ChaosTheme.bodyFont)
                                    .foregroundColor(ChaosTheme.ink)
                                    .textInputAutocapitalization(.characters)
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
                                    .overlay(Rectangle().stroke(ChaosTheme.border, lineWidth: 0.5))

                                Button {
                                    addCategory()
                                } label: {
                                    Text("ADD")
                                        .font(ChaosTheme.captionFont)
                                        .foregroundColor(ChaosTheme.red)
                                        .tracking(2)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 10)
                                        .overlay(
                                            Rectangle().stroke(ChaosTheme.red, lineWidth: 0.5)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(ChaosTheme.screenPadding)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(ChaosTheme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("CATEGORIES")
                        .font(ChaosTheme.titleFont)
                        .foregroundColor(ChaosTheme.ink)
                        .tracking(4)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("CLOSE") { dismiss() }
                        .font(ChaosTheme.captionFont)
                        .foregroundColor(ChaosTheme.faded)
                        .tracking(2)
                }
            }
        }
        .chaosKeyboardDismiss()
    }

    private func addCategory() {
        let name = newCategoryName.trimmingCharacters(in: .whitespaces).uppercased()
        guard !name.isEmpty else { return }
        guard !DefaultFoodCategory.defaultNames.contains(name) else { return }
        guard !(settings?.customCategories.contains(name) ?? false) else { return }

        settings?.customCategories.append(name)
        newCategoryName = ""
    }

    private func deleteCategory(_ name: String) {
        settings?.customCategories.removeAll { $0 == name }

        // Reassign foods in this category to UNCATEGORIZED
        let predicate = #Predicate<FoodItem> { $0.category == name }
        let descriptor = FetchDescriptor<FoodItem>(predicate: predicate)
        if let foods = try? modelContext.fetch(descriptor) {
            for food in foods {
                food.category = "UNCATEGORIZED"
            }
        }
    }
}
