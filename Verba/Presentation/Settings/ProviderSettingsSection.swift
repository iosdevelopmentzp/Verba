import SwiftUI

struct ProviderSettingsSection: View {
    @Bindable var viewModel: SettingsViewModel

    var body: some View {
        Section("Provider") {
            SecureField("OpenAI API key", text: $viewModel.apiKeyInput)
                .textFieldStyle(.roundedBorder)
                .onSubmit { viewModel.saveAPIKey() }

            Picker("Model", selection: $viewModel.selectedModelID) {
                ForEach(viewModel.modelOptions) { option in
                    Text(option.displayName).tag(option.id)
                }
            }

            Toggle("Economy mode", isOn: $viewModel.economyMode)

            TextField(
                "Monthly budget",
                value: $viewModel.monthlyBudgetUSD,
                format: .currency(code: "USD")
            )
            .textFieldStyle(.roundedBorder)

            HStack(spacing: 8) {
                Button("Test key") { viewModel.testKey() }
                    .disabled(viewModel.keyTestState == .testing)

                testStatusView
            }
        }
    }

    @ViewBuilder
    private var testStatusView: some View {
        switch viewModel.keyTestState {
        case .idle:
            EmptyView()
        case .testing:
            ProgressView()
                .controlSize(.small)
        case .success:
            Label("Key works", systemImage: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .font(.caption)
        case .failure(let error):
            Text(ErrorPresentation.message(for: error))
                .font(.caption)
                .foregroundStyle(.red)
        }
    }
}
