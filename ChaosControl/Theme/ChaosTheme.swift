import SwiftUI

// MARK: - Chaos Control Design System
// Archaic-Technical Blueprint Aesthetic

struct ChaosTheme {

    // MARK: - Colors

    /// Warm cream parchment background
    static let background = Color(hex: "F2EDE4")
    /// Near-black ink for primary text and lines
    static let ink = Color(hex: "1C1A17")
    /// Red accent for construction lines, highlights, and interactive elements
    static let red = Color(hex: "C43E3E")
    /// Faded ink for secondary text and labels
    static let faded = Color(hex: "9B9590")
    /// Paper slightly darker variant
    static let paperDark = Color(hex: "E8E1D5")

    /// Blood sugar in-range / success
    static let inRange = Color(hex: "4A7C59")
    /// Blood sugar high / warning
    static let warning = Color(hex: "C4873E")
    /// Blood sugar critical / danger (same as accent red)
    static let danger = Color(hex: "C43E3E")
    /// Blood sugar low
    static let low = Color(hex: "8B6CC4")

    /// Very faint construction line color
    static let constructionLine = Color(hex: "C43E3E").opacity(0.12)
    /// Border color for cards
    static let border = Color(hex: "1C1A17").opacity(0.12)
    /// Faint grid line
    static let gridLine = Color(hex: "1C1A17").opacity(0.015)

    // MARK: - Typography

    static let fontName = "ShadowMonoRegular"

    static func font(_ size: CGFloat) -> Font {
        .custom(fontName, size: size)
    }

    // Common font sizes
    static let displayFont = font(42)
    static let titleFont = font(13)
    static let bodyFont = font(10)
    static let captionFont = font(8)
    static let microFont = font(7)
    static let annotationFont = font(6.5)

    // MARK: - Spacing

    static let cornerBracketSize: CGFloat = 6
    static let cardPadding: CGFloat = 12
    static let screenPadding: CGFloat = 20

    // MARK: - Glucose Ranges

    static let glucoseRangeLow: Double = 70
    static let glucoseRangeHigh: Double = 180
    static let glucoseRangeCriticalLow: Double = 54
    static let glucoseRangeCriticalHigh: Double = 250

    static func glucoseColor(for value: Double) -> Color {
        switch value {
        case ..<glucoseRangeCriticalLow: return danger
        case ..<glucoseRangeLow: return low
        case ..<glucoseRangeHigh: return inRange
        case ..<glucoseRangeCriticalHigh: return warning
        default: return danger
        }
    }

    static func glucoseStatus(for value: Double) -> String {
        switch value {
        case ..<glucoseRangeCriticalLow: return "CRITICAL LOW"
        case ..<glucoseRangeLow: return "LOW"
        case ..<glucoseRangeHigh: return "IN RANGE"
        case ..<glucoseRangeCriticalHigh: return "HIGH"
        default: return "CRITICAL HIGH"
        }
    }
}

// MARK: - Color Hex Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = ((int >> 24) & 0xFF, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - View Modifiers

struct ChaosCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(ChaosTheme.cardPadding)
            .background(ChaosTheme.background.opacity(0.5))
            .overlay(
                Rectangle()
                    .stroke(ChaosTheme.border, lineWidth: 0.5)
            )
            .overlay(alignment: .topLeading) {
                CornerBracket()
                    .stroke(ChaosTheme.red, lineWidth: 0.5)
                    .frame(width: ChaosTheme.cornerBracketSize, height: ChaosTheme.cornerBracketSize)
                    .offset(x: -0.5, y: -0.5)
            }
            .overlay(alignment: .bottomTrailing) {
                CornerBracket()
                    .rotation(Angle(degrees: 180))
                    .stroke(ChaosTheme.red, lineWidth: 0.5)
                    .frame(width: ChaosTheme.cornerBracketSize, height: ChaosTheme.cornerBracketSize)
                    .offset(x: 0.5, y: 0.5)
            }
    }
}

struct CornerBracket: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        return path
    }
}

extension View {
    func chaosCard() -> some View {
        modifier(ChaosCardStyle())
    }
}
