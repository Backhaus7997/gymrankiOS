//
//  ExploreView.swift
//  gymrankiOS
//

import SwiftUI
import FirebaseFirestore

// MARK: - ViewModel

@MainActor
final class ExploreVM: ObservableObject {
    @Published var isLoading = false
    @Published var templates: [WorkoutTemplate] = []
    @Published var errorMessage: String?

    private let db = Firestore.firestore()

    func loadAll() async {
        isLoading = true
        errorMessage = nil

        do {
            let snap = try await db
                .collection("workoutTemplates")
                .order(by: "updatedAt", descending: true)
                .getDocuments()

            templates = snap.documents.compactMap { Self.parseTemplate($0) }
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
        }
    }

    private static func parseTemplate(_ doc: QueryDocumentSnapshot) -> WorkoutTemplate? {
        let data = doc.data()

        guard
            let title = data["title"] as? String,
            let description = data["description"] as? String,
            let frequencyPerWeek = data["frequencyPerWeek"] as? Int,
            let goalTags = data["goalTags"] as? [String],
            let isPro = data["isPro"] as? Bool,
            let level = data["level"] as? String,
            let visibility = data["visibility"] as? String,
            let weeks = data["weeks"] as? Int
        else { return nil }

        return WorkoutTemplate(
            id: doc.documentID,
            title: title,
            description: description,
            frequencyPerWeek: frequencyPerWeek,
            goalTags: goalTags,
            isPro: isPro,
            level: level,
            visibility: visibility,
            weeks: weeks,
            createdAt: data["createdAt"] as? Timestamp,
            updatedAt: data["updatedAt"] as? Timestamp
        )
    }
}

// MARK: - ExploreView

struct ExploreView: View {

    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab: ExploreTab = .official
    @State private var query: String = ""

    @StateObject private var vm = ExploreVM()

    enum ExploreTab: String, CaseIterable, Identifiable {
        case official = "Oficial"
        case community = "Comunidad"
        var id: String { rawValue }

        var visibilityValue: String {
            switch self {
            case .official: return "official"
            case .community: return "community"
            }
        }
    }

    var body: some View {
        ZStack {
            AppBackground().ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {

                    topBar
                    headerCard
                    segmentedTabs
                    searchBar

                    if vm.isLoading {
                        loadingState
                    } else if let err = vm.errorMessage {
                        errorState(err)
                    } else {
                        programsList
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
                .padding(.top, 10)
            }
        }
        .navigationBarBackButtonHidden(true)
        .task {
            if vm.templates.isEmpty {
                await vm.loadAll()
            }
        }
    }

    // MARK: - Data

    private var filteredTemplates: [WorkoutTemplate] {
        let byTab = vm.templates.filter { $0.visibility.lowercased() == selectedTab.visibilityValue }

        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return byTab }

        return byTab.filter {
            $0.title.lowercased().contains(q) ||
            $0.description.lowercased().contains(q) ||
            $0.goalTags.joined(separator: " ").lowercased().contains(q)
        }
    }

    // MARK: - UI

