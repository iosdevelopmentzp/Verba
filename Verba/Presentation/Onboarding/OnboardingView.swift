import KeyboardShortcuts
import SwiftUI

struct OnboardingView: View {
    let viewModel: OnboardingViewModel
    let onFinish: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            header
            Divider()
            apiKeyStep
            hotkeyStep
            clipboardStep
            launchStep
            Divider()
            footer
        }
        .padding(24)
        .frame(width: 460)
        .onAppear { viewModel.settings.start() }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Set up Verba")
                .font(.title2.weight(.semibold))
            Text("Four things, then it stays out of your way.")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
    }

    private var apiKeyStep: some View {
        step(number: 1, title: "OpenAI API key") {
            VStack(alignment: .leading, spacing: 8) {
                SecureField("sk-…", text: apiKeyBinding)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit { viewModel.settings.saveAPIKey() }

                HStack(spacing: 8) {
                    Button("Save") { viewModel.settings.saveAPIKey() }
                    Button("Test key") { viewModel.settings.testKey() }
                    keyTestStatus
                }
            }
        }
    }

    @ViewBuilder
    private var keyTestStatus: some View {
        switch viewModel.settings.keyTestState {
        case .idle:
            EmptyView()
        case .testing:
            ProgressView().controlSize(.small)
        case .success:
            Label("Working", systemImage: "checkmark.circle.fill")
                .font(.caption)
                .foregroundStyle(.green)
        case .failure(let error):
            Text(ErrorPresentation.message(for: error))
                .font(.caption)
                .foregroundStyle(.red)
        }
    }

    private var hotkeyStep: some View {
        step(number: 2, title: "Hotkey") {
            KeyboardShortcuts.Recorder(for: viewModel.settings.shortcutName)
        }
    }

    private var clipboardStep: some View {
        step(number: 3, title: "Clipboard access") {
            Text("""
            Verba reads what you copied when you press the hotkey. macOS asks once — \
            choose Always Allow, or Verba cannot see your text.
            """)
            .font(.callout)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var launchStep: some View {
        step(number: 4, title: "Launch at login") {
            Toggle("Start Verba when I log in", isOn: launchBinding)
                .toggleStyle(.switch)
        }
    }

    private var footer: some View {
        HStack {
            Spacer()
            Button("Done") {
                viewModel.settings.saveAPIKey()
                viewModel.finish()
                onFinish()
            }
            .keyboardShortcut(.defaultAction)
        }
    }

    private var apiKeyBinding: Binding<String> {
        Binding(
            get: { viewModel.settings.apiKeyInput },
            set: { viewModel.settings.apiKeyInput = $0 }
        )
    }

    private var launchBinding: Binding<Bool> {
        Binding(
            get: { viewModel.launchAtLogin },
            set: { viewModel.updateLaunchAtLogin($0) }
        )
    }

    private func step<Content: View>(
        number: Int,
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.caption.monospacedDigit().weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: 18, height: 18)
                .background(.quaternary, in: Circle())

            VStack(alignment: .leading, spacing: 6) {
                Text(title).font(.headline)
                content()
            }
        }
    }
}
