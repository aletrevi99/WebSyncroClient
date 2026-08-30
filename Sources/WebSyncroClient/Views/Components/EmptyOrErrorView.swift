import SwiftUI

/// Vista per stati vuoti, errori o caricamento con estetica Liquid Glass
public struct EmptyOrErrorView: View {
    public enum ViewType {
        case empty(title: String, message: String)
        case error(
            message: String,
            onRetry: () -> Void,
            onEditAccount: (() -> Void)? = nil,
            onEnableDemo: (() -> Void)? = nil
        )
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

                case .error(let message, let onRetry, let onEditAccount, let onEnableDemo):
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 44))
                        .foregroundColor(.orange)
                        .padding(.top, 4)

                    Text("Attenzione")
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text(message)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)

                    VStack(spacing: 10) {
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
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                        }

                        if let onEditAccount = onEditAccount {
                            Button(action: {
                                HapticFeedback.impact(.light)
                                onEditAccount()
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "person.crop.circle.badge.plus")
                                    Text("Configura Negozio e Utente")
                                }
                                .font(.system(.subheadline, design: .rounded))
                                .fontWeight(.medium)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(Color.secondary.opacity(0.12))
                                .foregroundColor(.primary)
                                .clipShape(Capsule())
                            }
                        }

                        if let onEnableDemo = onEnableDemo {
                            Button(action: {
                                HapticFeedback.selection()
                                onEnableDemo()
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "sparkles")
                                    Text("Prova con Dati Simulati (Demo)")
                                }
                                .font(.system(.caption, design: .rounded))
                                .fontWeight(.medium)
                                .foregroundColor(.accentColor)
                                .padding(.top, 4)
                            }
                        }
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
