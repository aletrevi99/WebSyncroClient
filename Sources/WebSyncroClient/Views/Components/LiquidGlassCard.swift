import SwiftUI

// MARK: - Liquid Glass Shape & Configuration

public enum GlassShape {
    case capsule
    case rect(cornerRadius: CGFloat)
    case circle
}

public struct GlassStyle: Equatable {
    public var tintColor: Color?
    public var isInteractive: Bool

    public static var regular: GlassStyle {
        GlassStyle(tintColor: nil, isInteractive: false)
    }

    public func tint(_ color: Color) -> GlassStyle {
        var copy = self
        copy.tintColor = color
        return copy
    }

    public func interactive(_ active: Bool = true) -> GlassStyle {
        var copy = self
        copy.isInteractive = active
        return copy
    }
}

// MARK: - Glass Effect Modifier

public struct GlassEffectModifier: ViewModifier {
    let style: GlassStyle
    let shape: GlassShape

    @Environment(\.colorScheme) private var colorScheme

    public init(style: GlassStyle = .regular, shape: GlassShape = .capsule) {
        self.style = style
        self.shape = shape
    }

    public func body(content: Content) -> some View {
        content
            .background(backgroundLayer)
    }

    @ViewBuilder
    private var backgroundLayer: some View {
        switch shape {
        case .capsule:
            Capsule()
                .fill(materialFill)
                .overlay(
                    Capsule()
                        .stroke(borderStroke, lineWidth: 0.8)
                )
                .overlay(tintOverlay(in: Capsule()))

        case .rect(let cornerRadius):
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(materialFill)
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(borderStroke, lineWidth: 0.8)
                )
                .overlay(tintOverlay(in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)))

        case .circle:
            Circle()
                .fill(materialFill)
                .overlay(
                    Circle()
                        .stroke(borderStroke, lineWidth: 0.8)
                )
                .overlay(tintOverlay(in: Circle()))
        }
    }

    private var materialFill: Material {
        .ultraThinMaterial
    }

    private var borderStroke: LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(colorScheme == .dark ? 0.22 : 0.45),
                Color.white.opacity(colorScheme == .dark ? 0.05 : 0.15)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    @ViewBuilder
    private func tintOverlay<S: Shape>(in shape: S) -> some View {
        if let tint = style.tintColor {
            shape
                .fill(tint.opacity(colorScheme == .dark ? 0.22 : 0.15))
        }
    }
}

// MARK: - GlassEffectContainer

public struct GlassEffectContainer<Content: View>: View {
    public let spacing: CGFloat
    public let content: Content

    public init(spacing: CGFloat = 8.0, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.content = content()
    }

    public var body: some View {
        content
    }
}

// MARK: - View Extensions for Liquid Glass

public extension View {
    @ViewBuilder
    func glassEffect(_ style: GlassStyle = .regular, in shape: GlassShape = .capsule) -> some View {
        self.modifier(GlassEffectModifier(style: style, shape: shape))
    }

    @ViewBuilder
    func glassEffect(in shape: GlassShape) -> some View {
        self.glassEffect(.regular, in: shape)
    }

    @ViewBuilder
    func glassEffectID(_ id: AnyHashable, in namespace: Namespace.ID) -> some View {
        self.matchedGeometryEffect(id: id, in: namespace)
    }

    @ViewBuilder
    func glassEffectUnion(id: AnyHashable, namespace: Namespace.ID) -> some View {
        self.matchedGeometryEffect(id: id, in: namespace)
    }
}

// MARK: - LiquidGlassCard

/// Card contenitore nativa con effetto Liquid Glass Apple
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
            .glassEffect(in: .rect(cornerRadius: cornerRadius))
    }
}

public extension View {
    func liquidGlassBackground(cornerRadius: CGFloat = 16, padding: CGFloat = 16) -> some View {
        LiquidGlassCard(cornerRadius: cornerRadius, padding: padding) {
            self
        }
    }
}
