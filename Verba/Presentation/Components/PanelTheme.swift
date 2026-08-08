import SwiftUI

enum PanelTheme {

    // MARK: Metrics

    static let width: CGFloat = 620
    static let cornerRadius: CGFloat = 18
    static let contentPadding: CGFloat = 22
    static let sectionSpacing: CGFloat = 16
    static let cardCornerRadius: CGFloat = 12
    static let grabberHeight: CGFloat = 14
    static let promptEditorMinHeight: CGFloat = 560
    static let rowCornerRadius: CGFloat = 10
    static let sidebarWidth: CGFloat = 208
    static let sidebarRailWidth: CGFloat = 30

    static func panelWidth(isSidebarExpanded: Bool) -> CGFloat {
        width + (isSidebarExpanded ? sidebarWidth : sidebarRailWidth) + 1
    }

    // MARK: Typography

    static let prominent = Font.system(size: 16, weight: .regular)
    static let title = Font.system(size: 15, weight: .semibold)
    static let body = Font.system(size: 14, weight: .regular)
    static let secondary = Font.system(size: 13, weight: .regular)
    static let caption = Font.system(size: 12, weight: .regular)
    static let key = Font.system(size: 12, weight: .semibold, design: .rounded)
    static let sectionLabel = Font.system(size: 10, weight: .semibold).width(.expanded)
    static let mono = Font.system(size: 12, weight: .regular, design: .monospaced)

    // MARK: Colors

    static let background = Color(white: 0.99)
    static let surface = Color(white: 0.955)
    static let hairline = Color.black.opacity(0.10)
    static let keyCap = Color.black.opacity(0.06)
    static let selection = Color.accentColor
    static let textPrimary = Color(white: 0.10)
    static let textSecondary = Color(white: 0.38)
    static let textTertiary = Color(white: 0.55)
    static let diffRemoved = Color(red: 0.75, green: 0.15, blue: 0.15)
    static let diffAdded = Color(red: 0.10, green: 0.5, blue: 0.20)
    static let sidebarBackground = Color(white: 0.945)
    static let locked = Color(white: 0.91)
    static let editable = Color(red: 0.99, green: 0.98, blue: 0.93)
    static let editableBorder = Color(red: 0.85, green: 0.72, blue: 0.25)
    static let selectionSoft = Color.accentColor.opacity(0.10)
    static let selectionBorder = Color.accentColor.opacity(0.40)
    static let selectionKeyCap = Color.accentColor.opacity(0.18)
    static let selectionText = Color.accentColor

    // MARK: Shapes

    static var panelShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
    }

    static var cardShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: cardCornerRadius, style: .continuous)
    }

    static var rowShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: rowCornerRadius, style: .continuous)
    }
}

struct HairlineDivider: View {
    var body: some View {
        Rectangle()
            .fill(PanelTheme.hairline)
            .frame(height: 1)
    }
}
