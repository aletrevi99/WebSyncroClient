import SwiftUI

public enum EmptyOrErrorType {
    case empty(title: String, message: String)
    case error(message: String, onRetry: (() -> Void)? = nil, onEditAccount: (() -> Void)? = nil)
    case loading(message: String)
}

/// Vista flessibile per gestire gli stati di vuoto, errore o caricamento con design Liquid Glass
public struct EmptyOrErrorView: View {
    public let type: EmptyOrErrorType

    public init(type: EmptyOrErrorType) {
        self.type = type
    }

    public var body: some View {
        LiquidGlassCard(cornerRadius: 24, padding: 24) {
            VStack(spacing: 16) {
                switch type {
                case .empty(let title, let message):
                    Image(systemName: "tray.fill")
                        .font(.system(size: 44))
                        .foregroundColor(.secondary.opacity(0.7))

                    VStack(spacing: 6) {
                        Text(title)
                            .font(.system(.title3, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundColor(.primary)

                        Text(message)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }

                case .error(let message, let onRetry, let onEditAccount):
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 44))
                        .foregroundColor(.orange)

                    VStack(spacing: 6) {
                        Text("Attenzione")
                            .font(.system(.title3, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundColor(.primary)

                        Text(message)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }

                    VStack(spacing: 10) {
                        if let onRetry = onRetry {
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
                                .padding(.vertical, 10)
                                .background(Color.accentColor)
                                .foregroundColor(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                        }

                        if let onEditAccount = onEditAccount {
                            Button(action: {
                                HapticFeedback.selection()
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
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                        }
                    }
                    .padding(.top, 4)

                case .loading(let message):
                    ProgressView()
                        .scaleEffect(1.3)
                        .padding(.vertical, 8)

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
