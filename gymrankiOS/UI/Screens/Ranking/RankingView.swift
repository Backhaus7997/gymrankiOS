import SwiftUI

struct RankingView: View {

    @EnvironmentObject private var session: SessionManager

    let bottomInset: CGFloat
    @State private var selected: Segment = .weekly
    @StateObject private var vm = RankingVM()

    enum Segment: String, CaseIterable, Identifiable {
        case weekly = "Semanal"
        case monthly = "Mensual"
        case history = "Historial"
        var id: String { rawValue }
    }

    private var uid: String { session.userId }

    var body: some View {
        ZStack {
            AppBackground().ignoresSafeArea()

            VStack(spacing: 12) {
                topBar
                segmented

                Divider()
                    .overlay(Color.white.opacity(0.08))
                
                if let err = vm.errorMessage, !err.isEmpty {
                    Text(err)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(.red.opacity(0.9))
                        .padding(.horizontal, 16)
                }
                
                podium
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 10) {
                        ForEach(vm.rest) { row in
                            RankingRowView(row: row)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                    .padding(.bottom, 120)
                }
            }

            if vm.isLoading {
                SwiftUI.ProgressView()
                    .tint(.white)
            }
        }
        .safeAreaInset(edge: .bottom) {
            bottomPinnedCard
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .padding(.bottom, max(8, bottomInset - 8))
                .background(Color.black.opacity(0.75))
        }
        .task {
            await vm.load(segment: mapSegment(selected), sessionUserId: uid)
        }
        .onChange(of: selected) { _, newValue in
            Task { await vm.load(segment: mapSegment(newValue), sessionUserId: uid) }
        }
        .navigationBarBackButtonHidden(true)
    }

    private func mapSegment(_ seg: Segment) -> RankingVM.Segment {
        switch seg {
        case .weekly: return .weekly
        case .monthly: return .monthly
        case .history: return .history
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack(spacing: 12) {
            
            Spacer().frame(width: 40)
                        
            VStack(alignment: .leading, spacing: 6) {
                Text(vm.gymName)
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .foregroundColor(.white.opacity(0.95))

                Text("Comunidad: \(vm.communityCount)")
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
            .frame(maxWidth: .infinity, alignment: .leading)

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
                Button { selected = seg } label: {
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
        let t = vm.top3
        return HStack(alignment: .top, spacing: 18) {
            
            PodiumItemView(
                rank: 2,
                name: t.count > 1 ? t[1].name : "—",
                points: t.count > 1 ? t[1].points : 0
            )
            .frame(maxWidth: CGFloat.infinity)
            
            PodiumItemView(
                rank: 1,
                name: t.count > 0 ? t[0].name : "—",
                points: t.count > 0 ? t[0].points : 0
            )
            .frame(maxWidth: CGFloat.infinity)
            
            PodiumItemView(
                rank: 3,
                name: t.count > 2 ? t[2].name : "—",
                points: t.count > 2 ? t[2].points : 0
            )
            .frame(maxWidth: CGFloat.infinity)
        }
    }

    // MARK: - Bottom pinned card

    private var bottomPinnedCard: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Tu posición")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.55))

                Text(vm.me.rank > 0 ? "#\(vm.me.rank) · \(formatPoints(vm.me.points)) pts" : "—")
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                    .foregroundColor(.white.opacity(0.92))
            }

            Spacer()

            Button { print("ver detalles") } label: {
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
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.black.opacity(0.75))
        )
    }

    private func formatPoints(_ points: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = "."
        formatter.decimalSeparator = ","
        return formatter.string(from: NSNumber(value: points)) ?? "\(points)"
    }
}


struct PodiumItemView: View {
    let rank: Int
    let name: String
    let points: Int

    private var isWinner: Bool { rank == 1 }

    private var medalColor: Color {
        switch rank {
        case 1: return Color.yellow.opacity(0.95)
        case 2: return Color.white.opacity(0.85)
        default: return Color.orange.opacity(0.85)
        }
    }

    private var ringColor: Color {
        switch rank {
        case 1: return Color.appGreen.opacity(0.90)
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

struct RankingRowView: View {
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
