import SwiftUI
import SwiftData

struct CategoryManagementView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var allSettings: [UserSettings]

    @State private var newCategoryName: String = ""

    private var settings: UserSettings? { allSettings.first }

    private var customCategories: [String] {
        settings?.customCategories ?? [] as [String]
    }

    var body: some View {
        NavigationStack {
            List {
                // Default categories (read-only)
                Section("Default Categories") {
                    ForEach(DefaultFoodCategory.defaultNames, id: \.self) { name in
                        Text(name)
                    }
                }

                // Custom categories
                Section("Custom Categories") {
                    if customCategories.isEmpty {
                        Text("No custom categories")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(customCategories, id: \.self) { name in
                            HStack {
                                Text(name)
                                Spacer()
                                Button {
                                    deleteCategory(name)
                                } label: {
                                    Image(systemName: "trash")
                                        .foregroundStyle(.red)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    HStack {
                        TextField("New category", text: $newCategoryName)
                            .textInputAutocapitalization(.characters)

                        Button("Add") {
                            addCategory()
                        }
                        .disabled(newCategoryName.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
            }
            .navigationTitle("Categories")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private func addCategory() {
        let name = newCategoryName.trimmingCharacters(in: .whitespaces).uppercased()
        guard !name.isEmpty else { return }
        guard !DefaultFoodCategory.defaultNames.contains(name) else { return }
        guard !(settings?.customCategories?.contains(name) ?? false) else { return }

        if settings?.customCategories == nil {
            settings?.customCategories = [name]
        } else {
            settings?.customCategories?.append(name)
        }
        newCategoryName = ""
    }

    private func deleteCategory(_ name: String) {
        settings?.customCategories?.removeAll { $0 == name }

        let predicate = #Predicate<FoodItem> { $0.category == name }
        let descriptor = FetchDescriptor<FoodItem>(predicate: predicate)
        if let foods = try? modelContext.fetch(descriptor) {
            for food in foods {
                food.category = "UNCATEGORIZED"
            }
        }
    }
}
