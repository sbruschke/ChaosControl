import SwiftUI

// MARK: - Chaos Control Utilities (Stripped for functionality testing)

struct ChaosTheme {

    // MARK: - Glucose Ranges

    static let glucoseRangeLow: Double = 70
    static let glucoseRangeHigh: Double = 180
    static let glucoseRangeCriticalLow: Double = 54
    static let glucoseRangeCriticalHigh: Double = 250

    static func glucoseColor(for value: Double) -> Color {
        switch value {
        case ..<glucoseRangeCriticalLow: return .red
        case ..<glucoseRangeLow: return .purple
        case ..<glucoseRangeHigh: return .green
        case ..<glucoseRangeCriticalHigh: return .orange
        default: return .red
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

// MARK: - View Utilities

extension View {
    func chaosKeyboardDismiss() -> some View {
        self.scrollDismissesKeyboard(.interactively)
    }

    func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
