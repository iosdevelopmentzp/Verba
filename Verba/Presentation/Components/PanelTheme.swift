import SwiftUI

enum PanelTheme {

    // MARK: Metrics

    static let width: CGFloat = 620
    static let cornerRadius: CGFloat = 18
    static let contentPadding: CGFloat = 22
    static let sectionSpacing: CGFloat = 16
    static let cardCornerRadius: CGFloat = 12
    static let rowCornerRadius: CGFloat = 10

    // MARK: Typography

    static let prominent = Font.system(size: 16, weight: .regular)
    static let title = Font.system(size: 15, weight: .semibold)
    static let body = Font.system(size: 14, weight: .regular)
    static let secondary = Font.system(size: 13, weight: .regular)
    static let caption = Font.system(size: 12, weight: .regular)
    static let key = Font.system(size: 12, weight: .semibold, design: .rounded)

    // MARK: Colors

    static let surface = Color.black.opacity(0.04)
    static let hairline = Color.black.opacity(0.09)
    static let keyCap = Color.black.opacity(0.07)
    static let selection = Color.accentColor

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
