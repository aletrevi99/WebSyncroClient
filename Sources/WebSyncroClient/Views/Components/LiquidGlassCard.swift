import SwiftUI

/// Card contenitore Liquid Glass stock Apple basata al 100% su materiali di sistema (.ultraThinMaterial)
public struct LiquidGlassCard<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    
    private let cornerRadius: CGFloat
    private let padding: CGFloat
    private let content: Content

    public init(
        cornerRadius: CGFloat = 20,
        padding: CGFloat = 16,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.content = content()
    }

    private var isDark: Bool {
        colorScheme == .dark
    }

    public var body: some View {
        content
            .padding(padding)
            .background(
                .ultraThinMaterial,
                in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        isDark ? Color.white.opacity(0.16) : Color.white.opacity(0.40),
                        lineWidth: 0.8
                    )
            )
            .shadow(
                color: Color.black.opacity(isDark ? 0.20 : 0.05),
                radius: 8,
                x: 0,
                y: 3
            )
    }
}

public extension View {
    func liquidGlassBackground(cornerRadius: CGFloat = 20, padding: CGFloat = 16) -> some View {
        LiquidGlassCard(cornerRadius: cornerRadius, padding: padding) {
            self
        }
    }
}
