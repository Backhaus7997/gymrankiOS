//
//  ChallengesView.swift
//  gymrankiOS
//

import SwiftUI

// MARK: - ViewModel

@MainActor
final class ChallengesHomeVM: ObservableObject {
    @Published var isLoading = false
    @Published var active: [ActiveChallenge] = []
    @Published var completed: [ActiveChallenge] = []
    @Published var errorMessage: String?

    private let repo = ChallengeRepository()

    struct ActiveChallenge: Identifiable, Hashable {
        let id: String
        let userChallenge: UserChallenge
        let template: ChallengeTemplate

        var elapsedDays: Int {
            max(0, Int(Date().timeIntervalSince(userChallenge.startedDate) / 86400.0))
        }

        var remainingDays: Int {
            max(0, template.durationDays - elapsedDays)
        }

        var progress01: Double {
            guard template.durationDays > 0 else { return 0 }
            // si está completed lo mostramos lleno
            if userChallenge.status == UserChallengeStatus.completed { return 1.0 }
            return min(1.0, Double(elapsedDays) / Double(template.durationDays))
        }

        var dayIndex: Int {
            let total = max(template.durationDays, 1)
            return min(elapsedDays + 1, total)
        }

        var totalDays: Int {
            max(template.durationDays, 1)
        }
    }

    func load(uid: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            // Traemos todo y separamos por status
            let all = try await repo.fetchUserChallenges(uid: uid, onlyActive: false)

            let activeUC = all.filter { $0.status == UserChallengeStatus.active }
            let completedUC = all.filter { $0.status == UserChallengeStatus.completed }

            let ids = Array(Set(all.map { $0.templateId }))
            let templates = try await repo.fetchTemplates(byIds: ids)

            let map: [String: ChallengeTemplate] = Dictionary(uniqueKeysWithValues: templates.map { ($0.id, $0) })

            func merge(_ list: [UserChallenge]) -> [ActiveChallenge] {
                list.compactMap { uc in
                    guard let tpl = map[uc.templateId] else { return nil }
                    return ActiveChallenge(
                        id: "\(uc.templateId)_\(uc.uid)",
                        userChallenge: uc,
                        template: tpl
                    )
                }
            }

            self.active = merge(activeUC)
            self.completed = merge(completedUC)

        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
}

// MARK: - View

struct ChallengesView: View {

    @EnvironmentObject private var session: SessionManager

    @StateObject private var vm = ChallengesHomeVM()

    @State private var selected: Segment = .pending
    @State private var route: Route? = nil
    @State private var selectedActiveChallenge: ChallengesHomeVM.ActiveChallenge? = nil

    @State private var showEquipmentSheet = false
    @State private var showDestinyBetPopup = false

    private let sidePadding: CGFloat = 16
    private var uid: String { session.userId }

    enum Segment: String, CaseIterable, Identifiable {
        case pending = "Pendiente"
        case completed = "Completados"
        var id: String { rawValue }

        var icon: String {
            switch self {
            case .pending: return "checkmark.circle"
            case .completed: return "checkmark.seal"
            }
        }
    }

    enum Route: Hashable, Identifiable {
        case discover
        case missions
        var id: String { String(describing: self) }
    }

    private let items: [QuickCard] = [
        .init(title: "Descubrir", subtitle: "Nuevos desafíos", icon: "magnifyingglass"),
        .init(title: "Misiones", subtitle: "Crear y gestionar", icon: "checklist"),
        .init(title: "Apuestas", subtitle: "Rueda y dados", icon: "die.face.5"),
        .init(title: "Equipamiento", subtitle: "Tus ítems y stats", icon: "wrench.and.screwdriver")
    ]

    private let columns: [GridItem] = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]

    private var listToShow: [ChallengesHomeVM.ActiveChallenge] {
        selected == .pending ? vm.active : vm.completed
    }

    private var showError: Binding<Bool> {
        Binding(
            get: { vm.errorMessage != nil },
            set: { if !$0 { vm.errorMessage = nil } }
        )
    }

