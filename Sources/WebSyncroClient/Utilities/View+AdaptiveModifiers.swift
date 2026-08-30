import SwiftUI

public extension View {
    /// Adatta il display mode della barra di navigazione solo su iOS
    @ViewBuilder
    func adaptiveInlineTitle() -> some View {
        #if os(iOS)
        self.navigationBarTitleDisplayMode(.inline)
        #else
        self
        #endif
    }

    /// Adatta il display mode large della barra di navigazione solo su iOS
    @ViewBuilder
    func adaptiveLargeTitle() -> some View {
        #if os(iOS)
        self.navigationBarTitleDisplayMode(.large)
        #else
        self
        #endif
    }
}

