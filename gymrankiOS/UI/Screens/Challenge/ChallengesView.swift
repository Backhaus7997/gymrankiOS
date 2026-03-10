//
//  ChallengesView.swift
//  gymrankiOS
//

import SwiftUI

// MARK: - ViewModel

@MainActor
final class ChallengesHomeVM: ObservableObject {
    @Published var isLoading = false
    @Published var activeEntries: [Entry] = []
    @Published var completedEntries: [Entry] = []
    @Published var errorMessage: String?

    private let challengeRepo = ChallengeRepository()
    private let missionRepo = MissionRepository()
    private let betRepo = BetRepository()

    // MARK: Types

    struct ActiveChallenge: Identifiable, Hashable {
        let id: String
        let userChallenge: UserChallenge
        let template: ChallengeTemplate

        var elapsedDays: Int { max(0, Int(Date().timeIntervalSince(userChallenge.startedDate) / 86400.0)) }
        var totalDays: Int { max(template.durationDays, 1) }
        var remainingDays: Int { max(0, template.durationDays - elapsedDays) }

        var progress01: Double {
            if template.durationDays == 0 { return userChallenge.status == UserChallengeStatus.completed ? 1.0 : 0.0 }
            guard template.durationDays > 0 else { return 0.0 }
            if userChallenge.status == UserChallengeStatus.completed { return 1.0 }
            return min(Double(elapsedDays) / Double(template.durationDays), 1.0)
        }

        var dayIndex: Int { min(elapsedDays + 1, totalDays) }
        var sortKey: Int64 { userChallenge.createdAt }
    }

    struct ActiveMission: Identifiable, Hashable {
        let id: String
        let userMission: UserMission
        let template: MissionTemplate

        var elapsedDays: Int { max(0, Int(Date().timeIntervalSince(userMission.startedDate) / 86400.0)) }
        var totalDays: Int { max(template.durationDays, 1) }
        var remainingDays: Int { max(0, template.durationDays - elapsedDays) }

        var progress01: Double {
            guard template.durationDays > 0 else { return 0 }
            if userMission.status == UserMissionStatus.completed { return 1.0 }
            return min(1.0, Double(elapsedDays) / Double(template.durationDays))
        }

        var dayIndex: Int { min(elapsedDays + 1, totalDays) }
        var sortKey: Int64 { userMission.createdAt }
    }

    struct ActiveBet: Identifiable, Hashable {
        let id: String
        let userBet: UserBet
        let template: BetTemplate

        var completedTasks: Int {
            zip(template.tasks, userBet.progress).filter { (task, value) in value >= task.target }.count
        }

        var totalTasks: Int { template.tasks.count }

        var progress01: Double {
            guard totalTasks > 0 else { return 0 }
            return min(1.0, Double(completedTasks) / Double(totalTasks))
        }

        var progressLine: String {
            "Tareas \(completedTasks)/\(max(totalTasks, 0))"
        }

        var subtitle: String {
            template.durationType == "daily"
                ? "Completá todas las tareas en 24 horas"
                : "Completá todas las tareas en 3 horas"
        }

        var levelDisplay: String { template.difficultyDisplay }
        var sortKey: Int64 { userBet.createdAt }
    }

    enum Entry: Identifiable, Hashable {
        case challenge(ActiveChallenge)
        case mission(ActiveMission)
        case bet(ActiveBet)

        var id: String {
            switch self {
            case .challenge(let c): return "challenge_\(c.id)"
            case .mission(let m): return "mission_\(m.id)"
            case .bet(let b): return "bet_\(b.id)"
            }
        }

        var kindLabel: String {
            switch self {
            case .challenge: return "DESAFÍO"
            case .mission: return "MISIÓN"
            case .bet: return "APUESTA"
            }
        }

        var title: String {
            switch self {
            case .challenge(let c): return c.template.title
            case .mission(let m): return m.template.title
            case .bet(let b): return b.template.title
            }
        }

        var subtitle: String {
            switch self {
            case .challenge(let c): return c.template.subtitle
            case .mission(let m): return m.template.subtitle
            case .bet(let b): return b.subtitle
            }
        }

        var levelDisplay: String {
            switch self {
            case .challenge(let c): return c.template.levelDisplay
            case .mission(let m): return m.template.levelDisplay
            case .bet(let b): return b.levelDisplay
            }
        }

        var progress01: Double {
            switch self {
            case .challenge(let c): return c.progress01
            case .mission(let m): return m.progress01
            case .bet(let b): return b.progress01
            }
        }

        var progressLine: String {
            switch self {
            case .challenge(let c):
                return "Día \(c.dayIndex) de \(c.totalDays) • Restan \(c.remainingDays)"
            case .mission(let m):
                return "Día \(m.dayIndex) de \(m.totalDays) • Restan \(m.remainingDays)"
            case .bet(let b):
                return b.progressLine
            }
        }

