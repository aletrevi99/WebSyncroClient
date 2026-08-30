import SwiftUI

/// Sfondo nativo di sistema iOS
public struct LiquidGlassBackground: View {
    public init() {}

    public var body: some View {
        #if os(iOS)
        Color(uiColor: .systemGroupedBackground)
            .ignoresSafeArea()
        #else
        Color(white: 0.95)
            .ignoresSafeArea()
        #endif
    }
}
