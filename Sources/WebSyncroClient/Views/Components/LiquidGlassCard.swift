import SwiftUI

/// Card contenitore Liquid Glass ad alte prestazioni (120fps) con materiali di sistema nativi Apple (.ultraThinMaterial)
public struct LiquidGlassCard<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    
    private let cornerRadius: CGFloat
    private let padding: CGFloat
    private let content: Content

    public init(
        cornerRadius: CGFloat = 22,
        padding: CGFloat = 16,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.content = content()
    }

    public var body: some View {
        content
            .padding(padding)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        colorScheme == .dark
                            ? Color.white.opacity(0.12)
                            : Color.white.opacity(0.60),
                        lineWidth: 1
                    )
            )
            .shadow(
                color: colorScheme == .dark
                    ? Color.black.opacity(0.20)
                    : Color.black.opacity(0.04),
                radius: 6,
                x: 0,
                y: 3
            )
    }
}

public extension View {
    func liquidGlassBackground(cornerRadius: CGFloat = 22, padding: CGFloat = 16) -> some View {
        LiquidGlassCard(cornerRadius: cornerRadius, padding: padding) {
            self
        }
    }
}
