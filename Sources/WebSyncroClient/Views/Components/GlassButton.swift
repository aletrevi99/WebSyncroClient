import SwiftUI

/// Pulsante in stile Liquid Glass con feedback al tocco
public struct GlassButton: View {
    let title: String
    let iconName: String?
    let tint: Color
    let action: () -> Void

    public init(
        title: String,
        iconName: String? = nil,
        tint: Color = .blue,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.iconName = iconName
        self.tint = tint
        self.action = action
    }

    public var body: some View {
        Button(action: {
            HapticFeedback.impact(.light)
            action()
        }) {
            HStack(spacing: 8) {
                if let iconName = iconName {
                    Image(systemName: iconName)
                        .font(.system(size: 15, weight: .semibold))
                }
                Text(title)
                    .font(.system(.subheadline, design: .rounded))
                    .fontWeight(.semibold)
            }
            .foregroundColor(tint)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

