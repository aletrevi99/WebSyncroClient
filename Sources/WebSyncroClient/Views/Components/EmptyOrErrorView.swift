import SwiftUI

/// Vista per stati vuoti, errori o caricamento con estetica Liquid Glass
public struct EmptyOrErrorView: View {
    public enum ViewType {
        case empty(title: String, message: String)
        case error(message: String, onRetry: () -> Void)
        case loading(message: String)
    }

    let type: ViewType

    public init(type: ViewType) {
        self.type = type
    }

    public var body: some View {
        LiquidGlassCard(cornerRadius: 24, padding: 24) {
            VStack(spacing: 16) {
                switch type {
                case .empty(let title, let message):
                    Image(systemName: "tray")
                        .font(.system(size: 40, weight: .light))
                        .foregroundColor(.secondary)
                        .padding(.top, 8)

                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text(message)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)

                case .error(let message, let onRetry):
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.orange)
                        .padding(.top, 8)

                    Text("Attenzione")
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text(message)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)

                    Button(action: {
                        HapticFeedback.impact(.medium)
                        onRetry()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.clockwise")
                            Text("Riprova")
                        }
                        .font(.system(.subheadline, design: .rounded))
                        .fontWeight(.semibold)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                    }
                    .padding(.top, 8)

                case .loading(let message):
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(1.2)
                        .padding(.top, 12)

                    Text(message)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
}

