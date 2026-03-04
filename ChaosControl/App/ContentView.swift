import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView(selectedTab: $selectedTab)
                .tabItem {
                    Label("Nexus", systemImage: "target")
                }
                .tag(0)

            GlucoseEntryView(selectedTab: $selectedTab)
                .tabItem {
                    Label("Log", systemImage: "plus.circle")
                }
                .tag(1)

            DoseCalculatorView(selectedTab: $selectedTab)
                .tabItem {
                    Label("Dose", systemImage: "triangle")
                }
                .tag(2)

            MealLogView(selectedTab: $selectedTab)
                .tabItem {
                    Label("Meals", systemImage: "square.grid.2x2")
                }
                .tag(3)

            TrendsView(selectedTab: $selectedTab)
                .tabItem {
                    Label("Trends", systemImage: "chart.xyaxis.line")
                }
                .tag(4)
        }
    }
}
