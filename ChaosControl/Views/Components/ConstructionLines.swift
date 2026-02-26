import SwiftUI

// MARK: - Construction Line Background
// Faint red crosshairs and grid typical of the archaic-technical aesthetic

struct ConstructionLines: View {
    var showVertical: Bool = true
    var showHorizontal: Bool = true
    var verticalOffset: CGFloat = 0.5
    var horizontalOffset: CGFloat = 0.4

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Faint grid pattern
                GridPattern()
                    .stroke(ChaosTheme.ink.opacity(0.015), lineWidth: 0.3)

                // Vertical construction line
                if showVertical {
                    Path { path in
                        let x = geometry.size.width * verticalOffset
                        path.move(to: CGPoint(x: x, y: geometry.size.height * 0.15))
                        path.addLine(to: CGPoint(x: x, y: geometry.size.height * 0.55))
                    }
                    .stroke(
                        LinearGradient(
                            colors: [
                                ChaosTheme.red.opacity(0),
                                ChaosTheme.red.opacity(0.15),
                                ChaosTheme.red.opacity(0.08),
                                ChaosTheme.red.opacity(0.15),
                                ChaosTheme.red.opacity(0)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 0.5
                    )
                }

                // Horizontal construction line
                if showHorizontal {
                    Path { path in
                        let y = geometry.size.height * horizontalOffset
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: geometry.size.width, y: y))
                    }
                    .stroke(
                        LinearGradient(
                            colors: [
                                ChaosTheme.red.opacity(0),
                                ChaosTheme.red.opacity(0.15),
                                ChaosTheme.red.opacity(0.08),
                                ChaosTheme.red.opacity(0.15),
                                ChaosTheme.red.opacity(0)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        lineWidth: 0.5
                    )
                }
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Grid Pattern Shape

struct GridPattern: Shape {
    var spacing: CGFloat = 40

    func path(in rect: CGRect) -> Path {
        var path = Path()

        // Vertical lines
        var x: CGFloat = 0
        while x <= rect.width {
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: rect.height))
            x += spacing
        }

        // Horizontal lines
        var y: CGFloat = 0
        while y <= rect.height {
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: rect.width, y: y))
            y += spacing
        }

        return path
    }
}

// MARK: - Ink Splatter Decoration

struct InkSplatter: View {
    var count: Int = 5

    var body: some View {
        GeometryReader { geometry in
            ForEach(0..<count, id: \.self) { i in
                Circle()
                    .fill(i % 3 == 0 ? ChaosTheme.red.opacity(0.04) : ChaosTheme.ink.opacity(0.04))
                    .frame(width: CGFloat.random(in: 2...6), height: CGFloat.random(in: 2...6))
                    .position(
                        x: CGFloat.random(in: 20...geometry.size.width - 20),
                        y: CGFloat.random(in: 40...geometry.size.height - 40)
                    )
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Annotation Text

struct AnnotationText: View {
    let text: String
    var color: Color = ChaosTheme.ink.opacity(0.12)

    var body: some View {
        Text(text)
            .font(ChaosTheme.annotationFont)
            .foregroundColor(color)
            .tracking(1.5)
    }
}
