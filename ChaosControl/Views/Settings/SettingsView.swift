import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var allSettings: [UserSettings]

    @State private var carbRatio: Double = 10
    @State private var sensitivityFactor: Double = 40
    @State private var targetGlucose: Double = 120
    @State private var insulinActionDuration: Double = 4
    @State private var lowThreshold: Double = 70
    @State private var highThreshold: Double = 180

    // Dexcom
    @State private var dexcomEnabled: Bool = false
    @State private var dexcomUsername: String = ""
    @State private var dexcomPassword: String = ""
    @State private var dexcomStatus: String = ""
    @State private var isConnecting = false

    private var settings: UserSettings? { allSettings.first }

    var body: some View {
        NavigationStack {
            ZStack {
                ChaosTheme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 0) {
                        // Insulin Settings
                        settingsGroup("INSULIN PARAMETERS") {
                            settingRow("CARB RATIO (1:X)", value: $carbRatio, unit: "g")
                            settingRow("SENSITIVITY (1:X)", value: $sensitivityFactor, unit: "mg/dL")
                            settingRow("TARGET GLUCOSE", value: $targetGlucose, unit: "mg/dL")
                            settingRow("ACTION DURATION", value: $insulinActionDuration, unit: "hrs")
                        }

                        RedDivider().padding(.vertical, 16)

                        // Range Thresholds
                        settingsGroup("RANGE THRESHOLDS") {
                            settingRow("LOW THRESHOLD", value: $lowThreshold, unit: "mg/dL")
                            settingRow("HIGH THRESHOLD", value: $highThreshold, unit: "mg/dL")
                        }

                        RedDivider().padding(.vertical, 16)

                        // Dexcom Integration
                        settingsGroup("DEXCOM INTEGRATION") {
                            Toggle(isOn: $dexcomEnabled) {
                                Text("ENABLE DEXCOM")
                                    .font(ChaosTheme.captionFont)
                                    .foregroundColor(ChaosTheme.ink)
                                    .tracking(2)
                            }
                            .tint(ChaosTheme.red)
                            .padding(.vertical, 4)

                            if dexcomEnabled {
                                VStack(spacing: 12) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("USERNAME")
                                            .font(ChaosTheme.microFont)
                                            .foregroundColor(ChaosTheme.faded)
                                            .tracking(2)
                                        TextField("", text: $dexcomUsername)
                                            .font(ChaosTheme.bodyFont)
                                            .foregroundColor(ChaosTheme.ink)
                                            .textInputAutocapitalization(.never)
                                            .autocorrectionDisabled()
                                            .padding(10)
                                            .overlay(Rectangle().stroke(ChaosTheme.border, lineWidth: 0.5))
                                    }

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("PASSWORD")
                                            .font(ChaosTheme.microFont)
                                            .foregroundColor(ChaosTheme.faded)
                                            .tracking(2)
                                        SecureField("", text: $dexcomPassword)
                                            .font(ChaosTheme.bodyFont)
                                            .foregroundColor(ChaosTheme.ink)
                                            .padding(10)
                                            .overlay(Rectangle().stroke(ChaosTheme.border, lineWidth: 0.5))
                                    }

                                    if !dexcomStatus.isEmpty {
                                        Text(dexcomStatus)
                                            .font(ChaosTheme.captionFont)
                                            .foregroundColor(
                                                dexcomStatus.contains("CONNECTED") ? ChaosTheme.inRange : ChaosTheme.red
                                            )
                                            .tracking(1)
                                    }

                                    ChaosButton(title: isConnecting ? "CONNECTING..." : "CONNECT") {
                                        Task { await connectDexcom() }
                                    }
                                }
                                .padding(.top, 8)
                            }
                        }

                        RedDivider().padding(.vertical, 16)

                        // About
                        settingsGroup("SYSTEM") {
                            HStack {
                                Text("VERSION")
                                    .font(ChaosTheme.captionFont)
                                    .foregroundColor(ChaosTheme.faded)
                                    .tracking(2)
                                Spacer()
                                Text("0.1.0")
                                    .font(ChaosTheme.bodyFont)
                                    .foregroundColor(ChaosTheme.ink)
                            }
                            .padding(.vertical, 4)

                            HStack {
                                Text("REGION")
                                    .font(ChaosTheme.captionFont)
                                    .foregroundColor(ChaosTheme.faded)
                                    .tracking(2)
                                Spacer()
                                Text("US")
                                    .font(ChaosTheme.bodyFont)
                                    .foregroundColor(ChaosTheme.ink)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .padding(ChaosTheme.screenPadding)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("SETTINGS")
                        .font(ChaosTheme.titleFont)
                        .foregroundColor(ChaosTheme.ink)
                        .tracking(4)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("SAVE") { save(); dismiss() }
                        .font(ChaosTheme.captionFont)
                        .foregroundColor(ChaosTheme.red)
                        .tracking(2)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("CLOSE") { dismiss() }
                        .font(ChaosTheme.captionFont)
                        .foregroundColor(ChaosTheme.faded)
                        .tracking(2)
                }
            }
        }
        .onAppear { loadSettings() }
    }

    // MARK: - Helpers

    private func settingsGroup(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(title: title)
            content()
        }
    }

    private func settingRow(_ label: String, value: Binding<Double>, unit: String) -> some View {
        HStack {
            Text(label)
                .font(ChaosTheme.captionFont)
                .foregroundColor(ChaosTheme.faded)
                .tracking(1)

            Spacer()

            HStack(spacing: 4) {
                TextField("", value: value, format: .number)
                    .font(ChaosTheme.bodyFont)
                    .foregroundColor(ChaosTheme.ink)
                    .multilineTextAlignment(.trailing)
                    .keyboardType(.decimalPad)
                    .frame(width: 60)

                Text(unit)
                    .font(ChaosTheme.microFont)
                    .foregroundColor(ChaosTheme.faded)
                    .tracking(1)
            }
        }
        .padding(.vertical, 6)
        .overlay(alignment: .bottom) {
            Rectangle().fill(ChaosTheme.ink.opacity(0.04)).frame(height: 0.5)
        }
    }

    private func loadSettings() {
        if let s = settings {
            carbRatio = s.carbRatio
            sensitivityFactor = s.sensitivityFactor
            targetGlucose = s.targetGlucose
            insulinActionDuration = s.insulinActionDuration
            lowThreshold = s.lowThreshold
            highThreshold = s.highThreshold
            dexcomEnabled = s.dexcomEnabled
        }

        if KeychainService.hasCredentials {
            dexcomUsername = (try? KeychainService.getUsername()) ?? ""
            dexcomStatus = "CREDENTIALS STORED"
        }
    }

    private func save() {
        if let s = settings {
            s.carbRatio = carbRatio
            s.sensitivityFactor = sensitivityFactor
            s.targetGlucose = targetGlucose
            s.insulinActionDuration = insulinActionDuration
            s.lowThreshold = lowThreshold
            s.highThreshold = highThreshold
            s.dexcomEnabled = dexcomEnabled
        } else {
            let newSettings = UserSettings(
                carbRatio: carbRatio,
                sensitivityFactor: sensitivityFactor,
                targetGlucose: targetGlucose,
                insulinActionDuration: insulinActionDuration,
                lowThreshold: lowThreshold,
                highThreshold: highThreshold,
                dexcomEnabled: dexcomEnabled
            )
            modelContext.insert(newSettings)
        }
    }

    private func connectDexcom() async {
        guard !dexcomUsername.isEmpty, !dexcomPassword.isEmpty else {
            dexcomStatus = "ENTER CREDENTIALS"
            return
        }

        isConnecting = true
        dexcomStatus = "AUTHENTICATING..."

        let service = DexcomShareService(region: .us)
        do {
            try await service.authenticate(username: dexcomUsername, password: dexcomPassword)
            try KeychainService.saveUsername(dexcomUsername)
            try KeychainService.savePassword(dexcomPassword)
            dexcomStatus = "\u{25C6} CONNECTED"
        } catch {
            dexcomStatus = "ERROR: \(error.localizedDescription.uppercased())"
        }

        isConnecting = false
    }
}
