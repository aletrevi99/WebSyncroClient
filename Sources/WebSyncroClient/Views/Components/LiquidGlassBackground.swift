import SwiftUI

/// Sfondo fluido ambientale con gradienti dinamici e sfocature progressive che risaltano i materiali nativi
public struct LiquidGlassBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    public init() {}

    public var body: some View {
        ZStack {
            // Colore base di sfondo di sistema
            #if os(iOS)
            (colorScheme == .dark ? Color(uiColor: .systemBackground) : Color(uiColor: .secondarySystemBackground))
                .ignoresSafeArea()
            #else
            (colorScheme == .dark ? Color.black : Color(white: 0.95))
                .ignoresSafeArea()
            #endif

            // Bolle di luce ambientali per attivare la rifrazione e vibranza dei materiali
            GeometryReader { proxy in
                let size = proxy.size
                
                Circle()
                    .fill(
                        RadialGradient(
                            colors: colorScheme == .dark
                                ? [Color.blue.opacity(0.22), Color.clear]
                                : [Color.blue.opacity(0.12), Color.clear],
                            center: .center,
                            startRadius: 20,
                            endRadius: size.width * 0.45
                        )
                    )
                    .frame(width: size.width * 0.9, height: size.width * 0.9)
                    .offset(x: -size.width * 0.2, y: -size.height * 0.1)
                    .blur(radius: 60)

                Circle()
                    .fill(
                        RadialGradient(
                            colors: colorScheme == .dark
                                ? [Color.indigo.opacity(0.20), Color.clear]
                                : [Color.teal.opacity(0.10), Color.clear],
                            center: .center,
                            startRadius: 20,
                            endRadius: size.width * 0.40
                        )
                    )
                    .frame(width: size.width * 0.8, height: size.width * 0.8)
                    .offset(x: size.width * 0.35, y: size.height * 0.25)
                    .blur(radius: 50)

                Circle()
                    .fill(
                        RadialGradient(
                            colors: colorScheme == .dark
                                ? [Color.emeraldTint.opacity(0.15), Color.clear]
                                : [Color.green.opacity(0.08), Color.clear],
                            center: .center,
                            startRadius: 20,
                            endRadius: size.width * 0.35
                        )
                    )
                    .frame(width: size.width * 0.7, height: size.width * 0.7)
                    .offset(x: -size.width * 0.1, y: size.height * 0.6)
                    .blur(radius: 60)
            }
            .ignoresSafeArea()
        }
    }
}

private extension Color {
    static let emeraldTint = Color(red: 0.1, green: 0.75, blue: 0.45)
}

