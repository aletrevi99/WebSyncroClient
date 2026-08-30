import SwiftUI

/// Sfondo ultra-fluido ad alte prestazioni (ottimizzato per ProMotion 120Hz)
public struct LiquidGlassBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    public init() {}

    public var body: some View {
        ZStack {
            // Sfondo di sistema base
            #if os(iOS)
            (colorScheme == .dark ? Color(uiColor: .systemBackground) : Color(uiColor: .secondarySystemGroupedBackground))
                .ignoresSafeArea()
            #else
            (colorScheme == .dark ? Color.black : Color(white: 0.95))
                .ignoresSafeArea()
            #endif

            // Gradiente d'atmosfera sottile e veloce, accelerato da GPU senza blur software pesante
            LinearGradient(
                colors: colorScheme == .dark ? [
                    Color.brandOrange.opacity(0.08),
                    Color.clear,
                    Color.clear
                ] : [
                    Color.brandOrange.opacity(0.05),
                    Color.clear,
                    Color.clear
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        }
    }
}
