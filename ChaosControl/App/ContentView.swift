import SwiftUI

// MARK: - Main Tab Navigation

struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            // Tab content
            TabView(selection: $selectedTab) {
                DashboardView(selectedTab: $selectedTab)
                    .tag(0)

                GlucoseEntryView()
                    .tag(1)

                DoseCalculatorView()
                    .tag(2)

                MealLogView()
                    .tag(3)

                TrendsView(selectedTab: $selectedTab)
                    .tag(4)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            // Custom nav bar
            ChaosTabBar(selectedTab: $selectedTab)
        }
        .ignoresSafeArea(.keyboard)
    }
}

// MARK: - Custom Tab Bar

struct ChaosTabBar: View {
    @Binding var selectedTab: Int

    private let tabs: [(icon: String, label: String)] = [
        ("nexus", "NEXUS"),
        ("log", "LOG"),
        ("dose", "DOSE"),
        ("meals", "MEALS"),
        ("trends", "TRENDS")
    ]

    var body: some View {
        HStack {
            ForEach(0..<tabs.count, id: \.self) { index in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = index
                    }
                } label: {
                    VStack(spacing: 4) {
                        tabIcon(index)
                            .frame(width: 22, height: 22)

                        Text(tabs[index].label)
                            .font(ChaosTheme.microFont)
                            .foregroundColor(selectedTab == index ? ChaosTheme.red : ChaosTheme.ink)
                            .tracking(1.5)
                    }
                    .opacity(selectedTab == index ? 1 : 0.35)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.top, 14)
        .padding(.bottom, 32)
        .background(
            ChaosTheme.background
                .shadow(color: .black.opacity(0.03), radius: 10, y: -5)
        )
        .overlay(alignment: .top) {
            Rectangle()
                .fill(ChaosTheme.ink.opacity(0.08))
                .frame(height: 0.5)
        }
    }

    @ViewBuilder
    private func tabIcon(_ index: Int) -> some View {
        let isActive = selectedTab == index
        let color = isActive ? ChaosTheme.red : ChaosTheme.ink

        switch index {
        case 0: // Nexus - crosshair
            ZStack {
                Circle()
                    .stroke(color, lineWidth: 0.8)
                    .frame(width: 16, height: 16)
                Circle()
                    .stroke(color, lineWidth: 0.8)
                    .frame(width: 6, height: 6)
                Rectangle()
                    .fill(color)
                    .frame(width: 0.8, height: 22)
                Rectangle()
                    .fill(color)
                    .frame(width: 22, height: 0.8)
            }

        case 1: // Log - plus in circle
            ZStack {
                Circle()
                    .stroke(color, lineWidth: 0.8)
                    .frame(width: 16, height: 16)
                Rectangle()
                    .fill(color)
                    .frame(width: 10, height: 1)
                Rectangle()
                    .fill(color)
                    .frame(width: 1, height: 10)
            }

        case 2: // Dose - triangle
            ZStack {
                Triangle()
                    .stroke(color, lineWidth: 0.8)
                    .frame(width: 18, height: 16)
                Circle()
                    .stroke(color, lineWidth: 0.8)
                    .frame(width: 4, height: 4)
                    .offset(y: 3)
            }

        case 3: // Meals - grid
            VStack(spacing: 2) {
                HStack(spacing: 2) {
                    Rectangle().stroke(color, lineWidth: 0.8).frame(width: 8, height: 8)
                    Rectangle().stroke(color, lineWidth: 0.8).frame(width: 8, height: 8)
                }
                HStack(spacing: 2) {
                    Rectangle().stroke(color, lineWidth: 0.8).frame(width: 8, height: 8)
                    Rectangle().stroke(color, lineWidth: 0.8).frame(width: 8, height: 8)
                }
            }

        case 4: // Trends - chart line
            ZStack {
                Path { path in
                    path.move(to: CGPoint(x: 0, y: 18))
                    path.addLine(to: CGPoint(x: 5, y: 12))
                    path.addLine(to: CGPoint(x: 10, y: 14))
                    path.addLine(to: CGPoint(x: 14, y: 4))
                    path.addLine(to: CGPoint(x: 18, y: 8))
                    path.addLine(to: CGPoint(x: 22, y: 2))
                }
                .stroke(color, lineWidth: 0.8)

                Circle()
                    .fill(color)
                    .frame(width: 3, height: 3)
                    .offset(x: 3, y: -7)
            }

        default:
            EmptyView()
        }
    }
}

// MARK: - Triangle Shape

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
