import SwiftUI
import SwiftData

@main
struct ChaosControlApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            GlucoseReading.self,
            Meal.self,
            MealItem.self,
            InsulinDose.self,
            FoodItem.self,
            UserSettings.self
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )

        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])

            // Ensure default settings exist
            let context = ModelContext(container)
            let descriptor = FetchDescriptor<UserSettings>()
            if (try? context.fetch(descriptor))?.isEmpty ?? true {
                let defaultSettings = UserSettings()
                context.insert(defaultSettings)
                try? context.save()
            }

            return container
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.light)
        }
        .modelContainer(sharedModelContainer)
    }
}