        var sortKey: Int64 {
            switch self {
            case .challenge(let c): return c.sortKey
            case .mission(let m): return m.sortKey
            case .bet(let b): return b.sortKey
            }
        }
    }

    // MARK: Load

    func load(uid: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            async let chAllTask = challengeRepo.fetchUserChallenges(uid: uid, onlyActive: false)
            async let msAllTask = missionRepo.fetchUserMissions(uid: uid, onlyActive: false)
            async let btAllTask = betRepo.fetchUserBets(uid: uid, onlyActive: false)

            let (chAll, msAll, btAll) = try await (chAllTask, msAllTask, btAllTask)

            let chActive = chAll.filter { $0.status == UserChallengeStatus.active }
            let chCompleted = chAll.filter { $0.status == UserChallengeStatus.completed }

            let msActive = msAll.filter { $0.status == UserMissionStatus.active }
            let msCompleted = msAll.filter { $0.status == UserMissionStatus.completed }

            let btActive = btAll.filter { $0.status == UserBetStatus.active }
            let btCompleted = btAll.filter { $0.status == UserBetStatus.completed }

            let chIds = Array(Set((chActive + chCompleted).map { $0.templateId }))
            let msIds = Array(Set((msActive + msCompleted).map { $0.templateId }))
            let btIds = Array(Set((btActive + btCompleted).map { $0.templateId }))

            async let chTemplatesTask = challengeRepo.fetchTemplates(byIds: chIds)
            async let msTemplatesTask = missionRepo.fetchTemplates(byIds: msIds)
            async let btTemplatesTask = betRepo.fetchTemplates(byIds: btIds)

            let (chTemplates, msTemplates, btTemplates) = try await (chTemplatesTask, msTemplatesTask, btTemplatesTask)

            let chMap: [String: ChallengeTemplate] = Dictionary(uniqueKeysWithValues: chTemplates.map { ($0.id, $0) })
            let msMap: [String: MissionTemplate] = Dictionary(uniqueKeysWithValues: msTemplates.map { ($0.id, $0) })
            let btMap: [String: BetTemplate] = Dictionary(uniqueKeysWithValues: btTemplates.map { ($0.id, $0) })

            func buildChallengeEntries(_ list: [UserChallenge]) -> [Entry] {
                list.compactMap { uc in
                    guard let tpl = chMap[uc.templateId] else { return nil }
                    return .challenge(.init(id: "\(uc.templateId)_\(uc.uid)", userChallenge: uc, template: tpl))
                }
            }

            func buildMissionEntries(_ list: [UserMission]) -> [Entry] {
                list.compactMap { um in
                    guard let tpl = msMap[um.templateId] else { return nil }
                    return .mission(.init(id: "\(um.templateId)_\(um.uid)", userMission: um, template: tpl))
                }
            }

            func buildBetEntries(_ list: [UserBet]) -> [Entry] {
                list.compactMap { ub in
                    guard let tpl = btMap[ub.templateId] else { return nil }
                    return .bet(.init(id: "\(ub.templateId)_\(ub.uid)", userBet: ub, template: tpl))
                }
            }

            var activeMerged = buildChallengeEntries(chActive) + buildMissionEntries(msActive) + buildBetEntries(btActive)
            var completedMerged = buildChallengeEntries(chCompleted) + buildMissionEntries(msCompleted) + buildBetEntries(btCompleted)

            activeMerged.sort { $0.sortKey > $1.sortKey }
            completedMerged.sort { $0.sortKey > $1.sortKey }

            self.activeEntries = activeMerged
            self.completedEntries = completedMerged

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
    @State private var selectedEntry: ChallengesHomeVM.Entry? = nil

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

    private var listToShow: [ChallengesHomeVM.Entry] {
        selected == .pending ? vm.activeEntries : vm.completedEntries
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
                    entriesSection

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
                SwiftUI.ProgressView().tint(.white.opacity(0.9))
            }
        }
        .task { await reload() }
        .onReceive(NotificationCenter.default.publisher(for: .betCreated)) { _ in
            Task { await reload() }
        }
        .navigationBarBackButtonHidden(true)
        .navigationDestination(item: $route) { r in
            switch r {
            case .discover: ChallengesDiscoverView()
            case .missions: MissionsView()
            }
        }
        .navigationDestination(item: $selectedEntry) { e in
            switch e {
            case .challenge(let c):
                ActiveChallengeDetailView(active: c) { Task { await reload() } }
            case .mission(let m):
                ActiveMissionDetailView(active: m) { Task { await reload() } }
            case .bet(let b):
                ActiveBetDetailView(active: b) { Task { await reload() } }
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

    @MainActor
    private func reload() async {
        let cleanUid = uid.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanUid.isEmpty else { return }
        await vm.load(uid: cleanUid)
    }

    // MARK: - Top bar

    private var topBar: some View {
        HStack {
            Text("Desafíos")
                .font(.system(size: 34, weight: .heavy, design: .rounded))
                .foregroundColor(.white)

            Spacer()

            Button { print("menu") } label: {
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
                Button { handleQuickTap(item.title) } label: {
                    QuickCardView(item: item)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func handleQuickTap(_ title: String) {
        switch title {
        case "Descubrir": route = .discover
        case "Misiones": route = .missions
        case "Equipamiento": showEquipmentSheet = true
        case "Apuestas": showDestinyBetPopup = true
        default: break
        }
    }

    // MARK: - Segmented

    private var segmented: some View {
        HStack(spacing: 10) {
            ForEach(Segment.allCases) { seg in
                Button { selected = seg } label: {
                    HStack(spacing: 8) {
                        Image(systemName: seg.icon).font(.system(size: 13, weight: .bold))
                        Text(seg.rawValue)
                            .font(.system(size: 13, weight: .heavy, design: .rounded))
                            .lineLimit(1)
                    }
                    .foregroundColor(selected == seg ? Color.appGreen : .white.opacity(0.55))
                    .padding(.vertical, 10)
                    .padding(.horizontal, 12)
                    .frame(maxWidth: .infinity)
                    .background(Capsule().fill(selected == seg ? Color.appGreen.opacity(0.12) : Color.white.opacity(0.06)))
                    .overlay(Capsule().stroke(selected == seg ? Color.appGreen.opacity(0.35) : Color.white.opacity(0.10), lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.top, 2)
    }

    // MARK: - Entries Section

    @ViewBuilder
    private var entriesSection: some View {
        if listToShow.isEmpty {
            emptyStateCard
        } else {
            VStack(spacing: 14) {
                ForEach(listToShow) { entry in
                    Button { selectedEntry = entry } label: {
                        HomeEntryCard(entry: entry, mode: selected)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.top, 6)
        }
    }

    private var emptyStateCard: some View {
        let title = (selected == .pending) ? "No hay pendientes" : "No hay completados"
        let subtitle = (selected == .pending) ? "Sumate a un desafío, misión o apuesta" : "Completá uno para verlo acá"

        return VStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.black.opacity(0.25))
                .frame(height: 210)
                .overlay(
                    Image(systemName: selected == .pending ? "flag.checkered" : "checkmark.seal.fill")
                        .font(.system(size: 54, weight: .bold))
                        .foregroundColor(.white.opacity(0.30))
                )
                .overlay(RoundedRectangle(cornerRadius: 22).stroke(Color.white.opacity(0.10), lineWidth: 1))
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
                .overlay(RoundedRectangle(cornerRadius: 22).stroke(Color.appGreen.opacity(0.22), lineWidth: 1))
        )
        .padding(.top, 6)
    }
}

// MARK: - Card

private struct HomeEntryCard: View {
    let entry: ChallengesHomeVM.Entry
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
        HStack(spacing: 10) {
            Text(entry.title)
                .font(.system(size: 16, weight: .heavy, design: .rounded))
                .foregroundColor(.white.opacity(0.95))
                .lineLimit(1)

            Spacer()

            kindPill
            levelPill
        }
    }

    private var kindPill: some View {
        Text(entry.kindLabel)
            .font(.system(size: 11, weight: .heavy, design: .rounded))
            .foregroundColor(.white.opacity(0.85))
            .lineLimit(1)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Capsule().fill(Color.white.opacity(0.06)))
            .overlay(Capsule().stroke(Color.white.opacity(0.10), lineWidth: 1))
    }

    private var levelPill: some View {
        Text(entry.levelDisplay)
            .font(.system(size: 12, weight: .heavy, design: .rounded))
            .foregroundColor(.white.opacity(0.90))
            .lineLimit(1)
            .minimumScaleFactor(0.75)
            .allowsTightening(true)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Capsule().fill(Color.appGreen.opacity(0.18)))
            .overlay(Capsule().stroke(Color.appGreen.opacity(0.55), lineWidth: 1))
            .fixedSize(horizontal: true, vertical: false)
    }

    private var subtitleText: some View {
        Text(entry.subtitle)
            .font(.system(size: 12, weight: .semibold, design: .rounded))
            .foregroundColor(.white.opacity(0.55))
            .lineLimit(2)
    }

    @ViewBuilder
    private var modeSection: some View {
        switch mode {
        case .pending: progressBlock
        case .completed: completedBlock
        }
    }

    private var progressBlock: some View {
        VStack(alignment: .leading, spacing: 6) {
            SwiftUI.ProgressView(value: entry.progress01)
                .tint(Color.appGreen.opacity(0.9))

            Text(entry.progressLine)
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
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.appGreen.opacity(0.22), lineWidth: 1))
    }
}

// MARK: - Models (UI)

private struct QuickCard: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let icon: String
}

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
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                    .allowsTightening(true)

                Text(item.subtitle)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.55))
                    .lineLimit(2)
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
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.appGreen.opacity(0.20), lineWidth: 1))
        )
    }
}
