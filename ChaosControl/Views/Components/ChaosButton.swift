import SwiftUI

// MARK: - Primary Action Button (red border with corner brackets)

struct ChaosButton: View {
    let title: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(ChaosTheme.font(10))
                .foregroundColor(ChaosTheme.red)
                .tracking(4)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(ChaosTheme.red.opacity(0.06))
                .overlay(
                    Rectangle()
                        .stroke(ChaosTheme.red, lineWidth: 0.5)
                )
                .overlay(alignment: .topLeading) {
                    CornerBracket()
                        .stroke(ChaosTheme.red, lineWidth: 1)
                        .frame(width: 8, height: 8)
                        .offset(x: -0.5, y: -0.5)
                }
                .overlay(alignment: .bottomTrailing) {
                    CornerBracket()
                        .rotation(Angle(degrees: 180))
                        .stroke(ChaosTheme.red, lineWidth: 1)
                        .frame(width: 8, height: 8)
                        .offset(x: 0.5, y: 0.5)
                }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Secondary Button (subtle border)

struct ChaosSecondaryButton: View {
    let title: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(ChaosTheme.font(9))
                .foregroundColor(ChaosTheme.faded)
                .tracking(3)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .overlay(
                    Rectangle()
                        .stroke(ChaosTheme.ink.opacity(0.1), lineWidth: 0.5)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Quick Action Button

struct QuickActionButton: View {
    let title: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(ChaosTheme.microFont)
                .foregroundColor(ChaosTheme.red)
                .tracking(2)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(ChaosTheme.red.opacity(0.03))
                .overlay(
                    Rectangle()
                        .stroke(ChaosTheme.red.opacity(0.25), lineWidth: 0.5)
                )
        }
        .buttonStyle(.plain)
    }
}
