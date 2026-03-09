import SwiftUI

struct RankingView: View {

    @EnvironmentObject private var session: SessionManager

    let bottomInset: CGFloat
    @State private var selected: Segment = .weekly
    @StateObject private var vm = RankingVM()

    @State private var showGlobalTop = false
    @State private var showDetails = false

    enum Segment: String, CaseIterable, Identifiable {
        case weekly = "Semanal"
        case monthly = "Mensual"
        var id: String { rawValue }
    }

    private var uid: String { session.userId }

    private var shouldShowNoGymState: Bool {
        guard let err = vm.errorMessage?.lowercased() else { return false }
        return err.contains("gymid")
    }

    var body: some View {
        ZStack {
            AppBackground().ignoresSafeArea()

            VStack(spacing: 12) {
                topBar
                segmented

                Divider()
                    .overlay(Color.white.opacity(0.08))

                if shouldShowNoGymState {
                    Spacer()

                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.06))
                                .frame(width: 78, height: 78)

                            Image(systemName: "building.2.crop.circle")
                                .font(.system(size: 32, weight: .semibold))
                                .foregroundColor(Color.appGreen.opacity(0.95))
                        }

                        Text("No participás del ranking semanal/mensual")
                            .font(.system(size: 20, weight: .heavy, design: .rounded))
                            .foregroundColor(.white.opacity(0.95))
                            .multilineTextAlignment(.center)

                        Text("Tu gimnasio no está vinculado a la app.\nSolicitá a tu gym vincularse para acceder al ranking.")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundColor(.white.opacity(0.60))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 28)
                    }
                    .padding(.horizontal, 20)

                    Spacer()
                } else {
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
        .navigationDestination(isPresented: $showGlobalTop) {
            GlobalRankingView(bottomInset: bottomInset)
                .environmentObject(session)
        }
        .sheet(isPresented: $showDetails) {
            RankingDetailsSheet()
                .environmentObject(session)
        }
        .navigationBarBackButtonHidden(true)
    }

    private func mapSegment(_ seg: Segment) -> RankingVM.Segment {
        switch seg {
        case .weekly: return .weekly
        case .monthly: return .monthly
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack(spacing: 12) {

            Spacer().frame(width: 40)

            VStack(alignment: .leading, spacing: 6) {
                Text(shouldShowNoGymState ? "Ranking" : vm.gymName)
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .foregroundColor(.white.opacity(0.95))

                Text(shouldShowNoGymState ? "Gym no vinculado" : "Comunidad: \(vm.communityCount)")
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

            Button {
                showGlobalTop = true
            } label: {
                Text("Top Global")
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .foregroundColor(.black.opacity(0.9))
                    .padding(.horizontal, 12)
                    .frame(height: 40)
                    .background(Capsule().fill(Color.appGreen.opacity(0.95)))
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

            Button { showDetails = true } label: {
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
