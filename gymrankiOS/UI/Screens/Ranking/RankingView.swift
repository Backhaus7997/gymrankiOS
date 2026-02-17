import SwiftUI

struct RankingView: View {

    let bottomInset: CGFloat

    @State private var selected: Segment = .weekly

    enum Segment: String, CaseIterable, Identifiable {
        case weekly = "Semanal"
        case monthly = "Mensual"
        case history = "Historial"
        var id: String { rawValue }
    }

    private var model: RankingModel {
        switch selected {
        case .weekly: return .weeklyMock
        case .monthly: return .monthlyMock
        case .history: return .historyMock
        }
    }

    var body: some View {
        ZStack {
            AppBackground().ignoresSafeArea()

            VStack(spacing: 12) {
                topBar
                segmented

                Divider()
                    .overlay(Color.white.opacity(0.08))

                // ⬇️ Podio fijo (no scrollea)
                podium
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                // ⬇️ SOLO lista scrolleable
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 10) {
                        ForEach(model.rest) { row in
                            RankingRowView(row: row)
                        }

                        // ✅ aire dinámico para que el último item no quede debajo del card + tab bar
                        Spacer().frame(height: bottomInset + 90)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                }
            }

            // ⬇️ Bloque opaco fijo (tapa la lista detrás)
            VStack(spacing: 0) {
                Spacer()

                // esta placa opaca es la que "tapa" el ranking por debajo
                Rectangle()
                    .fill(Color.black)
                    .frame(height: bottomInset + 120) // ajustá el 120 si querés más/menos alto
                    .overlay(
                        // arriba de la placa ponemos el card
                        bottomPinnedCard
                            .padding(.horizontal, 16)
                            .padding(.bottom, bottomInset - 12), // tu ajuste fino
                        alignment: .top
                    )
            }
            .ignoresSafeArea(edges: .bottom)
        }
        .navigationBarBackButtonHidden(true)
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack(spacing: 12) {

            Button {
                print("back")
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white.opacity(0.9))
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(Color.white.opacity(0.06)))
                    .overlay(Circle().stroke(Color.white.opacity(0.10), lineWidth: 1))
            }
            .buttonStyle(.plain)

            VStack(spacing: 4) {
                Text(model.gymName)
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .foregroundColor(.white.opacity(0.95))

                Text(model.location)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.55))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.white.opacity(0.06))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(Color.white.opacity(0.10), lineWidth: 1)
                    )
            }

            Spacer()

            Button { print("search") } label: {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.white.opacity(0.9))
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(Color.white.opacity(0.06)))
                    .overlay(Circle().stroke(Color.white.opacity(0.10), lineWidth: 1))
            }
            .buttonStyle(.plain)

            Button { print("bell") } label: {
                Image(systemName: "bell")
                    .foregroundColor(.white.opacity(0.9))
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(Color.white.opacity(0.06)))
                    .overlay(Circle().stroke(Color.white.opacity(0.10), lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
    }

    // MARK: - Segmented Tabs

    private var segmented: some View {
        HStack(spacing: 0) {
            ForEach(Segment.allCases) { seg in
                Button {
                    selected = seg
                } label: {
                    VStack(spacing: 10) {
                        Text(seg.rawValue)
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(selected == seg ? Color.appGreen : .white.opacity(0.55))
                            .frame(maxWidth: .infinity)

                        Rectangle()
                            .fill(selected == seg ? Color.appGreen : Color.clear)
                            .frame(height: 2)
                            .padding(.horizontal, 18)
                    }
                    .padding(.top, 8)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 8)
    }

    // MARK: - Podium

    private var podium: some View {
        HStack(alignment: .top, spacing: 18) {

            PodiumItemView(
                rank: 2,
                name: model.top[1].name,
                points: model.top[1].points
            )
            .frame(maxWidth: .infinity)

            PodiumItemView(
                rank: 1,
                name: model.top[0].name,
                points: model.top[0].points
            )
            .frame(maxWidth: .infinity)

            PodiumItemView(
                rank: 3,
                name: model.top[2].name,
                points: model.top[2].points
            )
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Bottom pinned card

    private var bottomPinnedCard: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Tu posición")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.55))

                Text("#\(model.me.rank) · \(formatPoints(model.me.points)) pts")
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                    .foregroundColor(.white.opacity(0.92))
            }

            Spacer()

            Button {
                print("ver detalles")
            } label: {
                Text("Ver detalles")
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .foregroundColor(.black)
                    .frame(width: 120, height: 40)
                    .background(Capsule().fill(Color.appGreen.opacity(0.95)))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.black) // ✅ solo bloque negro, sin borde
    }


    private func formatPoints(_ points: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = "."
        formatter.decimalSeparator = ","
        return formatter.string(from: NSNumber(value: points)) ?? "\(points)"
    }
}

// MARK: - Podium Item (con medallas color)

private struct PodiumItemView: View {
    let rank: Int
    let name: String
    let points: Int

    private var isWinner: Bool { rank == 1 }

    private var medalColor: Color {
        switch rank {
        case 1: return Color.yellow.opacity(0.95)   // oro
        case 2: return Color.white.opacity(0.85)    // plata
        default: return Color.orange.opacity(0.85)  // bronce
        }
    }

    private var ringColor: Color {
        switch rank {
        case 1: return Color.appGreen.opacity(0.90) // aro verde
        case 2: return Color.white.opacity(0.20)
        default: return Color.white.opacity(0.18)
        }
    }

    var body: some View {
        VStack(spacing: 10) {

            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.07))
                    .frame(width: isWinner ? 96 : 76, height: isWinner ? 96 : 76)

                Circle()
                    .stroke(ringColor, lineWidth: isWinner ? 2 : 1)
                    .frame(width: isWinner ? 108 : 76, height: isWinner ? 108 : 76)

                Image(systemName: "medal.fill")
                    .font(.system(size: isWinner ? 34 : 28, weight: .semibold))
                    .foregroundColor(medalColor)
            }

            Text("#\(rank)")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(isWinner ? Color.appGreen.opacity(0.95) : .white.opacity(0.65))

            VStack(spacing: 4) {
                Text(name)
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .foregroundColor(.white.opacity(0.92))
                    .lineLimit(1)

                Text("\(points) pts")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.55))
            }
        }
    }
}

