import SwiftUI

// MARK: - Section Header with trailing line

struct SectionHeader: View {
    let title: String

    var body: some View {
        HStack(spacing: 8) {
            Text(title)
                .font(ChaosTheme.captionFont)
                .foregroundColor(ChaosTheme.faded)
                .tracking(3)

            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [ChaosTheme.ink.opacity(0.15), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 0.5)
        }
    }
}

// MARK: - Red Section Header

struct RedSectionHeader: View {
    let title: String

    var body: some View {
        HStack(spacing: 8) {
            Text(title)
                .font(ChaosTheme.captionFont)
                .foregroundColor(ChaosTheme.faded)
                .tracking(3)

            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [ChaosTheme.red.opacity(0.2), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 0.5)
        }
    }
}

// MARK: - Divider Styles

struct ChaosDivider: View {
    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [.clear, ChaosTheme.ink.opacity(0.1), .clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(height: 0.5)
    }
}

struct RedDivider: View {
    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [.clear, ChaosTheme.red.opacity(0.25), .clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(height: 0.5)
    }
}

// MARK: - Settings Row

struct SettingsRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(ChaosTheme.captionFont)
                .foregroundColor(ChaosTheme.faded)
                .tracking(2)
            Spacer()
            Text(value)
                .font(ChaosTheme.bodyFont)
                .foregroundColor(ChaosTheme.ink)
                .tracking(1)
        }
        .padding(.vertical, 8)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(ChaosTheme.ink.opacity(0.05))
                .frame(height: 0.5)
        }
    }
}
