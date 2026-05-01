import SwiftUI


public func actionButton(title: String, disabled: Bool, action: @escaping () -> Void) -> some View {
    Button(action: action) {
        HStack {
            Spacer()
            Text(title).fontWeight(.semibold)
            Spacer()
        }
    }
    .disabled(disabled)
}