// MARK: - Row

private struct RankingRowView: View {
    let row: RankingRow

    var body: some View {
        HStack(spacing: 12) {

            Text("#\(row.rank)")
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .foregroundColor(.white.opacity(0.65))
                .frame(width: 34, alignment: .leading)

            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.07))
                    .frame(width: 34, height: 34)

                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.75))
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(row.name)
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                    .foregroundColor(.white.opacity(0.92))

                Text(row.role)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.50))
            }

            Spacer()

            Text("\(row.points) pts")
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .foregroundColor(.white.opacity(0.85))
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.10), lineWidth: 1)
                )
        )
    }
}

// MARK: - Model

private struct RankingModel {
    let gymName: String
    let location: String
    let top: [RankingTop]
    let rest: [RankingRow]
    let me: RankingMe

    static let weeklyMock = RankingModel(
        gymName: "Iron Temple",
        location: "Buenos Aires, AR",
        top: [
            .init(name: "Mateo Rossi", points: 2450),
            .init(name: "Sofía Hernández", points: 2100),
            .init(name: "Lucas González", points: 1850)
        ],
        rest: [
            .init(rank: 4, name: "Valentina Solís", role: "Competidor/a", points: 1640),
            .init(rank: 5, name: "Joaquín Paz", role: "Competidor/a", points: 1520),
            .init(rank: 6, name: "Micaela Suárez", role: "Competidor/a", points: 1450),
            .init(rank: 7, name: "Tomás Herrera", role: "Competidor/a", points: 1320),
            .init(rank: 8, name: "Agustín Rivas", role: "Competidor/a", points: 1280),
            .init(rank: 9, name: "Florencia Neri", role: "Competidor/a", points: 1210)
        ],
        me: .init(rank: 14, points: 6240)
    )

    static let monthlyMock = RankingModel(
        gymName: "Iron Temple",
        location: "Buenos Aires, AR",
        top: [
            .init(name: "Camila Duarte", points: 8120),
            .init(name: "Bruno Sosa", points: 7650),
            .init(name: "Nicolás Reyes", points: 7020)
        ],
        rest: [
            .init(rank: 4, name: "Martina Gil", role: "Competidor/a", points: 6810),
            .init(rank: 5, name: "Franco Paredes", role: "Competidor/a", points: 6590),
            .init(rank: 6, name: "Lucía Peralta", role: "Competidor/a", points: 6420),
            .init(rank: 7, name: "Santiago Lemos", role: "Competidor/a", points: 6210),
            .init(rank: 8, name: "Julieta Vázquez", role: "Competidor/a", points: 6050),
            .init(rank: 9, name: "Matías Aquino", role: "Competidor/a", points: 5980)
        ],
        me: .init(rank: 14, points: 11240)
    )

    static let historyMock = RankingModel(
        gymName: "Iron Temple",
        location: "Buenos Aires, AR",
        top: [
            .init(name: "Renata Molina", points: 22100),
            .init(name: "Iván Correa", points: 20500),
            .init(name: "Paula Benítez", points: 19250)
        ],
        rest: [
            .init(rank: 4, name: "Diego Funes", role: "Competidor/a", points: 18440),
            .init(rank: 5, name: "Carla Ríos", role: "Competidor/a", points: 17620),
            .init(rank: 6, name: "Esteban Vidal", role: "Competidor/a", points: 16990),
            .init(rank: 7, name: "Ana Cordero", role: "Competidor/a", points: 15800),
            .init(rank: 8, name: "Pablo Ferrer", role: "Competidor/a", points: 14950),
            .init(rank: 9, name: "Cecilia Mena", role: "Competidor/a", points: 14110)
        ],
        me: .init(rank: 14, points: 35240)
    )
}

private struct RankingTop {
    let name: String
    let points: Int
}

private struct RankingRow: Identifiable {
    let id = UUID()
    let rank: Int
    let name: String
    let role: String
    let points: Int
}

private struct RankingMe {
    let rank: Int
    let points: Int
}

#Preview {
    NavigationStack {
        RankingView(bottomInset: 36)
    }
}
