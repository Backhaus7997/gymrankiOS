//
//  DiscoverView.swift
//  gymrankiOS
//
//  Created by Martin Backhaus on 10/02/2026.
//

import SwiftUI

struct ChallengesDiscoverView: View {

    enum Segment: String, CaseIterable, Identifiable {
        case discover = "Descubrir"
        case library = "Mi biblioteca"
        var id: String { rawValue }
    }

    @Environment(\.dismiss) private var dismiss
    @State private var selected: Segment = .discover
    @State private var query: String = ""

    private var challenges: [ChallengeItem] {
        // en un futuro: si selected == .library -> otra data
        let base = ChallengeItem.mock
        if query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return base }
        let q = query.lowercased()
        return base.filter {
            $0.title.lowercased().contains(q) ||
            $0.subtitle.lowercased().contains(q) ||
            $0.level.rawValue.lowercased().contains(q)
        }
    }

    var body: some View {
        ZStack {
            AppBackground().ignoresSafeArea()

            VStack(spacing: 14) {
                topBar
                segmented
                searchBar

                HStack {
                    Text("Total: \(challenges.count)")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.55))
                    Spacer()
                }
                .padding(.horizontal, 16)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        ForEach(challenges) { item in
                            ChallengeCard(item: item)
                        }
                        Spacer().frame(height: 22)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 14)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
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
    let item: ChallengeItem

    var body: some View {
        Button {
            print("open challenge \(item.title)")
        } label: {
            HStack(spacing: 12) {
                imageThumb

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(item.title)
                            .font(.system(size: 16, weight: .heavy, design: .rounded))
                            .foregroundColor(.white.opacity(0.95))
                            .lineLimit(1)

                        Spacer()

                        if item.isHot {
                            Text("🔥")
                                .font(.system(size: 16))
                        }
                    }

                    Text(item.subtitle)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.55))
                        .lineLimit(2)

                    HStack(spacing: 8) {
                        TagPill(text: item.level.rawValue)
                        TagPill(text: item.durationText)
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

            if let name = item.imageName {
                Image(name)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 118, height: 78)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            } else {
                Image(systemName: item.fallbackIcon)
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
                    .overlay(
                        Capsule().stroke(Color.appGreen.opacity(0.55), lineWidth: 1)
                    )
            )
    }
}

// MARK: - Model

private struct ChallengeItem: Identifiable {
    enum Level: String {
        case principiante = "Principiante"
        case intermedio = "Intermedio"
        case avanzado = "Avanzado"
        case experto = "Experto"
    }

    let id = UUID()
    let title: String
    let subtitle: String
    let level: Level
    let durationDays: Int
    let isHot: Bool

    /// Nombre del asset (Assets.xcassets). Ej: "challenge_walk", "challenge_dumbbell"
    /// Si es nil, se usa fallbackIcon (SF Symbol).
    let imageName: String?

    /// SF Symbol fallback (si imageName == nil)
    let fallbackIcon: String

    var durationText: String { "\(durationDays) DÍAS" }

    // ✅ Asigná acá los nombres de tus assets
    // Cargás imágenes en Assets con esos nombres y automáticamente reemplazan los símbolos.
    static let mock: [ChallengeItem] = [
        .init(
            title: "Los 50 diarios",
            subtitle: "Completá el desafío de peso corporal de 50 días",
            level: .intermedio,
            durationDays: 50,
            isHot: true,
            imageName: "challenge1",
            fallbackIcon: "figure.walk"
        ),
        .init(
            title: "Desafío 75 Hard",
            subtitle: "Un desafío para fortalecer la mentalidad",
            level: .experto,
            durationDays: 75,
            isHot: false,
            imageName: "challenge2",
            fallbackIcon: "dumbbell.fill"
        ),
        .init(
            title: "Quemá entre 500–750 kcal por día…",
            subtitle: "Quemá 500–750 kcal diarias con pasos y cardio",
            level: .avanzado,
            durationDays: 30,
            isHot: false,
            imageName: "challenge3",
            fallbackIcon: "flame.fill"
        ),
        .init(
            title: "10.000 pasos diarios",
            subtitle: "Caminá al menos 10k pasos todos los días",
            level: .principiante,
            durationDays: 21,
            isHot: false,
            imageName: "challenge4",
            fallbackIcon: "figure.walk.motion"
        )
    ]
}

#Preview {
    NavigationStack {
        ChallengesDiscoverView()
    }
}
