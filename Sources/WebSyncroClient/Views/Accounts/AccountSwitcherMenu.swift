import SwiftUI

/// Menu rapido di selezione account posizionato nella testata dell'app
public struct AccountSwitcherMenu: View {
    @ObservedObject var accountStore: AccountStore
    let onManageAccounts: () -> Void

    public init(accountStore: AccountStore, onManageAccounts: @escaping () -> Void) {
        self.accountStore = accountStore
        self.onManageAccounts = onManageAccounts
    }

    public var body: some View {
        Menu {
            Section(AppSettingsStore.shared.isExNovoOnlyMode ? "Profili Utente" : "I Miei Negozi") {
                ForEach(accountStore.accounts) { account in
                    Button(action: {
                        accountStore.selectAccount(id: account.id)
                        HapticFeedback.selection()
                    }) {
                        HStack {
                            Text(account.displayName)
                            if account.id == accountStore.activeAccountId {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            }

            Section {
                Button(action: {
                    HapticFeedback.impact(.light)
                    onManageAccounts()
                }) {
                    Label(AppSettingsStore.shared.isExNovoOnlyMode ? "Gestisci profili..." : "Gestisci negozi...", systemImage: "person.crop.circle.badge.plus")
                }
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "storefront.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.brandOrange)

                Text(accountStore.activeAccount?.displayName ?? "Seleziona")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                    .foregroundColor(.primary)

                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(.ultraThinMaterial, in: Capsule())
        }
        .buttonStyle(PlainButtonStyle())
    }
}
