import SwiftUI

/// Lista scrollabile delle vendite con raggruppamento temporale
public struct SalesListView: View {
    @ObservedObject var viewModel: DashboardViewModel

    public init(viewModel: DashboardViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        LazyVStack(spacing: 16) {
            ForEach(viewModel.groupedItems, id: \.section) { group in
                VStack(alignment: .leading, spacing: 10) {
                    // Intestazione sezione (es. "Agosto 2026")
                    HStack {
                        Text(group.section)
                            .font(.system(.footnote, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                            .tracking(0.5)

                        Spacer()

                        let sectionTotal = group.items.reduce(Decimal(0)) { $0 + $1.amount }
                        Text(CurrencyFormatter.format(decimal: sectionTotal))
                            .font(.system(.caption, design: .rounded))
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 6)

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

