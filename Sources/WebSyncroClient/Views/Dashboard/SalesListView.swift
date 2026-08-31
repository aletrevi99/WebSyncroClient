import SwiftUI

/// Lista scrollabile delle vendite con raggruppamento temporale
public struct SalesListView: View {
    @ObservedObject var viewModel: DashboardViewModel

    public init(viewModel: DashboardViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        LazyVStack(spacing: 20) {
            ForEach(viewModel.groupedItems, id: \.section) { group in
                VStack(alignment: .leading, spacing: 12) {
                    // Intestazione Mese con Totale
                    HStack(alignment: .center) {
                        Text(group.section)
                            .font(.system(.subheadline, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                            .textCase(.uppercase)
                            .tracking(0.6)

                        Spacer()

                        let sectionTotal = group.items.reduce(Decimal(0)) { $0 + $1.amount }
                        Text(CurrencyFormatter.format(decimal: sectionTotal))
                            .font(.system(.caption, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .glassEffect(in: .capsule)
                    }
                    .padding(.horizontal, 4)
                    .padding(.top, 6)

                    // Righe vendite del gruppo
                    ForEach(group.items) { item in
                        SaleItemRowView(item: item) {
                            viewModel.selectedItemForDetail = item
                        }
                    }
                }
            }
        }
    }
}

