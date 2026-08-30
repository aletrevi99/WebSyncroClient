import SwiftUI

/// Card contenitore nativa con materiale di sistema Apple (.ultraThinMaterial)
public struct LiquidGlassCard<Content: View>: View {
    private let cornerRadius: CGFloat
    private let padding: CGFloat
    private let content: Content

    public init(
        cornerRadius: CGFloat = 16,
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
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

public extension View {
    func liquidGlassBackground(cornerRadius: CGFloat = 16, padding: CGFloat = 16) -> some View {
        LiquidGlassCard(cornerRadius: cornerRadius, padding: padding) {
            self
        }
    }
}