    private var topBar: some View {
        HStack(spacing: 10) {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white.opacity(0.9))
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(Color.white.opacity(0.06)))
                    .overlay(Circle().stroke(Color.white.opacity(0.10), lineWidth: 1))
            }
            .buttonStyle(.plain)

            Text("Explorar")
                .font(.system(size: 20, weight: .heavy, design: .rounded))
                .foregroundColor(.white)

            Spacer()
        }
        .padding(.top, 4)
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Programas y rutinas")
                .font(.system(size: 16, weight: .heavy, design: .rounded))
                .foregroundColor(.white.opacity(0.95))

            Text("Elegí un programa y empezá hoy.")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.55))
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.white.opacity(0.10), lineWidth: 1)
                )
        )
    }

    private var segmentedTabs: some View {
        HStack(spacing: 10) {
            ForEach(ExploreTab.allCases) { tab in
                Button { selectedTab = tab } label: {
                    Text(tab.rawValue)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(selectedTab == tab ? .black : .white.opacity(0.85))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(selectedTab == tab ? Color.appGreen.opacity(0.95) : Color.black.opacity(0.25))
                        )
                        .overlay(Capsule().stroke(Color.white.opacity(0.10), lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
    }

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.white.opacity(0.45))

            TextField("Buscar programas...", text: $query)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
                .foregroundColor(.white.opacity(0.9))
        }
        .padding(.horizontal, 14)
        .frame(height: 48)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.25))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.10), lineWidth: 1)
                )
        )
    }

    private var programsList: some View {
        VStack(spacing: 14) {
            ForEach(filteredTemplates) { t in
                NavigationLink {
                    ProgramDetailView(template: t)
                        .id(t.id)
                } label: {
                    ExploreProgramCard(
                        title: t.title,
                        subtitle: t.description,
                        tags: buildTags(for: t),
                        frequency: "\(t.frequencyPerWeek)x/sem",
                        level: t.level,
                        isPro: t.isPro,
                        imageName: imageName(for: t)
                    )
                    // ✅ Hace que TODA la card sea tappable, incluso zonas “vacías”
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .simultaneousGesture(TapGesture().onEnded {
                    print("OPEN TEMPLATE:", t.id, "| title:", t.title)
                })
            }

            if filteredTemplates.isEmpty {
                emptyState
            }
        }
    }

    private var loadingState: some View {
        VStack(spacing: 10) {
            ProgressView().tint(Color.appGreen.opacity(0.95))
            Text("Cargando programas…")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.6))
        }
        .padding(.top, 18)
    }

    private func errorState(_ msg: String) -> some View {
        VStack(spacing: 10) {
            Text("No se pudo cargar")
                .font(.system(size: 14, weight: .heavy, design: .rounded))
                .foregroundColor(.white.opacity(0.9))

            Text(msg)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.55))
                .multilineTextAlignment(.center)

            Button { Task { await vm.loadAll() } } label: {
                Text("Reintentar")
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .foregroundColor(.black)
                    .padding(.horizontal, 14)
                    .frame(height: 36)
                    .background(Capsule().fill(Color.appGreen.opacity(0.95)))
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 18)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Text("No hay programas")
                .font(.system(size: 14, weight: .heavy, design: .rounded))
                .foregroundColor(.white.opacity(0.9))
            Text("Probá con otra búsqueda o tab.")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.55))
        }
        .padding(.top, 18)
    }

    // MARK: - Helpers

    private func buildTags(for t: WorkoutTemplate) -> [String] {
        var out: [String] = []
        if t.isPro { out.append("PRO") }
        out.append("\(t.weeks) \(t.weeks == 1 ? "Semana" : "Semanas")")
        out.append(t.level)
        out.append(contentsOf: t.goalTags)

        var seen = Set<String>()
        return out.filter { seen.insert($0).inserted }
    }

    private func imageName(for t: WorkoutTemplate) -> String? {
        let lower = t.title.lowercased()
        if lower.contains("candito") { return "program1" }
        if lower.contains("juggernaut") { return "program2" }
        return nil
    }
}

// MARK: - Program Card (incluida acá para que exista)

private struct ExploreProgramCard: View {

    let title: String
    let subtitle: String
    let tags: [String]
    let frequency: String
    let level: String
    let isPro: Bool
    let imageName: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            ZStack(alignment: .topLeading) {
                headerImage

                if isPro {
                    Badge(text: "PRO")
                        .padding(10)
                        .allowsHitTesting(false)
                }
            }

            Text(title)
                .font(.system(size: 17, weight: .heavy, design: .rounded))
                .foregroundColor(.white.opacity(0.95))
                .allowsHitTesting(false)

            Text(subtitle)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.55))
                .allowsHitTesting(false)

            FlowTags(tags: tags)
                .allowsHitTesting(false)

            HStack(spacing: 10) {
                InfoMiniCard(title: "Frecuencia", value: frequency)
                    .allowsHitTesting(false)
                InfoMiniCard(title: "Nivel", value: level)
                    .allowsHitTesting(false)

                Spacer()

                Text("Ver")
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .foregroundColor(.black)
                    .frame(width: 64, height: 36)
                    .background(Capsule().fill(Color.appGreen.opacity(0.95)))
                    .allowsHitTesting(false)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.black.opacity(0.25))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.appGreen.opacity(0.12), lineWidth: 1)
                )
        )
    }

    private var headerImage: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.06))

            if let name = imageName {
                Image(name)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 78)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            } else {
                Image(systemName: "photo")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.white.opacity(0.25))
            }
        }
        .frame(height: 78)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.10), lineWidth: 1)
        )
        .allowsHitTesting(false)
    }
}

private struct Badge: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.system(size: 12, weight: .heavy, design: .rounded))
            .foregroundColor(Color.appGreen.opacity(0.95))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Capsule().fill(Color.black.opacity(0.45)))
            .overlay(Capsule().stroke(Color.appGreen.opacity(0.35), lineWidth: 1))
    }
}

private struct FlowTags: View {
    let tags: [String]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(tags, id: \.self) { tag in
                    Text(tag)
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(tag == "PRO" ? Color.appGreen.opacity(0.95) : .white.opacity(0.75))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(Color.white.opacity(0.06)))
                        .overlay(Capsule().stroke(Color.white.opacity(0.10), lineWidth: 1))
                }
            }
        }
    }
}

private struct InfoMiniCard: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.45))

            Text(value)
                .font(.system(size: 12, weight: .heavy, design: .rounded))
                .foregroundColor(.white.opacity(0.90))
        }
        .padding(10)
        .frame(width: 120, height: 54, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.06))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.10), lineWidth: 1))
        )
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ExploreView()
    }
}
