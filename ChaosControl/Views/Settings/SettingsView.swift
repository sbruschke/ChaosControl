import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var allSettings: [UserSettings]

    var dashboardViewModel: DashboardViewModel

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
                        dexcomSection

                        RedDivider().padding(.vertical, 16)

                        // About
                        settingsGroup("SYSTEM") {
                            SettingsRow(label: "VERSION", value: "0.1.0")
                            SettingsRow(label: "REGION", value: "US")
                        }
                    }
                    .padding(ChaosTheme.screenPadding)
                    .onTapGesture {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(ChaosTheme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
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
        .chaosKeyboardDismiss()
        .onAppear { loadSettings() }
    }

    // MARK: - Dexcom Section

    private var dexcomSection: some View {
        settingsGroup("DEXCOM INTEGRATION") {
            if dashboardViewModel.dexcomConnected {
                // Connected state
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(ChaosTheme.inRange)
                            .frame(width: 6, height: 6)
                        Text("\u{25C6} CONNECTED")
                            .font(ChaosTheme.captionFont)
                            .foregroundColor(ChaosTheme.inRange)
                            .tracking(2)
                    }

                    if let username = try? KeychainService.getUsername() {
                        SettingsRow(label: "ACCOUNT", value: username.uppercased())
                    }

                    ChaosButton(title: "DISCONNECT") {
                        dashboardViewModel.disconnectDexcom()
                        dexcomEnabled = false
                        dexcomUsername = ""
                        dexcomPassword = ""
                        dexcomStatus = ""
                    }
                }
            } else {
                // Not connected state
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
                                .background(ChaosTheme.paperDark.opacity(0.5))
                                .overlay(alignment: .bottom) {
                                    LinearGradient(
                                        colors: [ChaosTheme.red.opacity(0.4), ChaosTheme.red.opacity(0.1)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                    .frame(height: 1.5)
                                }
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
                                .background(ChaosTheme.paperDark.opacity(0.5))
                                .overlay(alignment: .bottom) {
                                    LinearGradient(
                                        colors: [ChaosTheme.red.opacity(0.4), ChaosTheme.red.opacity(0.1)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                    .frame(height: 1.5)
                                }
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
        }
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
                    .padding(.vertical, 4)
                    .padding(.horizontal, 6)
                    .background(ChaosTheme.paperDark.opacity(0.5))
                    .overlay(alignment: .bottom) {
                        LinearGradient(
                            colors: [ChaosTheme.red.opacity(0.4), ChaosTheme.red.opacity(0.1)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(height: 1.5)
                    }

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
            if dashboardViewModel.dexcomConnected {
                dexcomStatus = "\u{25C6} CONNECTED"
            } else {
                dexcomStatus = "CREDENTIALS STORED"
            }
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

        await dashboardViewModel.connectDexcom(username: dexcomUsername, password: dexcomPassword)

        if dashboardViewModel.dexcomConnected {
            dexcomStatus = "\u{25C6} CONNECTED"
        } else if let error = dashboardViewModel.errorMessage {
            dexcomStatus = "ERROR: \(error.uppercased())"
        }

        isConnecting = false
    }
}
