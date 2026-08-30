import SwiftUI

/// Pulsante Liquid Glass nativo stock basato su .ultraThinMaterial e forme continue
public struct GlassButton: View {
    @Environment(\.colorScheme) private var colorScheme
    let title: String
    let iconName: String?
    let tint: Color
    let action: () -> Void

    public init(
        title: String,
        iconName: String? = nil,
        tint: Color = .brandOrange,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.iconName = iconName
        self.tint = tint
        self.action = action
    }

    private var isDark: Bool {
        colorScheme == .dark
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
            .background(.ultraThinMaterial, in: Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(
                        isDark ? Color.white.opacity(0.18) : Color.white.opacity(0.40),
                        lineWidth: 0.8
                    )
            )
            .shadow(color: Color.black.opacity(isDark ? 0.18 : 0.04), radius: 6, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
