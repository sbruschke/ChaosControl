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
            Form {
                // Insulin Settings
                Section("Insulin Parameters") {
                    settingRow("Carb Ratio (1:X)", value: $carbRatio, unit: "g")
                    settingRow("Sensitivity (1:X)", value: $sensitivityFactor, unit: "mg/dL")
                    settingRow("Target Glucose", value: $targetGlucose, unit: "mg/dL")
                    settingRow("Action Duration", value: $insulinActionDuration, unit: "hrs")
                }

                // Range Thresholds
                Section("Range Thresholds") {
                    settingRow("Low Threshold", value: $lowThreshold, unit: "mg/dL")
                    settingRow("High Threshold", value: $highThreshold, unit: "mg/dL")
                }

                // Dexcom Integration
                Section("Dexcom Integration") {
                    if dashboardViewModel.dexcomConnected {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Connected")
                                .foregroundColor(.green)
                        }

                        if let username = try? KeychainService.getUsername() {
                            HStack {
                                Text("Account")
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text(username)
                            }
                        }

                        Button("Disconnect", role: .destructive) {
                            dashboardViewModel.disconnectDexcom()
                            dexcomEnabled = false
                            dexcomUsername = ""
                            dexcomPassword = ""
                            dexcomStatus = ""
                        }
                    } else {
                        Toggle("Enable Dexcom", isOn: $dexcomEnabled)

                        if dexcomEnabled {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Username")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                TextField("Username", text: $dexcomUsername)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                                    .textFieldStyle(.roundedBorder)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Password")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                SecureField("Password", text: $dexcomPassword)
                                    .textFieldStyle(.roundedBorder)
                            }

                            if !dexcomStatus.isEmpty {
                                Text(dexcomStatus)
                                    .font(.caption)
                                    .foregroundColor(
                                        dexcomStatus.contains("CONNECTED") ? .green : .red
                                    )
                            }

                            Button(isConnecting ? "Connecting..." : "Connect") {
                                Task { await connectDexcom() }
                            }
                            .disabled(isConnecting)
                        }
                    }
                }

                // System
                Section("System") {
                    HStack {
                        Text("Version")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("0.1.0")
                    }
                    HStack {
                        Text("Region")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("US")
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save(); dismiss() }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .onAppear { loadSettings() }
    }

    // MARK: - Helpers

    private func settingRow(_ label: String, value: Binding<Double>, unit: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)

            Spacer()

            HStack(spacing: 4) {
                TextField("", value: value, format: .number)
                    .multilineTextAlignment(.trailing)
                    .keyboardType(.decimalPad)
                    .frame(width: 60)
                    .textFieldStyle(.roundedBorder)

                Text(unit)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
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
                dexcomStatus = "CONNECTED"
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
            dexcomStatus = "CONNECTED"
        } else if let error = dashboardViewModel.errorMessage {
            dexcomStatus = "ERROR: \(error.uppercased())"
        }

        isConnecting = false
    }
}
