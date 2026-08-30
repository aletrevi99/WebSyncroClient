import SwiftUI

/// Vista per la gestione e configurazione degli account negozio salvati
public struct AccountManagerView: View {
    @StateObject private var viewModel = AccountManagerViewModel()
    @Environment(\.dismiss) private var dismiss

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                LiquidGlassBackground()

                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(viewModel.accounts) { account in
                            let isSelected = account.id == viewModel.activeAccountId

                            LiquidGlassCard(cornerRadius: 20, padding: 16) {
                                HStack(spacing: 14) {
                                    // Indicatore attivo
                                    ZStack {
                                        Circle()
                                            .fill(isSelected ? Color.green.opacity(0.15) : Color.secondary.opacity(0.12))
                                            .frame(width: 40, height: 40)

                                        Image(systemName: isSelected ? "checkmark.circle.fill" : "person.crop.circle")
                                            .font(.system(size: 20))
                                            .foregroundColor(isSelected ? .green : .secondary)
                                    }

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(account.displayName)
                                            .font(.headline)
                                            .foregroundColor(.primary)

                                        Text(account.subtitle)
                                            .font(.caption)
                                            .foregroundColor(.secondary)

                                        if let lastEarned = account.lastTotalEarned {
                                            Text("Ultimo totale: \(CurrencyFormatter.format(decimal: lastEarned))")
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        }
                                    }

                                    Spacer()

                                    // Azioni: Modifica ed Elimina
                                    Menu {
                                        Button(action: {
                                            viewModel.selectAccount(account)
                                        }) {
                                            Label("Imposta come attivo", systemImage: "checkmark.circle")
                                        }

                                        Button(action: {
                                            viewModel.prepareEditAccount(account)
                                        }) {
                                            Label("Modifica", systemImage: "pencil")
                                        }

                                        Divider()

                                        Button(role: .destructive, action: {
                                            viewModel.deleteAccount(account)
                                        }) {
                                            Label("Elimina", systemImage: "trash")
                                        }
                                    } label: {
                                        Image(systemName: "ellipsis.circle")
                                            .font(.system(size: 20))
                                            .foregroundColor(.secondary)
                                            .padding(6)
                                    }
                                }
                            }
                            .onTapGesture {
                                viewModel.selectAccount(account)
                            }
                        }

                        // Pulsante Aggiungi Account / Utente
                        Button(action: {
                            viewModel.prepareAddAccount()
                        }) {
                            LiquidGlassCard(cornerRadius: 20, padding: 16) {
                                HStack(spacing: 12) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title3)
                                        .foregroundColor(.brandOrange)

                                    Text(AppSettingsStore.shared.isExNovoOnlyMode ? "Aggiungi un altro utente" : "Aggiungi un altro negozio")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.primary)

                                    Spacer()
                                }
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.top, 8)
                    }
                    .padding(16)
                }
            }
            .navigationTitle(AppSettingsStore.shared.isExNovoOnlyMode ? "I Miei Profili" : "I Miei Negozi")
            .adaptiveInlineTitle()
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fine") {
                        dismiss()
                    }
                    .foregroundColor(.brandOrange)
                    .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $viewModel.isAddingAccount) {
                AddAccountSheet(viewModel: viewModel)
            }
        }
    }
}
