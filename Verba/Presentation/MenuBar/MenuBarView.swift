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
    let onOpenSettings: () -> Void
    let onAbout: () -> Void
    let onQuit: () -> Void

    var body: some View {
        Group {
            if viewModel.isOverBudget {
                Text("Monthly budget exceeded")
                Divider()
            }

            Button("Settings…", action: onOpenSettings)
            Button("About Verba", action: onAbout)
            Divider()
            Button("Quit", action: onQuit)
        }
        .task { await viewModel.refresh() }
    }
}
