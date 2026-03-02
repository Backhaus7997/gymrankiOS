//
//  ChallengesDiscoverView.swift
//  gymrankiOS
//

import SwiftUI

// MARK: - VM

@MainActor
final class ChallengesDiscoverVM: ObservableObject {
    @Published var isLoading = false
    @Published var templates: [ChallengeTemplate] = []
    @Published var joinedActiveTemplateIds: Set<String> = []
    @Published var joinedTemplateIds: Set<String> = []
    @Published var libraryTemplates: [ChallengeTemplate] = []
    @Published var errorMessage: String?

    private let repo = ChallengeRepository()

    func load(uid: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            async let activeTemplatesTask = repo.fetchActiveTemplates()
            async let activeUserChallengesTask = repo.fetchUserChallenges(uid: uid, onlyActive: true)

            let (activeTemplates, activeUserChallenges) = try await (activeTemplatesTask, activeUserChallengesTask)

            self.templates = activeTemplates
            self.joinedActiveTemplateIds = Set(activeUserChallenges.map { $0.templateId })

            // Traigo TODOS los challenges del usuario (para filtrar Discover y armar biblioteca)
            let allUserChallenges = try await repo.fetchUserChallenges(uid: uid, onlyActive: false)
            self.joinedTemplateIds = Set(allUserChallenges.map { $0.templateId })

            let ids = Array(Set(allUserChallenges.map { $0.templateId }))
            self.libraryTemplates = try await repo.fetchTemplates(byIds: ids)

        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
}

// MARK: - View

struct ChallengesDiscoverView: View {

    enum Segment: String, CaseIterable, Identifiable {
        case discover = "Descubrir"
        case library = "Mi biblioteca"
        var id: String { rawValue }
    }

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var session: SessionManager

    @StateObject private var vm = ChallengesDiscoverVM()

    @State private var selected: Segment = .discover
    @State private var query: String = ""
    @State private var selectedTemplate: ChallengeTemplate? = nil

    private var uid: String { session.userId }

    /// ✅ Base list según segmento + filtro para que Discover no muestre los ya agregados
    private var baseList: [ChallengeTemplate] {
        switch selected {
        case .discover:
            return vm.templates.filter { !vm.joinedTemplateIds.contains($0.id) }
        case .library:
            return vm.libraryTemplates
        }
    }

    private var filtered: [ChallengeTemplate] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return baseList }

        return baseList.filter {
            $0.title.lowercased().contains(q) ||
            $0.subtitle.lowercased().contains(q) ||
            $0.levelDisplay.lowercased().contains(q) ||
            $0.tags.contains(where: { $0.lowercased().contains(q) })
        }
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

