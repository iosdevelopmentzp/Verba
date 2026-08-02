import SwiftUI

struct MenuBarLabelView: View {
    let viewModel: MenuBarViewModel

    var body: some View {
        Image(systemName: viewModel.isOverBudget ? "exclamationmark.triangle.fill" : "text.badge.checkmark")
            .accessibilityLabel("Verba")
            .task { await viewModel.refresh() }
    }
}

struct MenuBarView: View {
    let viewModel: MenuBarViewModel
    let onOpenPanel: () -> Void
    let onOpenSettings: () -> Void
    let onOpenOnboarding: () -> Void
    let onAbout: () -> Void
    let onQuit: () -> Void

    var body: some View {
        Group {
            if viewModel.isOverBudget {
                Text("Monthly budget exceeded")
                Divider()
            }

            Text("Today \(viewModel.costToday) · Month \(viewModel.costMonth)")
            Divider()

            Button("Open Verba (⌃⌥Space)", action: onOpenPanel)
            Button("Settings…", action: onOpenSettings)
            Button("Setup Guide…", action: onOpenOnboarding)
            Button("About Verba", action: onAbout)
            Divider()
            Button("Quit", action: onQuit)
        }
        .task { await viewModel.refresh() }
    }
}