    var body: some View {
        ZStack {
            AppBackground().ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {

                    topBar

                    quickActionsGrid

                    Text("Vista:")
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                        .foregroundColor(.white.opacity(0.9))
                        .padding(.top, 4)

                    segmented

                    challengesSection

                    Spacer(minLength: 110)
                }
                .padding(.horizontal, sidePadding)
                .padding(.top, 10)
                .padding(.bottom, 24)
            }

            if showDestinyBetPopup {
                CenterModalOverlay(isPresented: $showDestinyBetPopup) {
                    DestinyBetFlowPopup(onClose: { showDestinyBetPopup = false })
                        .padding(.horizontal, 18)
                }
                .zIndex(50)
            }

            if vm.isLoading {
                SwiftUI.ProgressView()
                    .tint(.white.opacity(0.9))
            }
        }
        .task {
            let cleanUid = uid.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !cleanUid.isEmpty else { return }
            await vm.load(uid: cleanUid)
        }
        .navigationBarBackButtonHidden(true)
        .navigationDestination(item: $route) { r in
            switch r {
            case .discover:
                ChallengesDiscoverView()
            case .missions:
                MissionsView()
            }
        }
        .navigationDestination(item: $selectedActiveChallenge) { a in
            ActiveChallengeDetailView(active: a) {
                Task {
                    let cleanUid = uid.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !cleanUid.isEmpty else { return }
                    await vm.load(uid: cleanUid)
                }
            }
        }
        .sheet(isPresented: $showEquipmentSheet) {
            EquipmentView { selectedItems in
                print("Equipamiento elegido:", selectedItems)
            }
            .presentationDetents([.fraction(0.70), .large])
            .presentationDragIndicator(.hidden)
            .presentationCornerRadius(22)
        }
        .alert("Error", isPresented: showError, actions: {
            Button("OK") { vm.errorMessage = nil }
        }, message: {
            Text(vm.errorMessage ?? "")
        })
    }

    // MARK: - Top bar

    private var topBar: some View {
        HStack {
            Text("Desafíos")
                .font(.system(size: 34, weight: .heavy, design: .rounded))
                .foregroundColor(.white)

            Spacer()

            Button {
                print("menu")
            } label: {
                Image(systemName: "line.3.horizontal")
                    .foregroundColor(.white.opacity(0.9))
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(Color.white.opacity(0.06)))
                    .overlay(Circle().stroke(Color.white.opacity(0.10), lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 6)
    }

    // MARK: - Grid

    private var quickActionsGrid: some View {
        LazyVGrid(columns: columns, spacing: 14) {
            ForEach(items) { item in
                Button {
                    handleQuickTap(item.title)
                } label: {
                    QuickCardView(item: item)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func handleQuickTap(_ title: String) {
        switch title {
        case "Descubrir":
            route = .discover
        case "Misiones":
            route = .missions
        case "Equipamiento":
            showEquipmentSheet = true
        case "Apuestas":
            showDestinyBetPopup = true
        default:
            print("tap \(title)")
        }
    }

    // MARK: - Segmented

    private var segmented: some View {
        HStack(spacing: 10) {
            ForEach(Segment.allCases) { seg in
                Button {
                    selected = seg
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: seg.icon)
                            .font(.system(size: 13, weight: .bold))

                        Text(seg.rawValue)
                            .font(.system(size: 13, weight: .heavy, design: .rounded))
                            .lineLimit(1)
                    }
                    .foregroundColor(selected == seg ? Color.appGreen : .white.opacity(0.55))
                    .padding(.vertical, 10)
                    .padding(.horizontal, 12)
                    .frame(maxWidth: .infinity)
                    .background(
                        Capsule()
                            .fill(selected == seg ? Color.appGreen.opacity(0.12) : Color.white.opacity(0.06))
                    )
                    .overlay(
                        Capsule()
                            .stroke(selected == seg ? Color.appGreen.opacity(0.35) : Color.white.opacity(0.10), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.top, 2)
    }

    // MARK: - Section

    @ViewBuilder
    private var challengesSection: some View {
        if listToShow.isEmpty {
            emptyStateCard
        } else {
            VStack(spacing: 14) {
                ForEach(listToShow) { a in
                    Button {
                        selectedActiveChallenge = a
                    } label: {
                        ActiveChallengeCard(active: a, mode: selected)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.top, 6)
        }
    }

    private var emptyStateCard: some View {
        let title: String = (selected == .pending) ? "No hay desafíos pendientes" : "No hay desafíos completados"
        let subtitle: String = (selected == .pending) ? "Sumate a uno en Descubrir" : "Completá uno para verlo acá"

        return VStack(spacing: 14) {

            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.black.opacity(0.25))
                .frame(height: 210)
                .overlay(
                    Image(systemName: selected == .pending ? "flag.checkered" : "checkmark.seal.fill")
                        .font(.system(size: 54, weight: .bold))
                        .foregroundColor(.white.opacity(0.30))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.white.opacity(0.10), lineWidth: 1)
                )
                .padding(.top, 6)

            VStack(spacing: 6) {
                Text(title)
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .foregroundColor(.white.opacity(0.92))

                Text(subtitle)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.55))
            }

            Capsule()
                .fill(Color.appGreen.opacity(0.50))
                .frame(width: 70, height: 4)
                .padding(.top, 4)
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.appGreen.opacity(0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.appGreen.opacity(0.22), lineWidth: 1)
                )
        )
        .padding(.top, 6)
    }
}

// MARK: - Active Challenge Card

private struct ActiveChallengeCard: View {
    let active: ChallengesHomeVM.ActiveChallenge
    let mode: ChallengesView.Segment

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            headerRow
            subtitleText
            modeSection
        }
        .padding(14)
        .background(cardBackground)
    }

    private var headerRow: some View {
        HStack {
            Text(active.template.title)
                .font(.system(size: 16, weight: .heavy, design: .rounded))
                .foregroundColor(.white.opacity(0.95))
                .lineLimit(1)

            Spacer()

            Text(active.template.levelDisplay)
                .font(.system(size: 12, weight: .heavy, design: .rounded))
                .foregroundColor(.white.opacity(0.90))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Capsule().fill(Color.appGreen.opacity(0.18)))
                .overlay(Capsule().stroke(Color.appGreen.opacity(0.55), lineWidth: 1))
        }
    }

    private var subtitleText: some View {
        Text(active.template.subtitle)
            .font(.system(size: 12, weight: .semibold, design: .rounded))
            .foregroundColor(.white.opacity(0.55))
            .lineLimit(2)
    }

    @ViewBuilder
    private var modeSection: some View {
        switch mode {
        case .pending:
            // ✅ Pendiente muestra la barra (lo que era “Progreso” antes)
            progressBlock
        case .completed:
            completedBlock
        }
    }

    private var progressBlock: some View {
        VStack(alignment: .leading, spacing: 6) {
            SwiftUI.ProgressView(value: active.progress01)
                .tint(Color.appGreen.opacity(0.9))

            Text("Día \(active.dayIndex) de \(active.totalDays) • Restan \(active.remainingDays)")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.55))
        }
    }

    private var completedBlock: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.seal.fill")
                .foregroundColor(Color.appGreen.opacity(0.95))
            Text("Completado")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.60))
            Spacer()
        }
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(Color.white.opacity(0.06))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.appGreen.opacity(0.22), lineWidth: 1)
            )
    }
}

// MARK: - Models (UI)

private struct QuickCard: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let icon: String
}

// MARK: - Quick Card View

private struct QuickCardView: View {
    let item: QuickCard

    var body: some View {
        HStack(spacing: 12) {

            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.appGreen.opacity(0.18))
                    .frame(width: 44, height: 44)

                Image(systemName: item.icon)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color.appGreen.opacity(0.95))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .foregroundColor(.white.opacity(0.92))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .minimumScaleFactor(0.82)
                    .allowsTightening(true)
                    .textCase(nil)

                Text(item.subtitle)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.55))
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            RoundedRectangle(cornerRadius: 2)
                .fill(Color.appGreen.opacity(0.55))
                .frame(width: 3, height: 18)
        }
        .padding(14)
        .frame(height: 92)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.appGreen.opacity(0.20), lineWidth: 1)
                )
        )
    }
}

#Preview {
    NavigationStack {
        ChallengesView()
            .environmentObject(SessionManager())
    }
}