            VStack(spacing: 14) {
                topBar
                segmented
                searchBar

                HStack {
                    Text("Total: \(filtered.count)")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.55))
                    Spacer()
                }
                .padding(.horizontal, 16)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        ForEach(filtered, id: \.self) { item in
                            ChallengeCard(
                                template: item,
                                /// En biblioteca puede que sea completed/cancelled; igualmente “ya lo tiene”
                                isInLibrary: vm.joinedTemplateIds.contains(item.id),
                                isActive: vm.joinedActiveTemplateIds.contains(item.id)
                            ) {
                                selectedTemplate = item
                            }
                        }
                        Spacer().frame(height: 22)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 14)
                }
            }

            if vm.isLoading {
                VStack {
                    SwiftUI.ProgressView().tint(.white.opacity(0.9))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black.opacity(0.15))
            }
        }
        .task {
            let cleanUid = uid.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !cleanUid.isEmpty else { return }
            await vm.load(uid: cleanUid)
        }
        .navigationBarBackButtonHidden(true)
        .navigationDestination(item: $selectedTemplate) { tpl in
            ChallengeDetailView(
                template: tpl,
                /// ✅ Deshabilita “Unirme” si YA lo agregó alguna vez
                isJoined: vm.joinedTemplateIds.contains(tpl.id),
                onJoined: {
                    Task {
                        let cleanUid = uid.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !cleanUid.isEmpty else { return }
                        await vm.load(uid: cleanUid)
                    }
                }
            )
        }
        .alert("Error", isPresented: showError, actions: {
            Button("OK") { vm.errorMessage = nil }
        }, message: {
            Text(vm.errorMessage ?? "")
        })
    }

    // MARK: - TopBar

    private var topBar: some View {
        HStack(spacing: 12) {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white.opacity(0.92))
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(Color.white.opacity(0.06)))
                    .overlay(Circle().stroke(Color.white.opacity(0.10), lineWidth: 1))
            }
            .buttonStyle(.plain)

            Text("Desafíos")
                .font(.system(size: 20, weight: .heavy, design: .rounded))
                .foregroundColor(.white.opacity(0.95))

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
    }

    // MARK: - Segmented

    private var segmented: some View {
        HStack(spacing: 10) {
            ForEach(Segment.allCases) { seg in
                Button {
                    selected = seg
                } label: {
                    Text(seg.rawValue)
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                        .foregroundColor(selected == seg ? .white.opacity(0.95) : .white.opacity(0.65))
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(selected == seg ? Color.appGreen.opacity(0.22) : Color.white.opacity(0.06))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(selected == seg ? Color.appGreen.opacity(0.55) : Color.white.opacity(0.10), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Search

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.white.opacity(0.45))

            TextField("Buscar", text: $query)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.95))
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)

            if !query.isEmpty {
                Button { query = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white.opacity(0.35))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .frame(height: 46)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.white.opacity(0.10), lineWidth: 1)
                )
        )
        .padding(.horizontal, 16)
    }
}

// MARK: - Card

private struct ChallengeCard: View {
    let template: ChallengeTemplate
    let isInLibrary: Bool
    let isActive: Bool
    let onTap: () -> Void

    var body: some View {
        Button {
            onTap()
        } label: {
            HStack(spacing: 12) {

                imageThumb

                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Text(template.title)
                            .font(.system(size: 16, weight: .heavy, design: .rounded))
                            .foregroundColor(.white.opacity(0.95))
                            .lineLimit(1)

                        Spacer()

                        if template.hotDisplay {
                            Text("🔥").font(.system(size: 16))
                        }

                        // Badge “ya lo tiene”
                        if isInLibrary {
                            Image(systemName: isActive ? "checkmark.seal.fill" : "checkmark.circle.fill")
                                .foregroundColor(Color.appGreen.opacity(0.95))
                                .font(.system(size: 14, weight: .bold))
                        }
                    }

                    Text(template.subtitle)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.55))
                        .lineLimit(2)

                    HStack(spacing: 8) {
                        TagPill(text: template.levelDisplay)
                        TagPill(text: template.durationText)
                        Spacer()
                    }
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.white.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color.appGreen.opacity(0.25), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private var imageThumb: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.black.opacity(0.35))

            if let name = template.imageName, !name.isEmpty {
                Image(name)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 118, height: 78)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            } else {
                Image(systemName: fallbackIcon)
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundColor(.white.opacity(0.25))
            }
        }
        .frame(width: 118, height: 78)
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.10), lineWidth: 1)
        )
    }

    private var fallbackIcon: String {
        let tags = template.tags.map { $0.lowercased() }
        if tags.contains(where: { $0.contains("run") || $0.contains("running") }) { return "figure.run" }
        if tags.contains(where: { $0.contains("stretch") || $0.contains("mobility") }) { return "figure.cooldown" }
        if tags.contains(where: { $0.contains("warmup") }) { return "flame.fill" }
        return "flag.checkered"
    }
}

private struct TagPill: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 12, weight: .heavy, design: .rounded))
            .foregroundColor(.white.opacity(0.92))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(Color.appGreen.opacity(0.18))
                    .overlay(Capsule().stroke(Color.appGreen.opacity(0.55), lineWidth: 1))
            )
    }
}
