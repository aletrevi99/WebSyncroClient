import SwiftUI

/// Card contenitore Liquid Glass realizzata esclusivamente con materiali di sistema nativi Apple (.ultraThinMaterial)
public struct LiquidGlassCard<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    
    private let cornerRadius: CGFloat
    private let padding: CGFloat
    private let content: Content

    public init(
        cornerRadius: CGFloat = 24,
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
                        LinearGradient(
                            colors: colorScheme == .dark ? [
                                Color.white.opacity(0.20),
                                Color.white.opacity(0.08),
                                Color.white.opacity(0.02)
                            ] : [
                                Color.white.opacity(0.70),
                                Color.white.opacity(0.30),
                                Color.white.opacity(0.10)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(
                color: colorScheme == .dark
                    ? Color.black.opacity(0.25)
                    : Color.black.opacity(0.06),
                radius: 12,
                x: 0,
                y: 6
            )
    }
}

public extension View {
    /// Applica l'effetto Liquid Glass a qualsiasi vista
    func liquidGlassBackground(cornerRadius: CGFloat = 24, padding: CGFloat = 16) -> some View {
        LiquidGlassCard(cornerRadius: cornerRadius, padding: padding) {
            self
        }
    }
}

