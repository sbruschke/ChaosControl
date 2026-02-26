import SwiftUI
import SwiftData

@main
struct ChaosControlApp: App {
    init() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(ChaosTheme.background)
        appearance.shadowColor = .clear
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
    }

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

        func createContainer() throws -> ModelContainer {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            let context = ModelContext(container)
            let descriptor = FetchDescriptor<UserSettings>()
            if (try? context.fetch(descriptor))?.isEmpty ?? true {
                let defaultSettings = UserSettings()
                context.insert(defaultSettings)
                try? context.save()
            }
            return container
        }

        do {
            return try createContainer()
        } catch {
            // Schema mismatch — delete old store and retry
            let url = modelConfiguration.url
            let storePath = url.path()
            for suffix in ["", "-wal", "-shm"] {
                try? FileManager.default.removeItem(atPath: storePath + suffix)
            }
            do {
                return try createContainer()
            } catch {
                fatalError("Could not create ModelContainer: \(error)")
            }
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
