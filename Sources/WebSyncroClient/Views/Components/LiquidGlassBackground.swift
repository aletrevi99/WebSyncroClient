import SwiftUI

/// Sfondo nativo Apple con illuminazione d'ambiente e superficie per rifrazione Liquid Glass (.ultraThinMaterial)
public struct LiquidGlassBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    public init() {}

    private var isDark: Bool {
        colorScheme == .dark
    }

    public var body: some View {
        ZStack {
            // Fondo di sistema dinamico nativo Apple
            #if os(iOS)
            (isDark ? Color(uiColor: .systemBackground) : Color(uiColor: .systemGroupedBackground))
                .ignoresSafeArea()
            #else
            (isDark ? Color.black : Color(white: 0.95))
                .ignoresSafeArea()
            #endif

            // Bagliore d'ambiente superiore (Arancio Brand)
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.brandOrange.opacity(isDark ? 0.28 : 0.18),
                            Color.brandOrange.opacity(isDark ? 0.08 : 0.04),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 10,
                        endRadius: 200
                    )
                )
                .frame(width: 360, height: 360)
                .offset(x: -80, y: -160)
                .blur(radius: 40)
                .ignoresSafeArea()

            // Bagliore d'ambiente inferiore (Zaffiro / Indaco)
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.blue.opacity(isDark ? 0.20 : 0.12),
                            Color.indigo.opacity(isDark ? 0.06 : 0.03),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 15,
                        endRadius: 220
                    )
                )
                .frame(width: 400, height: 400)
                .offset(x: 90, y: 170)
                .blur(radius: 45)
                .ignoresSafeArea()
        }
    }
}
