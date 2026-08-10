import SwiftUI

struct SelectableRowStyle: ViewModifier {
    let isSelected: Bool
    let shape: RoundedRectangle

    func body(content: Content) -> some View {
        content
            .background(isSelected ? PanelTheme.selectionSoft : Color.clear, in: shape)
            .overlay(alignment: .leading) {
                if isSelected {
                    Capsule()
                        .fill(PanelTheme.selection)
                        .frame(width: 3)
                        .padding(.vertical, 4)
                        .padding(.leading, 1)
                }
            }
            .overlay {
                shape.strokeBorder(isSelected ? PanelTheme.selectionBorder : Color.clear, lineWidth: 1)
            }
    }
}

extension View {
    func selectableRow(isSelected: Bool, shape: RoundedRectangle = PanelTheme.rowShape) -> some View {
        modifier(SelectableRowStyle(isSelected: isSelected, shape: shape))
    }
}
