import SwiftUI

/// Schermata di consultazione integrale delle clausole del Mandato di Vendita
public struct MandateClausesView: View {
    @Environment(\.dismiss) private var dismiss

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                LiquidGlassBackground()

                ScrollView {
                    VStack(spacing: 16) {
                        // Header Introduttivo
                        LiquidGlassCard(cornerRadius: 22, padding: 18) {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(spacing: 8) {
                                    Image(systemName: "signature")
                                        .font(.title3)
                                        .foregroundColor(.brandOrange)

                                    Text("Condizioni Mandato di Vendita")
                                        .font(.system(.headline, design: .rounded))
                                        .fontWeight(.bold)
                                        .foregroundColor(.primary)
                                }

                                Text("Riepilogo ufficiale delle condizioni contrattuali sottoscritte all'affidamento degli oggetti in conto vendita (art. 115 T.U.L.P.S.).")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }

                        // Elenco Clausole
                        clauseCard(
                            number: 1,
                            title: "Proprietà e Custodia",
                            badge: "Esposizione Gratuita",
                            badgeColor: .blue,
                            text: "Gli oggetti restano di proprietà del cliente fino alla loro vendita e permangono presso il mercatino mandatario in esposizione gratuita."
                        )

                        clauseCard(
                            number: 2,
                            title: "Corresponsione del Ricavato",
                            badge: "Provvigione Concordata",
                            badgeColor: .blue,
                            text: "Dopo l'avvenuta vendita sarà corrisposto al cliente l'importo concordato meno la percentuale di provvigione IVA compresa indicata sulla Lista Oggetti Ricevuti."
                        )

                        clauseCard(
                            number: 3,
                            title: "Maturazione Pagamento (15 Giorni)",
                            badge: "15 Giorni Diritto di Recesso",
                            badgeColor: .brandOrange,
                            text: "L'importo degli oggetti venduti diventa disponibile e ritirabile in cassa dopo 15 giorni dall'avvenuta vendita. Durante questo periodo l'articolo figura nella sezione 'In Recesso' a garanzia del cliente acquirente."
                        )

                        clauseCard(
                            number: 4,
                            title: "Durata Esposizione e Saldo al 50%",
                            badge: "60 Giorni Pieni + 30 Giorni Saldo",
                            badgeColor: .orange,
                            text: "La durata massima di esposizione a prezzo pieno è di 60 (sessanta) giorni. Dopo tale termine, gli oggetti invenduti e non ritirati vengono proposti scontati fino al 50% del prezzo concordato per ulteriori 30 giorni."
                        )

                        clauseCard(
                            number: 5,
                            title: "Scadenza dei 90 Giorni e Maggior Realizzo",
                            badge: "Oltre 90 Giorni",
                            badgeColor: .red,
                            text: "Trascorsi complessivamente 90 giorni (60gg pieni + 30gg scontati) senza che la merce sia stata venduta o ritirata, il mercatino è autorizzato a determinare il prezzo di vendita al maggior realizzo senza obbligo di preavviso."
                        )

                        clauseCard(
                            number: 6,
                            title: "Decadenza Crediti a 1 Anno",
                            badge: "365 Giorni (Art. 2964 C.C.)",
                            badgeColor: .red,
                            text: "Ogni diritto alla riscossione dei crediti maturati decade trascorso 1 anno (365 giorni) dalla data di vendita dell'oggetto, ai sensi dell'art. 2964 del Codice Civile."
                        )

                        clauseCard(
                            number: 7,
                            title: "Monitoraggio Scadenze",
                            badge: "A Cura del Cliente",
                            badgeColor: .secondary,
                            text: "Al fine di evitare lo sconto al 50% o la vendita al maggior realizzo, è cura del cliente verificare periodicamente lo stato e i tempi di esposizione dei propri oggetti tramite questa applicazione."
                        )

                        clauseCard(
                            number: 8,
                            title: "Privacy e Trattamento Dati",
                            badge: "Normativa GDPR",
                            badgeColor: .secondary,
                            text: "I dati personali sono trattati esclusivamente per le finalità connesse all'esecuzione del mandato di vendita e per la gestione amministrativa e fiscale."
                        )

                        Spacer(minLength: 20)
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Mandato di Vendita")
            .adaptiveInlineTitle()
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Chiudi") { dismiss() }
                        .foregroundColor(.brandOrange)
                        .fontWeight(.semibold)
                }
            }
        }
    }

    @ViewBuilder
    private func clauseCard(
        number: Int,
        title: String,
        badge: String,
        badgeColor: Color,
        text: String
    ) -> some View {
        LiquidGlassCard(cornerRadius: 20, padding: 16) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    ZStack {
                        Circle()
                            .fill(Color.brandOrange.opacity(0.15))
                            .frame(width: 28, height: 28)

                        Text("\(number)")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(.brandOrange)
                    }

                    Text(title)
                        .font(.system(.subheadline, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundColor(.primary)

                    Spacer()

                    Text(badge)
                        .font(.system(size: 10, weight: .semibold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(badgeColor.opacity(0.12))
                        .foregroundColor(badgeColor)
                        .clipShape(Capsule())
                }

                Divider()

                Text(text)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
